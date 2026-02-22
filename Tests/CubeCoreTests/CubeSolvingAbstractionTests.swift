import XCTest
@testable import CubeCore

final class CubeSolvingAbstractionTests: XCTestCase {
    func testKociembaCompatibleSolverReturnsValidSolutionFormat() async throws {
        var scrambledState = CubeState()
        let scramble: [Move] = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .clockwise),
            Move(turn: .F, amount: .counter)
        ]

        EnhancedCubeSolver.applyMoves(to: &scrambledState, moves: scramble)

        let solver = KociembaCompatibleCubeSolver(
            fallback: AnyCubeSolver(EnhancedSearchCubeSolver(validationMode: .basic))
        )

        let solution = try await solver.solve(state: scrambledState)

        XCTAssertFalse(solution.isEmpty)
        XCTAssertTrue(solution.allSatisfy { Move(notation: $0.notation) != nil })

        var solved = scrambledState
        EnhancedCubeSolver.applyMoves(to: &solved, moves: solution)
        XCTAssertTrue(isSolved(solved))
    }

    private func isSolved(_ state: CubeState) -> Bool {
        for face in Face.allCases {
            guard let stickers = state.faces[face], let first = stickers.first else {
                return false
            }
            if stickers.contains(where: { $0 != first }) {
                return false
            }
        }
        return true
    }
}
