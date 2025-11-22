//
//  ARCoachView.swift
//  CubeSolver - AR Coach Mode Main View
//
//  Created by GitHub Copilot
//

#if canImport(SwiftUI)

import SwiftUI
import CubeCore
import CubeAR

/// Main AR coaching view that guides users through solving a physical cube
@MainActor
public struct ARCoachView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: ARCoachViewModel
    @State private var showExplanation = false
    @State private var showCompletionSummary = false
    
    public init(initialState: CubeState) {
        _viewModel = StateObject(wrappedValue: ARCoachViewModel(initialState: initialState))
    }
    
    public var body: some View {
        ZStack {
            // AR view container (placeholder for now)
            ARPlaceholderView(
                currentMove: viewModel.currentMove,
                coachingState: viewModel.coachingState
            )
            
            // Overlay UI
            VStack {
                // Top bar
                topBar
                
                Spacer()
                
                // Calibration overlay
                if viewModel.coachingState == .calibrating {
                    calibrationOverlay
                }
                
                // Error overlay
                if case .error(let message) = viewModel.coachingState {
                    errorOverlay(message: message)
                }
                
                // Bottom controls
                if viewModel.coachingState == .running {
                    bottomControls
                }
            }
            .padding()
            
            // Completion summary
            if viewModel.coachingState == .completed || showCompletionSummary {
                completionSummaryView
            }
            
            // Explanation sheet
            if showExplanation {
                explanationSheet
            }
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.startCoaching(with: viewModel.currentCubeState)
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
            
            Spacer()
            
            // Step counter
            Text(viewModel.stepCounter)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
            
            Spacer()
            
            // Info button
            Button(action: { showExplanation = true }) {
                Image(systemName: "info.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
        }
    }
    
    // MARK: - Calibration Overlay
    
    private var calibrationOverlay: some View {
        VStack(spacing: 24) {
            Text("Cube Calibration")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Hold the cube in front of the camera")
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            
            Text("White face up, green face front")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
                .padding()
            
            Button("Start Coaching") {
                viewModel.beginCoaching()
            }
            .buttonStyle(GlassButtonStyle(color: .green))
            .padding(.horizontal)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.3), radius: 10)
    }
    
    // MARK: - Error Overlay
    
    private func errorOverlay(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Error Detected")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(message)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button("Undo") {
                    viewModel.undoCurrentMove()
                }
                .buttonStyle(GlassButtonStyle(color: .orange))
                
                Button("Re-sync") {
                    viewModel.resyncToDetectedState()
                }
                .buttonStyle(GlassButtonStyle(color: .blue))
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.3), radius: 10)
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Current move display
            if let step = viewModel.currentAlgorithmStep {
                VStack(spacing: 8) {
                    HStack {
                        Text(step.phase.displayName)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                    }
                    
                    HStack {
                        Text(step.move.notation)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: { showExplanation = true }) {
                            Text("Why?")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                        }
                    }
                    
                    HStack {
                        Text(step.description)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
            }
            
            // Control buttons
            HStack(spacing: 16) {
                Button(action: { viewModel.previousStep() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(.ultraThinMaterial)
                        .cornerRadius(30)
                }
                .disabled(viewModel.currentStepIndex == 0)
                
                Button(action: { viewModel.toggleAutoStep() }) {
                    Image(systemName: viewModel.autoStepEnabled ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(viewModel.autoStepEnabled ? Color.green : .ultraThinMaterial)
                        .cornerRadius(30)
                }
                
                Button(action: { viewModel.nextStep() }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(.ultraThinMaterial)
                        .cornerRadius(30)
                }
                .disabled(viewModel.currentStepIndex >= viewModel.plannedMoves.count - 1)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    // MARK: - Explanation Sheet
    
    private var explanationSheet: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    showExplanation = false
                }
            
            VStack(spacing: 20) {
                HStack {
                    Text("Move Explanation")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: { showExplanation = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let step = viewModel.currentAlgorithmStep {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(step.move.notation)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        
                        Text(step.phase.displayName)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(step.description)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Text(step.move.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
            }
            .padding(24)
            .background(
                colorScheme == .dark ? Color.black.opacity(0.9) : Color.white.opacity(0.95)
            )
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
            .padding(.vertical, 100)
        }
    }
    
    // MARK: - Completion Summary
    
    private var completionSummaryView: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Celebration icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("Congratulations!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("You've completed the solve!")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                
                // Statistics
                VStack(spacing: 12) {
                    StatRow(label: "Total Time", value: formatTime(viewModel.sessionStats.totalTime))
                    StatRow(label: "Total Moves", value: "\(viewModel.sessionStats.totalMoves)")
                    StatRow(label: "Errors Corrected", value: "\(viewModel.sessionStats.errorsDetected)")
                    StatRow(label: "Hints Used", value: "\(viewModel.sessionStats.hintsRequested)")
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                
                // Buttons
                VStack(spacing: 12) {
                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(GlassButtonStyle(color: .blue))
                }
                .padding(.horizontal)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.3), radius: 20)
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Supporting Views

/// Placeholder AR view
struct ARPlaceholderView: View {
    let currentMove: Move?
    let coachingState: CoachingState
    
    var body: some View {
        ZStack {
            Color.black
            
            VStack(spacing: 20) {
                Image(systemName: "cube.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.white.opacity(0.3))
                
                Text("AR View")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.5))
                
                if let move = currentMove {
                    Text("Next: \(move.notation)")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}

/// Statistic row
struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

/// Glassmorphic button style
struct GlassButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(color.opacity(configuration.isPressed ? 0.7 : 1.0))
            .cornerRadius(12)
    }
}

#endif
