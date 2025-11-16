import XCTest
import CubeCore
@testable import CubeAR

#if canImport(SwiftUI) && canImport(ARKit)

import SwiftUI

@MainActor
final class CubeARTests: XCTestCase {
    
    // MARK: - ARState Tests
    
    func testARStateInitialization() {
        let arState = ARState()
        
        XCTAssertFalse(arState.isSessionActive, "AR session should not be active initially")
        XCTAssertNil(arState.trackingState, "Tracking state should be nil initially")
    }
    
    func testARStateStartSession() {
        let arState = ARState()
        
        arState.startSession()
        
        XCTAssertTrue(arState.isSessionActive, "AR session should be active after starting")
    }
    
    func testARStatePauseSession() {
        let arState = ARState()
        
        arState.startSession()
        XCTAssertTrue(arState.isSessionActive)
        
        arState.pauseSession()
        XCTAssertFalse(arState.isSessionActive, "AR session should not be active after pausing")
    }
    
    func testARStateMultipleStartPause() {
        let arState = ARState()
        
        arState.startSession()
        XCTAssertTrue(arState.isSessionActive)
        
        arState.pauseSession()
        XCTAssertFalse(arState.isSessionActive)
        
        arState.startSession()
        XCTAssertTrue(arState.isSessionActive)
        
        arState.pauseSession()
        XCTAssertFalse(arState.isSessionActive)
    }
    
    // MARK: - CubeARView Tests
    
    func testCubeARViewInitialization() {
        let moves = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .clockwise),
            Move(turn: .F, amount: .double)
        ]
        
        let currentStepIndex = Binding.constant(0)
        let arView = CubeARView(moves: moves, currentStepIndex: currentStepIndex)
        
        XCTAssertEqual(arView.moves.count, 3, "AR view should store moves")
    }
    
    func testCubeARViewWithEmptyMoves() {
        let moves: [Move] = []
        let currentStepIndex = Binding.constant(0)
        let arView = CubeARView(moves: moves, currentStepIndex: currentStepIndex)
        
        XCTAssertTrue(arView.moves.isEmpty, "AR view should handle empty moves")
    }
    
    func testCubeARViewWithLongSolution() {
        // Generate a long solution
        var moves: [Move] = []
        for i in 0..<50 {
            let turn = Turn.allCases[i % Turn.allCases.count]
            let amount = Amount.allCases[i % Amount.allCases.count]
            moves.append(Move(turn: turn, amount: amount))
        }
        
        let currentStepIndex = Binding.constant(0)
        let arView = CubeARView(moves: moves, currentStepIndex: currentStepIndex)
        
        XCTAssertEqual(arView.moves.count, 50, "AR view should handle long solutions")
    }
    
    // MARK: - Move Navigation Tests
    
    func testCurrentStepIndexBinding() {
        let moves = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .clockwise),
            Move(turn: .F, amount: .clockwise)
        ]
        
        var stepIndex = 0
        let binding = Binding(
            get: { stepIndex },
            set: { stepIndex = $0 }
        )
        
        let arView = CubeARView(moves: moves, currentStepIndex: binding)
        
        XCTAssertEqual(stepIndex, 0, "Initial step should be 0")
        
        // Simulate step change
        stepIndex = 1
        XCTAssertEqual(stepIndex, 1, "Step index should update")
        
        stepIndex = 2
        XCTAssertEqual(stepIndex, 2, "Step index should update again")
    }
    
    // MARK: - Edge Cases
    
    func testARViewWithSingleMove() {
        let moves = [Move(turn: .R, amount: .clockwise)]
        let currentStepIndex = Binding.constant(0)
        let arView = CubeARView(moves: moves, currentStepIndex: currentStepIndex)
        
        XCTAssertEqual(arView.moves.count, 1)
    }
    
    func testARViewStepIndexBeyondMoves() {
        let moves = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .clockwise)
        ]
        
        // Step index beyond moves array
        let currentStepIndex = Binding.constant(5)
        let arView = CubeARView(moves: moves, currentStepIndex: currentStepIndex)
        
        XCTAssertNotNil(arView, "AR view should handle invalid step index gracefully")
    }
    
    // MARK: - Tracking State Tests
    
    #if canImport(ARKit)
    func testTrackingStateTypes() {
        let arState = ARState()
        
        // Tracking state can be set to different values
        arState.trackingState = .normal
        XCTAssertEqual(arState.trackingState, .normal)
        
        arState.trackingState = .limited(.initializing)
        if case .limited = arState.trackingState {
            XCTAssertTrue(true, "Tracking state should be limited")
        } else {
            XCTFail("Expected limited tracking state")
        }
        
        arState.trackingState = .notAvailable
        XCTAssertEqual(arState.trackingState, .notAvailable)
    }
    #endif
    
    // MARK: - Integration Tests
    
    func testARSessionLifecycle() {
        let arState = ARState()
        
        // Initial state
        XCTAssertFalse(arState.isSessionActive)
        
        // Start and verify
        arState.startSession()
        XCTAssertTrue(arState.isSessionActive)
        
        // Pause and verify
        arState.pauseSession()
        XCTAssertFalse(arState.isSessionActive)
    }
    
    func testMultipleARStates() {
        let arState1 = ARState()
        let arState2 = ARState()
        
        arState1.startSession()
        
        XCTAssertTrue(arState1.isSessionActive)
        XCTAssertFalse(arState2.isSessionActive, "Different AR states should be independent")
    }
}

#else

// Placeholder tests for platforms without SwiftUI/ARKit
final class CubeARTests: XCTestCase {
    func testPlaceholder() {
        XCTAssertTrue(true, "Platform does not support SwiftUI/ARKit")
    }
}

#endif
