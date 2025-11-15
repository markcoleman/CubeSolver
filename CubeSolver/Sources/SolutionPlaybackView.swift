//
//  SolutionPlaybackView.swift
//  CubeSolver
//
//  Step-by-step solution playback view
//

import SwiftUI

/// View for displaying and playing back cube solution steps
struct SolutionPlaybackView: View {
    @ObservedObject var cubeViewModel: CubeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    @State private var isPlaying = false
    @State private var playbackTimer: Timer?
    @State private var cubeStates: [CubeState] = []
    @State private var moves: [Move] = []
    
    let initialState: CubeState
    
    var body: some View {
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
                    
                    // Cube visualization
                    if currentStep < cubeStates.count {
                        CubeView(cube: cubeStates[currentStep].toRubiksCube())
                            .frame(maxWidth: 350, maxHeight: 350)
                            .accessibilityLabel("Cube state at step \(currentStep)")
                    }
                    
                    // Current move display
                    if currentStep > 0 && currentStep <= moves.count {
                        CurrentMoveCard(move: moves[currentStep - 1])
                            .padding(.horizontal)
                    }
                    
                    // Playback controls
                    PlaybackControls(
                        currentStep: $currentStep,
                        isPlaying: $isPlaying,
                        totalSteps: moves.count,
                        onPrevious: previousStep,
                        onNext: nextStep,
                        onPlayPause: togglePlayback,
                        onReset: resetPlayback
                    )
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
            moves = try EnhancedCubeSolver.solveCube(from: initialState)
            
            // Generate cube states for each step
            cubeStates = [initialState]
            var currentState = initialState
            
            for move in moves {
                EnhancedCubeSolver.applyMoves(to: &currentState, moves: [move])
                cubeStates.append(currentState)
            }
        } catch {
            // If solving fails, just show the initial state
            moves = []
            cubeStates = [initialState]
        }
    }
    
    private func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }
    
    private func nextStep() {
        if currentStep < moves.count {
            currentStep += 1
        }
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
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if currentStep < moves.count {
                currentStep += 1
            } else {
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
    }
}

/// Card showing solution overview
struct SolutionOverviewCard: View {
    let totalMoves: Int
    let currentStep: Int
    
    var body: some View {
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
struct CurrentMoveCard: View {
    let move: Move
    
    var body: some View {
        GlassmorphicCard {
            VStack(spacing: 10) {
                Text("Current Move")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 15) {
                    Text(move.notation)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(move.description)
                            .font(.body)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
        }
        .accessibilityLabel("Move: \(move.notation), \(move.description)")
    }
}

/// Playback control buttons
struct PlaybackControls: View {
    @Binding var currentStep: Int
    @Binding var isPlaying: Bool
    let totalSteps: Int
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onPlayPause: () -> Void
    let onReset: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 20) {
                // Reset button
                PlaybackButton(icon: "backward.end.fill", action: onReset)
                    .disabled(currentStep == 0)
                    .accessibilityLabel("Reset to beginning")
                
                // Previous button
                PlaybackButton(icon: "backward.fill", action: onPrevious)
                    .disabled(currentStep == 0)
                    .accessibilityLabel("Previous step")
                
                // Play/Pause button
                PlaybackButton(
                    icon: isPlaying ? "pause.fill" : "play.fill",
                    action: onPlayPause,
                    isLarge: true
                )
                .disabled(currentStep >= totalSteps)
                .accessibilityLabel(isPlaying ? "Pause" : "Play")
                
                // Next button
                PlaybackButton(icon: "forward.fill", action: onNext)
                    .disabled(currentStep >= totalSteps)
                    .accessibilityLabel("Next step")
                
                // Fast forward (to end)
                PlaybackButton(icon: "forward.end.fill") {
                    currentStep = totalSteps
                }
                .disabled(currentStep >= totalSteps)
                .accessibilityLabel("Skip to end")
            }
        }
    }
}

/// Individual playback button
struct PlaybackButton: View {
    let icon: String
    let action: () -> Void
    var isLarge: Bool = false
    
    var body: some View {
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
        initialState: CubeState()
    )
}
