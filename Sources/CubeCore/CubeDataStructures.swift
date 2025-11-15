//
//  CubeDataStructures.swift
//  CubeSolver
//
//  Shared data structures for Rubik's Cube solver
//

import Foundation

// MARK: - Color Definitions

/// Represents the six standard colors on a Rubik's Cube
/// Aligned with existing FaceColor enum for backward compatibility
public enum CubeColor: String, CaseIterable, Codable, Equatable, Sendable {
    case white = "W"
    case yellow = "Y"
    case red = "R"
    case orange = "O"
    case blue = "B"
    case green = "G"
}

// MARK: - Face Definitions

/// Represents the six faces of a Rubik's Cube
public enum Face: String, CaseIterable, Codable, Equatable, Sendable {
    case up = "U"
    case down = "D"
    case left = "L"
    case right = "R"
    case front = "F"
    case back = "B"
    
    /// Returns the opposite face
    public var opposite: Face {
        switch self {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        case .front: return .back
        case .back: return .front
        }
    }
}

// MARK: - Cube State

/// Represents the complete state of a Rubik's Cube as 54 individual stickers
/// Each face has 9 stickers arranged in a 3x3 grid
public struct CubeState: Equatable, Codable, Sendable {
    /// Dictionary mapping each face to its 9 sticker colors
    /// Stickers are ordered from top-left to bottom-right (row by row)
    public var faces: [Face: [CubeColor]]
    
    /// Initializes a solved cube state with standard color configuration
    public init() {
        faces = [
            .up: Array(repeating: .white, count: 9),
            .down: Array(repeating: .yellow, count: 9),
            .left: Array(repeating: .green, count: 9),
            .right: Array(repeating: .blue, count: 9),
            .front: Array(repeating: .red, count: 9),
            .back: Array(repeating: .orange, count: 9)
        ]
    }
    
    /// Initializes a cube state with custom face colors
    public init(faces: [Face: [CubeColor]]) {
        self.faces = faces
    }
    
    /// Get the color of a specific sticker
    /// - Parameters:
    ///   - face: The face of the sticker
    ///   - index: The index of the sticker (0-8, top-left to bottom-right)
    /// - Returns: The color of the sticker
    public func getSticker(face: Face, index: Int) -> CubeColor? {
        guard index >= 0 && index < 9 else { return nil }
        return faces[face]?[index]
    }
    
    /// Set the color of a specific sticker
    /// - Parameters:
    ///   - face: The face of the sticker
    ///   - index: The index of the sticker (0-8, top-left to bottom-right)
    ///   - color: The color to set
    mutating func setSticker(face: Face, index: Int, color: CubeColor) {
        guard index >= 0 && index < 9 else { return }
        faces[face]?[index] = color
    }
    
    /// Get the center color of a face
    public func centerColor(of face: Face) -> CubeColor? {
        return faces[face]?[4] // Center is always at index 4
    }
}

// MARK: - Move Definitions

/// Represents the turn type (which face to rotate)
public enum Turn: String, CaseIterable, Codable, Equatable, Sendable {
    case U = "U" // Up/Top face
    case D = "D" // Down/Bottom face
    case L = "L" // Left face
    case R = "R" // Right face
    case F = "F" // Front face
    case B = "B" // Back face
    
    /// Convert to Face enum
    public var face: Face {
        switch self {
        case .U: return .up
        case .D: return .down
        case .L: return .left
        case .R: return .right
        case .F: return .front
        case .B: return .back
        }
    }
    
    /// Create from Face enum
    public init(from face: Face) {
        switch face {
        case .up: self = .U
        case .down: self = .D
        case .left: self = .L
        case .right: self = .R
        case .front: self = .F
        case .back: self = .B
        }
    }
}

/// Represents the amount of rotation
public enum Amount: String, CaseIterable, Codable, Equatable, Sendable {
    case clockwise = ""      // 90° clockwise (no suffix)
    case counter = "'"       // 90° counter-clockwise (prime)
    case double = "2"        // 180° (double turn)
    
    /// Number of 90° clockwise turns this amount represents
    public var quarters: Int {
        switch self {
        case .clockwise: return 1
        case .counter: return 3
        case .double: return 2
        }
    }
}

/// Represents a single move in a cube solution
public struct Move: Equatable, Codable, Sendable {
    /// The face to turn
    public let turn: Turn
    
