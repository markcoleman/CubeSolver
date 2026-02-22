import XCTest
@testable import CubeCore
@testable import CubeUI

final class SolveModeEngineTests: XCTestCase {
    func testNextIncrementsIndexAndUpdatesState() {
        var engine = makeEngine()

        let nextState = engine.next()

        XCTAssertEqual(engine.stepIndex, 1)
        XCTAssertEqual(nextState, CubeReducer.apply(sampleSolution[0], to: initialState))
        XCTAssertEqual(engine.progressText(), "1/4")
    }

    func testBackDecrementsIndexAndUpdatesState() {
        var engine = makeEngine()
        _ = engine.jump(to: 3)

        let stateAfterBack = engine.back()

        XCTAssertEqual(engine.stepIndex, 2)
        let expected = CubeReducer.apply(Array(sampleSolution.prefix(2)), to: initialState)
        XCTAssertEqual(stateAfterBack, expected)
    }

    func testJumpToStepProducesDeterministicState() {
        var engine = makeEngine()

        let jumped = engine.jump(to: 2)
        let expected = CubeReducer.apply(Array(sampleSolution.prefix(2)), to: initialState)

        XCTAssertEqual(jumped, expected)
        XCTAssertEqual(engine.currentState(), expected)
        XCTAssertEqual(engine.currentMove(), sampleSolution[2])
    }

    func testSolvedStepAndProgressAtEnd() {
        var engine = makeEngine()

        _ = engine.jump(to: sampleSolution.count)

        XCTAssertTrue(engine.isSolvedStep())
        XCTAssertNil(engine.currentMove())
        XCTAssertEqual(engine.progressText(), "4/4")
    }

    func testRestartResetsToInitialState() {
        var engine = makeEngine()
        _ = engine.jump(to: 3)

        let restarted = engine.restart()

        XCTAssertEqual(engine.stepIndex, 0)
        XCTAssertEqual(restarted, initialState)
        XCTAssertEqual(engine.currentState(), initialState)
    }

    private let initialState = CubeState()

    private let sampleSolution: [Move] = [
        Move(turn: .R, amount: .clockwise),
        Move(turn: .U, amount: .counter),
        Move(turn: .F, amount: .double),
        Move(turn: .L, amount: .clockwise)
    ]

    private func makeEngine() -> SolveModeEngine {
        SolveModeEngine(initialState: initialState, solution: sampleSolution, checkpointInterval: 2)
    }
}
