//
//  ARCoachViewModelTests.swift
//  CubeSolver - AR Coach ViewModel Tests
//
//  Created by GitHub Copilot
//

#if canImport(XCTest) && canImport(SwiftUI)

import XCTest
import SwiftUI
import CubeCore
@testable import CubeAR

/// Mock cube solver for testing
final class MockCubeSolver: CubeSolverProtocol, @unchecked Sendable {
    var moves: [Move] = []
    var shouldThrow = false
    
    func solve(from state: CubeState) throws -> [Move] {
        if shouldThrow {
            throw CubeValidationError.invalidCornerOrientation
        }
        return moves
    }
}

final class ARCoachViewModelTests: XCTestCase {
    
    // MARK: - Basic Tests
    
    @MainActor
    func testInitialization() {
        let mockSolver = MockCubeSolver()
        let testState = CubeState()
        
        let viewModel = ARCoachViewModel(
            initialState: testState,
            solver: mockSolver
        )
        
        XCTAssertTrue(viewModel.coachingState == CoachingState.idle)
        XCTAssertEqual(viewModel.currentStepIndex, 0)
        XCTAssertTrue(viewModel.plannedMoves.isEmpty)
        XCTAssertNil(viewModel.lastErrorMessage)
    }
    
    @MainActor
    func testStartCoachingProducesMovesAndSetsReady() {
        let mockSolver = MockCubeSolver()
        mockSolver.moves = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .clockwise),
            Move(turn: .F, amount: .counter)
        ]
        
        let testState = CubeState()
        let viewModel = ARCoachViewModel(
            initialState: testState,
            solver: mockSolver
        )
        
        viewModel.startCoaching(with: testState)
        
        XCTAssertEqual(viewModel.plannedMoves.count, 3, "Should have 3 planned moves")
        XCTAssertTrue(viewModel.coachingState == CoachingState.ready, "Should be in ready state")
        XCTAssertEqual(viewModel.currentStepIndex, 0, "Should start at step 0")
    }
    
    @MainActor
    func testBeginCoachingTransitionsToRunning() {
        let mockSolver = MockCubeSolver()
        mockSolver.moves = [Move(turn: .R, amount: .clockwise)]
        
        let testState = CubeState()
        let viewModel = ARCoachViewModel(
            initialState: testState,
            solver: mockSolver
        )
        
        viewModel.startCoaching(with: testState)
        viewModel.beginCoaching()
        
        XCTAssertTrue(viewModel.coachingState == CoachingState.running, "Should be in running state")
    }
    
    @MainActor
    func testNextStepAdvancesIndex() {
        let mockSolver = MockCubeSolver()
        mockSolver.moves = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .clockwise)
        ]
        
        let testState = CubeState()
        let viewModel = ARCoachViewModel(
            initialState: testState,
            solver: mockSolver
        )
        
        viewModel.startCoaching(with: testState)
        viewModel.beginCoaching()
        
        let initialIndex = viewModel.currentStepIndex
        viewModel.nextStep()
        
        XCTAssertEqual(viewModel.currentStepIndex, initialIndex + 1, "Index should advance by 1")
    }
    
    @MainActor
    func testToggleAutoStepEnablesAndDisables() {
        let mockSolver = MockCubeSolver()
        let testState = CubeState()
        
        let viewModel = ARCoachViewModel(
            initialState: testState,
            solver: mockSolver
        )
        
        XCTAssertFalse(viewModel.autoStepEnabled, "Auto-step should be disabled initially")
        
        viewModel.toggleAutoStep()
        XCTAssertTrue(viewModel.autoStepEnabled, "Auto-step should be enabled")
        
        viewModel.toggleAutoStep()
        XCTAssertFalse(viewModel.autoStepEnabled, "Auto-step should be disabled again")
    }
    
    @MainActor
    func testProgressCalculation() {
        let mockSolver = MockCubeSolver()
        mockSolver.moves = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .clockwise),
            Move(turn: .F, amount: .clockwise)
        ]
        
        let testState = CubeState()
        let viewModel = ARCoachViewModel(
            initialState: testState,
            solver: mockSolver
        )
        
        viewModel.startCoaching(with: testState)
        
        XCTAssertEqual(viewModel.progress, 0.0, accuracy: 0.01, "Progress should be 0 at start")
        
        viewModel.beginCoaching()
        viewModel.nextStep()
        
        // We're at step 1 out of 3 total, so progress = 1/3 ≈ 0.33
        XCTAssertEqual(viewModel.progress, 1.0 / 3.0, accuracy: 0.01)
    }
}

#endif
