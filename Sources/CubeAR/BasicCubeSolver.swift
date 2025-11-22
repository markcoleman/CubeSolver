//
//  BasicCubeSolver.swift
//  CubeSolver - Basic solver implementation for AR coaching
//
//  Created by GitHub Copilot
//

import Foundation
import CubeCore

/// Basic cube solver implementation that wraps EnhancedCubeSolver
/// Conforms to CubeSolverProtocol for dependency injection in AR coach
public final class BasicCubeSolver: CubeSolverProtocol, @unchecked Sendable {
    
    /// Shared instance
    public static let shared = BasicCubeSolver()
    
    private init() {}
    
    // MARK: - CubeSolverProtocol
    
    public func solve(from state: CubeState) throws -> [Move] {
        // Use the existing EnhancedCubeSolver
        return try EnhancedCubeSolver.solveCube(from: state)
    }
    
    /// Solve with algorithm explanations
    /// - Parameter state: Current cube state
    /// - Returns: Array of algorithm steps with explanations
    /// - Throws: Error if state is invalid
    public func solveWithExplanations(from state: CubeState) throws -> [AlgorithmStep] {
        let moves = try solve(from: state)
        
        // Wrap moves with explanations based on position in solution
        return moves.enumerated().map { index, move in
            let (description, phase) = explainMove(move, at: index, total: moves.count)
            return AlgorithmStep(move: move, description: description, phase: phase)
        }
    }
    
    // MARK: - Private Helpers
    
    /// Generate explanation for a move based on its position in the solution
    private func explainMove(_ move: Move, at index: Int, total: Int) -> (String, SolvePhase) {
        // Estimate which phase based on position in solution
        let progress = Double(index) / Double(max(total, 1))
        
        let phase: SolvePhase
        let description: String
        
        switch progress {
        case 0..<0.25:
            phase = .cross
            description = describeForCross(move)
        case 0.25..<0.5:
            phase = .f2l
            description = describeForF2L(move)
        case 0.5..<0.75:
            phase = .oll
            description = describeForOLL(move)
        case 0.75...1.0:
            phase = .pll
            description = describeForPLL(move)
        default:
            phase = .other
            description = "Execute \(move.notation)"
        }
        
        return (description, phase)
    }
    
    private func describeForCross(_ move: Move) -> String {
        switch move.turn {
        case .F, .B, .L, .R:
            return "Positioning white edge piece"
        case .U:
            return "Aligning white cross"
        case .D:
            return "Adjusting bottom layer for cross"
        }
    }
    
    private func describeForF2L(_ move: Move) -> String {
        return "Inserting corner-edge pair for first two layers"
    }
    
    private func describeForOLL(_ move: Move) -> String {
        return "Orienting last layer pieces to face upward"
    }
    
    private func describeForPLL(_ move: Move) -> String {
        return "Positioning last layer pieces to solve cube"
    }
}

// MARK: - CubeState Serialization Extension

public extension CubeState {
    /// Serialize to 54-character string format
    /// Format: Each color is one character (W/Y/R/O/B/G)
    /// Order: U face (9), D face (9), L face (9), R face (9), F face (9), B face (9)
    var serialized: String {
        var result = ""
        
        for face in [Face.up, .down, .left, .right, .front, .back] {
            if let colors = faces[face] {
                for color in colors {
                    result.append(color.rawValue)
                }
            }
        }
        
        return result
    }
    
    /// Initialize from 54-character serialized string
    /// - Parameter serialized: 54-character string with color codes
    init?(serialized: String) {
        guard serialized.count == 54 else { return nil }
        
        var faceDict: [Face: [CubeColor]] = [:]
        let faceOrder: [Face] = [.up, .down, .left, .right, .front, .back]
        
        for (faceIndex, face) in faceOrder.enumerated() {
            var colors: [CubeColor] = []
            
            for colorIndex in 0..<9 {
                let stringIndex = faceIndex * 9 + colorIndex
                let char = serialized[serialized.index(serialized.startIndex, offsetBy: stringIndex)]
                
                guard let color = CubeColor(rawValue: String(char)) else {
                    return nil
                }
                colors.append(color)
            }
            
            faceDict[face] = colors
        }
        
        self.init(faces: faceDict)
    }
}
