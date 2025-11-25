#if canImport(SwiftUI)
//
//  PracticeView.swift
//  CubeSolver - Practice Mode
//
//  Created by GitHub Copilot
//

import SwiftUI
import CubeCore

/// Practice mode view with timer and scramble generation
///
/// Provides functionality to:
/// - Generate random scrambles for practice
/// - Track solving time with a precision timer
/// - Show hints for next move
/// - Display full solution with playback
public struct PracticeView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var cubeViewModel: CubeViewModel
    @State private var scrambleMoves: [CubeCore.Move] = []
    @State private var scrambleNotation: String = ""
    @State private var timeElapsed: TimeInterval = 0
    @State private var timerActive = false
    @State private var timer: Timer?
    @State private var timerStartTime: Date?
    @State private var showHint = false
    @State private var showSolution = false
    @State private var showingSolutionPlayback = false
    
    public init(cubeViewModel: CubeViewModel) {
        self.cubeViewModel = cubeViewModel
    }
    
    public var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: CubeSolverColors.backgroundGradient(for: colorScheme)),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    Text("Practice Mode")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                        .padding(.top, 20)
                    
                    // Description
                    Text("Practice solving with random scrambles")
                        .font(.subheadline)
                        .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Timer
                    VStack(spacing: 8) {
                        Text("Time")
                            .font(.caption)
                            .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
                        
                        Text(timeString(from: timeElapsed))
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                            .accessibilityLabel("Time elapsed")
                            .accessibilityValue(timeString(from: timeElapsed))
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    
                    // Cube visualization - Use 3D view for better UX
                    #if canImport(SceneKit)
                    Cube3DView(
                        cube: cubeViewModel.cube,
                        autoRotate: false,
                        allowInteraction: true
                    )
                    .frame(height: 400)
                    .padding(.horizontal)
                    #else
                    // Fallback to 2D view
                    CubeView(cube: cubeViewModel.cube)
                        .frame(maxWidth: 400, maxHeight: 400)
                        .padding()
                    #endif
                    
                    // Scramble display
                    if !scrambleNotation.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Scramble")
                                .font(.headline)
                                .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                            
                            Text(scrambleNotation)
                                .font(.body)
                                .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                                .padding()
                                .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.5))
                                .cornerRadius(8)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            generateNewScramble()
                        }) {
                            HStack {
                                Image(systemName: "shuffle")
                                    .font(.title3)
                                Text("New Scramble")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.orange, .orange.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                toggleTimer()
                            }) {
                                HStack {
                                    Image(systemName: timerActive ? "pause.fill" : "play.fill")
                                        .font(.title3)
                                    Text(timerActive ? "Pause" : "Start")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.green, .green.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            
                            Button(action: {
                                resetPractice()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.title3)
                                    Text("Reset")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                            }
                        }
                        
                        // Help buttons
                        HStack(spacing: 12) {
                            Button(action: {
                                showHint.toggle()
                            }) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.title3)
                                    Text("Hint")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            
                            Button(action: {
                                Task {
                                    await cubeViewModel.solveAsync()
                                    if !cubeViewModel.solution.isEmpty {
                                        showSolution = true
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "book.fill")
                                        .font(.title3)
                                    Text(cubeViewModel.solution.isEmpty ? "Get Solution" : "Show Solution")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.purple, .purple.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Hint display
                    if showHint && !cubeViewModel.solution.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Next Move Hint")
                                .font(.headline)
                                .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                            
                            Text(cubeViewModel.solution.first.map { String(describing: $0) } ?? "No hint available")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // Solution display
                    if showSolution && !cubeViewModel.solution.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Full Solution")
                                .font(.headline)
                                .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                            
                            Text("\(cubeViewModel.solution.count) moves")
                                .font(.subheadline)
                                .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
                            
                            Button(action: {
                                showingSolutionPlayback = true
                            }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                        .font(.title3)
                                    Text("View Playback")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.green, .green.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Practice")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationDestination(isPresented: $showingSolutionPlayback) {
            SolutionPlaybackView(
                initialState: CubeState(from: cubeViewModel.cube)
            )
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func generateNewScramble() {
        stopTimer()
        cubeViewModel.reset()
        scrambleMoves = EnhancedCubeSolver.generateScramble(moveCount: 20)
        scrambleNotation = scrambleMoves.map { String(describing: $0) }.joined(separator: " ")
        
        // Apply scramble to cube
        var state = CubeState(from: cubeViewModel.cube)
        EnhancedCubeSolver.applyMoves(to: &state, moves: scrambleMoves)
        cubeViewModel.cube = state.toRubiksCube()
        
        timeElapsed = 0
        showHint = false
        showSolution = false
        cubeViewModel.solution = []  // Clear stale solution
    }
    
    private func toggleTimer() {
        if timerActive {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        timerActive = true
        timerStartTime = Date()
        let newTimer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if let startTime = self.timerStartTime {
                self.timeElapsed = Date().timeIntervalSince(startTime)
            }
        }
        RunLoop.current.add(newTimer, forMode: .common)
        timer = newTimer
    }
    
    private func stopTimer() {
        timerActive = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resetPractice() {
        stopTimer()
        timeElapsed = 0
        showHint = false
        showSolution = false
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        let milliseconds = Int((interval.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, milliseconds)
    }
}

#endif
