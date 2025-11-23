//
//  EnhancedCubeCamExample.swift
//  CubeSolver - Example Usage of Enhanced CubeCam
//
//  Created by GitHub Copilot
//

#if os(iOS)

import SwiftUI
import CubeCore
import CubeUI

/// Example view demonstrating how to use EnhancedCubeCamView
struct EnhancedCubeCamExample: View {
    @State private var showScanner = false
    @State private var scannedCube: CubeState?
    @State private var showingSolution = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "cube.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Enhanced CubeCam")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Improved scanning experience with step-by-step guidance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Status
                if let cube = scannedCube {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        Text("Cube Scanned Successfully!")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        // Show cube state summary
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach([Face.up, .down, .left, .right, .front, .back], id: \.self) { face in
                                if let colors = cube.faces[face] {
                                    HStack {
                                        Text("\(faceDisplayName(face)):")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .frame(width: 60, alignment: .leading)
                                        
                                        Text("\(colors.count) stickers")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        
                        Button(action: {
                            showingSolution = true
                        }) {
                            Text("Solve Cube")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(16)
                        }
                        
                        Button(action: {
                            scannedCube = nil
                        }) {
                            Text("Scan Again")
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No cube scanned yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Tap 'Start Scanning' to begin")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Features list
                VStack(alignment: .leading, spacing: 12) {
                    Text("Features:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    FeatureRow(icon: "1.circle.fill", text: "Step-by-step guidance (1 of 6, 2 of 6, etc.)")
                    FeatureRow(icon: "cube.fill", text: "Interactive mini 3D cube")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Strong success feedback with haptics")
                    FeatureRow(icon: "hand.tap.fill", text: "Tap any face to rescan it")
                    FeatureRow(icon: "exclamationmark.circle.fill", text: "Helpful error states with recovery tips")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Scan button
                Button(action: {
                    showScanner = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Start Scanning")
                            .fontWeight(.bold)
                    }
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
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            .padding()
            .navigationTitle("Enhanced CubeCam Demo")
            .sheet(isPresented: $showScanner) {
                NavigationStack {
                    EnhancedCubeCamView { cubeState in
                        scannedCube = cubeState
                        showScanner = false
                    }
                }
            }
            .alert("Solve Cube", isPresented: $showingSolution) {
                Button("OK") { showingSolution = false }
            } message: {
                Text("Solution feature would be implemented here using EnhancedCubeSolver")
            }
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

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    EnhancedCubeCamExample()
}

#endif
