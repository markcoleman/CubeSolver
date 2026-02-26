import XCTest
@testable import CubeCore
@testable import CubeUI

final class CubeReducerTests: XCTestCase {
    func testApplyingMovesIsDeterministic() {
        let initial = CubeState()
        let moves = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .counter),
            Move(turn: .F, amount: .double),
            Move(turn: .L, amount: .clockwise)
        ]

        let first = CubeReducer.apply(moves, to: initial)
        let second = CubeReducer.apply(moves, to: initial)

        XCTAssertEqual(first, second)
    }

    func testMoveThenInverseReturnsPriorState() {
        let allTurns = Turn.allCases
        let amounts: [Amount] = [.clockwise, .counter, .double]

        for turn in allTurns {
            for amount in amounts {
                let move = Move(turn: turn, amount: amount)
                let initial = CubeReducer.apply(Move(turn: .R, amount: .clockwise), to: CubeState())
                let moved = CubeReducer.apply(move, to: initial)
                let restored = CubeReducer.apply(CubeReducer.invert(move), to: moved)

                XCTAssertEqual(restored, initial, "Failed inverse check for \(move.notation)")
            }
        }
    }
}
