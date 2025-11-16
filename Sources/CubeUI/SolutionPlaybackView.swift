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
    @ObservedObject var cubeViewModel: CubeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    @State private var isPlaying = false
    @State private var playbackTimer: Timer?
    @State private var cubeStates: [CubeCore.CubeState] = []
    @State private var moves: [String] = []
    @State private var currentAnimatingMove: String?
    @State private var isAnimating = false
    
    let initialState: CubeCore.CubeState
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.2, green: 0.15, blue: 0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .accessibilityHidden(true)
                
                VStack(spacing: 30) {
                    Text("Solution Playback")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 50)
                        .accessibilityAddTraits(.isHeader)
                    
                    // Solution overview
                    SolutionOverviewCard(
                        totalMoves: moves.count,
                        currentStep: currentStep
                    )
                    .padding(.horizontal)
                    
                    // Cube visualization - Use 3D view for better UX with animations
                    if currentStep < cubeStates.count {
                        #if canImport(SceneKit)
                        AnimatedCube3DView(
                            cube: cubeStates[currentStep].toRubiksCube(),
                            currentMove: .constant(nil),
                            onMoveComplete: handleAnimationComplete
                        )
                        .frame(height: 450)
                        .padding(.horizontal)
                        .accessibilityLabel("3D animated cube at step \(currentStep)")
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
                        .id(currentStep) // Force SwiftUI to recognize state changes
                        #else
                        // Fallback to 2D view on platforms without SceneKit
                        CubeView(cube: cubeStates[currentStep].toRubiksCube())
                            .frame(maxWidth: 450, maxHeight: 450)
                            .accessibilityLabel("Cube state at step \(currentStep)")
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
                            .id(currentStep)
                        #endif
                    }
                    
                    // Current move display
                    if currentStep > 0 && currentStep <= moves.count {
                        CurrentMoveCard(move: moves[currentStep - 1])
                            .padding(.horizontal)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
                    }
                    
                    // Playback controls
                    PlaybackControls(
                        currentStep: $currentStep,
                        isPlaying: $isPlaying,
                        totalSteps: moves.count,
                        onPrevious: previousStep,
                        onNext: nextStep,
                        onPlayPause: togglePlayback,
                        onReset: resetPlayback,
                        isAnimating: isAnimating
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
                        stopPlayback()
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                loadSolution()
            }
            .onDisappear {
                stopPlayback()
            }
        }
    }
    
    private func loadSolution() {
        // Get solution moves
        do {
            let coreMoves = try EnhancedCubeSolver.solveCube(from: initialState)
            moves = coreMoves.map { String(describing: $0) }
            
            // Generate cube states for each step using core moves for correctness
            cubeStates = [initialState]
            var currentState = initialState
            
            for coreMove in coreMoves {
                EnhancedCubeSolver.applyMoves(to: &currentState, moves: [coreMove])
                cubeStates.append(currentState)
            }
        } catch {
            // If solving fails, just show the initial state
            moves = []
            cubeStates = [initialState]
        }
    }
    
    private func previousStep() {
        guard !isAnimating else { return }
        if currentStep > 0 {
            currentStep -= 1
        }
    }
    
    private func nextStep() {
        guard !isAnimating else { return }
        if currentStep < moves.count {
            triggerAnimation(for: currentStep)
            currentStep += 1
        }
    }
    
    private func triggerAnimation(for step: Int) {
        #if canImport(SceneKit)
        if step < moves.count {
            isAnimating = true
            currentAnimatingMove = moves[step]
        }
        #endif
    }
    
    private func handleAnimationComplete() {
        isAnimating = false
        currentAnimatingMove = nil
    }
    
    private func togglePlayback() {
        isPlaying.toggle()
        
        if isPlaying {
            startPlayback()
        } else {
            stopPlayback()
        }
    }
    
    private func startPlayback() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            if currentStep < moves.count && !isAnimating {
                triggerAnimation(for: currentStep)
                currentStep += 1
            } else if currentStep >= moves.count {
                stopPlayback()
            }
        }
    }
    
    private func stopPlayback() {
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func resetPlayback() {
        stopPlayback()
        currentStep = 0
        currentAnimatingMove = nil
        isAnimating = false
    }
}

/// Card showing solution overview
public struct SolutionOverviewCard: View {
    let totalMoves: Int
    let currentStep: Int
    
    public var body: some View {
        GlassmorphicCard {
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Moves")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(totalMoves)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Current Step")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(currentStep)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.white.opacity(0.2))
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
    let move: String
    
    public var body: some View {
        GlassmorphicCard {
            VStack(spacing: 10) {
                Text("Current Move")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 15) {
                    Text(moveDisplay(move))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(moveDetails(move))
                            .font(.body)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
        }
        .accessibilityLabel("Move: \(moveDisplay(move))")
    }
    
    private func moveDisplay(_ move: String) -> String { move }
    private func moveDetails(_ move: String) -> String { "" }
}

/// Playback control buttons
public struct PlaybackControls: View {
    @Binding var currentStep: Int
    @Binding var isPlaying: Bool
    let totalSteps: Int
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onPlayPause: () -> Void
    let onReset: () -> Void
    var isAnimating: Bool = false
    
    public var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 20) {
                // Reset button
                PlaybackButton(icon: "backward.end.fill", action: onReset)
                    .disabled(currentStep == 0 || isAnimating)
                    .accessibilityLabel("Reset to beginning")
                
                // Previous button
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
                
                // Next button
                PlaybackButton(icon: "forward.fill", action: onNext)
                    .disabled(currentStep >= totalSteps || isAnimating)
                    .accessibilityLabel("Next step")
                
                // Fast forward (to end)
                PlaybackButton(icon: "forward.end.fill") {
                    currentStep = totalSteps
                }
                .disabled(currentStep >= totalSteps || isAnimating)
                .accessibilityLabel("Skip to end")
            }
        }
    }
}

/// Individual playback button
public struct PlaybackButton: View {
    let icon: String
    let action: () -> Void
    var isLarge: Bool = false
    
    public var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: isLarge ? 32 : 24))
                .foregroundColor(.white)
                .frame(width: isLarge ? 70 : 50, height: isLarge ? 70 : 50)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SolutionPlaybackView(
        cubeViewModel: CubeViewModel(),
        initialState: CubeCore.CubeState()
    )
}
#endif

