#if canImport(SwiftUI)

import XCTest
@testable import CubeCore
@testable import CubeUI

@MainActor
final class SolveModeViewModelTests: XCTestCase {
    func testNextStepIncrementsIndexAndUpdatesState() async {
        let renderer = MockRenderer(initial: CubeState())
        let viewModel = SolveModeViewModel(
            initialState: CubeState(),
            solution: sampleMoves,
            renderer: renderer,
            animator: ImmediateAnimator()
        )

        viewModel.nextStep()
        await Task.yield()

        XCTAssertEqual(viewModel.stepIndex, 1)
        XCTAssertEqual(viewModel.progressText, "1/3")
        XCTAssertEqual(viewModel.displayedState, CubeReducer.apply(sampleMoves[0], to: CubeState()))
    }

    func testBackDecrementsIndexAndUpdatesState() async {
        let renderer = MockRenderer(initial: CubeState())
        let viewModel = SolveModeViewModel(
            initialState: CubeState(),
            solution: sampleMoves,
            renderer: renderer,
            animator: ImmediateAnimator()
        )

        viewModel.jump(to: 2)
        viewModel.previousStep()
        await Task.yield()

        XCTAssertEqual(viewModel.stepIndex, 1)
        XCTAssertEqual(viewModel.displayedState, CubeReducer.apply(sampleMoves[0], to: CubeState()))
    }

    func testJumpToStepProducesExpectedState() {
        let renderer = MockRenderer(initial: CubeState())
        let viewModel = SolveModeViewModel(
            initialState: CubeState(),
            solution: sampleMoves,
            renderer: renderer,
            animator: ImmediateAnimator()
        )

        viewModel.jump(to: 3)

        XCTAssertEqual(viewModel.stepIndex, 3)
        XCTAssertTrue(viewModel.isSolved)
        let expected = CubeReducer.apply(sampleMoves, to: CubeState())
        XCTAssertEqual(viewModel.displayedState, expected)
    }

    func testOrientationLockBlocksInputUntilConfirmed() async {
        let renderer = MockRenderer(initial: CubeState())
        let viewModel = SolveModeViewModel(
            initialState: CubeState(),
            solution: sampleMoves,
            renderer: renderer,
            animator: ImmediateAnimator(),
            requireOrientationConfirmation: true
        )

        viewModel.nextStep()
        await Task.yield()
        XCTAssertEqual(viewModel.stepIndex, 0)

        viewModel.confirmOrientation()
        viewModel.nextStep()
        await Task.yield()
        XCTAssertEqual(viewModel.stepIndex, 1)
    }

    private let sampleMoves: [Move] = [
        Move(turn: .R, amount: .clockwise),
        Move(turn: .U, amount: .counter),
        Move(turn: .F, amount: .double)
    ]
}

@MainActor
private final class MockRenderer: CubeRenderer {
    private(set) var state: CubeState
    private(set) var highlightedMove: Move?

    init(initial: CubeState) {
        state = initial
    }

    func setState(_ state: CubeState) {
        self.state = state
    }

    func highlight(move: Move) {
        highlightedMove = move
    }

    func clearHighlight() {
        highlightedMove = nil
    }
}

@MainActor
private final class ImmediateAnimator: CubeMoveAnimator {
    func animate(move: Move, on renderer: CubeRenderer, completion: @escaping @Sendable () -> Void) {
        renderer.highlight(move: move)
        completion()
    }
}

#endif
