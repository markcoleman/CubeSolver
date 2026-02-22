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
    let sourceImageSize: CGSize
    var showsPreciseBounds: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            let guideRect = framingRect(in: geometry.size)
            let detectionRect = convertNormalizedRect(detection.boundingBox, in: geometry.size)
            let overlap = overlapRatio(between: guideRect, and: detectionRect)
            let isAligned = overlap >= 0.45 && stability >= 0.7

            ZStack {
                // Primary user-facing guide. This remains stable and avoids the "jumping box" UX.
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        isAligned ? Color.green : Color.white.opacity(0.75),
                        style: StrokeStyle(lineWidth: 3, dash: [10, 6])
                    )
                    .frame(width: guideRect.width, height: guideRect.height)
                    .position(x: guideRect.midX, y: guideRect.midY)

                Circle()
                    .fill(isAligned ? Color.green.opacity(0.35) : Color.white.opacity(0.2))
                    .frame(width: 16, height: 16)
                    .position(x: guideRect.midX, y: guideRect.midY)

                // Optional precise bounds for debug sessions.
                if showsPreciseBounds {
                    Rectangle()
                        .stroke(
                            isAligned ? Color.green : Color.yellow,
                            lineWidth: 2
                        )
                        .frame(width: detectionRect.width, height: detectionRect.height)
                        .position(x: detectionRect.midX, y: detectionRect.midY)

                    ForEach(Array(detection.corners.enumerated()), id: \.offset) { _, corner in
                        let point = convertNormalizedPoint(corner, in: geometry.size)

                        Circle()
                            .fill(isAligned ? Color.green : Color.yellow)
                            .frame(width: 10, height: 10)
                            .position(point)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    private func convertNormalizedRect(_ rect: CGRect, in size: CGSize) -> CGRect {
        guard sourceImageSize.width > 0, sourceImageSize.height > 0 else {
            return CGRect(
                x: rect.minX * size.width,
                y: (1 - rect.maxY) * size.height,
                width: rect.width * size.width,
                height: rect.height * size.height
            )
        }

        // Vision uses a bottom-left origin; UI uses top-left.
        let normalizedRect = CGRect(
            x: rect.minX,
            y: 1 - rect.maxY,
            width: rect.width,
            height: rect.height
        )

        let source = normalizedSourceSize(for: size)
        let scale = max(size.width / source.width, size.height / source.height)
        let scaledWidth = source.width * scale
        let scaledHeight = source.height * scale
        let xInset = (scaledWidth - size.width) / 2
        let yInset = (scaledHeight - size.height) / 2

        return CGRect(
            x: (normalizedRect.minX * scaledWidth) - xInset,
            y: (normalizedRect.minY * scaledHeight) - yInset,
            width: normalizedRect.width * scaledWidth,
            height: normalizedRect.height * scaledHeight
        )
    }
    
    private func convertNormalizedPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        guard sourceImageSize.width > 0, sourceImageSize.height > 0 else {
            return CGPoint(
                x: point.x * size.width,
                y: (1 - point.y) * size.height
            )
        }

        let source = normalizedSourceSize(for: size)
        let scale = max(size.width / source.width, size.height / source.height)
        let scaledWidth = source.width * scale
        let scaledHeight = source.height * scale
        let xInset = (scaledWidth - size.width) / 2
        let yInset = (scaledHeight - size.height) / 2

        return CGPoint(
            x: (point.x * scaledWidth) - xInset,
            y: ((1 - point.y) * scaledHeight) - yInset
        )
    }

    private func framingRect(in size: CGSize) -> CGRect {
        let side = min(size.width, size.height) * 0.62
        return CGRect(
            x: (size.width - side) / 2,
            y: (size.height - side) / 2,
            width: side,
            height: side
        )
    }

    private func overlapRatio(between lhs: CGRect, and rhs: CGRect) -> CGFloat {
        guard !lhs.isEmpty, !rhs.isEmpty else {
            return 0
        }

        let intersection = lhs.intersection(rhs)
        guard !intersection.isNull else {
            return 0
        }

        let lhsArea = lhs.width * lhs.height
        guard lhsArea > 0 else {
            return 0
        }

        return (intersection.width * intersection.height) / lhsArea
    }

    private func normalizedSourceSize(for viewSize: CGSize) -> CGSize {
        // If frame orientation disagrees with the view orientation, swap dimensions.
        let sourceIsPortrait = sourceImageSize.height >= sourceImageSize.width
        let viewIsPortrait = viewSize.height >= viewSize.width

        if sourceIsPortrait == viewIsPortrait {
            return sourceImageSize
        }

        return CGSize(width: sourceImageSize.height, height: sourceImageSize.width)
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
