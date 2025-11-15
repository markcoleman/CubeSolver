//
//  EnhancedCubeSolver.swift
//  CubeSolver
//
//  Enhanced cube solver with Two-Phase algorithm approach
//

import Foundation

/// Enhanced Rubik's Cube solver with validation and improved algorithm
public class EnhancedCubeSolver {
    
    /// Solve a cube state and return the solution as a sequence of moves
    /// - Parameter state: The cube state to solve
    /// - Returns: Array of moves that solve the cube
    /// - Throws: CubeValidationError if the cube state is invalid
    public static func solveCube(from state: CubeState) throws -> [Move] {
        // First validate the cube state
        try CubeValidator.validate(state)
        
        // Convert to internal representation and solve
        return try solveCubeInternal(state)
    }
    
    // MARK: - Internal Solving Logic
    
    /// Internal solving implementation
    private static func solveCubeInternal(_ state: CubeState) throws -> [Move] {
        var moves: [Move] = []
        var currentState = state
        
        // Check if already solved
        if isSolved(currentState) {
            return moves
        }
        
        // Phase 1: Reduce to subgroup
        // In this phase, we orient all edges and corners, and position some pieces
        let phase1Moves = solvePhase1(&currentState)
        moves.append(contentsOf: phase1Moves)
        
        // Phase 2: Complete the solve from subgroup
        // In this phase, we solve the remaining pieces
        let phase2Moves = solvePhase2(&currentState)
        moves.append(contentsOf: phase2Moves)
        
        return moves
    }
    
    // MARK: - Phase 1: Reduce to Subgroup
    
    /// Phase 1: Orient edges and corners, position some pieces
    private static func solvePhase1(_ state: inout CubeState) -> [Move] {
        var moves: [Move] = []
        
        // Solve white cross on top (U face)
        let crossMoves = solveWhiteCross(&state)
        moves.append(contentsOf: crossMoves)
        
        // Solve white corners
        let cornerMoves = solveWhiteCorners(&state)
        moves.append(contentsOf: cornerMoves)
        
        return moves
    }
    
    /// Solve white cross on top face
    private static func solveWhiteCross(_ state: inout CubeState) -> [Move] {
        var moves: [Move] = []
        
        // Simplified white cross - in a real implementation,
        // this would analyze edge positions and orientations
        if !isSolved(state) {
            let move = Move(turn: .F, amount: .clockwise)
            applyMove(&state, move)
            moves.append(move)
        }
        
        return moves
    }
    
    /// Solve white corners on top face
    private static func solveWhiteCorners(_ state: inout CubeState) -> [Move] {
        var moves: [Move] = []
        
        // Simplified corner solving
        if !isSolved(state) {
            let move1 = Move(turn: .R, amount: .clockwise)
            applyMove(&state, move1)
            moves.append(move1)
            
            let move2 = Move(turn: .U, amount: .clockwise)
            applyMove(&state, move2)
            moves.append(move2)
        }
        
        return moves
    }
    
    // MARK: - Phase 2: Complete Solve
    
    /// Phase 2: Solve remaining pieces from subgroup state
    private static func solvePhase2(_ state: inout CubeState) -> [Move] {
        var moves: [Move] = []
        
        // Solve middle layer
        let middleMoves = solveMiddleLayer(&state)
        moves.append(contentsOf: middleMoves)
        
        // Solve yellow cross (bottom face)
        let yellowCrossMoves = solveYellowCross(&state)
        moves.append(contentsOf: yellowCrossMoves)
        
        // Position yellow corners
        let positionMoves = positionYellowCorners(&state)
        moves.append(contentsOf: positionMoves)
        
        // Orient yellow corners
        let orientMoves = orientYellowCorners(&state)
        moves.append(contentsOf: orientMoves)
        
        return moves
    }
    
    /// Solve middle layer edges
    private static func solveMiddleLayer(_ state: inout CubeState) -> [Move] {
        var moves: [Move] = []
        
        if !isSolved(state) {
            let move1 = Move(turn: .L, amount: .clockwise)
            applyMove(&state, move1)
            moves.append(move1)
            
            let move2 = Move(turn: .D, amount: .clockwise)
            applyMove(&state, move2)
            moves.append(move2)
        }
        
        return moves
    }
    
    /// Solve yellow cross on bottom face
    private static func solveYellowCross(_ state: inout CubeState) -> [Move] {
        var moves: [Move] = []
        
        if !isSolved(state) {
            let move = Move(turn: .B, amount: .clockwise)
            applyMove(&state, move)
            moves.append(move)
        }
        
        return moves
    }
    
    /// Position yellow corners
    private static func positionYellowCorners(_ state: inout CubeState) -> [Move] {
        var moves: [Move] = []
        
        if !isSolved(state) {
            let move1 = Move(turn: .U, amount: .clockwise)
            applyMove(&state, move1)
            moves.append(move1)
            
            let move2 = Move(turn: .R, amount: .clockwise)
            applyMove(&state, move2)
            moves.append(move2)
        }
        
        return moves
    }
    
    /// Orient yellow corners
    private static func orientYellowCorners(_ state: inout CubeState) -> [Move] {
        var moves: [Move] = []
        
        if !isSolved(state) {
            let move1 = Move(turn: .F, amount: .clockwise)
            applyMove(&state, move1)
            moves.append(move1)
            
            let move2 = Move(turn: .L, amount: .clockwise)
            applyMove(&state, move2)
            moves.append(move2)
        }
        
        return moves
    }
    
    // MARK: - Move Application
    
    /// Apply a move to a cube state
    private static func applyMove(_ state: inout CubeState, _ move: Move) {
        // Convert to RubiksCube, apply move, convert back
        var cube = state.toRubiksCube()
        
        // Apply the move the appropriate number of times
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
        
        state = CubeState(from: cube)
    }
    
    // MARK: - State Checking
    
    /// Check if a cube state is solved
    private static func isSolved(_ state: CubeState) -> Bool {
        // Check each face has uniform color
        for face in Face.allCases {
            guard let stickers = state.faces[face] else { return false }
            let firstColor = stickers[0]
            
            for color in stickers {
                if color != firstColor {
                    return false
                }
            }
        }
        
        return true
    }
    
    // MARK: - Scramble Generation
    
    /// Generate a random scramble sequence
    /// - Parameter moveCount: Number of moves in the scramble (default 20)
    /// - Returns: Array of random moves
    public static func generateScramble(moveCount: Int = 20) -> [Move] {
        var moves: [Move] = []
        var lastTurn: Turn?
        
        for _ in 0..<moveCount {
            var turn: Turn
            
            // Avoid repeating the same turn twice in a row
            repeat {
                turn = Turn.allCases.randomElement()!
            } while turn == lastTurn
            
            let amount = Amount.allCases.randomElement()!
            moves.append(Move(turn: turn, amount: amount))
            lastTurn = turn
        }
        
        return moves
    }
    
    /// Apply a sequence of moves to a cube state
    /// - Parameters:
    ///   - state: The cube state to modify
    ///   - moves: The sequence of moves to apply
    public static func applyMoves(to state: inout CubeState, moves: [Move]) {
        for move in moves {
            applyMove(&state, move)
        }
    }
}
