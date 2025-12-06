import CubeCore
//
//  CubeDataStructuresTests.swift
//  CubeSolver
//
//  Tests for CubeDataStructures module
//

import XCTest
@testable import CubeCore

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
    
    // MARK: - CubeState Hashable Tests
    
    func testCubeStateHashable() {
        let state1 = CubeState()
        let state2 = CubeState()
        
        // Can be used in Set - equal states should be treated as same
        var stateSet = Set<CubeState>()
        stateSet.insert(state1)
        XCTAssertTrue(stateSet.contains(state2), "Equal states should hash to same bucket")
        XCTAssertEqual(stateSet.count, 1, "Set should contain only one element for equal states")
    }
    
    func testCubeStateHashDifferentStates() {
        let state1 = CubeState()
        var state2 = CubeState()
        state2.setSticker(face: .front, index: 0, color: .blue)
        
        // Different states should be distinguishable in Set
        var stateSet = Set<CubeState>()
        stateSet.insert(state1)
        stateSet.insert(state2)
        XCTAssertEqual(stateSet.count, 2)
    }
    
    func testCubeStateIsSolved() {
        let solvedState = CubeState()
        XCTAssertTrue(solvedState.isSolved)
        
        var scrambledState = CubeState()
        scrambledState.setSticker(face: .front, index: 0, color: .blue)
        XCTAssertFalse(scrambledState.isSolved)
    }
    
    func testCubeStateMisplacedStickerCount() {
        let solvedState = CubeState()
        XCTAssertEqual(solvedState.misplacedStickerCount, 0)
        
        var modifiedState = CubeState()
        // Change one non-center sticker
        modifiedState.setSticker(face: .front, index: 0, color: .blue)
        XCTAssertEqual(modifiedState.misplacedStickerCount, 1)
    }
    
    // MARK: - Move Extension Tests
    
    func testMoveAllMoves() {
        let allMoves = Move.allMoves
        // 6 turns × 3 amounts = 18 moves
        XCTAssertEqual(allMoves.count, 18)
        
        // Check all turns are present
        for turn in Turn.allCases {
            let movesWithTurn = allMoves.filter { $0.turn == turn }
            XCTAssertEqual(movesWithTurn.count, 3, "Should have 3 moves for turn \(turn)")
        }
    }
    
    func testMoveInverse() {
        let clockwise = Move(turn: .R, amount: .clockwise)
        XCTAssertEqual(clockwise.inverse.amount, .counter)
        XCTAssertEqual(clockwise.inverse.turn, .R)
        
        let counter = Move(turn: .U, amount: .counter)
        XCTAssertEqual(counter.inverse.amount, .clockwise)
        XCTAssertEqual(counter.inverse.turn, .U)
        
        let double = Move(turn: .F, amount: .double)
        XCTAssertEqual(double.inverse.amount, .double)
        XCTAssertEqual(double.inverse.turn, .F)
    }
    
    func testMoveCanCombine() {
        let r1 = Move(turn: .R, amount: .clockwise)
        let r2 = Move(turn: .R, amount: .counter)
        let u1 = Move(turn: .U, amount: .clockwise)
        
        XCTAssertTrue(r1.canCombine(with: r2))
        XCTAssertFalse(r1.canCombine(with: u1))
    }
    
    func testMoveCombined() {
        // R + R = R2
        let r1 = Move(turn: .R, amount: .clockwise)
        let combined = r1.combined(with: r1)
        XCTAssertNotNil(combined)
        XCTAssertEqual(combined?.turn, .R)
        XCTAssertEqual(combined?.amount, .double)
        
        // R + R' = nothing (cancel out)
        let rPrime = Move(turn: .R, amount: .counter)
        let cancelled = r1.combined(with: rPrime)
        XCTAssertNil(cancelled, "R + R' should cancel out")
        
        // R2 + R = R'
        let r2 = Move(turn: .R, amount: .double)
        let combined2 = r2.combined(with: r1)
        XCTAssertNotNil(combined2)
        XCTAssertEqual(combined2?.amount, .counter)
        
        // Cannot combine different turns
        let u1 = Move(turn: .U, amount: .clockwise)
        XCTAssertNil(r1.combined(with: u1))
    }
    
    // MARK: - Move Sequence Optimization Tests
    
    func testMoveSequenceOptimized() {
        // R R should become R2
        let moves1 = [Move(turn: .R, amount: .clockwise), Move(turn: .R, amount: .clockwise)]
        let optimized1 = moves1.optimized()
        XCTAssertEqual(optimized1.count, 1)
        XCTAssertEqual(optimized1.first?.amount, .double)
        
        // R R' should cancel out
        let moves2 = [Move(turn: .R, amount: .clockwise), Move(turn: .R, amount: .counter)]
        let optimized2 = moves2.optimized()
        XCTAssertEqual(optimized2.count, 0)
        
        // R U R should not change (different turns in between)
        let moves3 = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .clockwise),
            Move(turn: .R, amount: .clockwise)
        ]
        let optimized3 = moves3.optimized()
        XCTAssertEqual(optimized3.count, 3)
    }
    
    func testMoveSequenceUniqueMoves() {
        let moves = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .clockwise),
            Move(turn: .R, amount: .clockwise),  // Duplicate
            Move(turn: .F, amount: .clockwise)
        ]
        let unique = moves.uniqueMoves()
        XCTAssertEqual(unique.count, 3)
    }
    
    func testMoveSequenceTurnCounts() {
        let moves = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .R, amount: .counter),
            Move(turn: .U, amount: .clockwise),
            Move(turn: .R, amount: .double)
        ]
        let counts = moves.turnCounts()
        XCTAssertEqual(counts[.R], 3)
        XCTAssertEqual(counts[.U], 1)
        XCTAssertNil(counts[.F])
    }
}
