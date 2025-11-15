//
//  RubiksCube.swift
//  CubeSolver
//
//  Created by GitHub Copilot
//

import Foundation

/// Represents a face color on the Rubik's Cube
enum FaceColor: String, CaseIterable {
    case white = "W"
    case yellow = "Y"
    case red = "R"
    case orange = "O"
    case blue = "B"
    case green = "G"
}

/// Represents a face of the Rubik's Cube (3x3 grid)
struct CubeFace {
    var colors: [[FaceColor]]
    
    init(color: FaceColor) {
        self.colors = Array(repeating: Array(repeating: color, count: 3), count: 3)
    }
    
    mutating func rotateClockwise() {
        let n = 3
        var rotated = colors
        for i in 0..<n {
            for j in 0..<n {
                rotated[j][n - 1 - i] = colors[i][j]
            }
        }
        colors = rotated
    }
    
    mutating func rotateCounterClockwise() {
        rotateClockwise()
        rotateClockwise()
        rotateClockwise()
    }
}

/// Represents a complete Rubik's Cube
struct RubiksCube {
    var front: CubeFace
    var back: CubeFace
    var left: CubeFace
    var right: CubeFace
    var top: CubeFace
    var bottom: CubeFace
    
    init() {
        front = CubeFace(color: .red)
        back = CubeFace(color: .orange)
        left = CubeFace(color: .green)
        right = CubeFace(color: .blue)
        top = CubeFace(color: .white)
        bottom = CubeFace(color: .yellow)
    }
    
    /// Check if the cube is solved
    var isSolved: Bool {
        return isFaceSolved(front) && isFaceSolved(back) &&
               isFaceSolved(left) && isFaceSolved(right) &&
               isFaceSolved(top) && isFaceSolved(bottom)
    }
    
    private func isFaceSolved(_ face: CubeFace) -> Bool {
        let firstColor = face.colors[0][0]
        for row in face.colors {
            for color in row {
                if color != firstColor {
                    return false
                }
            }
        }
        return true
    }
    
    // MARK: - Cube Rotations
    
    /// Rotate the front face clockwise
    mutating func rotateFront() {
        front.rotateClockwise()
        
        // Save top bottom row
        let topBottom = top.colors[2]
        
        // Top bottom -> Right left
        for i in 0..<3 {
            top.colors[2][i] = left.colors[2 - i][2]
        }
        
        // Left right -> Bottom bottom
        for i in 0..<3 {
            left.colors[i][2] = bottom.colors[0][i]
        }
        
        // Bottom bottom -> Right left
        for i in 0..<3 {
            bottom.colors[0][i] = right.colors[2 - i][0]
        }
        
        // Saved top -> Right left
        for i in 0..<3 {
            right.colors[i][0] = topBottom[i]
        }
    }
    
    /// Rotate the back face clockwise
    mutating func rotateBack() {
        back.rotateClockwise()
        
        let topTop = top.colors[0]
        
        for i in 0..<3 {
            top.colors[0][i] = right.colors[i][2]
        }
        
        for i in 0..<3 {
            right.colors[i][2] = bottom.colors[2][2 - i]
        }
        
        for i in 0..<3 {
            bottom.colors[2][i] = left.colors[2 - i][0]
        }
        
        for i in 0..<3 {
            left.colors[i][0] = topTop[2 - i]
        }
    }
    
    /// Rotate the left face clockwise
    mutating func rotateLeft() {
        left.rotateClockwise()
        
        let topLeft = [top.colors[0][0], top.colors[1][0], top.colors[2][0]]
        
        for i in 0..<3 {
            top.colors[i][0] = back.colors[2 - i][2]
        }
        
        for i in 0..<3 {
            back.colors[i][2] = bottom.colors[2 - i][0]
        }
        
        for i in 0..<3 {
            bottom.colors[i][0] = front.colors[i][0]
        }
        
        for i in 0..<3 {
            front.colors[i][0] = topLeft[i]
        }
    }
    
    /// Rotate the right face clockwise
    mutating func rotateRight() {
        right.rotateClockwise()
        
        let topRight = [top.colors[0][2], top.colors[1][2], top.colors[2][2]]
        
        for i in 0..<3 {
            top.colors[i][2] = front.colors[i][2]
        }
        
        for i in 0..<3 {
            front.colors[i][2] = bottom.colors[i][2]
        }
        
        for i in 0..<3 {
            bottom.colors[i][2] = back.colors[2 - i][0]
        }
        
        for i in 0..<3 {
            back.colors[i][0] = topRight[2 - i]
        }
    }
    
    /// Rotate the top face clockwise
    mutating func rotateTop() {
        top.rotateClockwise()
        
        let frontTop = front.colors[0]
        front.colors[0] = right.colors[0]
        right.colors[0] = back.colors[0]
        back.colors[0] = left.colors[0]
        left.colors[0] = frontTop
    }
    
    /// Rotate the bottom face clockwise
    mutating func rotateBottom() {
        bottom.rotateClockwise()
        
        let frontBottom = front.colors[2]
        front.colors[2] = left.colors[2]
        left.colors[2] = back.colors[2]
        back.colors[2] = right.colors[2]
        right.colors[2] = frontBottom
    }
}
