import XCTest
@testable import CubeCore

final class CubeStateValidatorEngineTests: XCTestCase {
    private let validator = CubeStateValidator()

    func testSolvedCubePassesValidation() {
        let result = validator.validate(state: CubeState())

        switch result {
        case .success:
            XCTAssertTrue(true)
        case .failure(let error):
            XCTFail("Expected success but got \(error)")
        }
    }

    func testInvalidColorCountsFailWithCountMismatch() {
        var state = CubeState()
        state.setSticker(face: .front, index: 0, color: .blue)

        let result = validator.validate(state: state)

        guard case let .failure(error) = result else {
            return XCTFail("Expected validation failure")
        }

        XCTAssertEqual(error.type, .countMismatch)
        XCTAssertTrue(error.message.contains("stickers"))
    }

    func testImpossibleParityFails() {
        var state = CubeState()

        // Swap two corners to force odd corner parity while keeping color counts valid.
        swapCorner(&state, (.up, 8), (.right, 0), (.front, 2), with: (.up, 6), (.front, 0), (.left, 2))

        let result = validator.validate(state: state)

        guard case let .failure(error) = result else {
            return XCTFail("Expected validation failure")
        }

        XCTAssertEqual(error.type, .impossibleParity)
    }

    func testSwappedEdgeScenarioFailsValidation() {
        var state = CubeState()

        // Swap UR and UF edge pieces as whole pieces.
        swapEdge(&state, first: (.up, 5), (.right, 1), second: (.up, 7), (.front, 1))

        let result = validator.validate(state: state)

        guard case let .failure(error) = result else {
            return XCTFail("Expected validation failure")
        }

        XCTAssertEqual(error.type, .impossibleParity)
    }

    private func swapEdge(
        _ state: inout CubeState,
        first firstA: (Face, Int), _ firstB: (Face, Int),
        second secondA: (Face, Int), _ secondB: (Face, Int)
    ) {
        let firstAColor = state.getSticker(face: firstA.0, index: firstA.1) ?? .white
        let firstBColor = state.getSticker(face: firstB.0, index: firstB.1) ?? .white
        let secondAColor = state.getSticker(face: secondA.0, index: secondA.1) ?? .white
        let secondBColor = state.getSticker(face: secondB.0, index: secondB.1) ?? .white

        state.setSticker(face: firstA.0, index: firstA.1, color: secondAColor)
        state.setSticker(face: firstB.0, index: firstB.1, color: secondBColor)
        state.setSticker(face: secondA.0, index: secondA.1, color: firstAColor)
        state.setSticker(face: secondB.0, index: secondB.1, color: firstBColor)
    }

    private func swapCorner(
        _ state: inout CubeState,
        _ firstA: (Face, Int), _ firstB: (Face, Int), _ firstC: (Face, Int),
        with secondA: (Face, Int), _ secondB: (Face, Int), _ secondC: (Face, Int)
    ) {
        let firstColors = [
            state.getSticker(face: firstA.0, index: firstA.1) ?? .white,
            state.getSticker(face: firstB.0, index: firstB.1) ?? .white,
            state.getSticker(face: firstC.0, index: firstC.1) ?? .white
        ]

        let secondColors = [
            state.getSticker(face: secondA.0, index: secondA.1) ?? .white,
            state.getSticker(face: secondB.0, index: secondB.1) ?? .white,
            state.getSticker(face: secondC.0, index: secondC.1) ?? .white
        ]

        state.setSticker(face: firstA.0, index: firstA.1, color: secondColors[0])
        state.setSticker(face: firstB.0, index: firstB.1, color: secondColors[1])
        state.setSticker(face: firstC.0, index: firstC.1, color: secondColors[2])

        state.setSticker(face: secondA.0, index: secondA.1, color: firstColors[0])
        state.setSticker(face: secondB.0, index: secondB.1, color: firstColors[1])
        state.setSticker(face: secondC.0, index: secondC.1, color: firstColors[2])
    }
}
