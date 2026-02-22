//
//  EnhancedCubeSolver.swift
//  CubeSolver
//
//  Search-based cube solver used by app flows and playback.
//

import Foundation

/// Errors that can occur while solving a cube.
public enum CubeSolverError: Error, LocalizedError, Equatable {
    case noSolutionFound(maxDepth: Int)
    case searchLimitReached(maxVisitedStates: Int)
    case internalConsistencyFailure
    
    public var errorDescription: String? {
        switch self {
        case .noSolutionFound(let maxDepth):
            return "No solution found within search depth \(maxDepth)."
        case .searchLimitReached(let maxVisitedStates):
            return "Search stopped after visiting \(maxVisitedStates) states."
        case .internalConsistencyFailure:
            return "Solver produced an inconsistent solution. Please try again."
        }
    }
}

/// Validation mode used before solving.
public enum CubeValidationMode: Sendable {
    case basic
    case strict
}

/// Enhanced Rubik's Cube solver with validation and search-based solving.
///
/// The solver now performs an actual graph search from the current state to
/// a solved target state based on the current face centers.
public final class EnhancedCubeSolver {
    
    private static let defaultSearchConfiguration = CubeSearchConfiguration(
        maxDepthPerSide: 7,
        maxVisitedStates: 300_000
    )
    
    /// Solve a cube state and return the solution as a sequence of moves.
    /// - Parameters:
    ///   - state: The cube state to solve
    ///   - validationMode: Basic or strict validation
    /// - Returns: Array of moves that solve the cube
    /// - Throws: `CubeValidationError` or `CubeSolverError`
    public static func solveCube(
        from state: CubeState,
        validationMode: CubeValidationMode = .basic
    ) throws -> [Move] {
        switch validationMode {
        case .basic:
            try CubeValidator.validateBasic(state)
        case .strict:
            try CubeValidator.validate(state)
        }
        
        return try solveCubeInternal(state, searchConfiguration: defaultSearchConfiguration)
    }
    
    /// Asynchronously solve a cube state and return the solution.
    /// - Parameters:
    ///   - state: The cube state to solve
    ///   - validationMode: Basic or strict validation
    /// - Returns: Array of moves that solve the cube
    /// - Throws: `CubeValidationError` or `CubeSolverError`
    public static func solveCubeAsync(
        from state: CubeState,
        validationMode: CubeValidationMode = .basic
    ) async throws -> [Move] {
        return try await Task.detached(priority: .userInitiated) {
            try solveCube(from: state, validationMode: validationMode)
        }.value
    }
    
    // MARK: - Internal Solving Logic
    
    private static func solveCubeInternal(
        _ state: CubeState,
        searchConfiguration: CubeSearchConfiguration
    ) throws -> [Move] {
        if isSolved(state) {
            return []
        }
        
        let goal = solvedStateUsingCurrentCenters(from: state)
        let solution = try CubeSearchSolver.solve(
            from: state,
            to: goal,
            configuration: searchConfiguration
        )
        
        // Defensive verification to ensure the returned solution actually solves
        // under the app's public move application semantics.
        var verificationState = state
        applyMoves(to: &verificationState, moves: solution)
        guard isSolved(verificationState) else {
            throw CubeSolverError.internalConsistencyFailure
        }
        
        return solution
    }
    
    private static func solvedStateUsingCurrentCenters(from state: CubeState) -> CubeState {
        var solved = state
        
        for face in Face.allCases {
            guard let centerColor = state.centerColor(of: face) else {
                continue
            }
            solved.faces[face] = Array(repeating: centerColor, count: 9)
        }
        
        return solved
    }
    
    // MARK: - Move Application
    
