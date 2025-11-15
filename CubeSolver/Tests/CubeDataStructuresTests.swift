//
//  CubeDataStructuresTests.swift
//  CubeSolver
//
//  Tests for CubeDataStructures module
//

import XCTest
@testable import CubeSolverCore

final class CubeDataStructuresTests: XCTestCase {
    
    // MARK: - CubeColor Tests
    
    func testCubeColorAllCases() {
        let colors = CubeColor.allCases
        XCTAssertEqual(colors.count, 6, "Should have exactly 6 cube colors")
    }
    
    // MARK: - Face Tests
    
    func testFaceAllCases() {
        let faces = Face.allCases
        XCTAssertEqual(faces.count, 6, "Should have exactly 6 faces")
    }
    
    func testFaceOpposite() {
        XCTAssertEqual(Face.up.opposite, .down)
        XCTAssertEqual(Face.down.opposite, .up)
        XCTAssertEqual(Face.left.opposite, .right)
        XCTAssertEqual(Face.right.opposite, .left)
        XCTAssertEqual(Face.front.opposite, .back)
        XCTAssertEqual(Face.back.opposite, .front)
    }
    
    // MARK: - CubeState Tests
    
    func testCubeStateInitialization() {
        let state = CubeState()
        
        // Check each face has 9 stickers
        for face in Face.allCases {
            XCTAssertEqual(state.faces[face]?.count, 9, "\(face) should have 9 stickers")
        }
        
        // Check center colors
        XCTAssertEqual(state.centerColor(of: .up), .white)
        XCTAssertEqual(state.centerColor(of: .down), .yellow)
        XCTAssertEqual(state.centerColor(of: .left), .green)
        XCTAssertEqual(state.centerColor(of: .right), .blue)
        XCTAssertEqual(state.centerColor(of: .front), .red)
        XCTAssertEqual(state.centerColor(of: .back), .orange)
    }
    
    func testCubeStateGetSetSticker() {
        var state = CubeState()
        
        // Get initial sticker
        let initialColor = state.getSticker(face: .front, index: 0)
        XCTAssertEqual(initialColor, .red)
        
        // Set sticker to new color
        state.setSticker(face: .front, index: 0, color: .blue)
        let updatedColor = state.getSticker(face: .front, index: 0)
        XCTAssertEqual(updatedColor, .blue)
    }
    
    func testCubeStateInvalidIndex() {
        let state = CubeState()
        
        // Test invalid indices
        XCTAssertNil(state.getSticker(face: .front, index: -1))
        XCTAssertNil(state.getSticker(face: .front, index: 9))
        XCTAssertNil(state.getSticker(face: .front, index: 100))
    }
    
    func testCubeStateCenterColor() {
        let state = CubeState()
        
        // Center is at index 4
        XCTAssertEqual(state.centerColor(of: .up), .white)
        XCTAssertEqual(state.getSticker(face: .up, index: 4), .white)
    }
    
    // MARK: - Turn Tests
    
    func testTurnToFace() {
        XCTAssertEqual(Turn.U.face, .up)
        XCTAssertEqual(Turn.D.face, .down)
        XCTAssertEqual(Turn.L.face, .left)
        XCTAssertEqual(Turn.R.face, .right)
        XCTAssertEqual(Turn.F.face, .front)
        XCTAssertEqual(Turn.B.face, .back)
    }
    
    func testTurnFromFace() {
        XCTAssertEqual(Turn(from: .up), .U)
        XCTAssertEqual(Turn(from: .down), .D)
        XCTAssertEqual(Turn(from: .left), .L)
        XCTAssertEqual(Turn(from: .right), .R)
        XCTAssertEqual(Turn(from: .front), .F)
        XCTAssertEqual(Turn(from: .back), .B)
    }
    
    // MARK: - Amount Tests
    
    func testAmountQuarters() {
        XCTAssertEqual(Amount.clockwise.quarters, 1)
        XCTAssertEqual(Amount.counter.quarters, 3)
        XCTAssertEqual(Amount.double.quarters, 2)
    }
    
    // MARK: - Move Tests
    
    func testMoveNotation() {
        let move1 = Move(turn: .R, amount: .clockwise)
        XCTAssertEqual(move1.notation, "R")
        
        let move2 = Move(turn: .U, amount: .counter)
        XCTAssertEqual(move2.notation, "U'")
        
        let move3 = Move(turn: .F, amount: .double)
        XCTAssertEqual(move3.notation, "F2")
    }
    
    func testMoveDescription() {
        let move1 = Move(turn: .R, amount: .clockwise)
        XCTAssertTrue(move1.description.contains("right"))
        XCTAssertTrue(move1.description.contains("clockwise"))
        
        let move2 = Move(turn: .U, amount: .counter)
        XCTAssertTrue(move2.description.contains("top"))
        XCTAssertTrue(move2.description.contains("counter-clockwise"))
        
        let move3 = Move(turn: .F, amount: .double)
        XCTAssertTrue(move3.description.contains("front"))
        XCTAssertTrue(move3.description.contains("180"))
    }
    
    func testMoveFromNotation() {
        // Test valid notations
        let move1 = Move(notation: "R")
        XCTAssertNotNil(move1)
        XCTAssertEqual(move1?.turn, .R)
        XCTAssertEqual(move1?.amount, .clockwise)
        
        let move2 = Move(notation: "U'")
        XCTAssertNotNil(move2)
        XCTAssertEqual(move2?.turn, .U)
        XCTAssertEqual(move2?.amount, .counter)
        
        let move3 = Move(notation: "F2")
        XCTAssertNotNil(move3)
        XCTAssertEqual(move3?.turn, .F)
        XCTAssertEqual(move3?.amount, .double)
        
        // Test invalid notations
        XCTAssertNil(Move(notation: ""))
        XCTAssertNil(Move(notation: "X"))
        XCTAssertNil(Move(notation: "R3"))
    }
    
    // MARK: - Conversion Tests
    
    func testCubeStateFromRubiksCube() {
        let cube = RubiksCube()
        let state = CubeState(from: cube)
        
        // Check that the conversion preserved the colors
        XCTAssertEqual(state.centerColor(of: .up), .white)
        XCTAssertEqual(state.centerColor(of: .down), .yellow)
        XCTAssertEqual(state.centerColor(of: .left), .green)
        XCTAssertEqual(state.centerColor(of: .right), .blue)
        XCTAssertEqual(state.centerColor(of: .front), .red)
        XCTAssertEqual(state.centerColor(of: .back), .orange)
        
        // Check that all stickers are present
        for face in Face.allCases {
            XCTAssertEqual(state.faces[face]?.count, 9)
        }
    }
    
    func testCubeStateToRubiksCube() {
        let state = CubeState()
        let cube = state.toRubiksCube()
        
        // Check that the conversion worked
        XCTAssertTrue(cube.isSolved)
    }
    
    func testCubeStateRoundTrip() {
        // Test: RubiksCube -> CubeState -> RubiksCube
        let originalCube = RubiksCube()
        let state = CubeState(from: originalCube)
        let convertedCube = state.toRubiksCube()
        
        XCTAssertTrue(convertedCube.isSolved)
        
        // Test: CubeState -> RubiksCube -> CubeState
        let originalState = CubeState()
        let cube = originalState.toRubiksCube()
        let convertedState = CubeState(from: cube)
        
        XCTAssertEqual(originalState, convertedState)
    }
}
