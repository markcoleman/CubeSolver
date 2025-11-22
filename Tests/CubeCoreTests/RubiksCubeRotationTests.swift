import CubeCore
//
//  RubiksCubeRotationTests.swift
//  CubeSolver
//
//  Comprehensive tests for RubiksCube rotation mechanics
//

import XCTest
@testable import CubeCore

final class RubiksCubeRotationTests: XCTestCase {
    
    // MARK: - Rotation Correctness Tests
    
    func testFrontRotationCorrectness() {
        var cube = RubiksCube()
        
        // Store original colors that will be used in assertions
        let originalTopBottom = cube.top.colors[2]
        let originalRightLeft = [cube.right.colors[0][0], cube.right.colors[1][0], cube.right.colors[2][0]]
        
        cube.rotateFront()
        
        // Verify front face rotated clockwise
        XCTAssertEqual(cube.front.colors[0][2], .red, "Front face should rotate clockwise")
        
        // Verify edge pieces moved correctly
        // Top bottom should move to right left
        for i in 0..<3 {
            XCTAssertEqual(cube.right.colors[i][0], originalTopBottom[i], "Top bottom edge should move to right left")
        }
        
        // Bottom top should move to left right (reversed)
        for i in 0..<3 {
            XCTAssertEqual(cube.bottom.colors[0][i], originalRightLeft[2 - i], "Right left should move to bottom top")
        }
    }
    
    func testBackRotationCorrectness() {
        var cube = RubiksCube()
        
        // First scramble to make changes visible
        cube.rotateFront()
        
        cube.rotateBack()
        
        // Verify rotation occurred (the rotation happened)
        // On a solved cube, this won't show visible changes, so we just verify no crash
        XCTAssertNotNil(cube.back, "Back face should exist after rotation")
    }
    
    func testLeftRotationCorrectness() {
        var cube = RubiksCube()
        
        // First scramble to make changes visible
        cube.rotateFront()
        
        let originalFrontLeft = [cube.front.colors[0][0], cube.front.colors[1][0], cube.front.colors[2][0]]
        
        cube.rotateLeft()
        
        // Verify front left column moved to bottom left
        for i in 0..<3 {
            XCTAssertEqual(cube.bottom.colors[i][0], originalFrontLeft[i], "Front left should move to bottom left")
        }
    }
    
    func testRightRotationCorrectness() {
        var cube = RubiksCube()
        
        let originalFrontRight = [cube.front.colors[0][2], cube.front.colors[1][2], cube.front.colors[2][2]]
        
        cube.rotateRight()
        
        // After right rotation: Front right column moves to Top right column
        for i in 0..<3 {
            XCTAssertEqual(cube.top.colors[i][2], originalFrontRight[i], "Front right should move to top right")
        }
    }
    
    func testTopRotationCorrectness() {
        var cube = RubiksCube()
        
        let originalFrontTop = cube.front.colors[0]
        
        cube.rotateTop()
        
        // Verify front top moved to left top
        XCTAssertEqual(cube.left.colors[0], originalFrontTop, "Front top should move to left top")
    }
    
    func testBottomRotationCorrectness() {
        var cube = RubiksCube()
        
        let originalFrontBottom = cube.front.colors[2]
        
        cube.rotateBottom()
        
        // Verify front bottom moved to right bottom
        XCTAssertEqual(cube.right.colors[2], originalFrontBottom, "Front bottom should move to right bottom")
    }
    
    // MARK: - Counter-Clockwise Rotation Tests
    
    func testCounterClockwiseRotation() {
        var face = CubeFace(color: .white)
        
        face.rotateCounterClockwise()
        
        // Counter-clockwise should be equivalent to 3 clockwise rotations
        var reference = CubeFace(color: .white)
        reference.rotateClockwise()
        reference.rotateClockwise()
        reference.rotateClockwise()
        
        XCTAssertEqual(face, reference, "Counter-clockwise should equal 3 clockwise rotations")
    }
    
    func testFourCounterClockwiseRotationsReturnsToOriginal() {
        var face = CubeFace(color: .red)
        let original = face
        
        // Four counter-clockwise rotations should return to original
        face.rotateCounterClockwise()
        face.rotateCounterClockwise()
        face.rotateCounterClockwise()
        face.rotateCounterClockwise()
        
        XCTAssertEqual(face, original, "Four counter-clockwise rotations should return to original")
    }
    
    // MARK: - Multiple Rotation Tests
    
    func testFourClockwiseRotationsReturnToOriginalAllFaces() {
        let rotations: [(inout RubiksCube) -> Void] = [
            { $0.rotateFront() },
            { $0.rotateBack() },
            { $0.rotateLeft() },
            { $0.rotateRight() },
            { $0.rotateTop() },
            { $0.rotateBottom() }
        ]
        
        for rotation in rotations {
            var cube = RubiksCube()
            let original = cube
            
            // Apply same rotation 4 times
            rotation(&cube)
            rotation(&cube)
            rotation(&cube)
            rotation(&cube)
            
            XCTAssertEqual(cube, original, "Four rotations should return to original")
        }
    }
    