    /// The amount to turn (clockwise, counter-clockwise, or double)
    public let amount: Amount
    
    /// Standard notation string (e.g., "R", "U'", "F2")
    public var notation: String {
        return turn.rawValue + amount.rawValue
    }
    
    /// Human-readable description
    public var description: String {
        let faceName: String
        switch turn {
        case .U: faceName = "top"
        case .D: faceName = "bottom"
        case .L: faceName = "left"
        case .R: faceName = "right"
        case .F: faceName = "front"
        case .B: faceName = "back"
        }
        
        let direction: String
        switch amount {
        case .clockwise: direction = "clockwise"
        case .counter: direction = "counter-clockwise"
        case .double: direction = "180 degrees"
        }
        
        return "Rotate \(faceName) face \(direction)"
    }
    
    /// Initialize from notation string (e.g., "R", "U'", "F2")
    public init?(notation: String) {
        guard !notation.isEmpty else { return nil }
        
        let turnChar = String(notation.prefix(1))
        guard let turn = Turn(rawValue: turnChar) else { return nil }
        self.turn = turn
        
        if notation.count == 1 {
            self.amount = .clockwise
        } else {
            let suffix = String(notation.suffix(1))
            guard let amount = Amount(rawValue: suffix) else { return nil }
            self.amount = amount
        }
    }
    
    /// Initialize with turn and amount
    public init(turn: Turn, amount: Amount = .clockwise) {
        self.turn = turn
        self.amount = amount
    }
}

// MARK: - Conversion Utilities

public extension CubeState {
    /// Convert from existing RubiksCube structure
    public init(from cube: RubiksCube) {
        self.init()
        
        // Convert each face
        self.faces[.front] = Self.flattenFace(cube.front)
        self.faces[.back] = Self.flattenFace(cube.back)
        self.faces[.left] = Self.flattenFace(cube.left)
        self.faces[.right] = Self.flattenFace(cube.right)
        self.faces[.up] = Self.flattenFace(cube.top)
        self.faces[.down] = Self.flattenFace(cube.bottom)
    }
    
    /// Convert to existing RubiksCube structure
    public func toRubiksCube() -> RubiksCube {
        var cube = RubiksCube()
        
        // Convert each face
        if let frontColors = faces[.front] {
            cube.front = Self.unflattenFace(frontColors)
        }
        if let backColors = faces[.back] {
            cube.back = Self.unflattenFace(backColors)
        }
        if let leftColors = faces[.left] {
            cube.left = Self.unflattenFace(leftColors)
        }
        if let rightColors = faces[.right] {
            cube.right = Self.unflattenFace(rightColors)
        }
        if let upColors = faces[.up] {
            cube.top = Self.unflattenFace(upColors)
        }
        if let downColors = faces[.down] {
            cube.bottom = Self.unflattenFace(downColors)
        }
        
        return cube
    }
    
    /// Flatten a CubeFace to array of CubeColor
    private static func flattenFace(_ face: CubeFace) -> [CubeColor] {
        var colors: [CubeColor] = []
        for row in face.colors {
            for faceColor in row {
                colors.append(Self.convertFaceColor(faceColor))
            }
        }
        return colors
    }
    
    /// Unflatten array of CubeColor to CubeFace
    private static func unflattenFace(_ colors: [CubeColor]) -> CubeFace {
        guard colors.count == 9 else {
            // Return a default face if invalid
            return CubeFace(color: .white)
        }
        
        var face = CubeFace(color: .white)
        for i in 0..<3 {
            for j in 0..<3 {
                let index = i * 3 + j
                face.colors[i][j] = Self.convertCubeColor(colors[index])
            }
        }
        return face
    }
    
    /// Convert FaceColor to CubeColor
    private static func convertFaceColor(_ faceColor: FaceColor) -> CubeColor {
        switch faceColor {
        case .white: return .white
        case .yellow: return .yellow
        case .red: return .red
        case .orange: return .orange
        case .blue: return .blue
        case .green: return .green
        }
    }
    
    /// Convert CubeColor to FaceColor
    private static func convertCubeColor(_ cubeColor: CubeColor) -> FaceColor {
        switch cubeColor {
        case .white: return .white
        case .yellow: return .yellow
        case .red: return .red
        case .orange: return .orange
        case .blue: return .blue
        case .green: return .green
        }
    }
}
