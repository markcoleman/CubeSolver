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
            CameraPreviewView(viewModel: viewModel)
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

// MARK: - Camera Preview (Reused)

struct CameraPreviewView: UIViewRepresentable {
    let viewModel: EnhancedCubeCamViewModel
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        return CameraPreviewUIView()
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.previewLayer = viewModel.getPreviewLayer()
    }
}

class CameraPreviewUIView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer? {
        didSet {
            if let old = oldValue {
                old.removeFromSuperlayer()
            }
            
            if let layer = previewLayer {
                layer.frame = bounds
                self.layer.addSublayer(layer)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}

// MARK: - Detection Overlay (Reused)

struct DetectionOverlay: View {
    let detection: CubeFaceDetectionResult
    let stability: Float
    
    var body: some View {
        GeometryReader { geometry in
            let rect = convertNormalizedRect(detection.boundingBox, in: geometry.size)
            
            Rectangle()
                .stroke(
                    stability > 0.7 ? Color.green : Color.yellow,
                    lineWidth: 3
                )
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
            
            // Corner markers
            ForEach(0..<4, id: \.self) { index in
                let corner = detection.corners[index]
                let point = convertNormalizedPoint(corner, in: geometry.size)
                
                Circle()
                    .fill(stability > 0.7 ? Color.green : Color.yellow)
                    .frame(width: 12, height: 12)
                    .position(point)
            }
        }
    }
    
    private func convertNormalizedRect(_ rect: CGRect, in size: CGSize) -> CGRect {
        return CGRect(
            x: rect.minX * size.width,
            y: (1 - rect.maxY) * size.height,
            width: rect.width * size.width,
            height: rect.height * size.height
        )
    }
    
    private func convertNormalizedPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        return CGPoint(
            x: point.x * size.width,
            y: (1 - point.y) * size.height
        )
    }
}

// MARK: - Stability Indicator (Reused)

struct StabilityIndicator: View {
    let stability: Float
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: stability > 0.7 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(stability > 0.7 ? .green : .yellow)
            
            Text(stability > 0.7 ? "Hold steady..." : "Move slowly")
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            // Stability bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.3))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.red, .yellow, .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(stability))
                }
            }
            .frame(width: 100, height: 8)
        }
    }
}

// MARK: - Completion Overlay (Reused)

struct CompletionOverlay: View {
    let onDone: () -> Void
    
    @State private var checkmarkScale: CGFloat = 0.5
    @State private var checkmarkRotation: Double = -90
    @State private var circleScale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Animated checkmark
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(circleScale)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(checkmarkScale)
                        .rotationEffect(.degrees(checkmarkRotation))
                }
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                        circleScale = 1.0
                    }
                    
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.1)) {
                        checkmarkScale = 1.0
                        checkmarkRotation = 0
                    }
                }
                
                Text("All Faces Captured!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Your cube is ready to solve")
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Button(action: onDone) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: 200)
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
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.5), radius: 20)
        }
    }
}

// MARK: - Helper Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    NavigationStack {
        EnhancedCubeCamView()
    }
}

#endif
