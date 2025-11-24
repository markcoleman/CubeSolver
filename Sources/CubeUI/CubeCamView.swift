//
//  CubeCamView.swift
//  CubeSolver - Cube Cam Auto-Scan View
//
//  Created by GitHub Copilot
//

#if os(iOS)

import SwiftUI
import AVFoundation
import CubeCore
import CubeScanner

/// Cube Cam auto-scanning view with camera preview and guided UX
@MainActor
public struct CubeCamView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = CubeCamViewModel()
    
    /// Completion handler with captured cube state
    public var onComplete: ((CubeState) -> Void)?
    
    public init(onComplete: ((CubeState) -> Void)? = nil) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        ZStack {
            // Camera preview
            CubeCamCameraPreviewView(viewModel: viewModel)
                .ignoresSafeArea()
            
            // PROMPT 9: Alignment guide (shown in manual mode)
            if !viewModel.capturePipeline.autoCaptureEnabled {
                AlignmentGuide(isAligned: viewModel.stability > 0.7)
                    .allowsHitTesting(false)
            }
            
            // Detection overlay
            if let detection = viewModel.detectionResult {
                DetectionOverlay(detection: detection, stability: viewModel.stability)
            }
            
            // Face capture flash animation
            if viewModel.faceCaptured {
                FaceCaptureFlash()
                    .transition(.opacity)
            }
            
            // PROMPT 2: Duplicate face warning
            if let warning = viewModel.duplicateFaceWarning {
                VStack {
                    DuplicateFaceWarning(message: warning) {
                        viewModel.duplicateFaceWarning = nil
                    }
                    .padding(.top, 100)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // PROMPT 3: Wrong face warning
            if let warning = viewModel.wrongFaceWarning {
                VStack {
                    WrongFaceWarning(message: warning) {
                        viewModel.wrongFaceWarning = nil
                    }
                    .padding(.top, 100)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // UI Overlay
            VStack {
                // Top instruction text
                VStack(spacing: 12) {
                    HStack {
                        Text(viewModel.captureProgressText)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // PROMPT 9: Capture mode badge
                        CaptureModeBadge(
                            isAutoMode: viewModel.capturePipeline.autoCaptureEnabled
                        ) {
                            viewModel.capturePipeline.autoCaptureEnabled.toggle()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    // PROMPT 4: Improved 3D face indicators
                    Improved3DFaceIndicator(
                        capturedFaces: Array(viewModel.capturedFaces),
                        currentFace: viewModel.currentFace,
                        nextFace: viewModel.capturePipeline.getNextFaceToCapture()
                    )
                    .padding(.horizontal)
                    
                    // PROMPT 1: Scanning stability overlay
                    if viewModel.capturePipeline.captureState != .idle {
                        ScanningOverlay(
                            captureState: viewModel.capturePipeline.captureState,
                            requiredFrames: viewModel.capturePipeline.requiredStableFrames,
                            currentFrames: viewModel.capturePipeline.consecutiveStableFrames
                        )
                        .transition(.opacity.combined(with: .scale))
                    }
                    
                    // PROMPT 10: Debug overlay (toggle with triple-tap)
                    if viewModel.debugModeEnabled {
                        DebugOverlay(
                            stability: viewModel.stability,
                            consecutiveStableFrames: viewModel.capturePipeline.consecutiveStableFrames,
                            requiredStableFrames: viewModel.capturePipeline.requiredStableFrames,
                            detectedFace: viewModel.currentFace,
                            detectedCenterColor: nil, // Would need to expose this
                            brightness: viewModel.frameMetadata?.brightness ?? 0.5,
                            capturedFaces: Array(viewModel.capturedFaces)
                        )
                        .padding(.horizontal)
                        .transition(.opacity)
                    }
                }
                .padding(.top, 60)
                .onTapGesture(count: 3) {
                    // PROMPT 10: Triple-tap to toggle debug mode
                    withAnimation {
                        viewModel.debugModeEnabled.toggle()
                    }
                }
                
                Spacer()
                
                // Bottom controls
                VStack(spacing: 16) {
                    // Stability indicator
                    StabilityIndicator(stability: viewModel.stability)
                    
                    // Progress bar
                    ProgressView(value: Double(viewModel.capturedFaceCount), total: 6)
                        .tint(.blue)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(4)
                        .accessibilityLabel("Cube faces captured")
                        .accessibilityValue("\(viewModel.capturedFaceCount) of 6 faces")
                    
                    Text("\(viewModel.capturedFaceCount)/6 faces captured")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        // Cancel button
                        Button {
                            viewModel.stop()
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                        }
                        
                        // PROMPT 9: Manual capture button with countdown (shown in manual mode)
                        if !viewModel.capturePipeline.autoCaptureEnabled && viewModel.capturedFaceCount < 6 {
                            ManualCaptureButton(
                                isEnabled: viewModel.stability > 0.7
                            ) {
                                Task {
                                    await viewModel.manualCapture()
                                }
                            }
                        }
                        
                        // Auto capture indicator (shown in auto mode when stable)
                        if viewModel.capturePipeline.autoCaptureEnabled 
                            && viewModel.stability > 0.7 
                            && viewModel.capturedFaceCount < 6 {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                Text("Auto-scanning...")
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
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: -4)
            }
            
            // PROMPT 8: Scan error overlay
            if let error = viewModel.capturePipeline.currentError {
                ScanErrorOverlay(error: error) {
                    viewModel.capturePipeline.currentError = nil
                }
            }
            
            // Error alert overlay
            if case .error(let message) = viewModel.detectionStatus {
                ErrorOverlay(message: message) {
                    viewModel.reset()
                }
            }
            
            // Completion overlay
            if viewModel.detectionStatus == .completed, let cubeState = viewModel.completedCubeState {
                CompletionOverlay {
                    viewModel.stop()
                    onComplete?(cubeState)
                    dismiss()
                }
            }
        }
        .navigationTitle("Cube Cam")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }
}

// MARK: - Face Capture Indicators

struct FaceCaptureIndicators: View {
    let capturedFaces: [Face]
    let currentFace: Face?
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach([Face.up, Face.front, Face.right, Face.back, Face.left, Face.down], id: \.self) { face in
                FaceIndicatorBadge(
                    face: face,
                    isCaptured: capturedFaces.contains(face),
                    isCurrent: currentFace == face
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct FaceIndicatorBadge: View {
    let face: Face
    let isCaptured: Bool
    let isCurrent: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(isCaptured ? Color.green : (isCurrent ? Color.blue : Color.gray.opacity(0.5)))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: isCaptured ? "checkmark" : "cube")
                        .font(.caption)
                        .foregroundColor(.white)
                )
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isCurrent ? 2 : 0)
                )
            
            Text(face.rawValue)
                .font(.caption2)
                .foregroundColor(.white)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
    
    /// Accessibility label describing face and capture status
    private var accessibilityLabel: String {
        var label = "\(faceDisplayName) face"
        if isCaptured {
            label += ", captured"
        } else {
            label += ", not captured"
        }
        if isCurrent {
            label += ", current face"
        }
        return label
    }
    
    /// Human-readable face name
    private var faceDisplayName: String {
        switch face {
        case .up: return "Up"
        case .down: return "Down"
        case .left: return "Left"
        case .right: return "Right"
        case .front: return "Front"
        case .back: return "Back"
        }
    }
}

// MARK: - Error Overlay

struct ErrorOverlay: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                
                Text("Error")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: onRetry) {
                    Text("Retry")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: 200)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.5), radius: 20)
        }
    }
}

// MARK: - Face Capture Flash

struct FaceCaptureFlash: View {
    @State private var opacity: Double = 0.8
    
    var body: some View {
        Rectangle()
            .fill(Color.green.opacity(opacity))
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                }
            }
    }
}

#Preview {
    NavigationStack {
        CubeCamView()
    }
}

#endif
