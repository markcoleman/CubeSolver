#if canImport(SwiftUI)
//
//  SolutionPlaybackView.swift
//  CubeSolver
//
//  Step-by-step solution playback view with 3D animations
//

import SwiftUI
import CubeCore

/// View for displaying and playing back cube solution steps with 3D animations
public struct SolutionPlaybackView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: SolutionPlaybackViewModel
    @State private var lastStep = 0
    @State private var currentAnimatingMove: Move?
    
    /// Initialize the solution playback view
    /// - Parameters:
    ///   - initialState: The initial cube state
    ///   - playbackSpeed: Speed in moves per second (default: 1.0)
    public init(initialState: CubeCore.CubeState, playbackSpeed: Double = 1.0) {
        // Create a solution from the initial state
        let solution: CubeSolution
        do {
            let moves = try EnhancedCubeSolver.solveCube(from: initialState)
            solution = CubeSolution(initialState: initialState, moves: moves)
        } catch {
            // If solving fails, create empty solution
            solution = CubeSolution(initialState: initialState, moves: [])
        }
        
        _viewModel = StateObject(wrappedValue: SolutionPlaybackViewModel(
            solution: solution,
            playbackSpeed: playbackSpeed
        ))
    }
    
    /// Initialize with an existing solution
    /// - Parameters:
    ///   - solution: The cube solution to play back
    ///   - playbackSpeed: Speed in moves per second (default: 1.0)
    public init(solution: CubeSolution, playbackSpeed: Double = 1.0) {
        _viewModel = StateObject(wrappedValue: SolutionPlaybackViewModel(
            solution: solution,
            playbackSpeed: playbackSpeed
        ))
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: CubeSolverColors.backgroundGradient(for: colorScheme)),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .accessibilityHidden(true)
                
                VStack(spacing: 25) {
                    // Title
                    Text("Solution Playback")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                        .padding(.top, 20)
                        .accessibilityAddTraits(.isHeader)
                    
                    // Solution overview card
                    SolutionOverviewCard(
                        totalMoves: viewModel.totalMoves,
                        currentStep: viewModel.currentStep
                    )
                    .padding(.horizontal)
                    
                    // Scrubbing slider
                    VStack(spacing: 10) {
                        Slider(
                            value: Binding(
                                get: { Double(viewModel.currentStep) },
                                set: { viewModel.scrub(to: Int($0)) }
                            ),
                            in: 0...Double(viewModel.totalMoves),
                            step: 1
                        )
                        .padding(.horizontal)
                        .accentColor(.blue)
                        .accessibilityLabel("Solution progress slider")
                        .accessibilityValue("Step \(viewModel.currentStep) of \(viewModel.totalMoves)")
                        
                        HStack {
                            Text("Start")
                                .font(.caption)
                                .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
                            Spacer()
                            Text("End")
                                .font(.caption)
                                .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
                        }
                        .padding(.horizontal)
                    }
                    
                    // 3D Cube visualization
                    #if canImport(SceneKit)
                    AnimatedCube3DView(
                        cube: viewModel.currentCubeState.toRubiksCube(),
                        currentMove: $currentAnimatingMove,
                        onMoveComplete: handleAnimationComplete
                    )
                    .frame(height: 350)
                    .padding(.horizontal)
                    .accessibilityLabel("3D animated cube at step \(viewModel.currentStep)")
                    .id(viewModel.currentStep)
                    #else
                    // Fallback to 2D view on platforms without SceneKit
                    CubeView(cube: viewModel.currentCubeState.toRubiksCube())
                        .frame(maxWidth: 350, maxHeight: 350)
                        .accessibilityLabel("Cube state at step \(viewModel.currentStep)")
                        .id(viewModel.currentStep)
                    #endif
                    
                    // Current move display
                    if viewModel.currentStep > 0 && viewModel.currentStep <= viewModel.totalMoves {
                        // Get the move that was just applied (currentStep - 1 because we show the result)
                        if viewModel.currentStep - 1 < viewModel.solution.moves.count {
                            let move = viewModel.solution.moves[viewModel.currentStep - 1]
                            CurrentMoveCard(moveNotation: move.notation, moveDescription: move.description)
                                .padding(.horizontal)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.currentStep)
                        }
                    }
                    
                    // Playback controls
                    PlaybackControls(
                        currentStep: viewModel.currentStep,
                        totalSteps: viewModel.totalMoves,
                        isPlaying: viewModel.isPlaying,
                        isAnimating: viewModel.isAnimating,
                        onPrevious: { viewModel.stepBackward() },
                        onNext: { viewModel.stepForward() },
                        onPlayPause: { viewModel.togglePlayPause() },
                        onReset: { viewModel.jumpToStart() },
                        onJumpToEnd: { viewModel.jumpToEnd() }
                    )
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        viewModel.pause()
                        dismiss()
                    }
                    .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                }
            }
            .onChange(of: viewModel.currentStep) { oldValue, newValue in
                handleStepChange(from: oldValue, to: newValue)
            }
            .onDisappear {
                viewModel.pause()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func handleStepChange(from oldStep: Int, to newStep: Int) {
        let stepDiff = newStep - oldStep
        
        #if canImport(SceneKit)
        // If we moved forward by exactly 1 step, trigger animation
        if stepDiff == 1 && newStep > 0 {
            if newStep - 1 < viewModel.solution.moves.count {
                currentAnimatingMove = viewModel.solution.moves[newStep - 1]
            }
        } else {
            // For other changes (backward, jumps), just update without animation
            currentAnimatingMove = nil
        }
        #endif
        
        lastStep = newStep
    }
    
    private func handleAnimationComplete() {
        currentAnimatingMove = nil
    }
}

