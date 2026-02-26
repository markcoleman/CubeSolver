#if canImport(SwiftUI)

import SwiftUI
import CubeCore
#if canImport(OSLog)
import OSLog
#endif

public enum SolveRendererMode: String, CaseIterable, Identifiable, Sendable {
    case flat2D = "2D"
    case scene3D = "3D"

    public var id: String { rawValue }
}

public struct SolveModeView: View {
    #if canImport(OSLog)
    private static let logger = Logger(subsystem: "com.cubesolver.ui", category: "SolveMode")
    #endif

    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var rendererBridge: SolveModeRendererBridge
    @StateObject private var viewModel: SolveModeViewModel

    @SceneStorage("solve_mode_step_index") private var persistedStepIndex = 0
    @State private var didRestoreState = false
    @State private var showAllMoves = false
    @State private var rendererMode: SolveRendererMode

    private let solution: [Move]

    public init(
        state: CubeState,
        solution: [Move],
        requireOrientationConfirmation: Bool = false,
        initialSpeed: SolvePlaybackSpeed = .normal,
        startIn3D: Bool = false
    ) {
        let bridge = SolveModeRendererBridge(initialState: state)
        _rendererBridge = StateObject(wrappedValue: bridge)
        _viewModel = StateObject(
            wrappedValue: SolveModeViewModel(
                initialState: state,
                solution: solution,
                rendererBridge: bridge,
                animator: TimedCubeMoveAnimator(),
                requireOrientationConfirmation: requireOrientationConfirmation,
                initialSpeed: initialSpeed
            )
        )
        _rendererMode = State(initialValue: startIn3D ? .scene3D : .flat2D)
        self.solution = solution
    }

    public init(
        state: CubeState,
        solutionNotation: [String],
        requireOrientationConfirmation: Bool = false,
        initialSpeed: SolvePlaybackSpeed = .normal,
        startIn3D: Bool = false,
        parser: CubeMoveParser = CubeMoveParser()
    ) {
        let parsedMoves: [Move]
        let initialErrorMessage: String?

        switch parser.parse(solutionNotation) {
        case .success(let moves):
            parsedMoves = moves
            initialErrorMessage = nil
        case .failure(let error):
            parsedMoves = []
            initialErrorMessage = error.localizedDescription
            #if canImport(OSLog)
            Self.logger.error("Solve mode move parse failed: \(error.localizedDescription, privacy: .public)")
            #endif
        }

        let bridge = SolveModeRendererBridge(initialState: state)
        _rendererBridge = StateObject(wrappedValue: bridge)
        _viewModel = StateObject(
            wrappedValue: SolveModeViewModel(
                initialState: state,
                solution: parsedMoves,
                rendererBridge: bridge,
                animator: TimedCubeMoveAnimator(),
                requireOrientationConfirmation: requireOrientationConfirmation,
                initialSpeed: initialSpeed,
                initialErrorMessage: initialErrorMessage
            )
        )
        _rendererMode = State(initialValue: startIn3D ? .scene3D : .flat2D)
        solution = parsedMoves
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                visualizationCard
                moveCard

                if let errorMessage = viewModel.errorMessage {
                    errorCard(errorMessage)
                }

                if requiresOrientationLock {
                    orientationLockCard
                }

                ControlsBarView(
                    stepIndex: viewModel.stepIndex,
                    totalSteps: viewModel.totalSteps,
                    progressText: viewModel.progressText,
                    isAnimating: viewModel.isAnimating,
                    isPlaying: viewModel.isPlaying,
                    speed: $viewModel.playbackSpeed,
                    onBack: viewModel.previousStep,
                    onNext: viewModel.nextStep,
                    onPlayPause: viewModel.togglePlayPause,
                    onRestart: viewModel.restart,
                    onJump: viewModel.jump
                )
                .disabled(requiresOrientationLock)

                if !solution.isEmpty {
                    movesList
                }
            }
            .padding()
        }
        .navigationTitle("Solve Mode")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            restoreStateIfNeeded()
        }
        .onDisappear {
            viewModel.stopPlayback()
        }
        .onChange(of: viewModel.stepIndex) { _, newStep in
            persistedStepIndex = newStep
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase != .active else { return }
            viewModel.stopPlayback()
            persistedStepIndex = viewModel.stepIndex
        }
    }

    private var visualizationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Cube")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()

                #if canImport(SceneKit)
                Picker("Renderer", selection: $rendererMode) {
                    ForEach(SolveRendererMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 120)
                .accessibilityLabel("Renderer mode")
                #endif

                if viewModel.isSolved {
                    Label("Solved", systemImage: "sparkles")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }

            Group {
                if rendererMode == .scene3D {
                    CubeRenderer3DView(bridge: rendererBridge)
                } else {
                    CubeRenderer2DView(
                        state: rendererBridge.state,
                        highlightedMove: rendererBridge.highlightedMove
                    )
                }
            }
            .frame(height: 290)
            .background(Color.black.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var moveCard: some View {
        MoveCardView(
            instruction: viewModel.currentInstruction,
            isSolved: viewModel.isSolved
        )
    }

    private var requiresOrientationLock: Bool {
        viewModel.requiresOrientationConfirmation && !viewModel.orientationConfirmed
    }

    private var orientationLockCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Orientation Lock")
                .font(.headline)

            Text("Confirm your holding orientation before starting. This keeps face instructions consistent.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let orientation = viewModel.orientation {
                HStack(spacing: 12) {
                    orientationChip(title: "Front", color: orientation.frontColor)
                    orientationChip(title: "Up", color: orientation.upColor)
                }
            }

            Button("Confirm Orientation") {
                viewModel.confirmOrientation()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .contain)
    }

    private var movesList: some View {
        DisclosureGroup(isExpanded: $showAllMoves) {
            LazyVStack(spacing: 6) {
                ForEach(Array(solution.enumerated()), id: \.offset) { item in
                    let index = item.offset
                    let move = item.element
                    let isCompleted = index < viewModel.stepIndex
                    let isCurrent = index == viewModel.stepIndex && !viewModel.isSolved

                    Button {
                        viewModel.jump(to: index)
                    } label: {
                        HStack(spacing: 10) {
                            Text("\(index + 1).")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 34, alignment: .trailing)

                            Text(move.notation)
                                .font(.body.monospaced().weight(.semibold))

                            Spacer()

                            if isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else if isCurrent {
                                Image(systemName: "arrowtriangle.left.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(isCurrent ? Color.accentColor.opacity(0.14) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isAnimating)
                    .accessibilityLabel("Move \(index + 1), \(move.notation)")
                }
            }
            .padding(.top, 8)
        } label: {
            Text("All Moves")
                .font(.headline)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func orientationChip(title: String, color: CubeColor) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(swiftUIColor(for: color))
                .frame(width: 18, height: 18)
            Text("\(title): \(color.name.uppercased())")
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.08), in: Capsule())
    }

    private func errorCard(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("Move Data Error")
                    .font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
    }

    private func restoreStateIfNeeded() {
        guard !didRestoreState else { return }
        didRestoreState = true

        guard persistedStepIndex > 0 else { return }
        viewModel.jump(to: persistedStepIndex)
    }
}

private extension CubeColor {
    var name: String {
        switch self {
        case .white:
            return "white"
        case .yellow:
            return "yellow"
        case .red:
            return "red"
        case .orange:
            return "orange"
        case .blue:
            return "blue"
        case .green:
            return "green"
        }
    }
}

#endif
