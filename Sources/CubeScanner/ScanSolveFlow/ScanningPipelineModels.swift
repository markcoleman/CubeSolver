import Foundation
import CubeCore

#if canImport(CoreVideo)
import CoreVideo
#endif

public struct RGBPixel: Equatable, Sendable {
    public let red: Float
    public let green: Float
    public let blue: Float

    public init(red: Float, green: Float, blue: Float) {
        self.red = max(0, min(1, red))
        self.green = max(0, min(1, green))
        self.blue = max(0, min(1, blue))
    }

    public static let black = RGBPixel(red: 0, green: 0, blue: 0)
}

public enum RGBFrameError: Error, LocalizedError, Equatable, Sendable {
    case invalidDimensions(width: Int, height: Int)
    case invalidPixelCount(expected: Int, actual: Int)

    public var errorDescription: String? {
        switch self {
        case .invalidDimensions(let width, let height):
            return "Invalid frame dimensions \(width)x\(height)."
        case .invalidPixelCount(let expected, let actual):
            return "Frame expected \(expected) pixels but received \(actual)."
        }
    }
}

public struct RGBFrame: Sendable {
    public let width: Int
    public let height: Int
    public let pixels: [RGBPixel]
#if canImport(CoreVideo)
    public let pixelBuffer: CVPixelBuffer?
#endif

    public init(width: Int, height: Int, pixels: [RGBPixel]) throws {
        try Self.validate(width: width, height: height, pixels: pixels)
        self.width = width
        self.height = height
        self.pixels = pixels
#if canImport(CoreVideo)
        self.pixelBuffer = nil
#endif
    }

#if canImport(CoreVideo)
    public init(width: Int, height: Int, pixels: [RGBPixel], pixelBuffer: CVPixelBuffer?) throws {
        try Self.validate(width: width, height: height, pixels: pixels)
        self.width = width
        self.height = height
        self.pixels = pixels
        self.pixelBuffer = pixelBuffer
    }
#endif

    private static func validate(width: Int, height: Int, pixels: [RGBPixel]) throws {
        guard width > 0 && height > 0 else {
            throw RGBFrameError.invalidDimensions(width: width, height: height)
        }

        let expectedCount = width * height
        guard pixels.count == expectedCount else {
            throw RGBFrameError.invalidPixelCount(expected: expectedCount, actual: pixels.count)
        }
    }

    public func pixel(x: Int, y: Int) -> RGBPixel {
        guard x >= 0, x < width, y >= 0, y < height else {
            return .black
        }
        return pixels[y * width + x]
    }
}

extension RGBFrame: Equatable {
    public static func == (lhs: RGBFrame, rhs: RGBFrame) -> Bool {
        lhs.width == rhs.width && lhs.height == rhs.height && lhs.pixels == rhs.pixels
    }
}

#if canImport(CoreVideo)
public extension RGBFrame {
    static func make(from pixelBuffer: CVPixelBuffer) -> RGBFrame? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return nil
        }

        var pixels: [RGBPixel] = []
        pixels.reserveCapacity(width * height)

        for y in 0..<height {
            let row = baseAddress.advanced(by: y * bytesPerRow).assumingMemoryBound(to: UInt8.self)
            for x in 0..<width {
                let offset = x * 4
                let blue = Float(row[offset]) / 255
                let green = Float(row[offset + 1]) / 255
                let red = Float(row[offset + 2]) / 255
                pixels.append(RGBPixel(red: red, green: green, blue: blue))
            }
        }

        return try? RGBFrame(width: width, height: height, pixels: pixels, pixelBuffer: pixelBuffer)
    }
}
#endif

public struct NormalizedPoint: Equatable, Codable, Sendable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct FaceQuadrilateral: Equatable, Codable, Sendable {
    public let topLeft: NormalizedPoint
    public let topRight: NormalizedPoint
    public let bottomRight: NormalizedPoint
    public let bottomLeft: NormalizedPoint

    public init(
        topLeft: NormalizedPoint,
        topRight: NormalizedPoint,
        bottomRight: NormalizedPoint,
        bottomLeft: NormalizedPoint
    ) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
    }

    /// Bilinear interpolation inside the quad where u,v are in [0,1].
    public func point(u: Double, v: Double) -> NormalizedPoint {
        let top = interpolate(from: topLeft, to: topRight, t: u)
        let bottom = interpolate(from: bottomLeft, to: bottomRight, t: u)
        return interpolate(from: top, to: bottom, t: v)
    }

    public static let centered = FaceQuadrilateral(
        topLeft: NormalizedPoint(x: 0.2, y: 0.2),
        topRight: NormalizedPoint(x: 0.8, y: 0.2),
        bottomRight: NormalizedPoint(x: 0.8, y: 0.8),
        bottomLeft: NormalizedPoint(x: 0.2, y: 0.8)
    )

    private func interpolate(from start: NormalizedPoint, to end: NormalizedPoint, t: Double) -> NormalizedPoint {
        let clamped = max(0, min(1, t))
        return NormalizedPoint(
            x: start.x + (end.x - start.x) * clamped,
            y: start.y + (end.y - start.y) * clamped
        )
    }
}

public struct StickerClassification: Equatable, Sendable {
    public let color: CubeColor
    public let confidence: Float

    public init(color: CubeColor, confidence: Float) {
        self.color = color
        self.confidence = max(0, min(1, confidence))
    }
}

public struct FaceSamplingResult: Equatable, Sendable {
    public let face: CubeFaceGrid
    public let stickerConfidences: [Float]
    public let meanConfidence: Float
    public let quadrilateral: FaceQuadrilateral

    public init(face: CubeFaceGrid, stickerConfidences: [Float], meanConfidence: Float, quadrilateral: FaceQuadrilateral) {
        self.face = face
        self.stickerConfidences = stickerConfidences
        self.meanConfidence = meanConfidence
        self.quadrilateral = quadrilateral
    }
}

public enum FaceScannerError: Error, LocalizedError, Equatable, Sendable {
    case noStableFaceDetected(face: FaceId)
    case scannerUnavailable

    public var errorDescription: String? {
        switch self {
        case .noStableFaceDetected(let face):
            return "Could not detect a stable \(face.displayName) face."
        case .scannerUnavailable:
            return "Scanner input is unavailable."
        }
    }
}

public protocol CameraFrameSource: Sendable {
    func nextFrame() async throws -> RGBFrame
}

public protocol FaceQuadDetecting: Sendable {
    func detectQuadrilateral(in frame: RGBFrame) async throws -> FaceQuadrilateral?
}

public protocol StickerColorClassifying: Sendable {
    func classify(pixel: RGBPixel) -> StickerClassification
}

public protocol FaceScanner: Sendable {
    func scanFace(for face: FaceId) async throws -> ScannedFaceData
}
