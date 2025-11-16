#if canImport(SwiftUI)
//
//  CubeView.swift
//  CubeSolver
//
//  Created by GitHub Copilot
//

import SwiftUI
import CubeCore

public struct CubeView: View {
    let cube: RubiksCube
    
    public var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let cellSize = size / 12
            
            VStack(spacing: cellSize / 4) {
                // Top face
                CubeFaceView(face: cube.top, cellSize: cellSize)
                    .offset(x: cellSize * 3)
                
                // Middle row: Left, Front, Right, Back
                HStack(spacing: cellSize / 4) {
                    CubeFaceView(face: cube.left, cellSize: cellSize)
                    CubeFaceView(face: cube.front, cellSize: cellSize)
                    CubeFaceView(face: cube.right, cellSize: cellSize)
                    CubeFaceView(face: cube.back, cellSize: cellSize)
                }
                
                // Bottom face
                CubeFaceView(face: cube.bottom, cellSize: cellSize)
                    .offset(x: cellSize * 3)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

public struct CubeFaceView: View {
    let face: CubeFace
    let cellSize: CGFloat
    
    public var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<3) { row in
                HStack(spacing: 2) {
                    ForEach(0..<3) { col in
                        Rectangle()
                            .fill(colorForFaceColor(face.colors[row][col]))
                            .frame(width: cellSize, height: cellSize)
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.black.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.2))
        )
    }
    
    private func colorForFaceColor(_ faceColor: FaceColor) -> Color {
        switch faceColor {
        case .white:
            return Color.white
        case .yellow:
            return Color.yellow
        case .red:
            return Color.red
        case .orange:
            return Color.orange
        case .blue:
            return Color.blue
        case .green:
            return Color.green
        }
    }
}

#Preview {
    CubeView(cube: RubiksCube())
        .frame(width: 400, height: 400)
        .padding()
        .background(Color.gray)
}
#endif
