import Foundation
import CubeCore

/// Deterministic step navigator for solve playback.
public struct SolveModeEngine: Sendable {
    public let initialState: CubeState
    public let solution: [Move]

    public private(set) var stepIndex: Int

    private let checkpointInterval: Int
    private var checkpoints: [Int: CubeState]

    public init(
        initialState: CubeState,
        solution: [Move],
        stepIndex: Int = 0,
        checkpointInterval: Int = 12
    ) {
        self.initialState = initialState
        self.solution = solution
        self.stepIndex = max(0, min(stepIndex, solution.count))
        self.checkpointInterval = max(1, checkpointInterval)
        self.checkpoints = [0: initialState]
    }

    public var totalSteps: Int {
        solution.count
    }

    public func state(at step: Int) -> CubeState {
        let clampedStep = clampStep(step)
        if let checkpoint = checkpoints[clampedStep] {
            return checkpoint
        }

        let nearestStep = bestCheckpointStep(atOrBefore: clampedStep)
        let nearestState = checkpoints[nearestStep] ?? initialState
        if clampedStep == nearestStep {
            return nearestState
        }

        let moves = Array(solution[nearestStep..<clampedStep])
        return CubeReducer.apply(moves, to: nearestState)
    }

    public func currentState() -> CubeState {
        state(at: stepIndex)
    }

    public func currentMove() -> Move? {
        guard stepIndex < solution.count else { return nil }
        return solution[stepIndex]
    }

    @discardableResult
    public mutating func next() -> CubeState {
        guard stepIndex < solution.count else {
            return currentState()
        }

        stepIndex += 1
        let state = state(at: stepIndex)
        cacheCheckpointIfNeeded(step: stepIndex, state: state)
        return state
    }

    @discardableResult
    public mutating func back() -> CubeState {
        guard stepIndex > 0 else {
            return currentState()
        }

        stepIndex -= 1
        return state(at: stepIndex)
    }

    @discardableResult
    public mutating func jump(to step: Int) -> CubeState {
        stepIndex = clampStep(step)
        let state = state(at: stepIndex)
        cacheCheckpointIfNeeded(step: stepIndex, state: state)
        return state
    }

    public func progressText() -> String {
        "\(stepIndex)/\(solution.count)"
    }

    public func isSolvedStep() -> Bool {
        stepIndex >= solution.count
    }

    public mutating func restart() -> CubeState {
        stepIndex = 0
        return initialState
    }

    private func clampStep(_ step: Int) -> Int {
        max(0, min(step, solution.count))
    }

    private func bestCheckpointStep(atOrBefore step: Int) -> Int {
        checkpoints.keys
            .filter { $0 <= step }
            .max() ?? 0
    }

    private mutating func cacheCheckpointIfNeeded(step: Int, state: CubeState) {
        guard step == solution.count || step.isMultiple(of: checkpointInterval) else { return }
        checkpoints[step] = state
    }
}
