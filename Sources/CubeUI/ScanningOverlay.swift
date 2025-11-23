//
//  ScanningOverlay.swift
//  CubeSolver - PROMPT 1: Scanning Stability Overlay
//
//  Created by GitHub Copilot
//

#if os(iOS)

import SwiftUI

/// PROMPT 1: Scanning overlay that shows stability detection progress
struct ScanningOverlay: View {
    let stability: Float
    let requiredFrames: Int
    let currentFrames: Int
    let isScanning: Bool
    
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
                        .trim(from: 0, to: CGFloat(currentFrames) / CGFloat(requiredFrames))
                        .stroke(
                            isScanning ? Color.green : Color.yellow,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: currentFrames)
                    
                    if isScanning {
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
                    Text(isScanning ? "Ready to scan" : "Stabilizing...")
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
        .accessibilityValue(isScanning ? "Ready to scan" : "Stabilizing, \(currentFrames) of \(requiredFrames) stable frames")
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 20) {
            ScanningOverlay(stability: 0.3, requiredFrames: 8, currentFrames: 2, isScanning: false)
            ScanningOverlay(stability: 0.7, requiredFrames: 8, currentFrames: 6, isScanning: false)
            ScanningOverlay(stability: 0.95, requiredFrames: 8, currentFrames: 8, isScanning: true)
        }
    }
}

#endif
