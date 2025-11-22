//
//  ARCoachViewModel.swift
//  CubeSolver - AR Coach Mode ViewModel
//
//  Created by GitHub Copilot
//

#if canImport(SwiftUI)

import Foundation
import SwiftUI
import Combine
import CubeCore

/// ViewModel managing AR coaching session state and logic
@MainActor
public final class ARCoachViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current cube state being coached
    @Published public var currentCubeState: CubeState
    
    /// Initial cube state before any moves
    private var initialCubeState: CubeState
    
    /// Planned sequence of moves to solve the cube
    @Published public var plannedMoves: [Move] = []
    
    /// Algorithm steps with explanations
    @Published public var algorithmSteps: [AlgorithmStep] = []
    
    /// Current step index in the solution
    @Published public var currentStepIndex: Int = 0
    
    /// Current coaching state
    @Published public var coachingState: CoachingState = .idle
    
    /// Last error message
    @Published public var lastErrorMessage: String?
    
    /// Calibration status
    @Published public var calibrationStatus: CalibrationStatus = .searching
    
    /// Session statistics
    @Published public var sessionStats = ARSessionStats()
    
    /// Auto-stepping enabled
    @Published public var autoStepEnabled: Bool = false
    
    // MARK: - Dependencies
    
    private let detectionService: CubeDetectionService
    private let solver: CubeSolverProtocol
    
    /// Timer for auto-stepping
    private var autoStepTimer: Timer?
    
    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(
        initialState: CubeState,
        detectionService: CubeDetectionService = VisionCubeDetectionService.shared,
        solver: CubeSolverProtocol = BasicCubeSolver.shared
    ) {
        self.currentCubeState = initialState
        self.initialCubeState = initialState
        self.detectionService = detectionService
        self.solver = solver
    }
    
    // MARK: - Public Methods
    
    /// Start the coaching session
    public func startCoaching(with state: CubeState) {
        currentCubeState = state
        initialCubeState = state // Store the initial state
        coachingState = .calibrating
        sessionStats = ARSessionStats()
        sessionStats.startTime = Date()
        lastErrorMessage = nil
        
        // Solve the cube and prepare moves
        do {
            let basicSolver = solver as? BasicCubeSolver ?? BasicCubeSolver.shared
            algorithmSteps = try basicSolver.solveWithExplanations(from: state)
            plannedMoves = algorithmSteps.map { $0.move }
            currentStepIndex = 0
            
            // Transition to ready state
            coachingState = .ready
        } catch {
            coachingState = .error("Failed to solve cube: \(error.localizedDescription)")
            lastErrorMessage = error.localizedDescription
        }
    }
    
    /// Begin coaching after calibration
    public func beginCoaching() {
        guard coachingState == .ready else { return }
        coachingState = .running
    }
    
    /// Move to next step
    public func nextStep() {
        guard coachingState == .running else { return }
        guard currentStepIndex < plannedMoves.count - 1 else {
            // Reached the end
            completeCoaching()
            return
        }
        
        currentStepIndex += 1
        
        // Apply the move to current state
        applyCurrentMove()
    }
    
    /// Move to previous step
    public func previousStep() {
        guard coachingState == .running else { return }
        guard currentStepIndex > 0 else { return }
        
        currentStepIndex -= 1
        
        // Recalculate state from beginning
        recalculateStateToCurrentStep()
    }
    
    /// Toggle auto-stepping mode
    public func toggleAutoStep() {
        autoStepEnabled.toggle()
        
        if autoStepEnabled {
            startAutoStepping()
        } else {
            stopAutoStepping()
        }
    }
    
    /// Apply detected state from camera
    public func applyDetectedState(_ state: CubeState) {
        // Update current state with detected state
        currentCubeState = state
        
        // Could add validation here to check if state matches expected
    }
    
    /// Validate detected move against expected move
    public func validateDetectedMove(_ detectedState: CubeState) {
        guard currentStepIndex < plannedMoves.count else { return }
        
        let expectedState = calculateExpectedState()
        
        // Compare states
        if detectedState != expectedState {
            // States don't match - wrong move detected
            sessionStats.errorsDetected += 1
            coachingState = .error("Move doesn't match expected result")
            lastErrorMessage = "The detected cube state doesn't match the expected result. You may have made a wrong move."
        }
    }
    
    /// Undo current move
    public func undoCurrentMove() {
        guard currentStepIndex > 0 else { return }
        previousStep()
        
        if case .error = coachingState {
            coachingState = .running
            lastErrorMessage = nil
        }
    }
    
    /// Resync to detected state
    public func resyncToDetectedState() {
        // Clear error and continue from detected state
        if case .error = coachingState {
            coachingState = .running
            lastErrorMessage = nil
        }
    }
    
    /// Request a hint
    public func requestHint() {
        sessionStats.hintsRequested += 1
    }
    
    /// Complete the coaching session
    public func completeCoaching() {
        autoStepEnabled = false
        stopAutoStepping()
        
        sessionStats.totalTime = Date().timeIntervalSince(sessionStats.startTime)
        sessionStats.totalMoves = plannedMoves.count
        
        coachingState = .completed
    }
    
    /// Reset the coaching session
    public func reset() {
        stopAutoStepping()
        currentStepIndex = 0
        coachingState = .idle
        lastErrorMessage = nil
        plannedMoves = []
        algorithmSteps = []
        sessionStats = ARSessionStats()
    }
    
    // MARK: - Private Methods
    
    private func applyCurrentMove() {
        guard currentStepIndex < plannedMoves.count else { return }
        let move = plannedMoves[currentStepIndex]
        
        var state = currentCubeState
        EnhancedCubeSolver.applyMoves(to: &state, moves: [move])
        currentCubeState = state
    }
    
    private func recalculateStateToCurrentStep() {
        // Recalculate state by applying all moves up to current step
        var state = initialCubeState // Start from the stored initial state
        
        let movesToApply = Array(plannedMoves[0..<currentStepIndex])
        EnhancedCubeSolver.applyMoves(to: &state, moves: movesToApply)
        currentCubeState = state
    }
    
    private func calculateExpectedState() -> CubeState {
        var state = currentCubeState
        
        if currentStepIndex < plannedMoves.count {
            let move = plannedMoves[currentStepIndex]
            EnhancedCubeSolver.applyMoves(to: &state, moves: [move])
        }
        
        return state
    }
    
    private func startAutoStepping() {
        stopAutoStepping() // Clear any existing timer
        
        autoStepTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.nextStep()
            }
        }
    }
    
    private func stopAutoStepping() {
        autoStepTimer?.invalidate()
        autoStepTimer = nil
    }
}

// MARK: - Computed Properties

public extension ARCoachViewModel {
    /// Current move being coached
    var currentMove: Move? {
        guard currentStepIndex < plannedMoves.count else { return nil }
        return plannedMoves[currentStepIndex]
    }
    
    /// Current algorithm step with explanation
    var currentAlgorithmStep: AlgorithmStep? {
        guard currentStepIndex < algorithmSteps.count else { return nil }
        return algorithmSteps[currentStepIndex]
    }
    
    /// Progress percentage (0.0 to 1.0)
    var progress: Double {
        guard !plannedMoves.isEmpty else { return 0 }
        return Double(currentStepIndex) / Double(plannedMoves.count)
    }
    
    /// Formatted step counter
    var stepCounter: String {
        guard !plannedMoves.isEmpty else { return "0 of 0" }
        return "\(currentStepIndex + 1) of \(plannedMoves.count)"
    }
}

#endif

