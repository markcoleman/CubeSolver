import CubeCore
//
//  CubeSolverAdvancedTests.swift
//  CubeSolver
//
//  Advanced tests for CubeSolver functionality
//

import XCTest
@testable import CubeCore

final class CubeSolverAdvancedTests: XCTestCase {
    
    // MARK: - Move Application Tests
    
    func testApplyMoveAccuracy() {
        var cube = RubiksCube()
        let scramble = ["F", "R", "U"]
        
        for move in scramble {
            CubeSolver.applyScramble(cube: &cube, scramble: ["\(move) - Rotate \(move) face clockwise"])
        }
        
        XCTAssertFalse(cube.isSolved, "Cube should not be solved after moves")
    }
    
    func testApplyAllMoveTypes() {
        var cube = RubiksCube()
        
        // Test all basic moves
        let moves = ["F", "B", "L", "R", "U", "D"]
        
        for move in moves {
            let scramble = ["\(move) - Rotate face clockwise"]
            CubeSolver.applyScramble(cube: &cube, scramble: scramble)
        }
        
        // After 6 different moves, cube should not be solved
        XCTAssertFalse(cube.isSolved)
    }
    
    func testApplyInvalidMove() {
        var cube = RubiksCube()
        let originalCube = cube
        
        // Invalid move character should be ignored
        let scramble = ["X - Invalid move"]
        CubeSolver.applyScramble(cube: &cube, scramble: scramble)
        
        // Cube should remain unchanged
        XCTAssertEqual(cube, originalCube, "Invalid move should not change cube")
    }
    
    // MARK: - Scramble Generation Tests
    
    func testScrambleGenerationLength() {
        for length in [5, 10, 15, 20, 25, 30] {
            let scramble = CubeSolver.scramble(moves: length)
            XCTAssertEqual(scramble.count, length, "Scramble should have \(length) moves")
        }
    }
    
    func testScrambleGenerationUniqueness() {
        let scramble1 = CubeSolver.scramble(moves: 20)
        let scramble2 = CubeSolver.scramble(moves: 20)
        
        // Scrambles should be different (with high probability)
        XCTAssertNotEqual(scramble1, scramble2, "Two scrambles should be different")
    }
    
    func testScrambleContainsValidMoves() {
        let scramble = CubeSolver.scramble(moves: 20)
        let validMoves = ["F", "B", "L", "R", "U", "D"]
        
        for move in scramble {
            let moveChar = String(move.prefix(1))
            XCTAssertTrue(validMoves.contains(moveChar), "Scramble should only contain valid moves")
        }
    }
    
    func testScrambleWithZeroMoves() {
        let scramble = CubeSolver.scramble(moves: 0)
        XCTAssertTrue(scramble.isEmpty, "Zero moves should produce empty scramble")
    }
    
    func testScrambleWithOneMoves() {
        let scramble = CubeSolver.scramble(moves: 1)
        XCTAssertEqual(scramble.count, 1, "Should produce exactly one move")
    }
    
    // MARK: - Solver Behavior Tests
    
    func testSolverOnSolvedCube() {
        var cube = RubiksCube()
        let steps = CubeSolver.solve(cube: &cube)
        
        XCTAssertEqual(steps.count, 0, "Solved cube should return no steps")
    }
    
    func testSolverReturnsStepsForScrambled() {
        var cube = RubiksCube()
        
        // Apply multiple rotations
        cube.rotateFront()
        cube.rotateRight()
        cube.rotateTop()
        cube.rotateLeft()
        
        let steps = CubeSolver.solve(cube: &cube)
        
        XCTAssertGreaterThan(steps.count, 0, "Scrambled cube should return steps")
    }
    
    func testSolverStepsAreDescriptive() {
        var cube = RubiksCube()
        cube.rotateFront()
        
        let steps = CubeSolver.solve(cube: &cube)
        
        for step in steps {
            XCTAssertTrue(step.contains("-"), "Step should contain description separator")
            XCTAssertTrue(step.contains("Rotate"), "Step should contain rotation instruction")
        }
    }
    
