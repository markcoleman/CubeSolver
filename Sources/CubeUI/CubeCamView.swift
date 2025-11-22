//
//  CubeCamView.swift
//  CubeSolver - Cube Cam Auto-Scan View
//
//  Created by GitHub Copilot
//

#if canImport(SwiftUI) && canImport(AVFoundation)

import SwiftUI
import AVFoundation
import CubeCore

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
            CameraPreviewView(viewModel: viewModel)
                .ignoresSafeArea()
            
            // Detection overlay
            if let detection = viewModel.detectionResult {
                DetectionOverlay(detection: detection, stability: viewModel.stability)
            }
            
            // Face capture flash animation
            if viewModel.faceCaptured {
                FaceCaptureFlash()
                    .transition(.opacity)
            }
            
            // UI Overlay
            VStack {
                // Top instruction text
                VStack(spacing: 12) {
                    Text(viewModel.captureProgressText)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    // Face capture indicators
                    FaceCaptureIndicators(
                        capturedFaces: Array(viewModel.capturedFaces),
                        currentFace: viewModel.currentFace
                    )
                    .padding(.horizontal)
                }
                .padding(.top, 60)
                
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
                        
                        // Manual capture button (shown when stable)
                        if viewModel.stability > 0.7 && viewModel.capturedFaceCount < 6 {
                            Button {
                                Task {
                                    await viewModel.manualCapture()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "camera.fill")
                                    Text("Capture")
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
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: -4)
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

// MARK: - Camera Preview

struct CameraPreviewView: UIViewRepresentable {
    let viewModel: CubeCamViewModel
    
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

// MARK: - Detection Overlay

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
            y: (1 - rect.maxY) * size.height, // Flip Y coordinate
            width: rect.width * size.width,
            height: rect.height * size.height
        )
    }
    
    private func convertNormalizedPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        return CGPoint(
            x: point.x * size.width,
            y: (1 - point.y) * size.height // Flip Y coordinate
        )
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
    }
}

// MARK: - Stability Indicator

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

// MARK: - Completion Overlay

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
                // Animated checkmark with spring animation
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
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0)) {
                        circleScale = 1.0
                    }
                    
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0).delay(0.1)) {
                        checkmarkScale = 1.0
                        checkmarkRotation = 0
                    }
                }
                
                Text("Success!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("All cube faces captured successfully")
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Button(action: onDone) {
                    Text("Done")
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
        CubeCamView()
    }
}

#endif
