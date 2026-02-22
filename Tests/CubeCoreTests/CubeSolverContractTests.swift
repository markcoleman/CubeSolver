import CubeCore
import XCTest

@testable import CubeCore

final class CubeSolverContractTests: XCTestCase {
    
    func testDeterministicScrambleProducesValidSolve() throws {
        var state = CubeState()
        let scramble = try parseMoves(["D", "U", "D'", "F'", "L2", "U"])
        EnhancedCubeSolver.applyMoves(to: &state, moves: scramble)
        
        let solution = try EnhancedCubeSolver.solveCube(from: state)
        XCTAssertFalse(solution.isEmpty, "Scrambled cube should return a non-empty solution")
        
        var solvedState = state
        EnhancedCubeSolver.applyMoves(to: &solvedState, moves: solution)
        XCTAssertTrue(isSolved(solvedState), "Applying solver output should produce a solved state")
    }
    
    func testMultipleShortScramblesRoundTrip() throws {
        let scrambles = [
            ["R", "U", "F", "R'", "U'"],
            ["L", "D", "L'", "F2", "U"],
            ["B", "R2", "U", "B'", "D"],
            ["U", "R", "U'", "R'", "F"],
            ["F", "D2", "L", "B", "R'"]
        ]
        
        for notation in scrambles {
            var state = CubeState()
            let scramble = try parseMoves(notation)
            EnhancedCubeSolver.applyMoves(to: &state, moves: scramble)
            
            let solution = try EnhancedCubeSolver.solveCube(from: state)
            var solvedState = state
            EnhancedCubeSolver.applyMoves(to: &solvedState, moves: solution)
            
            XCTAssertTrue(
                isSolved(solvedState),
                "Solver output should solve scramble: \(notation.joined(separator: " "))"
            )
        }
    }
    
    // MARK: - Helpers
    
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
    
    private func parseMoves(_ notations: [String]) throws -> [Move] {
        try notations.map { notation in
            guard let move = Move(notation: notation) else {
                throw NSError(domain: "CubeSolverContractTests", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Invalid move notation in test: \(notation)"
                ])
            }
            return move
        }
    }
}
