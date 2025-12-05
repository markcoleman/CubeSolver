import Foundation
import CoreGraphics
import ImageIO
import Vision
import UniformTypeIdentifiers

// MARK: - Helpers

struct RGB {
    let r: CGFloat
    let g: CGFloat
    let b: CGFloat
}

enum CubeColor: String {
    case white = "W", yellow = "Y", blue = "B", green = "G", red = "R", orange = "O", unknown = "?"
}

func loadImage(path: String) -> CGImage? {
    guard let url = URL(string: "file://" + path) else { return nil }
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(source, 0, nil)
}

func averageColor(in image: CGImage, rect: CGRect) -> RGB? {
    guard let cropped = image.cropping(to: rect) else { return nil }
    guard let context = CGContext(
        data: nil,
        width: 1,
        height: 1,
        bitsPerComponent: 8,
        bytesPerRow: 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    context.interpolationQuality = .high
    context.draw(cropped, in: CGRect(x: 0, y: 0, width: 1, height: 1))
    guard let data = context.data else { return nil }

    let pixel = data.bindMemory(to: UInt8.self, capacity: 4)
    return RGB(r: CGFloat(pixel[0]) / 255.0,
               g: CGFloat(pixel[1]) / 255.0,
               b: CGFloat(pixel[2]) / 255.0)
}

func classify(_ rgb: RGB) -> CubeColor {
    let colors: [(CubeColor, RGB)] = [
        (.white,  RGB(r: 0.9, g: 0.9, b: 0.9)),
        (.yellow, RGB(r: 0.95, g: 0.85, b: 0.15)),
        (.blue,   RGB(r: 0.1, g: 0.2,  b: 0.8)),
        (.green,  RGB(r: 0.1, g: 0.6,  b: 0.2)),
        (.red,    RGB(r: 0.8, g: 0.1,  b: 0.1)),
        (.orange, RGB(r: 0.95, g: 0.45, b: 0.1))
    ]

    func distance(_ lhs: RGB, _ rhs: RGB) -> CGFloat {
        let dr = lhs.r - rhs.r
        let dg = lhs.g - rhs.g
        let db = lhs.b - rhs.b
        return sqrt(dr * dr + dg * dg + db * db)
    }

    return colors.min(by: { distance(rgb, $0.1) < distance(rgb, $1.1) })?.0 ?? .unknown
}

func detectCubeRect(in image: CGImage) -> CGRect? {
    let request = VNDetectRectanglesRequest()
    request.minimumAspectRatio = 0.8
    request.maximumAspectRatio = 1.2
    request.minimumSize = 0.2
    request.maximumObservations = 3
    request.minimumConfidence = 0.5
    
    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    do {
        try handler.perform([request])
        guard let best = request.results?.first else { return nil }
        let bbox = best.boundingBox
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let rect = CGRect(
            x: bbox.minX * width,
            y: (1 - bbox.maxY) * height,
            width: bbox.width * width,
            height: bbox.height * height
        )
        // Force to square to align with cube face
        let side = min(rect.width, rect.height)
        let square = CGRect(
            x: rect.midX - side / 2,
            y: rect.midY - side / 2,
            width: side,
            height: side
        )
        let imageBounds = CGRect(origin: .zero, size: CGSize(width: width, height: height))
        let clamped = square.intersection(imageBounds)
        return clamped.isNull ? nil : clamped
    } catch {
        print("Detection failed: \(error.localizedDescription)")
        return nil
    }
}

// MARK: - Main

let imagePath = FileManager.default.currentDirectoryPath + "/cube.jpeg"
guard let image = loadImage(path: imagePath) else {
    fatalError("Unable to load cube.jpeg; place it next to this script.")
}

let detectedRect = detectCubeRect(in: image)
let samplingImage: CGImage
if let rect = detectedRect, let cropped = image.cropping(to: rect) {
    samplingImage = cropped
    print("Detected cube face, sampling within \(rect)")
} else {
    samplingImage = image
    print("Warning: Could not detect cube face. Sampling entire image.")
}

let width = CGFloat(samplingImage.width)
let height = CGFloat(samplingImage.height)
let gridSize = 3

var result: [[CubeColor]] = []

for row in 0..<gridSize {
    var line: [CubeColor] = []
    for col in 0..<gridSize {
        let cellRect = CGRect(
            x: CGFloat(col) * width / CGFloat(gridSize),
            y: CGFloat(row) * height / CGFloat(gridSize),
            width: width / CGFloat(gridSize),
            height: height / CGFloat(gridSize)
        ).insetBy(dx: width * 0.02, dy: height * 0.02)

        if let rgb = averageColor(in: samplingImage, rect: cellRect) {
            line.append(classify(rgb))
        } else {
            line.append(.unknown)
        }
    }
    result.append(line)
}

// Print 3×3 grid
print("Detected pattern:")
for row in result {
    print(row.map { $0.rawValue }.joined(separator: " "))
}