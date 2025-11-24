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
        .accessibilityElement()
        .accessibilityLabel("Stability indicator")
        .accessibilityValue(
            stability > 0.7
                ? "Hold steady. Stability is \(Int(stability * 100)) percent."
                : "Move slowly. Stability is \(Int(stability * 100)) percent."
        )
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
