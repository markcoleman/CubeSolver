//
//  CubeCamSharedComponents.swift
//  CubeSolver - Shared Components for CubeCam Views
//
//  Created by GitHub Copilot
//

#if os(iOS)

import SwiftUI
import AVFoundation
import CubeCore
import CubeScanner

// MARK: - Camera Preview

// We use two separate structs to avoid the ambiguity issue while maintaining type safety
// Each view file will use the appropriate one for its ViewModel type

struct CubeCamCameraPreviewView: UIViewRepresentable {
    let viewModel: CubeCamViewModel
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        return CameraPreviewUIView()
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.previewLayer = viewModel.getPreviewLayer()
    }
}

struct EnhancedCubeCamCameraPreviewView: UIViewRepresentable {
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
            
            ProgressView(value: stability, total: 1.0)
                .progressViewStyle(.linear)
                .tint(stability > 0.7 ? .green : .yellow)
                .frame(width: 100)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(.horizontal)
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
                        .frame(width: 120, height: 120)
                        .scaleEffect(circleScale)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(checkmarkScale)
                        .rotationEffect(.degrees(checkmarkRotation))
                }
                
                Text("Scan Complete!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("All faces captured successfully")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Button(action: onDone) {
                    Text("Continue")
                        .font(.headline)
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
                }
                .padding(.horizontal, 40)
            }
        }
        .onAppear {
            // Trigger spring animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0)) {
                checkmarkScale = 1.0
                checkmarkRotation = 0
            }
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
                circleScale = 1.0
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

#endif