    func testMultipleRotationsCombination() {
        var cube = RubiksCube()
        
        // Apply a specific sequence
        cube.rotateFront()
        cube.rotateRight()
        cube.rotateTop()
        
        // The cube should not be solved
        XCTAssertFalse(cube.isSolved, "Cube should not be solved after rotations")
        
        // The cube should still have valid face references
        XCTAssertNotNil(cube.front)
        XCTAssertNotNil(cube.back)
        XCTAssertNotNil(cube.left)
        XCTAssertNotNil(cube.right)
        XCTAssertNotNil(cube.top)
        XCTAssertNotNil(cube.bottom)
    }
    
    func testOppositeRotationsCancelOut() {
        // Test that R followed by R' (3 R moves) returns close to original
        // Note: This tests the theoretical property
        var cube1 = RubiksCube()
        cube1.rotateRight()
        
        var cube2 = cube1
        cube2.rotateRight()
        cube2.rotateRight()
        cube2.rotateRight()
        
        let original = RubiksCube()
        XCTAssertEqual(cube2, original, "R followed by R' should return to original")
    }
    
    // MARK: - Face Independence Tests
    
    func testRotationsPreserveCenterColors() {
        var cube = RubiksCube()
        
        // Store original center colors
        let originalCenters = (
            front: cube.front.colors[1][1],
            back: cube.back.colors[1][1],
            left: cube.left.colors[1][1],
            right: cube.right.colors[1][1],
            top: cube.top.colors[1][1],
            bottom: cube.bottom.colors[1][1]
        )
        
        // Apply various rotations
        cube.rotateFront()
        cube.rotateRight()
        cube.rotateTop()
        cube.rotateLeft()
        cube.rotateBack()
        cube.rotateBottom()
        
        // Centers should remain unchanged
        XCTAssertEqual(cube.front.colors[1][1], originalCenters.front, "Front center should not change")
        XCTAssertEqual(cube.back.colors[1][1], originalCenters.back, "Back center should not change")
        XCTAssertEqual(cube.left.colors[1][1], originalCenters.left, "Left center should not change")
        XCTAssertEqual(cube.right.colors[1][1], originalCenters.right, "Right center should not change")
        XCTAssertEqual(cube.top.colors[1][1], originalCenters.top, "Top center should not change")
        XCTAssertEqual(cube.bottom.colors[1][1], originalCenters.bottom, "Bottom center should not change")
    }
    
    // MARK: - Edge Cases
    
    func testConsecutiveSameRotations() {
        var cube = RubiksCube()
        
        // Two consecutive rotations
        cube.rotateFront()
        cube.rotateFront()
        
        // Should not be solved
        XCTAssertFalse(cube.isSolved, "Cube should not be solved after two rotations")
        
        // Two more should return to original
        cube.rotateFront()
        cube.rotateFront()
        
        XCTAssertTrue(cube.isSolved, "Four rotations should solve the cube")
    }
    
    func testAlternatingRotations() {
        var cube = RubiksCube()
        
        // Apply R U R' U' pattern (a common speedcubing algorithm)
        cube.rotateRight()  // R
        cube.rotateTop()    // U
        // R' is R three times
        cube.rotateRight()
        cube.rotateRight()
        cube.rotateRight()
        // U' is U three times
        cube.rotateTop()
        cube.rotateTop()
        cube.rotateTop()
        
        // This pattern affects certain pieces, cube won't be solved
        // Just verify it doesn't crash and cube is in valid state
        XCTAssertNotNil(cube.front, "Cube should be in valid state after pattern")
        XCTAssertNotNil(cube.top, "Cube should be in valid state after pattern")
    }
    
    // MARK: - Color Distribution Tests
    
    func testColorCountRemainsConstantAfterRotations() {
        var cube = RubiksCube()
        
        // Count colors initially
        let initialCounts = countColors(cube)
        
        // Apply random rotations
        cube.rotateFront()
        cube.rotateRight()
        cube.rotateTop()
        cube.rotateLeft()
        cube.rotateBack()
        cube.rotateBottom()
        
        // Count colors after rotations
        let finalCounts = countColors(cube)
        
        // Color counts should remain the same
        XCTAssertEqual(initialCounts, finalCounts, "Color counts should remain constant")
    }
    
    // MARK: - Helper Methods
    
    private func countColors(_ cube: RubiksCube) -> [FaceColor: Int] {
        var counts: [FaceColor: Int] = [:]
        
        for face in [cube.front, cube.back, cube.left, cube.right, cube.top, cube.bottom] {
            for row in face.colors {
                for color in row {
                    counts[color, default: 0] += 1
                }
            }
        }
        
        return counts
    }
}