/// Card showing solution overview
public struct SolutionOverviewCard: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let totalMoves: Int
    let currentStep: Int
    
    public var body: some View {
        GlassmorphicCard {
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Moves")
                            .font(.caption)
                            .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
                        Text("\(totalMoves)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Current Step")
                            .font(.caption)
                            .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
                        Text("\(currentStep)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                    }
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.2) : Color.gray.opacity(0.3))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.blue)
                            .frame(
                                width: totalMoves > 0 ? geometry.size.width * CGFloat(currentStep) / CGFloat(totalMoves) : 0,
                                height: 8
                            )
                    }
                }
                .frame(height: 8)
            }
            .padding()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Solution progress: step \(currentStep) of \(totalMoves)")
    }
}

/// Card showing current move
public struct CurrentMoveCard: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let moveNotation: String
    let moveDescription: String
    
    public var body: some View {
        GlassmorphicCard {
            VStack(spacing: 10) {
                Text("Current Move")
                    .font(.caption)
                    .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
                
                HStack(spacing: 15) {
                    Text(moveNotation)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(moveDescription)
                            .font(.body)
                            .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                    }
                }
            }
            .padding()
        }
        .accessibilityLabel("Move: \(moveNotation), \(moveDescription)")
    }
}

/// Playback control buttons
public struct PlaybackControls: View {
    let currentStep: Int
    let totalSteps: Int
    let isPlaying: Bool
    let isAnimating: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onPlayPause: () -> Void
    let onReset: () -> Void
    let onJumpToEnd: () -> Void
    
    public var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 20) {
                // Reset to start button
                PlaybackButton(icon: "backward.end.fill", action: onReset)
                    .disabled(currentStep == 0 || isAnimating)
                    .accessibilityLabel("Reset to beginning")
                
                // Previous step button
                PlaybackButton(icon: "backward.fill", action: onPrevious)
                    .disabled(currentStep == 0 || isAnimating)
                    .accessibilityLabel("Previous step")
                
                // Play/Pause button
                PlaybackButton(
                    icon: isPlaying ? "pause.fill" : "play.fill",
                    action: onPlayPause,
                    isLarge: true
                )
                .disabled(currentStep >= totalSteps || isAnimating)
                .accessibilityLabel(isPlaying ? "Pause" : "Play")
                
                // Next step button
                PlaybackButton(icon: "forward.fill", action: onNext)
                    .disabled(currentStep >= totalSteps || isAnimating)
                    .accessibilityLabel("Next step")
                
                // Jump to end button
                PlaybackButton(icon: "forward.end.fill", action: onJumpToEnd)
                    .disabled(currentStep >= totalSteps || isAnimating)
                    .accessibilityLabel("Skip to end")
            }
        }
    }
}

/// Individual playback button
public struct PlaybackButton: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let icon: String
    let action: () -> Void
    var isLarge: Bool = false
    
    public var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: isLarge ? 32 : 24))
                .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                .frame(width: isLarge ? 70 : 50, height: isLarge ? 70 : 50)
                .background(
                    Circle()
                        .fill(CubeSolverColors.cardBackground(for: colorScheme))
                        .overlay(
                            Circle()
                                .stroke(CubeSolverColors.glassBorder(for: colorScheme), lineWidth: 1)
                        )
                        .shadow(color: CubeSolverColors.shadow(for: colorScheme), radius: 5, x: 0, y: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SolutionPlaybackView(
        initialState: CubeCore.CubeState()
    )
}
#endif

