//
//  CubeDataStructures.swift
//  CubeSolver
//
//  Core data structures for Rubik's Cube representation and solving.
//
//  This file defines the primary types used throughout CubeSolver:
//  - CubeColor: The six standard cube colors (Sendable/Codable)
//  - Face: The six cube faces (U, D, L, R, F, B)
//  - CubeState: Complete 54-sticker state representation
//  - Move: Standard cube notation (R, U', F2, etc.)
//  - CubeSolution: A sequence of moves that solve a cube state
//

import Foundation
import Algorithms

// MARK: - Color Definitions

/// Represents the six standard colors on a Rubik's Cube.
///
/// Each color corresponds to a face center on a standard cube:
/// - White (W): Top face
/// - Yellow (Y): Bottom face
/// - Red (R): Front face
/// - Orange (O): Back face
/// - Blue (B): Right face
/// - Green (G): Left face
///
/// This type is Sendable and Codable for use in async contexts and persistence.
public enum CubeColor: String, CaseIterable, Codable, Equatable, Sendable {
    case white = "W"
    case yellow = "Y"
    case red = "R"
    case orange = "O"
    case blue = "B"
    case green = "G"
}

// MARK: - Face Definitions

/// Represents the six faces of a Rubik's Cube using standard notation.
///
/// Face notation follows the standard Rubik's Cube conventions:
/// - U (Up): Top face
/// - D (Down): Bottom face
/// - L (Left): Left face
/// - R (Right): Right face
/// - F (Front): Front face
/// - B (Back): Back face
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

/// Represents the complete state of a Rubik's Cube as 54 individual stickers.
///
/// Each face contains 9 stickers arranged in a 3x3 grid, indexed as follows:
/// ```
/// 0 | 1 | 2
/// ---------
/// 3 | 4 | 5
/// ---------
/// 6 | 7 | 8
/// ```
/// Index 4 is always the center sticker.
///
/// This type is the primary representation for cube states in the solver.
/// Use `CubeState(from:)` to convert from `RubiksCube` representation.
public struct CubeState: Equatable, Hashable, Codable, Sendable {
    /// Dictionary mapping each face to its 9 sticker colors.
    /// Stickers are ordered from top-left to bottom-right (row by row).
    public var faces: [Face: [CubeColor]]
    
    /// Initializes a solved cube state with standard color configuration.
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
    
    /// Hash function for use in sets and dictionaries (required for A* search)
    public func hash(into hasher: inout Hasher) {
        // Hash faces in a consistent order for deterministic hashing
        for face in Face.allCases.sorted(by: { $0.rawValue < $1.rawValue }) {
            if let colors = faces[face] {
                hasher.combine(face)
                for color in colors {
                    hasher.combine(color)
                }
            }
        }
    }
    
    /// Count the number of misplaced stickers (stickers not matching their face's center color)
    /// Used as a heuristic for search algorithms
    public var misplacedStickerCount: Int {
        var count = 0
        for face in Face.allCases {
            guard let colors = faces[face],
                  let centerColor = centerColor(of: face) else { continue }
            
            for (index, color) in colors.enumerated() {
                // Skip center sticker (index 4)
                if index != 4 && color != centerColor {
                    count += 1
                }
            }
        }
        return count
    }
    
