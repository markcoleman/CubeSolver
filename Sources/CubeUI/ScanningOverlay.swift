//
//  ScanningOverlay.swift
//  CubeSolver - PROMPT 1: Scanning Stability Overlay
//
//  Created by GitHub Copilot
//

#if os(iOS)

import SwiftUI
import CubeScanner

/// PROMPT 1: Scanning overlay that shows stability detection progress
struct ScanningOverlay: View {
    let captureState: CubeCamCapturePipeline.CaptureState
    let requiredFrames: Int
    let currentFrames: Int
    
    private var isReady: Bool {
        if case .stabilizing(let progress) = captureState {
            return progress >= 1.0
        }
        return false
    }
    
    private var progress: Double {
        switch captureState {
        case .idle, .detecting:
            return 0.0
        case .stabilizing(let p):
            return p
        case .capturing, .captured:
            return 1.0
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Scanning indicator
            HStack(spacing: 12) {
                // Animated scanning icon
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            isReady ? Color.green : Color.yellow,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                    
                    if isReady {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(statusText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("\(currentFrames)/\(requiredFrames) stable frames")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Scanning stability")
        .accessibilityValue("\(statusText), \(currentFrames) of \(requiredFrames) stable frames")
    }
    
    private var statusText: String {
        switch captureState {
        case .idle:
            return "Position cube"
        case .detecting:
            return "Detecting..."
        case .stabilizing(let progress):
            if progress >= 1.0 {
                return "Ready to scan"
            } else {
                return "Stabilizing..."
            }
        case .capturing:
            return "Capturing..."
        case .captured:
            return "Captured!"
        }
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 20) {
            ScanningOverlay(captureState: .detecting, requiredFrames: 8, currentFrames: 2)
            ScanningOverlay(captureState: .stabilizing(progress: 0.75), requiredFrames: 8, currentFrames: 6)
            ScanningOverlay(captureState: .stabilizing(progress: 1.0), requiredFrames: 8, currentFrames: 8)
            ScanningOverlay(captureState: .captured, requiredFrames: 8, currentFrames: 8)
        }
    }
}

#endif
