import XCTest
@testable import CubeCore
@testable import CubeUI

final class CubeMoveTests: XCTestCase {
    func testParseValidTokens() {
        let parser = CubeMoveParser()

        let result = parser.parse(["R", "U'", "F2"])

        guard case .success(let moves) = result else {
            return XCTFail("Expected successful parse")
        }

        XCTAssertEqual(moves, [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .counter),
            Move(turn: .F, amount: .double)
        ])
    }

    func testParseInvalidTokensFailsSafely() {
        let parser = CubeMoveParser()

        let result = parser.parse(["R", "X", "Z2", "U'"])

        guard case .failure(let error) = result else {
            return XCTFail("Expected parser failure for invalid tokens")
        }

        XCTAssertEqual(error, .invalidTokens(["X", "Z2"]))
    }

    func testDirectionAndAffectedFaceMapping() {
        let clockwise = Move(turn: .R, amount: .clockwise)
        let counter = Move(turn: .U, amount: .counter)
        let doubleTurn = Move(turn: .F, amount: .double)

        XCTAssertEqual(clockwise.direction, .clockwise)
        XCTAssertEqual(counter.direction, .counterClockwise)
        XCTAssertEqual(doubleTurn.direction, .doubleTurn)

        XCTAssertEqual(clockwise.affectedFace, .right)
        XCTAssertEqual(counter.affectedFace, .up)
        XCTAssertEqual(doubleTurn.affectedFace, .front)
    }
}