    /// Check if the cube is in a solved state
    public var isSolved: Bool {
        for face in Face.allCases {
            guard let colors = faces[face] else { return false }
            let firstColor = colors[0]
            for color in colors {
                if color != firstColor {
                    return false
                }
            }
        }
        return true
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
public struct Move: Equatable, Hashable, Codable, Sendable {
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

// MARK: - Solution

/// Represents a complete solution for a Rubik's Cube
public struct CubeSolution: Equatable, Codable, Sendable {
    /// The initial state of the cube before applying the solution
    public let initialState: CubeState
    
    /// The sequence of moves that solve the cube
    public let moves: [Move]
    
    /// Initialize a cube solution
    /// - Parameters:
    ///   - initialState: The starting cube state
    ///   - moves: The solution moves
    public init(initialState: CubeState, moves: [Move]) {
        self.initialState = initialState
        self.moves = moves
    }
}

// MARK: - Move Application Helpers

extension CubeState {
    /// Apply a single move to a cube state and return the new state
    /// - Parameters:
    ///   - move: The move to apply
    ///   - state: The current cube state
    /// - Returns: The new cube state after applying the move
    public static func apply(move: Move, to state: CubeState) -> CubeState {
        var newState = state
        var cube = state.toRubiksCube()
        
        // Apply the move the appropriate number of times based on amount
        for _ in 0..<move.amount.quarters {
            switch move.turn {
            case .F: cube.rotateFront()
            case .B: cube.rotateBack()
            case .L: cube.rotateLeft()
            case .R: cube.rotateRight()
            case .U: cube.rotateTop()
            case .D: cube.rotateBottom()
            }
        }
        
        newState = CubeState(from: cube)
        return newState
    }
    
    /// Get the cube state at a specific step in a solution
    /// - Parameters:
    ///   - step: The step number (0 = initial state, 1 = after first move, etc.)
    ///   - solution: The cube solution
    /// - Returns: The cube state at the specified step
    public static func state(at step: Int, for solution: CubeSolution) -> CubeState {
        guard step >= 0 else { return solution.initialState }
        guard step <= solution.moves.count else {
            // Return the final state if step is beyond the solution
            return state(at: solution.moves.count, for: solution)
        }
        
        // Start with the initial state
        var currentState = solution.initialState
        
        // Apply moves up to the specified step
        for i in 0..<step {
            currentState = apply(move: solution.moves[i], to: currentState)
        }
        
        return currentState
    }
}

// MARK: - Conversion Utilities

public extension CubeState {
    /// Convert from existing RubiksCube structure
    init(from cube: RubiksCube) {
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
    func toRubiksCube() -> RubiksCube {
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

// MARK: - Move Generation Utilities

/// Extension providing move generation utilities using swift-algorithms
public extension Move {
    /// Generate all possible single moves (18 moves total: 6 faces × 3 amounts)
    static var allMoves: [Move] {
        Turn.allCases.flatMap { turn in
            Amount.allCases.map { amount in
                Move(turn: turn, amount: amount)
            }
        }
    }
    
    /// Returns the inverse of this move
    var inverse: Move {
        switch amount {
        case .clockwise:
            return Move(turn: turn, amount: .counter)
        case .counter:
            return Move(turn: turn, amount: .clockwise)
        case .double:
            return Move(turn: turn, amount: .double)
        }
    }
    
    /// Check if this move can cancel with another move
    /// Two moves on the same face can be combined or cancelled
    func canCombine(with other: Move) -> Bool {
        return turn == other.turn
    }
    
    /// Combine two moves on the same face into a single move (if possible)
    /// Returns nil if the moves cancel out completely
    func combined(with other: Move) -> Move? {
        guard turn == other.turn else { return nil }
        
        // Sum of quarters ranges from 2 to 6 (1+1 to 3+3), modulo 4 gives 0-3
        // 0 = cancel out, 1 = clockwise, 2 = double, 3 = counter
        let totalQuarters = (amount.quarters + other.amount.quarters) % 4
        
        switch totalQuarters {
        case 0:
            return nil // Moves cancel out
        case 1:
            return Move(turn: turn, amount: .clockwise)
        case 2:
            return Move(turn: turn, amount: .double)
        case 3:
            return Move(turn: turn, amount: .counter)
        default:
            return nil
        }
    }
}

// MARK: - Move Sequence Utilities

/// Extension providing move sequence optimization utilities
public extension Array where Element == Move {
    /// Optimize a move sequence by combining consecutive moves on the same face
    func optimized() -> [Move] {
        guard count > 1 else { return self }
        
        var result: [Move] = []
        var index = 0
        
        while index < count {
            let current = self[index]
            
            // Look ahead for moves on the same face
            if index + 1 < count && current.canCombine(with: self[index + 1]) {
                if let combined = current.combined(with: self[index + 1]) {
                    result.append(combined)
                }
                // Skip both moves as they've been combined
                index += 2
            } else {
                result.append(current)
                index += 1
            }
        }
        
        // Recursively optimize if we made changes (to handle chains of same-face moves)
        if result.count < count {
            return result.optimized()
        }
        
        return result
    }
    
    /// Get unique moves in the sequence (using swift-algorithms' uniqued)
    func uniqueMoves() -> [Move] {
        return Array(uniqued())
    }
    
    /// Count occurrences of each turn type
    func turnCounts() -> [Turn: Int] {
        var counts: [Turn: Int] = [:]
        for move in self {
            counts[move.turn, default: 0] += 1
        }
        return counts
    }
}
