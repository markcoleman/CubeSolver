//
//  AlignmentGuides.swift
//  CubeSolver - PROMPT 9: Alignment Guides and Countdown
//
//  Created by GitHub Copilot
//

#if os(iOS)

import SwiftUI

/// PROMPT 9: Alignment guide showing where to center the cube face
struct AlignmentGuide: View {
    let isAligned: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height) * 0.6
            
            ZStack {
                // Outer square frame
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isAligned ? Color.green : Color.white.opacity(0.6),
                        style: StrokeStyle(lineWidth: 3, dash: [10, 5])
                    )
                    .frame(width: size, height: size)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Corner markers
                ForEach(0..<4, id: \.self) { index in
                    CornerMarker(
                        position: cornerPosition(
                            index: index,
                            size: size,
                            center: CGPoint(
                                x: geometry.size.width / 2,
                                y: geometry.size.height / 2
                            )
                        ),
                        isAligned: isAligned
                    )
                }
                
                // Center crosshair
                CrosshairCenter(isAligned: isAligned)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Alignment guide")
        .accessibilityValue(isAligned ? "Cube is aligned" : "Center the cube in the frame")
    }
    
    private func cornerPosition(index: Int, size: CGFloat, center: CGPoint) -> CGPoint {
        let halfSize = size / 2
        
        switch index {
        case 0: // Top-left
            return CGPoint(x: center.x - halfSize, y: center.y - halfSize)
        case 1: // Top-right
            return CGPoint(x: center.x + halfSize, y: center.y - halfSize)
        case 2: // Bottom-right
            return CGPoint(x: center.x + halfSize, y: center.y + halfSize)
        case 3: // Bottom-left
            return CGPoint(x: center.x - halfSize, y: center.y + halfSize)
        default:
            return center
        }
    }
}

/// Corner marker for alignment guide
struct CornerMarker: View {
    let position: CGPoint
    let isAligned: Bool
    
    var body: some View {
        ZStack {
            // Horizontal line
            Rectangle()
                .fill(isAligned ? Color.green : Color.white.opacity(0.8))
                .frame(width: 20, height: 3)
            
            // Vertical line
            Rectangle()
                .fill(isAligned ? Color.green : Color.white.opacity(0.8))
                .frame(width: 3, height: 20)
        }
        .position(position)
    }
}

/// Crosshair in center
struct CrosshairCenter: View {
    let isAligned: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(isAligned ? Color.green : Color.white.opacity(0.6), lineWidth: 2)
                .frame(width: 30, height: 30)
            
            Circle()
                .fill(isAligned ? Color.green.opacity(0.3) : Color.white.opacity(0.2))
                .frame(width: 8, height: 8)
        }
    }
}

/// PROMPT 9: Countdown overlay for manual capture
struct CaptureCountdown: View {
    let count: Int
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 120, height: 120)
                .scaleEffect(scale)
            
            Text("\(count)")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.white)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.2
                opacity = 1
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                scale = 0.8
                opacity = 0
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Countdown")
        .accessibilityValue("\(count)")
    }
}

/// PROMPT 9: Manual capture button with countdown
struct ManualCaptureButton: View {
    let isEnabled: Bool
    let onCapture: () -> Void
    
    @State private var countdown: Int? = nil
    @State private var isPressed: Bool = false
    @State private var countdownTimer: Timer? = nil
    
    var body: some View {
        ZStack {
            Button(action: startCountdown) {
                HStack(spacing: 12) {
                    Image(systemName: countdown != nil ? "timer" : "camera.fill")
                        .font(.title2)
                    
                    Text(countdown != nil ? "Capturing..." : "Capture Face")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: isEnabled 
                            ? [.blue, .blue.opacity(0.8)]
                            : [.gray, .gray.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: isEnabled ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                .scaleEffect(isPressed ? 0.95 : 1.0)
            }
            .disabled(!isEnabled || countdown != nil)
            .onDisappear {
                // Clean up timer if view disappears
                countdownTimer?.invalidate()
                countdownTimer = nil
            }
            
            // Countdown overlay
            if let count = countdown {
                CaptureCountdown(count: count)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Manual capture button")
        .accessibilityHint(isEnabled ? "Tap to start 3 second countdown and capture" : "Button disabled, align cube first")
    }
    
    private func startCountdown() {
        countdown = 3
        isPressed = true
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak countdownTimer] timer in
            guard let current = countdown else {
                timer.invalidate()
                self.countdownTimer = nil
                return
            }
            
            if current > 1 {
                countdown = current - 1
            } else {
                countdown = nil
                timer.invalidate()
                self.countdownTimer = nil
                
                // Trigger haptic
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                // Perform capture
                onCapture()
                
                // Reset button state
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        
        VStack(spacing: 40) {
            AlignmentGuide(isAligned: false)
                .frame(height: 300)
            
            AlignmentGuide(isAligned: true)
                .frame(height: 300)
            
            ManualCaptureButton(isEnabled: true, onCapture: {
                print("Captured!")
            })
            .padding()
        }
    }
}

#endif
