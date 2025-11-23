//
//  EnhancedErrorFeedback.swift
//  CubeSolver - Enhanced Error State UI with Recovery Guidance
//
//  Created by GitHub Copilot
//

#if os(iOS)

import SwiftUI
import CubeScanner

/// Enhanced error feedback with specific recovery suggestions
public struct EnhancedErrorFeedback: View {
    let errorType: ScanErrorType
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    @State private var isVisible: Bool = false
    
    public init(
        errorType: ScanErrorType,
        onRetry: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.errorType = errorType
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Error header with icon
            HStack(spacing: 12) {
                Image(systemName: errorType.iconName)
                    .font(.title)
                    .foregroundColor(errorType.accentColor)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(errorType.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(errorType.message)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(16)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Recovery suggestions
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Text("How to fix:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                ForEach(errorType.suggestions, id: \.self) { suggestion in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.caption)
                            .foregroundColor(.green.opacity(0.8))
                        
                        Text(suggestion)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(16)
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onDismiss) {
                    Text("Dismiss")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                }
                
                Button(action: {
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onRetry()
                }) {
                    Text("Try Again")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(errorType.accentColor)
                        .cornerRadius(10)
                }
            }
            .padding([.horizontal, .bottom], 16)
        }
        .background(errorType.accentColor.opacity(0.15))
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(errorType.accentColor.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: errorType.accentColor.opacity(0.3), radius: 12, x: 0, y: 4)
        .padding(.horizontal)
        .offset(y: isVisible ? 0 : -300)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            // Trigger error haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(errorType.title)")
        .accessibilityValue(errorType.message)
    }
}

/// Types of scan errors with specific recovery guidance
public enum ScanErrorType {
    case cubeNotDetected
    case poorLighting
    case tooMuchMotion
    case duplicateFace
    case invalidColors
    case backgroundClutter
    
    var title: String {
        switch self {
        case .cubeNotDetected:
            return "Couldn't Lock on to Cube"
        case .poorLighting:
            return "Lighting Issue"
        case .tooMuchMotion:
            return "Too Much Movement"
        case .duplicateFace:
            return "Face Already Scanned"
        case .invalidColors:
            return "Colors Unclear"
        case .backgroundClutter:
            return "Busy Background"
        }
    }
    
    var message: String {
        switch self {
        case .cubeNotDetected:
            return "The camera can't detect your cube clearly."
        case .poorLighting:
            return "The lighting is too dark or too bright."
        case .tooMuchMotion:
            return "The cube is moving too much to get a clear scan."
        case .duplicateFace:
            return "This face has already been captured."
        case .invalidColors:
            return "The cube colors are too similar or unclear."
        case .backgroundClutter:
            return "The background is making it hard to see the cube."
        }
    }
    
    var suggestions: [String] {
        switch self {
        case .cubeNotDetected:
            return [
                "Make sure the cube fills most of the frame",
                "Hold the cube steady with one face visible",
                "Try moving to a well-lit area"
            ]
        case .poorLighting:
            return [
                "Move to a brighter area or add more light",
                "Avoid direct sunlight or harsh shadows",
                "Try indoor lighting for best results"
            ]
        case .tooMuchMotion:
            return [
                "Hold the cube as steady as possible",
                "Rest your hands on a stable surface",
                "Wait for the green outline before moving"
            ]
        case .duplicateFace:
            return [
                "Rotate the cube to show a different face",
                "Check the mini cube to see which faces are captured",
                "Tap a face on the mini cube to rescan it"
            ]
        case .invalidColors:
            return [
                "Clean the cube if stickers are dirty",
                "Move to better lighting",
                "Ensure stickers are not faded or peeling"
            ]
        case .backgroundClutter:
            return [
                "Use a plain, solid-colored background",
                "Move away from patterned surfaces",
                "Try a white or black background for best results"
            ]
        }
    }
    
    var iconName: String {
        switch self {
        case .cubeNotDetected:
            return "viewfinder.circle"
        case .poorLighting:
            return "lightbulb.slash"
        case .tooMuchMotion:
            return "hand.raised.slash"
        case .duplicateFace:
            return "arrow.triangle.2.circlepath"
        case .invalidColors:
            return "paintpalette"
        case .backgroundClutter:
            return "rectangle.stack.badge.minus"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .cubeNotDetected, .poorLighting, .tooMuchMotion:
            return .orange
        case .duplicateFace:
            return .blue
        case .invalidColors, .backgroundClutter:
            return .red
        }
    }
}

/// Action buttons for scan control
public struct ScanActionButtons: View {
    let canCaptureNext: Bool
    let canFinish: Bool
    let onScanAgain: () -> Void
    let onNextFace: () -> Void
    let onFinish: () -> Void
    let onCancel: () -> Void
    
    public init(
        canCaptureNext: Bool,
        canFinish: Bool,
        onScanAgain: @escaping () -> Void,
        onNextFace: @escaping () -> Void,
        onFinish: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.canCaptureNext = canCaptureNext
        self.canFinish = canFinish
        self.onScanAgain = onScanAgain
        self.onNextFace = onNextFace
        self.onFinish = onFinish
        self.onCancel = onCancel
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            if canFinish {
                // Finish button (all faces captured)
                Button(action: onFinish) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        
                        Text("Finish Scanning")
                            .fontWeight(.bold)
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
                    .shadow(color: .green.opacity(0.4), radius: 8, x: 0, y: 4)
                }
            } else {
                HStack(spacing: 12) {
                    // Scan again button
                    Button(action: onScanAgain) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.subheadline)
                            
                            Text("Scan Again")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                    
                    // Next face button
                    Button(action: onNextFace) {
                        HStack(spacing: 8) {
                            Text("Next Face")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            
                            Image(systemName: "arrow.right")
                                .font(.subheadline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: canCaptureNext 
                                    ? [.blue, .blue.opacity(0.8)]
                                    : [.gray, .gray.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(
                            color: canCaptureNext ? .blue.opacity(0.3) : .clear,
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    }
                    .disabled(!canCaptureNext)
                }
            }
            
            // Cancel button
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    ZStack {
        Color.black
        
        VStack(spacing: 30) {
            EnhancedErrorFeedback(
                errorType: .cubeNotDetected,
                onRetry: {},
                onDismiss: {}
            )
            
            EnhancedErrorFeedback(
                errorType: .poorLighting,
                onRetry: {},
                onDismiss: {}
            )
            
            Spacer()
            
            ScanActionButtons(
                canCaptureNext: true,
                canFinish: false,
                onScanAgain: {},
                onNextFace: {},
                onFinish: {},
                onCancel: {}
            )
            .padding()
        }
    }
}

#endif