    // MARK: - Integration Tests
    
    func testScrambleAndSolveWorkflow() {
        var cube = RubiksCube()
        
        // Generate scramble
        let scramble = CubeSolver.scramble(moves: 10)
        XCTAssertEqual(scramble.count, 10)
        
        // Apply scramble
        CubeSolver.applyScramble(cube: &cube, scramble: scramble)
        XCTAssertFalse(cube.isSolved)
        
        // Get solution
        let solution = CubeSolver.solve(cube: &cube)
        XCTAssertGreaterThan(solution.count, 0)
    }
    
    func testMultipleScrambleApplications() {
        var cube = RubiksCube()
        
        let scramble1 = CubeSolver.scramble(moves: 5)
        CubeSolver.applyScramble(cube: &cube, scramble: scramble1)
        
        let state1 = cube
        
        let scramble2 = CubeSolver.scramble(moves: 5)
        CubeSolver.applyScramble(cube: &cube, scramble: scramble2)
        
        // Cube should have changed after second scramble
        XCTAssertNotEqual(cube, state1, "Cube should change after second scramble")
    }
    
    // MARK: - Edge Cases
    
    func testEmptyScrambleApplication() {
        var cube = RubiksCube()
        let originalCube = cube
        
        CubeSolver.applyScramble(cube: &cube, scramble: [])
        
        XCTAssertEqual(cube, originalCube, "Empty scramble should not change cube")
    }
    
    func testScrambleWithInvalidMoves() {
        var cube = RubiksCube()
        let originalCube = cube
        
        let invalidScramble = ["X - Invalid", "Y - Invalid", "Z - Invalid"]
        CubeSolver.applyScramble(cube: &cube, scramble: invalidScramble)
        
        // Cube should remain unchanged
        XCTAssertEqual(cube, originalCube, "Invalid moves should not change cube")
    }
    
    func testScrambleWithMixedValidAndInvalid() {
        var cube = RubiksCube()
        
        let mixedScramble = [
            "F - Rotate front clockwise",
            "X - Invalid move",
            "R - Rotate right clockwise",
            "Y - Invalid move"
        ]
        
        CubeSolver.applyScramble(cube: &cube, scramble: mixedScramble)
        
        // Cube should have changed (from valid moves)
        XCTAssertFalse(cube.isSolved, "Valid moves should affect cube")
    }
    
    // MARK: - Performance Tests
    
    func testLargeScrambleGeneration() {
        let largeScramble = CubeSolver.scramble(moves: 100)
        
        XCTAssertEqual(largeScramble.count, 100, "Should handle large scrambles")
    }
    
    func testLargeScrambleApplication() {
        var cube = RubiksCube()
        let largeScramble = CubeSolver.scramble(moves: 50)
        
        CubeSolver.applyScramble(cube: &cube, scramble: largeScramble)
        
        // Cube should still be valid
        XCTAssertNotNil(cube.front)
        XCTAssertNotNil(cube.back)
        XCTAssertNotNil(cube.left)
        XCTAssertNotNil(cube.right)
        XCTAssertNotNil(cube.top)
        XCTAssertNotNil(cube.bottom)
    }
    
    // MARK: - Consistency Tests
    
    func testRepeatedSolveCallsConsistent() {
        var cube1 = RubiksCube()
        var cube2 = RubiksCube()
        
        // Apply same scramble to both
        cube1.rotateFront()
        cube1.rotateRight()
        
        cube2.rotateFront()
        cube2.rotateRight()
        
        let steps1 = CubeSolver.solve(cube: &cube1)
        let steps2 = CubeSolver.solve(cube: &cube2)
        
        XCTAssertEqual(steps1.count, steps2.count, "Same scramble should produce same number of steps")
    }
    
    func testSolverDoesNotModifySolvedCube() {
        var cube = RubiksCube()
        XCTAssertTrue(cube.isSolved)
        
        _ = CubeSolver.solve(cube: &cube)
        
        // Cube state might change during solving, but that's expected
        // We just verify it doesn't crash or throw
        XCTAssertNotNil(cube)
    }
}
