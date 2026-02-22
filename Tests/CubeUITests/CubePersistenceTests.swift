#if canImport(SwiftUI)
//
//  CubePersistenceTests.swift
//  CubeUITests
//
//  Tests for solve history persistence and move serialization.
//

import XCTest
@testable import CubeUI
@testable import CubeCore

final class CubePersistenceTests: XCTestCase {

    func testSavedSolveRoundTripPreservesMoves() throws {
        let initialState = CubeState()
        let originalMoves = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .counter),
            Move(turn: .F, amount: .double)
        ]
        let original = SavedSolve(
            initialState: initialState,
            solution: originalMoves,
            moveCount: originalMoves.count,
            timeToSolve: 12.5
        )

        let encoded = try original.encoded()
        let decoded = try SavedSolve(from: encoded)

        XCTAssertEqual(decoded.solution, originalMoves)
        XCTAssertEqual(decoded.moveCount, originalMoves.count)
        XCTAssertEqual(decoded.initialState, initialState)
        XCTAssertNotNil(decoded.timeToSolve)
        XCTAssertEqual(decoded.timeToSolve ?? 0, 12.5, accuracy: 0.001)
    }

    func testSavedSolveDecodesLegacyMoveDescriptionFormat() throws {
        let persisted = SavedSolve.Persisted(
            id: UUID(),
            date: Date(timeIntervalSince1970: 1_700_000_000),
            initialState: CubeState(),
            solutionStrings: [
                "Move(turn: CubeCore.Turn.R, amount: CubeCore.Amount.clockwise)",
                "Move(turn: CubeCore.Turn.U, amount: CubeCore.Amount.counter)",
                "Move(turn: CubeCore.Turn.F, amount: CubeCore.Amount.double)"
            ],
            moveCount: 3,
            timeToSolve: 8.4
        )

        let data = try JSONEncoder().encode(persisted)
        let decoded = try SavedSolve(from: data)

        XCTAssertEqual(decoded.solution, [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .counter),
            Move(turn: .F, amount: .double)
        ])
    }

    func testSavedSolveSkipsInvalidMoveStrings() throws {
        let persisted = SavedSolve.Persisted(
            id: UUID(),
            date: Date(),
            initialState: CubeState(),
            solutionStrings: ["R", "INVALID", "U2"],
            moveCount: 3,
            timeToSolve: nil
        )

        let data = try JSONEncoder().encode(persisted)
        let decoded = try SavedSolve(from: data)

        XCTAssertEqual(decoded.solution, [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .double)
        ])
    }
}

#endif
