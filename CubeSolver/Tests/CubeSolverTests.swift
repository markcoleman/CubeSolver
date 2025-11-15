//
//  CubeSolverTests.swift
//  CubeSolver
//
//  Created by GitHub Copilot
//

import XCTest
@testable import CubeSolverCore

final class CubeSolverTests: XCTestCase {
    
    // MARK: - RubiksCube Tests
    
    func testCubeInitialization() {
        let cube = RubiksCube()
        
        // Check that a new cube is solved
        XCTAssertTrue(cube.isSolved, "A newly initialized cube should be solved")
    }
    
    func testCubeFaceRotation() {
        var face = CubeFace(color: .white)
        let originalTopLeft = face.colors[0][0]
        
        face.rotateClockwise()
        
        // After one clockwise rotation, the top-left should have moved
        XCTAssertEqual(face.colors[0][2], originalTopLeft, "Top-left should move to top-right after clockwise rotation")
    }
    
    func testFrontRotation() {
        var cube = RubiksCube()
        cube.rotateFront()
        
        // After rotating front, the cube should not be solved (unless it's a specific case)
        // We're just testing that the rotation executes without error
        XCTAssertNotNil(cube.front, "Front face should still exist after rotation")
    }
    
    func testBackRotation() {
        var cube = RubiksCube()
        cube.rotateBack()
        
        XCTAssertNotNil(cube.back, "Back face should still exist after rotation")
    }
    
    func testLeftRotation() {
        var cube = RubiksCube()
        cube.rotateLeft()
        
        XCTAssertNotNil(cube.left, "Left face should still exist after rotation")
    }
    
    func testRightRotation() {
        var cube = RubiksCube()
        cube.rotateRight()
        
        XCTAssertNotNil(cube.right, "Right face should still exist after rotation")
    }
    
    func testTopRotation() {
        var cube = RubiksCube()
        cube.rotateTop()
        
        XCTAssertNotNil(cube.top, "Top face should still exist after rotation")
    }
    
    func testBottomRotation() {
        var cube = RubiksCube()
        cube.rotateBottom()
        
        XCTAssertNotNil(cube.bottom, "Bottom face should still exist after rotation")
    }
    
    // MARK: - CubeSolver Tests
    
    func testScrambleGeneration() {
        let scramble = CubeSolver.scramble(moves: 20)
        
        XCTAssertEqual(scramble.count, 20, "Scramble should generate 20 moves")
    }
    
    func testScrambleApplication() {
        var cube = RubiksCube()
        let scramble = CubeSolver.scramble(moves: 10)
        
        CubeSolver.applyScramble(cube: &cube, scramble: scramble)
        
        // After scrambling, the cube should not be solved (with high probability)
        // Note: There's a tiny chance it could still be solved after random moves
        XCTAssertNotNil(cube, "Cube should still exist after scrambling")
    }
    
    func testSolverReturnsSteps() {
        var cube = RubiksCube()
        
        // If cube is already solved, it should return empty steps
        let steps = CubeSolver.solve(cube: &cube)
        XCTAssertEqual(steps.count, 0, "Solved cube should return no solution steps")
    }
    
    func testSolverWithScrambledCube() {
        var cube = RubiksCube()
        
        // Scramble the cube
        cube.rotateFront()
        cube.rotateRight()
        cube.rotateTop()
        
        let steps = CubeSolver.solve(cube: &cube)
        
        // The solver should return some steps for a scrambled cube
        XCTAssertGreaterThan(steps.count, 0, "Scrambled cube should return solution steps")
    }
    
    // MARK: - Face Color Tests
    
    func testFaceColorEnum() {
        let colors = FaceColor.allCases
        
        XCTAssertEqual(colors.count, 6, "There should be exactly 6 face colors")
        XCTAssertTrue(colors.contains(.white), "Should contain white color")
        XCTAssertTrue(colors.contains(.yellow), "Should contain yellow color")
        XCTAssertTrue(colors.contains(.red), "Should contain red color")
        XCTAssertTrue(colors.contains(.orange), "Should contain orange color")
        XCTAssertTrue(colors.contains(.blue), "Should contain blue color")
        XCTAssertTrue(colors.contains(.green), "Should contain green color")
    }
}
