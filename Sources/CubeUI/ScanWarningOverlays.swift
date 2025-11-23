//
//  ScanWarningOverlays.swift
//  CubeSolver - PROMPT 2 & 3: Warning Overlays
//
//  Created by GitHub Copilot
//

#if os(iOS)

import SwiftUI

/// PROMPT 2: Duplicate face warning overlay
struct DuplicateFaceWarning: View {
    let message: String
    let onDismiss: () -> Void
    
    @State private var isVisible: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duplicate Face Detected")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(16)
            .background(Color.orange.opacity(0.2))
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal)
        .offset(y: isVisible ? 0 : -100)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }
            
            // Auto-dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation {
                    isVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss()
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Duplicate face warning")
        .accessibilityValue(message)
    }
}

/// PROMPT 3: Wrong face warning overlay
struct WrongFaceWarning: View {
    let message: String
    let onDismiss: () -> Void
    
    @State private var isVisible: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wrong Face")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(16)
            .background(Color.blue.opacity(0.2))
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal)
        .offset(y: isVisible ? 0 : -100)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Wrong face warning")
        .accessibilityValue(message)
    }
}

/// PROMPT 9: Manual capture mode indicator
struct CaptureModeBadge: View {
    let isAutoMode: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isAutoMode ? "wand.and.stars" : "hand.tap")
                .font(.caption)
                .foregroundColor(.white)
            
            Text(isAutoMode ? "Auto Scan" : "Manual")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isAutoMode ? Color.purple.opacity(0.3) : Color.blue.opacity(0.3))
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        .onTapGesture(perform: onToggle)
        .accessibilityElement()
        .accessibilityLabel("Capture mode")
        .accessibilityValue(isAutoMode ? "Auto scan enabled" : "Manual capture mode")
        .accessibilityHint("Tap to toggle between auto and manual capture")
    }
}

#Preview {
    ZStack {
        Color.black
        
        VStack(spacing: 20) {
            DuplicateFaceWarning(
                message: "This side was already scanned. Please rotate to a different face.",
                onDismiss: {}
            )
            
            WrongFaceWarning(
                message: "This is the Top face (already scanned). Please scan the Bottom face next.",
                onDismiss: {}
            )
            
            Spacer()
            
            HStack {
                CaptureModeBadge(isAutoMode: true, onToggle: {})
                CaptureModeBadge(isAutoMode: false, onToggle: {})
            }
        }
        .padding()
    }
}

#endif
