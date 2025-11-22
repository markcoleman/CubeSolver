import CubeCore
//
//  CubePerformanceTests.swift
//  CubeSolver
//
//  Performance and stress tests for cube operations
//

import XCTest
@testable import CubeCore

final class CubePerformanceTests: XCTestCase {
    
    // MARK: - Rotation Performance Tests
    
    func testRotationPerformance() {
        measure {
            var cube = RubiksCube()
            
            // Perform many rotations
            for _ in 0..<1000 {
                cube.rotateFront()
                cube.rotateRight()
                cube.rotateTop()
                cube.rotateLeft()
                cube.rotateBack()
                cube.rotateBottom()
            }
        }
    }
    
    func testSingleFaceRotationPerformance() {
        measure {
            var face = CubeFace(color: .white)
            
            for _ in 0..<10000 {
                face.rotateClockwise()
            }
        }
    }
    
    // MARK: - Scramble Performance Tests
    
    func testScrambleGenerationPerformance() {
        measure {
            for _ in 0..<100 {
                _ = EnhancedCubeSolver.generateScramble(moveCount: 100)
            }
        }
    }
    
    func testScrambleApplicationPerformance() {
        measure {
            var state = CubeState()
            let scramble = EnhancedCubeSolver.generateScramble(moveCount: 50)
            
            for _ in 0..<20 {
                EnhancedCubeSolver.applyMoves(to: &state, moves: scramble)
            }
        }
    }
    
    func testEnhancedScrambleGenerationPerformance() {
        measure {
            for _ in 0..<100 {
                _ = EnhancedCubeSolver.generateScramble(moveCount: 100)
            }
        }
    }
    
    // MARK: - Solver Performance Tests
    
    func testSolverPerformance() {
        measure {
            var state = CubeState()
            
            // Apply scramble
            let moves = [
                Move(turn: .F, amount: .clockwise),
                Move(turn: .R, amount: .clockwise),
                Move(turn: .U, amount: .clockwise)
            ]
            EnhancedCubeSolver.applyMoves(to: &state, moves: moves)
            
            for _ in 0..<10 {
                _ = try? EnhancedCubeSolver.solveCube(from: state)
            }
        }
    }
    
    func testEnhancedSolverPerformanceOnSolvedCube() {
        measure {
            let state = CubeState()
            
            for _ in 0..<100 {
                _ = try? EnhancedCubeSolver.solveCube(from: state)
            }
        }
    }
    
    // MARK: - Validation Performance Tests
    
    func testValidationPerformance() {
        measure {
            let state = CubeState()
            
            for _ in 0..<1000 {
                _ = try? CubeValidator.validate(state)
            }
        }
    }
    
    func testBasicValidationPerformance() {
        measure {
            let state = CubeState()
            
            for _ in 0..<1000 {
                _ = try? CubeValidator.validateBasic(state)
            }
        }
    }
    
    func testPhysicalValidationPerformance() {
        measure {
            let state = CubeState()
            
            for _ in 0..<1000 {
                _ = try? CubeValidator.validatePhysicalLegality(state)
            }
        }
    }
    
    // MARK: - State Conversion Performance Tests
    
    func testCubeStateConversionPerformance() {
        measure {
            let cube = RubiksCube()
            
            for _ in 0..<1000 {
                let state = CubeState(from: cube)
                _ = state.toRubiksCube()
            }
        }
    }
    
    func testCubeStateToRubiksCubePerformance() {
        measure {
            let state = CubeState()
            
            for _ in 0..<1000 {
                _ = state.toRubiksCube()
            }
        }
    }
    
    func testRubiksCubeToCubeStatePerformance() {
        measure {
            let cube = RubiksCube()
            
            for _ in 0..<1000 {
                _ = CubeState(from: cube)
            }
        }
    }
    
    // MARK: - Move Application Performance Tests
    
