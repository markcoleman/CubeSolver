#if canImport(SwiftUI)

import Foundation
import SwiftUI
import CubeCore

public enum SolvePlaybackSpeed: Double, CaseIterable, Identifiable, Sendable {
    case half = 0.5
    case normal = 1.0
    case double = 2.0

    public var id: Double { rawValue }

    public var label: String {
        switch self {
        case .half:
            return "0.5x"
        case .normal:
            return "1x"
        case .double:
            return "2x"
        }
    }
}

@MainActor
public final class SolveModeViewModel: ObservableObject {
    @Published public private(set) var displayedState: CubeState
    @Published public private(set) var stepIndex: Int
    @Published public private(set) var totalSteps: Int
    @Published public private(set) var currentMove: Move?
    @Published public private(set) var currentInstruction: MoveInstruction?
    @Published public private(set) var progressText: String
    @Published public private(set) var isAnimating = false
    @Published public private(set) var isPlaying = false
    @Published public private(set) var isSolved = false
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var requiresOrientationConfirmation: Bool
    @Published public private(set) var orientationConfirmed: Bool
    @Published public var playbackSpeed: SolvePlaybackSpeed {
        didSet {
            if let configurableAnimator = animator as? ConfigurableCubeMoveAnimator {
                configurableAnimator.speedMultiplier = playbackSpeed.rawValue
            }
        }
    }

    public let solution: [Move]
    public let orientation: SolveOrientation?

    private var engine: SolveModeEngine
    private let renderer: CubeRenderer
    private var animator: CubeMoveAnimator
    private let formatter: MoveInstructionFormatter
    private var playbackTask: Task<Void, Never>?

    public var rendererBridge: SolveModeRendererBridge? {
        renderer as? SolveModeRendererBridge
    }

    public init(
        initialState: CubeState,
        solution: [Move],
        renderer: CubeRenderer? = nil,
        rendererBridge: SolveModeRendererBridge? = nil,
        animator: CubeMoveAnimator = TimedCubeMoveAnimator(),
        requireOrientationConfirmation: Bool = false,
        initialSpeed: SolvePlaybackSpeed = .normal,
        initialErrorMessage: String? = nil
    ) {
        self.solution = solution
        self.orientation = SolveOrientation.from(state: initialState)
        self.formatter = MoveInstructionFormatter(orientation: orientation)
        self.engine = SolveModeEngine(initialState: initialState, solution: solution)
        self.renderer = renderer ?? rendererBridge ?? SolveModeRendererBridge(initialState: initialState)
        self.animator = animator
        self.requiresOrientationConfirmation = requireOrientationConfirmation
        self.orientationConfirmed = !requireOrientationConfirmation
        self.playbackSpeed = initialSpeed

        displayedState = initialState
        stepIndex = 0
        totalSteps = solution.count
        currentMove = solution.first
        currentInstruction = solution.first.map(formatter.instruction(for:))
        progressText = "0/\(solution.count)"
        isSolved = solution.isEmpty
        errorMessage = initialErrorMessage

        if let configurableAnimator = self.animator as? ConfigurableCubeMoveAnimator {
            configurableAnimator.speedMultiplier = initialSpeed.rawValue
        }

        self.renderer.setState(initialState)
    }

    deinit {
        playbackTask?.cancel()
    }

    public func confirmOrientation() {
        orientationConfirmed = true
    }

    public func nextStep() {
        guard orientationConfirmed else { return }
        guard !isAnimating else { return }
        guard let move = engine.currentMove() else {
            isSolved = true
            isPlaying = false
            return
        }

        isAnimating = true
        animator.animate(move: move, on: renderer) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let newState = self.engine.next()
                self.finishTransition(newState: newState)
            }
        }
    }

    public func previousStep() {
        guard orientationConfirmed else { return }
        guard !isAnimating else { return }
        guard stepIndex > 0 else { return }

        isAnimating = true
        let inverseMove = solution[stepIndex - 1].inverse
        animator.animate(move: inverseMove, on: renderer) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let newState = self.engine.back()
                self.finishTransition(newState: newState)
            }
        }
    }

    public func jump(to step: Int) {
        guard orientationConfirmed else { return }
        guard !isAnimating else { return }
        stopPlayback()

        let newState = engine.jump(to: step)
        renderer.setState(newState)
        renderer.clearHighlight()
        syncFromEngine(newState: newState)
    }

    public func restart() {
        guard !isAnimating else { return }
        stopPlayback()

        let state = engine.restart()
        renderer.setState(state)
        renderer.clearHighlight()
        syncFromEngine(newState: state)
    }

    public func togglePlayPause() {
        guard orientationConfirmed else { return }

        if isPlaying {
            stopPlayback()
            return
        }

        guard !engine.isSolvedStep() else { return }
        isPlaying = true
        startPlaybackLoop()
    }

    public func stopPlayback() {
        isPlaying = false
        playbackTask?.cancel()
        playbackTask = nil
    }

    private func startPlaybackLoop() {
        playbackTask?.cancel()
        playbackTask = Task { [weak self] in
            while let self, !Task.isCancelled, self.isPlaying {
                if self.engine.isSolvedStep() {
                    self.isPlaying = false
                    self.isSolved = true
                    return
                }

                if !self.isAnimating {
                    self.nextStep()
                }

                let delay = UInt64((0.78 / self.playbackSpeed.rawValue) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: max(80_000_000, delay))
            }
        }
    }

    private func finishTransition(newState: CubeState) {
        renderer.setState(newState)
        renderer.clearHighlight()
        syncFromEngine(newState: newState)
        isAnimating = false

        if engine.isSolvedStep() {
            isSolved = true
            isPlaying = false
        }
    }

    private func syncFromEngine(newState: CubeState) {
        displayedState = newState
        stepIndex = engine.stepIndex
        totalSteps = engine.totalSteps
        progressText = engine.progressText()
        currentMove = engine.currentMove()
        currentInstruction = currentMove.map(formatter.instruction(for:))
        isSolved = engine.isSolvedStep()
    }
}

#endif
