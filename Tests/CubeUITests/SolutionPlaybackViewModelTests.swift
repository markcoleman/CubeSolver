//
//  SolutionPlaybackViewModelTests.swift
//  CubeUITests
//
//  Tests for SolutionPlaybackViewModel
//

#if canImport(SwiftUI)
import XCTest
@testable import CubeUI
@testable import CubeCore

@MainActor
final class SolutionPlaybackViewModelTests: XCTestCase {
    
    // MARK: - Test Constants
    
    /// Animation duration plus buffer for testing
    private let animationWaitDuration: UInt64 = 700_000_000 // 0.7 seconds in nanoseconds
    
    // MARK: - Initialization Tests
    
    func testInitialization() async {
        // Given: A solution with 3 moves
        let initialState = CubeState()
        let moves = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .clockwise),
            Move(turn: .F, amount: .clockwise)
        ]
        let solution = CubeSolution(initialState: initialState, moves: moves)
        
        // When: Creating a view model
        let viewModel = SolutionPlaybackViewModel(solution: solution)
        
        // Then: Properties should be initialized correctly
        XCTAssertEqual(viewModel.currentStep, 0)
        XCTAssertEqual(viewModel.totalMoves, 3)
        XCTAssertFalse(viewModel.isPlaying)
        XCTAssertEqual(viewModel.currentCubeState, initialState)
        XCTAssertFalse(viewModel.isAnimating)
    }
    
    func testInitializationWithCustomSpeed() async {
        // Given: A solution
        let solution = CubeSolution(
            initialState: CubeState(),
            moves: [Move(turn: .R, amount: .clockwise)]
        )
        
        // When: Creating a view model with custom speed
        let viewModel = SolutionPlaybackViewModel(solution: solution, playbackSpeed: 2.0)
        
        // Then: Should initialize successfully
        XCTAssertEqual(viewModel.totalMoves, 1)
    }
    
    // MARK: - Navigation Tests
    
    func testStepForward() async {
        // Given: A view model at step 0
        let moves = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .clockwise)
        ]
        let solution = CubeSolution(initialState: CubeState(), moves: moves)
        let viewModel = SolutionPlaybackViewModel(solution: solution)
        
        // When: Stepping forward
        viewModel.stepForward()
        
        // Then: Current step should increment
        // Wait for animation to complete
        try? await Task.sleep(nanoseconds: animationWaitDuration)
        XCTAssertEqual(viewModel.currentStep, 1)
    }
    
    func testStepForwardAtEnd() async {
        // Given: A view model at the final step
        let moves = [Move(turn: .R, amount: .clockwise)]
        let solution = CubeSolution(initialState: CubeState(), moves: moves)
        let viewModel = SolutionPlaybackViewModel(solution: solution)
        
        // Move to end
        viewModel.stepForward()
        try? await Task.sleep(nanoseconds: animationWaitDuration)
        
        // When: Attempting to step forward beyond the end
        viewModel.stepForward()
        
        // Then: Should remain at final step
        XCTAssertEqual(viewModel.currentStep, 1)
    }
    
    func testStepBackward() async {
        // Given: A view model at step 2
        let moves = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .clockwise),
            Move(turn: .F, amount: .clockwise)
        ]
        let solution = CubeSolution(initialState: CubeState(), moves: moves)
        let viewModel = SolutionPlaybackViewModel(solution: solution)
        
        // Move to step 2
        viewModel.scrub(to: 2)
        
        // When: Stepping backward
        viewModel.stepBackward()
        
        // Then: Current step should decrement
        XCTAssertEqual(viewModel.currentStep, 1)
    }
    
    func testStepBackwardAtStart() async {
        // Given: A view model at step 0
        let solution = CubeSolution(
            initialState: CubeState(),
            moves: [Move(turn: .R, amount: .clockwise)]
        )
        let viewModel = SolutionPlaybackViewModel(solution: solution)
        
        // When: Attempting to step backward at start
        viewModel.stepBackward()
        
        // Then: Should remain at step 0
        XCTAssertEqual(viewModel.currentStep, 0)
    }
    
    func testJumpToStart() async {
        // Given: A view model at step 2
        let moves = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .clockwise),
            Move(turn: .F, amount: .clockwise)
        ]
        let solution = CubeSolution(initialState: CubeState(), moves: moves)
        let viewModel = SolutionPlaybackViewModel(solution: solution)
        viewModel.scrub(to: 2)
        
        // When: Jumping to start
        viewModel.jumpToStart()
        
        // Then: Should be at step 0
        XCTAssertEqual(viewModel.currentStep, 0)
        XCTAssertEqual(viewModel.currentCubeState, solution.initialState)
    }
    
    func testJumpToEnd() async {
        // Given: A view model at step 0
        let moves = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .clockwise),
            Move(turn: .F, amount: .clockwise)
        ]
        let solution = CubeSolution(initialState: CubeState(), moves: moves)
        let viewModel = SolutionPlaybackViewModel(solution: solution)
        
        // When: Jumping to end
        viewModel.jumpToEnd()
        
        // Then: Should be at final step
        XCTAssertEqual(viewModel.currentStep, 3)
    }
    
    // MARK: - Playback Control Tests
    
    func testTogglePlayPause() async {
        // Given: A view model that is not playing
        let solution = CubeSolution(
            initialState: CubeState(),
            moves: [Move(turn: .R, amount: .clockwise)]
        )
        let viewModel = SolutionPlaybackViewModel(solution: solution)
        
        // When: Toggling play/pause
        viewModel.togglePlayPause()
        
        // Then: Should be playing
        XCTAssertTrue(viewModel.isPlaying)
        
        // When: Toggling again
        viewModel.togglePlayPause()
        
        // Then: Should be paused
        XCTAssertFalse(viewModel.isPlaying)
    }
    
    func testPauseStopsPlayback() async {
        // Given: A playing view model
        let solution = CubeSolution(
            initialState: CubeState(),
            moves: [Move(turn: .R, amount: .clockwise)]
        )
        let viewModel = SolutionPlaybackViewModel(solution: solution)
        viewModel.play()
        XCTAssertTrue(viewModel.isPlaying)
        
        // When: Pausing
        viewModel.pause()
        
        // Then: Should not be playing
        XCTAssertFalse(viewModel.isPlaying)
    }
    
    func testPlayAtEnd() async {
        // Given: A view model at the final step
        let moves = [Move(turn: .R, amount: .clockwise)]
        let solution = CubeSolution(initialState: CubeState(), moves: moves)
        let viewModel = SolutionPlaybackViewModel(solution: solution)
        viewModel.jumpToEnd()
        
        // When: Attempting to play at end
        viewModel.play()
        
        // Then: Should not start playing
        XCTAssertFalse(viewModel.isPlaying)
    }
    
    // MARK: - Scrubbing Tests
    
    func testScrubToValidStep() async {
        // Given: A view model
        let moves = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .clockwise),
            Move(turn: .F, amount: .clockwise)
        ]
        let solution = CubeSolution(initialState: CubeState(), moves: moves)
        let viewModel = SolutionPlaybackViewModel(solution: solution)
        
        // When: Scrubbing to step 2
        viewModel.scrub(to: 2)
        
        // Then: Should be at step 2
        XCTAssertEqual(viewModel.currentStep, 2)
    }
    
    func testScrubPausesPlayback() async {
        // Given: A playing view model
        let solution = CubeSolution(
            initialState: CubeState(),
            moves: [
                Move(turn: .R, amount: .clockwise),
                Move(turn: .U, amount: .clockwise)
            ]
        )
        let viewModel = SolutionPlaybackViewModel(solution: solution)
        viewModel.play()
        XCTAssertTrue(viewModel.isPlaying)
        
        // When: Scrubbing
        viewModel.scrub(to: 1)
        
        // Then: Should pause playback
        XCTAssertFalse(viewModel.isPlaying)
    }
    
    func testScrubBelowZero() async {
        // Given: A view model
        let solution = CubeSolution(
            initialState: CubeState(),
            moves: [Move(turn: .R, amount: .clockwise)]
        )
        let viewModel = SolutionPlaybackViewModel(solution: solution)
        
        // When: Scrubbing to negative step
        viewModel.scrub(to: -5)
        
        // Then: Should clamp to 0
        XCTAssertEqual(viewModel.currentStep, 0)
    }
    
    func testScrubAboveTotalMoves() async {
        // Given: A view model with 2 moves
        let moves = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .clockwise)
        ]
        let solution = CubeSolution(initialState: CubeState(), moves: moves)
        let viewModel = SolutionPlaybackViewModel(solution: solution)
        
        // When: Scrubbing beyond total moves
        viewModel.scrub(to: 100)
        
        // Then: Should clamp to total moves
        XCTAssertEqual(viewModel.currentStep, 2)
    }
    
    // MARK: - State Management Tests
    
    func testCubeStateUpdatesWithStep() async {
        // Given: A view model
        let initialState = CubeState()
        let move = Move(turn: .R, amount: .clockwise)
        let moves = [move]
        let solution = CubeSolution(initialState: initialState, moves: moves)
        let viewModel = SolutionPlaybackViewModel(solution: solution)
        
        // When: Stepping forward
        viewModel.scrub(to: 1)
        
        // Then: Cube state should update
        let expectedState = CubeState.apply(move: move, to: initialState)
        XCTAssertEqual(viewModel.currentCubeState, expectedState)
    }
    
    func testEmptySolution() async {
        // Given: An empty solution
        let initialState = CubeState()
        let solution = CubeSolution(initialState: initialState, moves: [])
        
        // When: Creating a view model
        let viewModel = SolutionPlaybackViewModel(solution: solution)
        
        // Then: Should handle gracefully
        XCTAssertEqual(viewModel.totalMoves, 0)
        XCTAssertEqual(viewModel.currentStep, 0)
        XCTAssertEqual(viewModel.currentCubeState, initialState)
    }
}

#endif // canImport(SwiftUI)