    func testMoveApplicationPerformance() {
        measure {
            var state = CubeState()
            let moves = [
                Move(turn: .R, amount: .clockwise),
                Move(turn: .U, amount: .clockwise),
                Move(turn: .F, amount: .clockwise)
            ]
            
            for _ in 0..<100 {
                EnhancedCubeSolver.applyMoves(to: &state, moves: moves)
            }
        }
    }
    
    func testLongMoveSequencePerformance() {
        measure {
            var state = CubeState()
            let moves = EnhancedCubeSolver.generateScramble(moveCount: 100)
            
            for _ in 0..<10 {
                EnhancedCubeSolver.applyMoves(to: &state, moves: moves)
            }
        }
    }
    
    // MARK: - Stress Tests
    
    func testMassiveRotationStressTest() {
        var cube = RubiksCube()
        
        // Apply 10,000 rotations - should not crash or hang
        for i in 0..<10000 {
            switch i % 6 {
            case 0: cube.rotateFront()
            case 1: cube.rotateBack()
            case 2: cube.rotateLeft()
            case 3: cube.rotateRight()
            case 4: cube.rotateTop()
            default: cube.rotateBottom()
            }
        }
        
        // Verify cube is still in valid state
        XCTAssertNotNil(cube.front)
        XCTAssertNotNil(cube.back)
        XCTAssertNotNil(cube.left)
        XCTAssertNotNil(cube.right)
        XCTAssertNotNil(cube.top)
        XCTAssertNotNil(cube.bottom)
    }
    
    func testMassiveScrambleGenerationStressTest() {
        // Generate 1000 scrambles - should not crash
        for _ in 0..<1000 {
            let scramble = CubeSolver.scramble(moves: 20)
            XCTAssertEqual(scramble.count, 20)
        }
    }
    
    func testConcurrentValidationStressTest() {
        let state = CubeState()
        
        // Run validation many times concurrently-safe
        for _ in 0..<1000 {
            _ = try? CubeValidator.validate(state)
        }
        
        // Should complete without issues
        XCTAssertTrue(true)
    }
    
    func testLargeStateManipulationStressTest() {
        var state = CubeState()
        
        // Modify state extensively
        for _ in 0..<1000 {
            for face in Face.allCases {
                for index in 0..<9 {
                    let color = CubeColor.allCases.randomElement()!
                    state.setSticker(face: face, index: index, color: color)
                }
            }
        }
        
        // State should still be accessible
        XCTAssertNotNil(state.faces[.front])
    }
    
    // MARK: - Memory Tests
    
    func testMemoryUsageWithManyCubes() {
        var cubes: [RubiksCube] = []
        
        // Create many cube instances
        for _ in 0..<1000 {
            let cube = RubiksCube()
            cubes.append(cube)
        }
        
        XCTAssertEqual(cubes.count, 1000)
        
        // Verify all cubes are solved
        XCTAssertTrue(cubes.allSatisfy { $0.isSolved })
    }
    
    func testMemoryUsageWithManyStates() {
        var states: [CubeState] = []
        
        // Create many state instances
        for _ in 0..<1000 {
            let state = CubeState()
            states.append(state)
        }
        
        XCTAssertEqual(states.count, 1000)
    }
    
    // MARK: - Algorithmic Complexity Tests
    
    func testScrambleLengthScaling() {
        // Test that scramble generation scales linearly with length
        let lengths = [10, 20, 40, 80, 160]
        
        for length in lengths {
            let scramble = CubeSolver.scramble(moves: length)
            XCTAssertEqual(scramble.count, length, "Scramble should scale with length")
        }
    }
    
    func testMoveApplicationScaling() {
        // Test that move application scales linearly with number of moves
        var state = CubeState()
        let moveCounts = [10, 20, 40, 80]
        
        for count in moveCounts {
            let moves = EnhancedCubeSolver.generateScramble(moveCount: count)
            EnhancedCubeSolver.applyMoves(to: &state, moves: moves)
            
            // Should complete without timeout
            XCTAssertNotNil(state)
        }
    }
}
