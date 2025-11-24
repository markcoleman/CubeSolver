//
//  EnhancedCubeCamView.swift
//  CubeSolver - Enhanced Cube Cam View with Improved UX
//
//  Created by GitHub Copilot
//

#if os(iOS)

import SwiftUI
import AVFoundation
import CubeCore
import CubeScanner

/// Enhanced CubeCam view with step-by-step guidance and improved UX
@MainActor
public struct EnhancedCubeCamView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = EnhancedCubeCamViewModel()
    
    /// Completion handler with captured cube state
    public var onComplete: ((CubeState) -> Void)?
    
    public init(onComplete: ((CubeState) -> Void)? = nil) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        ZStack {
            // Camera preview
            EnhancedCubeCamCameraPreviewView(viewModel: viewModel)
                .ignoresSafeArea()
            
            // Detection overlay (bounding box and corners)
            if let detection = viewModel.detectionResult {
                DetectionOverlay(detection: detection, stability: viewModel.stability)
            }
            
            // Main UI overlay
            VStack(spacing: 0) {
                // Top section: Guidance
                if let guidance = viewModel.currentGuidance {
                    EnhancedScanGuidance(
                        guidance: guidance,
                        scanState: viewModel.faceStates[guidance.targetFace] ?? .notScanned
                    )
                    .padding(.horizontal)
                    .padding(.top, 60)
                }
                
                // Mini 3D cube with tap-to-rescan
                InteractiveMiniCube(
                    faceStates: viewModel.faceStates,
                    nextFace: viewModel.nextFaceToScan(),
                    onFaceTap: { face in
                        viewModel.rescanFace(face)
                    }
                )
                .padding(.horizontal)
                .padding(.top, 12)
                
                Spacer()
                
                // Bottom section: Progress and actions
                VStack(spacing: 16) {
                    // Overall progress
                    VStack(spacing: 8) {
                        HStack {
                            Text("\(viewModel.capturedCount) of 6 faces captured")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Auto/Manual mode badge
                            CaptureModeBadge(
                                isAutoMode: viewModel.capturePipeline.autoCaptureEnabled
                            ) {
                                viewModel.capturePipeline.autoCaptureEnabled.toggle()
                            }
                        }
                        
                        ProgressView(value: Double(viewModel.capturedCount), total: 6)
                            .tint(.green)
                            .background(Color.white.opacity(0.3))
                            .cornerRadius(4)
                    }
                    
                    // Stability indicator
                    if !viewModel.isComplete {
                        StabilityIndicator(stability: viewModel.stability)
                    }
                    
                    // Action buttons
                    ScanActionButtons(
                        canCaptureNext: viewModel.stability > 0.7,
                        canFinish: viewModel.isComplete,
                        onScanAgain: {
                            if let nextFace = viewModel.nextFaceToScan() {
                                viewModel.rescanFace(nextFace)
                            }
                        },
                        onNextFace: {
                            viewModel.moveToNextFace()
                        },
                        onFinish: {
                            if let cubeState = viewModel.completedCubeState {
                                viewModel.stop()
                                onComplete?(cubeState)
                                dismiss()
                            }
                        },
                        onCancel: {
                            viewModel.stop()
                            dismiss()
                        }
                    )
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: -4)
            }
            
            // Success feedback overlay
            if let result = viewModel.lastScanResult, result.success {
                ScanSuccessFeedback(face: result.face) {
                    viewModel.lastScanResult = nil
                }
            }
            
            // Error overlay
            if let errorType = viewModel.currentError {
                EnhancedErrorFeedback(
                    errorType: errorType,
                    onRetry: {
                        viewModel.currentError = nil
                        viewModel.capturePipeline.currentError = nil
                    },
                    onDismiss: {
                        viewModel.currentError = nil
                        viewModel.capturePipeline.currentError = nil
                    }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Completion overlay
            if viewModel.isComplete, let cubeState = viewModel.completedCubeState {
                CompletionOverlay {
                    viewModel.stop()
                    onComplete?(cubeState)
                    dismiss()
                }
            }
        }
        .navigationTitle("Scan Cube")
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

#Preview {
    NavigationStack {
        EnhancedCubeCamView()
    }
}

#endif