    private static func applyMove(_ state: inout CubeState, _ move: Move) {
        var cube = state.toRubiksCube()
        
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
    
    private static func isSolved(_ state: CubeState) -> Bool {
        for face in Face.allCases {
            guard let stickers = state.faces[face], let firstColor = stickers.first else {
                return false
            }
            
            if stickers.contains(where: { $0 != firstColor }) {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Scramble Generation
    
    /// Generate a random scramble sequence.
    /// - Parameter moveCount: Number of moves in the scramble (default 20)
    /// - Returns: Array of random moves
    public static func generateScramble(moveCount: Int = 20) -> [Move] {
        var moves: [Move] = []
        var lastTurn: Turn?
        
        for _ in 0..<moveCount {
            var turn: Turn
            
            repeat {
                turn = Turn.allCases.randomElement()!
            } while turn == lastTurn
            
            let amount = Amount.allCases.randomElement()!
            moves.append(Move(turn: turn, amount: amount))
            lastTurn = turn
        }
        
        return moves
    }
    
    /// Apply a sequence of moves to a cube state.
    /// - Parameters:
    ///   - state: The cube state to modify
    ///   - moves: The sequence of moves to apply
    public static func applyMoves(to state: inout CubeState, moves: [Move]) {
        for move in moves {
            applyMove(&state, move)
        }
    }
}

// MARK: - Search Engine

private struct CubeSearchConfiguration {
    let maxDepthPerSide: Int
    let maxVisitedStates: Int
}

private struct FrontierRecord {
    let state: CubeState
    let parentKey: String?
    let moveFromParent: Move?
    let depth: Int
    let lastTurn: Turn?
}

private enum CubeSearchSolver {
    private static let allMoves: [Move] = Turn.allCases.flatMap { turn in
        [
            Move(turn: turn, amount: .clockwise),
            Move(turn: turn, amount: .counter),
            Move(turn: turn, amount: .double)
        ]
    }
    
    static func solve(
        from start: CubeState,
        to goal: CubeState,
        configuration: CubeSearchConfiguration
    ) throws -> [Move] {
        let startKey = stateKey(start)
        let goalKey = stateKey(goal)
        
        if startKey == goalKey {
            return []
        }
        
        var startRecords: [String: FrontierRecord] = [
            startKey: FrontierRecord(
                state: start,
                parentKey: nil,
                moveFromParent: nil,
                depth: 0,
                lastTurn: nil
            )
        ]
        var goalRecords: [String: FrontierRecord] = [
            goalKey: FrontierRecord(
                state: goal,
                parentKey: nil,
                moveFromParent: nil,
                depth: 0,
                lastTurn: nil
            )
        ]
        
        var startFrontier: Set<String> = [startKey]
        var goalFrontier: Set<String> = [goalKey]
        var visitedStates = 2
        
        while !startFrontier.isEmpty && !goalFrontier.isEmpty {
            if startFrontier.count <= goalFrontier.count {
                var nextFrontier: Set<String> = []
                
                for key in startFrontier {
                    guard let record = startRecords[key] else { continue }
                    guard record.depth < configuration.maxDepthPerSide else { continue }
                    
                    for move in allMoves where move.turn != record.lastTurn {
                        let nextState = CubeState.apply(move: move, to: record.state)
                        let nextKey = stateKey(nextState)
                        
                        if startRecords[nextKey] != nil {
                            continue
                        }
                        
                        startRecords[nextKey] = FrontierRecord(
                            state: nextState,
                            parentKey: key,
                            moveFromParent: move,
                            depth: record.depth + 1,
                            lastTurn: move.turn
                        )
                        nextFrontier.insert(nextKey)
                        visitedStates += 1
                        
                        if visitedStates > configuration.maxVisitedStates {
                            throw CubeSolverError.searchLimitReached(
                                maxVisitedStates: configuration.maxVisitedStates
                            )
                        }
                        
                        if goalRecords[nextKey] != nil {
                            return reconstructPath(
                                meetingKey: nextKey,
                                startRecords: startRecords,
                                goalRecords: goalRecords
                            )
                        }
                    }
                }
                
                startFrontier = nextFrontier
            } else {
                var nextFrontier: Set<String> = []
                
                for key in goalFrontier {
                    guard let record = goalRecords[key] else { continue }
                    guard record.depth < configuration.maxDepthPerSide else { continue }
                    
                    for move in allMoves where move.turn != record.lastTurn {
                        let nextState = CubeState.apply(move: move, to: record.state)
                        let nextKey = stateKey(nextState)
                        
                        if goalRecords[nextKey] != nil {
                            continue
                        }
                        
                        goalRecords[nextKey] = FrontierRecord(
                            state: nextState,
                            parentKey: key,
                            moveFromParent: move,
                            depth: record.depth + 1,
                            lastTurn: move.turn
                        )
                        nextFrontier.insert(nextKey)
                        visitedStates += 1
                        
                        if visitedStates > configuration.maxVisitedStates {
                            throw CubeSolverError.searchLimitReached(
                                maxVisitedStates: configuration.maxVisitedStates
                            )
                        }
                        
                        if startRecords[nextKey] != nil {
                            return reconstructPath(
                                meetingKey: nextKey,
                                startRecords: startRecords,
                                goalRecords: goalRecords
                            )
                        }
                    }
                }
                
                goalFrontier = nextFrontier
            }
        }
        
        throw CubeSolverError.noSolutionFound(maxDepth: configuration.maxDepthPerSide * 2)
    }
    
    private static func reconstructPath(
        meetingKey: String,
        startRecords: [String: FrontierRecord],
        goalRecords: [String: FrontierRecord]
    ) -> [Move] {
        var prefix: [Move] = []
        var cursor: String? = meetingKey
        
        while let key = cursor,
              let record = startRecords[key],
              let parentKey = record.parentKey,
              let move = record.moveFromParent {
            prefix.append(move)
            cursor = parentKey
        }
        prefix.reverse()
        
        var suffix: [Move] = []
        cursor = meetingKey
        
        while let key = cursor,
              let record = goalRecords[key],
              let parentKey = record.parentKey,
              let move = record.moveFromParent {
            suffix.append(move.inverse)
            cursor = parentKey
        }
        
        return prefix + suffix
    }
    
    private static func stateKey(_ state: CubeState) -> String {
        var key = ""
        key.reserveCapacity(54)
        
        for face in [Face.up, .down, .left, .right, .front, .back] {
            guard let stickers = state.faces[face], stickers.count == 9 else {
                key.append(String(repeating: "?", count: 9))
                continue
            }
            for color in stickers {
                key.append(color.rawValue)
            }
        }
        
        return key
    }
}

private extension Move {
    var inverse: Move {
        let inverseAmount: Amount
        switch amount {
        case .clockwise:
            inverseAmount = .counter
        case .counter:
            inverseAmount = .clockwise
        case .double:
            inverseAmount = .double
        }
        return Move(turn: turn, amount: inverseAmount)
    }
}
