//
//  CubeSolutionTests.swift
//  CubeCoreTests
//
//  Tests for CubeSolution data structure and move application
//

import XCTest
@testable import CubeCore

final class CubeSolutionTests: XCTestCase {
    
    // MARK: - Move Application Tests
    
    func testApplySingleMove() {
        // Given: A solved cube
        let initialState = CubeState()
        
        // When: Applying a single R move
        let move = Move(turn: .R, amount: .clockwise)
        let newState = CubeState.apply(move: move, to: initialState)
        
        // Then: The state should be different from the initial state
        XCTAssertNotEqual(newState, initialState, "Applying a move should change the cube state")
        
        // And: The right face should still be blue (center doesn't move)
        XCTAssertEqual(newState.centerColor(of: .right), .blue)
    }
    
    func testApplyCounterClockwiseMove() {
        // Given: A solved cube
        let initialState = CubeState()
        
        // When: Applying R then R'
        let moveR = Move(turn: .R, amount: .clockwise)
        let moveRPrime = Move(turn: .R, amount: .counter)
        
        let afterR = CubeState.apply(move: moveR, to: initialState)
        let afterRPrime = CubeState.apply(move: moveRPrime, to: afterR)
        
        // Then: Should return to initial state
        XCTAssertEqual(afterRPrime, initialState, "R followed by R' should return to initial state")
    }
    
    func testApplyDoubleMove() {
        // Given: A solved cube
        let initialState = CubeState()
        
        // When: Applying R2
        let moveR2 = Move(turn: .R, amount: .double)
        let afterR2 = CubeState.apply(move: moveR2, to: initialState)
        
        // And: Applying R twice manually
        let moveR = Move(turn: .R, amount: .clockwise)
        let afterR = CubeState.apply(move: moveR, to: initialState)
        let afterRR = CubeState.apply(move: moveR, to: afterR)
        
        // Then: R2 should equal R followed by R
        XCTAssertEqual(afterR2, afterRR, "R2 should equal two R moves")
    }
    
    func testApplyMultipleMoves() {
        // Given: A solved cube and a sequence of moves
        let initialState = CubeState()
        let moves = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .clockwise),
            Move(turn: .R, amount: .counter),
            Move(turn: .U, amount: .counter)
        ]
        
        // When: Applying all moves
        var currentState = initialState
        for move in moves {
            currentState = CubeState.apply(move: move, to: currentState)
        }
        
        // Then: The sexy move (R U R' U') repeated 6 times returns to solved state
        for _ in 0..<5 {
            for move in moves {
                currentState = CubeState.apply(move: move, to: currentState)
            }
        }
        
        XCTAssertEqual(currentState, initialState, "Sexy move repeated 6 times should return to solved")
    }
    
    // MARK: - CubeSolution Tests
    
    func testCubeSolutionInitialization() {
        // Given: Initial state and moves
        let initialState = CubeState()
        let moves = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .clockwise)
        ]
        
        // When: Creating a solution
        let solution = CubeSolution(initialState: initialState, moves: moves)
        
        // Then: Properties should be set correctly
        XCTAssertEqual(solution.initialState, initialState)
        XCTAssertEqual(solution.moves.count, 2)
        XCTAssertEqual(solution.moves[0].turn, .R)
        XCTAssertEqual(solution.moves[1].turn, .U)
    }
    
    func testStateAtStepZero() {
        // Given: A solution
        let initialState = CubeState()
        let moves = [Move(turn: .R, amount: .clockwise)]
        let solution = CubeSolution(initialState: initialState, moves: moves)
        
        // When: Getting state at step 0
        let stateAtZero = CubeState.state(at: 0, for: solution)
        
        // Then: Should equal initial state
        XCTAssertEqual(stateAtZero, initialState)
    }
    
    func testStateAtStep() {
        // Given: A solution with multiple moves
        let initialState = CubeState()
        let moves = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .clockwise),
            Move(turn: .F, amount: .clockwise)
        ]
        let solution = CubeSolution(initialState: initialState, moves: moves)
        
        // When: Getting state at step 1
        let stateAtOne = CubeState.state(at: 1, for: solution)
        
        // And: Manually applying first move
        let manualState = CubeState.apply(move: moves[0], to: initialState)
        
        // Then: States should be equal
        XCTAssertEqual(stateAtOne, manualState)
    }
    
    func testStateAtFinalStep() {
        // Given: A solution with 3 moves
        let initialState = CubeState()
        let moves = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .clockwise),
            Move(turn: .F, amount: .clockwise)
        ]
        let solution = CubeSolution(initialState: initialState, moves: moves)
        
        // When: Getting state at final step
        let finalState = CubeState.state(at: 3, for: solution)
        
        // And: Manually applying all moves
        var manualState = initialState
        for move in moves {
            manualState = CubeState.apply(move: move, to: manualState)
        }
        
        // Then: States should be equal
        XCTAssertEqual(finalState, manualState)
    }
    
    func testStateAtNegativeStep() {
        // Given: A solution
        let solution = CubeSolution(
            initialState: CubeState(),
            moves: [Move(turn: .R, amount: .clockwise)]
        )
        
        // When: Getting state at negative step
        let state = CubeState.state(at: -1, for: solution)
        
        // Then: Should return initial state
        XCTAssertEqual(state, solution.initialState)
    }
    
    func testStateAtStepBeyondSolution() {
        // Given: A solution with 2 moves
        let initialState = CubeState()
        let moves = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .clockwise)
        ]
        let solution = CubeSolution(initialState: initialState, moves: moves)
        
        // When: Getting state at step 100 (beyond solution)
        let state = CubeState.state(at: 100, for: solution)
        
        // And: Getting state at final step
        let finalState = CubeState.state(at: 2, for: solution)
        
        // Then: Should return final state
        XCTAssertEqual(state, finalState)
    }
    
    // MARK: - Edge Cases
    
    func testEmptySolution() {
        // Given: A solution with no moves
        let initialState = CubeState()
        let solution = CubeSolution(initialState: initialState, moves: [])
        
        // When: Getting state at any step
        let stateAtZero = CubeState.state(at: 0, for: solution)
        let stateAtOne = CubeState.state(at: 1, for: solution)
        
        // Then: Should always return initial state
        XCTAssertEqual(stateAtZero, initialState)
        XCTAssertEqual(stateAtOne, initialState)
    }
    
    func testAllFaceMoves() {
        // Given: A solved cube
        let initialState = CubeState()
        
        // When: Applying each face move 4 times (full rotation)
        for turn in Turn.allCases {
            var state = initialState
            let move = Move(turn: turn, amount: .clockwise)
            
            for _ in 0..<4 {
                state = CubeState.apply(move: move, to: state)
            }
            
            // Then: Should return to solved state
            XCTAssertEqual(state, initialState, "\(turn) applied 4 times should return to initial state")
        }
    }
}
