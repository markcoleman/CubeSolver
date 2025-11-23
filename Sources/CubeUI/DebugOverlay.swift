//
//  DebugOverlay.swift
//  CubeSolver - PROMPT 10: Debug Hooks and Developer Mode
//
//  Created by GitHub Copilot
//

#if os(iOS)

import SwiftUI
import CubeCore
import CubeScanner

/// PROMPT 10: Debug overlay showing internal scanning metrics
struct DebugOverlay: View {
    let stability: Float
    let consecutiveStableFrames: Int
    let requiredStableFrames: Int
    let detectedFace: Face?
    let detectedCenterColor: CubeColor?
    let brightness: Float
    let capturedFaces: [Face]
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Toggle button
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: "ladybug.fill")
                        .foregroundColor(.green)
                    
                    Text("Debug Mode")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.2))
                .background(.ultraThinMaterial)
            }
            
            // Debug info (expanded)
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .background(Color.white.opacity(0.3))
                    
                    DebugRow(label: "Stability", value: String(format: "%.2f", stability))
                    DebugRow(
                        label: "Stable Frames",
                        value: "\(consecutiveStableFrames)/\(requiredStableFrames)"
                    )
                    DebugRow(
                        label: "Brightness",
                        value: String(format: "%.2f", brightness),
                        color: brightnessColor
                    )
                    
                    if let face = detectedFace {
                        DebugRow(label: "Detected Face", value: faceDisplayName(face))
                    }
                    
                    if let color = detectedCenterColor {
                        DebugRow(label: "Center Color", value: color.rawValue)
                    }
                    
                    DebugRow(
                        label: "Captured",
                        value: "\(capturedFaces.count)/6",
                        color: capturedFaces.count == 6 ? .green : .white
                    )
                    
                    if !capturedFaces.isEmpty {
                        HStack(spacing: 4) {
                            Text("Faces:")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            
                            ForEach(capturedFaces, id: \.self) { face in
                                Text(face.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 4)
                    }
                }
                .padding(.bottom, 8)
                .transition(.opacity)
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Debug overlay")
        .accessibilityHint("Shows internal scanning metrics")
    }
    
    private var brightnessColor: Color {
        if brightness < 0.3 {
            return .red
        } else if brightness > 0.8 {
            return .orange
        } else {
            return .white
        }
    }
    
    private func faceDisplayName(_ face: Face) -> String {
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

/// Debug row showing label and value
struct DebugRow: View {
    let label: String
    let value: String
    var color: Color = .white
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
    }
}

/// PROMPT 10: Debug export functionality
struct DebugExportButton: View {
    let capturedFaces: [Face: [CubeColor]]
    
    var body: some View {
        Button(action: exportDebugData) {
            HStack(spacing: 6) {
                Image(systemName: "square.and.arrow.up")
                    .font(.caption)
                
                Text("Export Debug Data")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.green.opacity(0.3))
            .background(.ultraThinMaterial)
            .cornerRadius(8)
        }
        .accessibilityLabel("Export debug data")
        .accessibilityHint("Exports scanning data as JSON")
    }
    
    private func exportDebugData() {
        // Convert to debug JSON
        var debugData: [String: Any] = [:]
        
        for (face, colors) in capturedFaces {
            debugData[face.rawValue] = colors.map { $0.rawValue }
        }
        
        if let jsonData = try? JSONSerialization.data(
            withJSONObject: debugData,
            options: .prettyPrinted
        ) {
            // In a real app, would share via UIActivityViewController
            // For now, just print to console
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Debug Data Export:")
                print(jsonString)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        
        VStack(spacing: 20) {
            DebugOverlay(
                stability: 0.85,
                consecutiveStableFrames: 6,
                requiredStableFrames: 8,
                detectedFace: .front,
                detectedCenterColor: .red,
                brightness: 0.65,
                capturedFaces: [.front, .right, .up]
            )
            .padding()
            
            DebugExportButton(capturedFaces: [
                .front: [.red, .red, .white, .red, .red, .red, .white, .red, .red],
                .right: [.blue, .blue, .blue, .blue, .blue, .blue, .blue, .blue, .blue]
            ])
        }
    }
}

#endif
