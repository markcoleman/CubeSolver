//
//  Improved3DFaceIndicator.swift
//  CubeSolver - PROMPT 4: 3D Cube Mini-Diagram Face Indicators
//
//  Created by GitHub Copilot
//

#if os(iOS)

import SwiftUI
import CubeCore

/// PROMPT 4: Improved face indicators with 3D cube mini-diagram
struct Improved3DFaceIndicator: View {
    let capturedFaces: [Face]
    let currentFace: Face?
    let nextFace: Face?
    
    var body: some View {
        VStack(spacing: 12) {
            // Mini 3D cube visualization
            MiniCubeVisualization(
                capturedFaces: capturedFaces,
                currentFace: currentFace,
                nextFace: nextFace
            )
            .frame(width: 120, height: 120)
            
            // Text label showing what to scan next
            if let next = nextFace {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .opacity(0.8)
                    
                    Text("Scan \(faceDisplayName(next)) Side")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.3))
                .background(.ultraThinMaterial)
                .cornerRadius(8)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
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

/// PROMPT 4: Mini cube visualization showing scan progress
struct MiniCubeVisualization: View {
    let capturedFaces: [Face]
    let currentFace: Face?
    let nextFace: Face?
    
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Simple isometric cube representation
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let faceSize: CGFloat = size * 0.35
                
                ZStack {
                    // Top face (Up)
                    IsometricFace(
                        offset: CGPoint(x: center.x, y: center.y - faceSize * 0.6),
                        size: faceSize,
                        face: .up,
                        isCaptured: capturedFaces.contains(.up),
                        isCurrent: currentFace == .up,
                        isNext: nextFace == .up,
                        angle: 0
                    )
                    
                    // Front face
                    IsometricFace(
                        offset: CGPoint(x: center.x, y: center.y + faceSize * 0.2),
                        size: faceSize,
                        face: .front,
                        isCaptured: capturedFaces.contains(.front),
                        isCurrent: currentFace == .front,
                        isNext: nextFace == .front,
                        angle: 0
                    )
                    
                    // Right face
                    IsometricFace(
                        offset: CGPoint(x: center.x + faceSize * 0.7, y: center.y - faceSize * 0.2),
                        size: faceSize,
                        face: .right,
                        isCaptured: capturedFaces.contains(.right),
                        isCurrent: currentFace == .right,
                        isNext: nextFace == .right,
                        angle: 30
                    )
                }
            }
        }
    }
}

/// Individual face in the isometric cube
struct IsometricFace: View {
    let offset: CGPoint
    let size: CGFloat
    let face: Face
    let isCaptured: Bool
    let isCurrent: Bool
    let isNext: Bool
    let angle: Double
    
    @State private var isPulsing: Bool = false
    
    var body: some View {
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
            .stroke(strokeColor, lineWidth: isCurrent || isNext ? 2.5 : 1.5)
        )
        .scaleEffect(isNext && isPulsing ? 1.05 : 1.0)
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
    }
    
    private var fillColor: Color {
        if isCaptured {
            return Color.green.opacity(0.6)
        } else if isNext {
            return Color.blue.opacity(0.4)
        } else if isCurrent {
            return Color.yellow.opacity(0.3)
        } else {
            return Color.gray.opacity(0.2)
        }
    }
    
    private var strokeColor: Color {
        if isCaptured {
            return Color.green
        } else if isNext {
            return Color.blue
        } else if isCurrent {
            return Color.yellow
        } else {
            return Color.white.opacity(0.3)
        }
    }
    
    private var shadowColor: Color {
        if isNext {
            return Color.blue.opacity(0.5)
        } else if isCaptured {
            return Color.green.opacity(0.3)
        } else {
            return Color.clear
        }
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 30) {
            Improved3DFaceIndicator(
                capturedFaces: [.front, .right],
                currentFace: .up,
                nextFace: .up
            )
            
            Improved3DFaceIndicator(
                capturedFaces: [.front, .right, .up, .left],
                currentFace: .down,
                nextFace: .down
            )
        }
    }
}

#endif
