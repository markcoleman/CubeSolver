//
//  ARCoachModels.swift
//  CubeSolver - AR Coach Mode Models
//
//  Created by GitHub Copilot
//

import Foundation
import CubeCore
#if canImport(CoreVideo)
import CoreVideo
#endif

// MARK: - Cube Pose

/// Represents a 3D position
public struct Position3D: Equatable, Sendable {
    public let x: Float
    public let y: Float
    public let z: Float
    
    public init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
}

/// Represents a rotation quaternion
public struct Quaternion: Equatable, Sendable {
    public let x: Float
    public let y: Float
    public let z: Float
    public let w: Float
    
    public init(x: Float, y: Float, z: Float, w: Float) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
}

/// Represents the detected 3D pose of a physical Rubik's cube
public struct CubePose: Equatable, Sendable {
    /// Position in 3D space (in meters)
    public let position: Position3D
    
    /// Rotation quaternion
    public let rotation: Quaternion
    
    /// Confidence score (0.0 to 1.0)
    public let confidence: Float
    
    public init(position: Position3D, rotation: Quaternion, confidence: Float) {
        self.position = position
        self.rotation = rotation
        self.confidence = confidence
    }
    
    /// Convenience initializer with tuple values
    public init(position: (Float, Float, Float), rotation: (Float, Float, Float, Float), confidence: Float) {
        self.position = Position3D(x: position.0, y: position.1, z: position.2)
        self.rotation = Quaternion(x: rotation.0, y: rotation.1, z: rotation.2, w: rotation.3)
        self.confidence = confidence
    }
}

// MARK: - Detected Sticker

/// Represents a single detected sticker on a physical cube
public struct DetectedSticker: Equatable, Sendable {
    /// Face this sticker belongs to
    public let face: Face
    
    /// Position index on the face (0-8)
    public let index: Int
    
    /// Detected color
    public let color: CubeColor
    
    /// Detection confidence (0.0 to 1.0)
    public let confidence: Float
    
    public init(face: Face, index: Int, color: CubeColor, confidence: Float) {
        self.face = face
        self.index = index
        self.color = color
        self.confidence = confidence
    }
}

// MARK: - Cube Detection Service Protocol

/// Protocol for detecting cube pose and sticker colors from camera frames
public protocol CubeDetectionService: Sendable {
    #if canImport(CoreVideo)
    /// Detect the 3D pose of a physical Rubik's cube in the frame
    /// - Parameter frame: Raw camera frame data
    /// - Returns: Detected cube pose, or nil if no cube detected
    func detectCubePose(frame: CVPixelBuffer) async -> CubePose?
    
    /// Detect individual sticker colors on the cube
    /// - Parameters:
    ///   - frame: Raw camera frame data
    ///   - pose: Previously detected cube pose for context
    /// - Returns: Array of detected stickers
    func detectStickers(frame: CVPixelBuffer, pose: CubePose) async -> [DetectedSticker]
    #endif
}

// MARK: - Cube Solver Protocol

/// Protocol for solving Rubik's cube from a given state
public protocol CubeSolverProtocol: Sendable {
    /// Solve the cube from the given state
    /// - Parameter state: Current cube state
    /// - Returns: Sequence of moves to solve the cube
    /// - Throws: Error if state is invalid or unsolvable
    func solve(from state: CubeState) throws -> [Move]
}

// MARK: - Algorithm Step with Explanation

/// Extended move information with algorithm context
public struct AlgorithmStep: Equatable, Sendable {
    /// The cube move
    public let move: Move
    
    /// Human-readable explanation of what this move accomplishes
    public let description: String
    
    /// Which phase of solving this belongs to
    public let phase: SolvePhase
    
    public init(move: Move, description: String, phase: SolvePhase) {
        self.move = move
        self.description = description
        self.phase = phase
    }
}

/// Phases in a CFOP-style solve
public enum SolvePhase: String, CaseIterable, Codable, Equatable, Sendable {
    case cross = "Cross"
    case f2l = "F2L (First 2 Layers)"
    case oll = "OLL (Orient Last Layer)"
    case pll = "PLL (Permute Last Layer)"
    case other = "Other"
    
    public var displayName: String {
        return rawValue
    }
}

// MARK: - Session Statistics

/// Statistics for an AR coaching session
public struct ARSessionStats: Equatable, Sendable {
    /// Total time spent in the session
    public var totalTime: TimeInterval = 0
    
    /// Number of moves in the solution
    public var totalMoves: Int = 0
    
    /// Number of errors detected and corrected
    public var errorsDetected: Int = 0
    
    /// Number of times user asked for hints
    public var hintsRequested: Int = 0
    
    /// Session start time
    public var startTime: Date = Date()
    
    public init() {}
}

// MARK: - Coaching State

/// State of the AR coaching session
public enum CoachingState: Equatable, Sendable {
    /// Not yet started
    case idle
    
    /// Calibrating cube position and orientation
    case calibrating
    
    /// Ready to start coaching
    case ready
    
    /// Actively coaching through moves
    case running
    
    /// Coaching completed successfully
    case completed
    
    /// Error state with message
    case error(String)
}

// MARK: - Calibration Status

/// Status messages during cube calibration
public enum CalibrationStatus: String, Equatable, Sendable {
    case searching = "Looking for cube..."
    case tooFar = "Move cube closer"
    case tooDark = "Need better lighting"
    case unstable = "Hold cube steady"
    case aligned = "Cube aligned - tap to start"
    
    public var message: String {
        return rawValue
    }
}
