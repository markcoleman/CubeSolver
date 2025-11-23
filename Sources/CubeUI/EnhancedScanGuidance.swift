//
//  EnhancedScanGuidance.swift
//  CubeSolver - Enhanced Step-by-Step Scan Guidance UI
//
//  Created by GitHub Copilot
//

#if os(iOS)

import SwiftUI
import CubeCore
import CubeScanner

/// Enhanced step-by-step guidance display for cube scanning
public struct EnhancedScanGuidance: View {
    let guidance: ScanStepGuidance
    let scanState: FaceScanState
    
    public init(guidance: ScanStepGuidance, scanState: FaceScanState) {
        self.guidance = guidance
        self.scanState = scanState
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Step indicator with icon
            HStack(spacing: 12) {
                Image(systemName: guidance.iconName)
                    .font(.title2)
                    .foregroundColor(statusColor)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Step \(guidance.stepNumber) of \(guidance.totalSteps)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(guidance.instruction)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Progress indicator for scanning state
            if case .scanning(let progress) = scanState {
                HStack(spacing: 8) {
                    ProgressView(value: Double(progress))
                        .tint(.green)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(2)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 45)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            
            // Hint text
            if let hint = guidance.hint {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(.yellow.opacity(0.8))
                    
                    Text(hint)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .italic()
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(statusColor.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Scan guidance")
        .accessibilityValue("\(guidance.instruction). \(guidance.hint ?? "")")
    }
    
    private var statusColor: Color {
        switch scanState {
        case .notScanned:
            return .blue
        case .scanning:
            return .yellow
        case .captured:
            return .green
        case .error:
            return .red
        }
    }
}

/// Interactive mini 3D cube with tap-to-rescan capability
public struct InteractiveMiniCube: View {
    let faceStates: [Face: FaceScanState]
    let nextFace: Face?
    let onFaceTap: (Face) -> Void
    
    @State private var rotation: Double = 0
    
    public init(
        faceStates: [Face: FaceScanState],
        nextFace: Face?,
        onFaceTap: @escaping (Face) -> Void
    ) {
        self.faceStates = faceStates
        self.nextFace = nextFace
        self.onFaceTap = onFaceTap
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Mini cube visualization
            ZStack {
                GeometryReader { geometry in
                    let size = min(geometry.size.width, geometry.size.height)
                    let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    let faceSize: CGFloat = size * 0.35
                    
                    ZStack {
                        // Top face (Up)
                        TappableIsometricFace(
                            offset: CGPoint(x: center.x, y: center.y - faceSize * 0.6),
                            size: faceSize,
                            face: .up,
                            state: faceStates[.up] ?? .notScanned,
                            isNext: nextFace == .up,
                            onTap: { onFaceTap(.up) }
                        )
                        
                        // Front face
                        TappableIsometricFace(
                            offset: CGPoint(x: center.x, y: center.y + faceSize * 0.2),
                            size: faceSize,
                            face: .front,
                            state: faceStates[.front] ?? .notScanned,
                            isNext: nextFace == .front,
                            onTap: { onFaceTap(.front) }
                        )
                        
                        // Right face
                        TappableIsometricFace(
                            offset: CGPoint(x: center.x + faceSize * 0.7, y: center.y - faceSize * 0.2),
                            size: faceSize,
                            face: .right,
                            state: faceStates[.right] ?? .notScanned,
                            isNext: nextFace == .right,
                            onTap: { onFaceTap(.right) }
                        )
                    }
                }
            }
            .frame(height: 140)
            
            // Instruction label
            if let next = nextFace {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("Tap any face to rescan")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

/// Tappable isometric face with state visualization
struct TappableIsometricFace: View {
    let offset: CGPoint
    let size: CGFloat
    let face: Face
    let state: FaceScanState
    let isNext: Bool
    let onTap: () -> Void
    
    @State private var isPulsing: Bool = false
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback for tap
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            Path { path in
                // Draw parallelogram for isometric view
                let halfSize = size / 2
                
                if face == .up {
                    // Top face (horizontal parallelogram)
                    path.move(to: CGPoint(x: offset.x, y: offset.y - halfSize))
                    path.addLine(to: CGPoint(x: offset.x + halfSize * 0.86, y: offset.y - halfSize * 0.5))
                    path.addLine(to: CGPoint(x: offset.x, y: offset.y))
                    path.addLine(to: CGPoint(x: offset.x - halfSize * 0.86, y: offset.y - halfSize * 0.5))
                    path.closeSubpath()
                } else if face == .right {
                    // Right face (right-slanted parallelogram)
                    path.move(to: CGPoint(x: offset.x, y: offset.y - halfSize))
                    path.addLine(to: CGPoint(x: offset.x + halfSize * 0.86, y: offset.y - halfSize * 0.5))
                    path.addLine(to: CGPoint(x: offset.x + halfSize * 0.86, y: offset.y + halfSize * 0.5))
                    path.addLine(to: CGPoint(x: offset.x, y: offset.y))
                    path.closeSubpath()
                } else {
                    // Front face (square)
                    path.move(to: CGPoint(x: offset.x - halfSize * 0.86, y: offset.y - halfSize * 0.5))
                    path.addLine(to: CGPoint(x: offset.x, y: offset.y - halfSize))
                    path.addLine(to: CGPoint(x: offset.x, y: offset.y))
                    path.addLine(to: CGPoint(x: offset.x - halfSize * 0.86, y: offset.y + halfSize * 0.5))
                    path.closeSubpath()
                }
            }
            .fill(fillColor)
            .overlay(
                Group {
                    // Checkmark for captured state
                    if case .captured = state {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: size * 0.4))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                            .position(offset)
                            .accessibilityLabel("Captured")
                            .accessibilityHidden(true) // Parent button already has accessibility info
                    }
                }
            )
            .overlay(
                Path { path in
                    let halfSize = size / 2
                    
                    if face == .up {
                        path.move(to: CGPoint(x: offset.x, y: offset.y - halfSize))
                        path.addLine(to: CGPoint(x: offset.x + halfSize * 0.86, y: offset.y - halfSize * 0.5))
                        path.addLine(to: CGPoint(x: offset.x, y: offset.y))
                        path.addLine(to: CGPoint(x: offset.x - halfSize * 0.86, y: offset.y - halfSize * 0.5))
                        path.closeSubpath()
                    } else if face == .right {
                        path.move(to: CGPoint(x: offset.x, y: offset.y - halfSize))
                        path.addLine(to: CGPoint(x: offset.x + halfSize * 0.86, y: offset.y - halfSize * 0.5))
                        path.addLine(to: CGPoint(x: offset.x + halfSize * 0.86, y: offset.y + halfSize * 0.5))
                        path.addLine(to: CGPoint(x: offset.x, y: offset.y))
                        path.closeSubpath()
                    } else {
                        path.move(to: CGPoint(x: offset.x - halfSize * 0.86, y: offset.y - halfSize * 0.5))
                        path.addLine(to: CGPoint(x: offset.x, y: offset.y - halfSize))
                        path.addLine(to: CGPoint(x: offset.x, y: offset.y))
                        path.addLine(to: CGPoint(x: offset.x - halfSize * 0.86, y: offset.y + halfSize * 0.5))
                        path.closeSubpath()
                    }
                }
                .stroke(strokeColor, lineWidth: isNext ? 2.5 : 1.5)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : (isNext && isPulsing ? 1.05 : 1.0))
        .shadow(color: shadowColor, radius: isNext ? 8 : 4, x: 0, y: 2)
        .onAppear {
            if isNext {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
        .onChange(of: isNext) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            } else {
                isPulsing = false
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(faceDisplayName) face")
        .accessibilityValue(stateDescription)
        .accessibilityHint("Tap to rescan this face")
    }
    
    private var fillColor: Color {
        switch state {
        case .captured:
            return Color.green.opacity(0.7)
        case .scanning:
            return Color.yellow.opacity(0.5)
        case .notScanned:
            if isNext {
                return Color.blue.opacity(0.4)
            } else {
                return Color.gray.opacity(0.2)
            }
        case .error:
            return Color.red.opacity(0.4)
        }
    }
    
    private var strokeColor: Color {
        switch state {
        case .captured:
            return Color.green
        case .scanning:
            return Color.yellow
        case .notScanned:
            return isNext ? Color.blue : Color.white.opacity(0.3)
        case .error:
            return Color.red
        }
    }
    
    private var shadowColor: Color {
        if isNext {
            return Color.blue.opacity(0.5)
        } else if case .captured = state {
            return Color.green.opacity(0.3)
        } else {
            return Color.clear
        }
    }
    
    private var faceDisplayName: String {
        switch face {
        case .up: return "Top"
        case .down: return "Bottom"
        case .left: return "Left"
        case .right: return "Right"
        case .front: return "Front"
        case .back: return "Back"
        }
    }
    
    private var stateDescription: String {
        switch state {
        case .captured:
            return "Captured"
        case .scanning(let progress):
            return "Scanning, \(Int(progress * 100))% complete"
        case .notScanned:
            return isNext ? "Next to scan" : "Not scanned"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}

/// Success feedback overlay with animation
public struct ScanSuccessFeedback: View {
    let face: Face
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var checkmarkRotation: Double = -90
    @State private var opacity: Double = 0
    
    public init(face: Face, onDismiss: @escaping () -> Void) {
        self.face = face
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack {
            // Semi-transparent background
            Color.green.opacity(0.3)
                .ignoresSafeArea()
                .opacity(opacity)
            
            VStack(spacing: 16) {
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
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(checkmarkRotation))
                }
                .scaleEffect(scale)
                
                Text("\(faceDisplayName) face captured!")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(opacity)
            }
            .padding(30)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(color: .green.opacity(0.3), radius: 20)
        }
        .onAppear {
            // Trigger haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Animate appearance
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
                checkmarkRotation = 0
            }
            
            // Auto-dismiss after 1.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                    scale = 0.8
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss()
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Success")
        .accessibilityValue("\(faceDisplayName) face captured successfully")
    }
    
    private var faceDisplayName: String {
        switch face {
        case .up: return "Top"
        case .down: return "Bottom"
        case .left: return "Left"
        case .right: return "Right"
        case .front: return "Front"
        case .back: return "Back"
        }
    }
}

#Preview {
    ZStack {
        Color.black
        
        VStack(spacing: 20) {
            EnhancedScanGuidance(
                guidance: ScanStepGuidance.guidance(for: .up, stepNumber: 1),
                scanState: .scanning(progress: 0.65)
            )
            .padding()
            
            InteractiveMiniCube(
                faceStates: [
                    .front: .captured,
                    .right: .captured,
                    .up: .scanning(progress: 0.5),
                    .left: .notScanned,
                    .back: .notScanned,
                    .down: .notScanned
                ],
                nextFace: .up,
                onFaceTap: { face in
                    print("Tapped \(face)")
                }
            )
            .padding()
        }
    }
}

#endif
