#if canImport(SwiftUI)
//
//  SolutionPlaybackViewModel.swift
//  CubeSolver
//
//  ViewModel for controlling solution playback with step-by-step navigation
//

import SwiftUI
import Combine
import CubeCore

/// ViewModel for managing the playback of a Rubik's Cube solution
@MainActor
public class SolutionPlaybackViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The current step in the solution (0 = initial state)
    @Published public private(set) var currentStep: Int = 0
    
    /// Total number of moves in the solution
    @Published public private(set) var totalMoves: Int = 0
    
    /// Whether the solution is currently playing automatically
    @Published public private(set) var isPlaying: Bool = false
    
    /// The cube state at the current step
    @Published public private(set) var currentCubeState: CubeState
    
    /// Whether an animation is currently in progress
    @Published public private(set) var isAnimating: Bool = false
    
    // MARK: - Private Properties
    
    /// The complete solution being played back
    private let solution: CubeSolution
    
    /// Timer for automatic playback
    private var playbackTimer: Timer?
    
    /// Playback speed in moves per second
    private let playbackSpeed: Double
    
    // MARK: - Initialization
    
    /// Initialize the playback view model
    /// - Parameters:
    ///   - solution: The cube solution to play back
    ///   - playbackSpeed: Speed in moves per second (default: 1.0)
    public init(solution: CubeSolution, playbackSpeed: Double = 1.0) {
        self.solution = solution
        self.playbackSpeed = playbackSpeed
        self.totalMoves = solution.moves.count
        self.currentCubeState = solution.initialState
        self.currentStep = 0
    }
    
    // MARK: - Navigation Methods
    
    /// Move forward one step in the solution
    public func stepForward() {
        guard !isAnimating else { return }
        guard currentStep < totalMoves else { return }
        
        isAnimating = true
        currentStep += 1
        updateCubeState()
        
        // Animation will be handled by the view
        // Set isAnimating back to false after a delay
        Task {
            try? await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
            isAnimating = false
        }
    }
    
    /// Move backward one step in the solution
    public func stepBackward() {
        guard !isAnimating else { return }
        guard currentStep > 0 else { return }
        
        currentStep -= 1
        updateCubeState()
    }
    
    /// Jump to the start of the solution (initial state)
    public func jumpToStart() {
        guard !isAnimating else { return }
        pause()
        currentStep = 0
        updateCubeState()
    }
    
    /// Jump to the end of the solution (final state)
    public func jumpToEnd() {
        guard !isAnimating else { return }
        pause()
        currentStep = totalMoves
        updateCubeState()
    }
    
    // MARK: - Playback Control
    
    /// Start automatic playback
    public func play() {
        guard !isPlaying else { return }
        guard currentStep < totalMoves else { return }
        
        isPlaying = true
        
        let interval = 1.0 / playbackSpeed
        playbackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if self.currentStep >= self.totalMoves || self.isAnimating {
                    if self.currentStep >= self.totalMoves {
                        self.pause()
                    }
                    return
                }
                
                self.stepForward()
            }
        }
    }
    
    /// Pause automatic playback
    public func pause() {
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    /// Toggle between play and pause
    public func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    // MARK: - Scrubbing
    
    /// Scrub to a specific step in the solution
    /// - Parameter step: The target step (will be clamped to valid range)
    public func scrub(to step: Int) {
        // Always pause when scrubbing
        pause()
        
        // Clamp step to valid range
        let clampedStep = max(0, min(step, totalMoves))
        
        // Update current step
        currentStep = clampedStep
        updateCubeState()
    }
    
    // MARK: - Private Methods
    
    /// Update the cube state based on the current step
    private func updateCubeState() {
        currentCubeState = CubeState.state(at: currentStep, for: solution)
    }
    
    /// Clean up resources
    deinit {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
}

#endif
