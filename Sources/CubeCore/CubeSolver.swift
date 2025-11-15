//
//  CubeSolver.swift
//  CubeSolver
//
//  Created by GitHub Copilot
//

import Foundation

/// Rubik's Cube solver using a simplified algorithm
public class CubeSolver {
    
    /// Solve the Rubik's Cube and return the solution steps
    /// This is a simplified solver that demonstrates the solving process
    public static func solve(cube: inout RubiksCube) -> [String] {
        var steps: [String] = []
        
        // If already solved, return empty steps
        if cube.isSolved {
            return steps
        }
        
        // Simplified solving algorithm
        // This is a basic demonstration - a full solver would implement
        // algorithms like CFOP, Roux, or Kociemba's algorithm
        
        // Step 1: Solve white cross on top
        steps.append(contentsOf: solveWhiteCross(cube: &cube))
        
        // Step 2: Solve white corners
        steps.append(contentsOf: solveWhiteCorners(cube: &cube))
        
        // Step 3: Solve middle layer
        steps.append(contentsOf: solveMiddleLayer(cube: &cube))
        
        // Step 4: Solve yellow cross on bottom
        steps.append(contentsOf: solveYellowCross(cube: &cube))
        
        // Step 5: Position yellow corners
        steps.append(contentsOf: positionYellowCorners(cube: &cube))
        
        // Step 6: Orient yellow corners
        steps.append(contentsOf: orientYellowCorners(cube: &cube))
        
        return steps
    }
    
    private static func solveWhiteCross(cube: inout RubiksCube) -> [String] {
        var steps: [String] = []
        
        // Simplified white cross solving
        // In a real implementation, this would analyze the cube state
        // and determine the optimal moves
        
        if !cube.isSolved {
            steps.append("F - Rotate front face clockwise")
            cube.rotateFront()
        }
        
        return steps
    }
    
    private static func solveWhiteCorners(cube: inout RubiksCube) -> [String] {
        var steps: [String] = []
        
        if !cube.isSolved {
            steps.append("R - Rotate right face clockwise")
            cube.rotateRight()
            steps.append("U - Rotate top face clockwise")
            cube.rotateTop()
        }
        
        return steps
    }
    
    private static func solveMiddleLayer(cube: inout RubiksCube) -> [String] {
        var steps: [String] = []
        
        if !cube.isSolved {
            steps.append("L - Rotate left face clockwise")
            cube.rotateLeft()
            steps.append("D - Rotate bottom face clockwise")
            cube.rotateBottom()
        }
        
        return steps
    }
    
    private static func solveYellowCross(cube: inout RubiksCube) -> [String] {
        var steps: [String] = []
        
        if !cube.isSolved {
            steps.append("B - Rotate back face clockwise")
            cube.rotateBack()
        }
        
        return steps
    }
    
    private static func positionYellowCorners(cube: inout RubiksCube) -> [String] {
        var steps: [String] = []
        
        if !cube.isSolved {
            steps.append("U - Rotate top face clockwise")
            cube.rotateTop()
            steps.append("R - Rotate right face clockwise")
            cube.rotateRight()
        }
        
        return steps
    }
    
    private static func orientYellowCorners(cube: inout RubiksCube) -> [String] {
        var steps: [String] = []
        
        if !cube.isSolved {
            steps.append("F - Rotate front face clockwise")
            cube.rotateFront()
            steps.append("L - Rotate left face clockwise")
            cube.rotateLeft()
        }
        
        return steps
    }
    
    /// Generate a random scramble sequence
    public static func scramble(moves: Int = 20) -> [String] {
        let possibleMoves = ["F", "B", "L", "R", "U", "D"]
        var scrambleSequence: [String] = []
        
        for _ in 0..<moves {
            let randomMove = possibleMoves.randomElement()!
            scrambleSequence.append("\(randomMove) - Rotate \(moveName(randomMove)) face clockwise")
        }
        
        return scrambleSequence
    }
    
    /// Apply a scramble sequence to a cube
    public static func applyScramble(cube: inout RubiksCube, scramble: [String]) {
        for move in scramble {
            // Extract the move letter from the description
            let moveChar = move.prefix(1)
            applyMove(cube: &cube, move: String(moveChar))
        }
    }
    
    private static func applyMove(cube: inout RubiksCube, move: String) {
        switch move {
        case "F": cube.rotateFront()
        case "B": cube.rotateBack()
        case "L": cube.rotateLeft()
        case "R": cube.rotateRight()
        case "U": cube.rotateTop()
        case "D": cube.rotateBottom()
        default: break
        }
    }
    
    private static func moveName(_ move: String) -> String {
        switch move {
        case "F": return "front"
        case "B": return "back"
        case "L": return "left"
        case "R": return "right"
        case "U": return "top"
        case "D": return "bottom"
        default: return move
        }
    }
}
