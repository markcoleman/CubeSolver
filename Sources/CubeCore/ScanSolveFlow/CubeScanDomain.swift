import Foundation

/// Canonical face IDs used throughout the scan -> solve flow.
public enum FaceId: String, CaseIterable, Codable, Sendable {
    case up = "U"
    case right = "R"
    case front = "F"
    case down = "D"
    case left = "L"
    case back = "B"

    /// Guided scan order shown to users while capturing faces.
    public static let guidedScanOrder: [FaceId] = [.up, .right, .front, .down, .left, .back]

    public var face: Face {
        switch self {
        case .up: return .up
        case .right: return .right
        case .front: return .front
        case .down: return .down
        case .left: return .left
        case .back: return .back
        }
    }

    public init(face: Face) {
        switch face {
        case .up: self = .up
        case .right: self = .right
        case .front: self = .front
        case .down: self = .down
        case .left: self = .left
        case .back: self = .back
        }
    }

    public var displayName: String {
        switch self {
        case .up: return "Up"
        case .right: return "Right"
        case .front: return "Front"
        case .down: return "Down"
        case .left: return "Left"
        case .back: return "Back"
        }
    }
}

public enum CubeFaceGridError: Error, LocalizedError, Equatable, Sendable {
    case invalidStickerCount(expected: Int, actual: Int)

    public var errorDescription: String? {
        switch self {
        case .invalidStickerCount(let expected, let actual):
            return "Each face requires \(expected) stickers. Found \(actual)."
        }
    }
}

/// 3x3 grid for a single cube face.
public struct CubeFaceGrid: Equatable, Codable, Sendable {
    public static let stickerCount = 9

    public var stickers: [CubeColor]

    public init(stickers: [CubeColor]) throws {
        guard stickers.count == Self.stickerCount else {
            throw CubeFaceGridError.invalidStickerCount(expected: Self.stickerCount, actual: stickers.count)
        }
        self.stickers = stickers
    }

    public init(repeating color: CubeColor) {
        self.stickers = Array(repeating: color, count: Self.stickerCount)
    }

    public subscript(index: Int) -> CubeColor {
        get { stickers[index] }
        set { stickers[index] = newValue }
    }

    public subscript(row: Int, column: Int) -> CubeColor {
        get {
            stickers[Self.flatten(row: row, column: column)]
        }
        set {
            stickers[Self.flatten(row: row, column: column)] = newValue
        }
    }

    public var center: CubeColor {
        stickers[4]
    }

    public var rows: [[CubeColor]] {
        [
            Array(stickers[0...2]),
            Array(stickers[3...5]),
            Array(stickers[6...8])
        ]
    }

    private static func flatten(row: Int, column: Int) -> Int {
        max(0, min(2, row)) * 3 + max(0, min(2, column))
    }
}

public struct ScannedFaceData: Equatable, Codable, Sendable {
    public let id: FaceId
    public var grid: CubeFaceGrid
    public let confidence: Float
    public let debugImagePath: String?

    public init(id: FaceId, grid: CubeFaceGrid, confidence: Float, debugImagePath: String? = nil) {
        self.id = id
        self.grid = grid
        self.confidence = confidence
        self.debugImagePath = debugImagePath
    }
}

public enum CubeStateAssemblyError: Error, LocalizedError, Equatable, Sendable {
    case missingFaces([FaceId])

    public var errorDescription: String? {
        switch self {
        case .missingFaces(let missing):
            let names = missing.map(\.rawValue).joined(separator: ", ")
            return "Missing scanned faces: \(names)."
        }
    }
}

public struct CubeStateAssembler: Sendable {
    public init() {}

    public func assemble(from scannedFaces: [FaceId: CubeFaceGrid]) throws -> CubeState {
        let missing = FaceId.guidedScanOrder.filter { scannedFaces[$0] == nil }
        guard missing.isEmpty else {
            throw CubeStateAssemblyError.missingFaces(missing)
        }

        var faces: [Face: [CubeColor]] = [:]
        for faceId in FaceId.guidedScanOrder {
            guard let grid = scannedFaces[faceId] else { continue }
            faces[faceId.face] = grid.stickers
        }

        return CubeState(faces: faces)
    }
}

public extension CubeState {
    func faceGrid(_ id: FaceId) -> CubeFaceGrid? {
        guard let stickers = faces[id.face], stickers.count == CubeFaceGrid.stickerCount else {
            return nil
        }
        return try? CubeFaceGrid(stickers: stickers)
    }

    mutating func setFaceGrid(_ grid: CubeFaceGrid, for id: FaceId) {
        faces[id.face] = grid.stickers
    }
}
