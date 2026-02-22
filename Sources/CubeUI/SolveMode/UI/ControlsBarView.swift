#if canImport(SwiftUI)

import SwiftUI

public struct ControlsBarView: View {
    let stepIndex: Int
    let totalSteps: Int
    let progressText: String
    let isAnimating: Bool
    let isPlaying: Bool
    @Binding var speed: SolvePlaybackSpeed
    let onBack: () -> Void
    let onNext: () -> Void
    let onPlayPause: () -> Void
    let onRestart: () -> Void
    let onJump: (Int) -> Void

    public init(
        stepIndex: Int,
        totalSteps: Int,
        progressText: String,
        isAnimating: Bool,
        isPlaying: Bool,
        speed: Binding<SolvePlaybackSpeed>,
        onBack: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onPlayPause: @escaping () -> Void,
        onRestart: @escaping () -> Void,
        onJump: @escaping (Int) -> Void
    ) {
        self.stepIndex = stepIndex
        self.totalSteps = totalSteps
        self.progressText = progressText
        self.isAnimating = isAnimating
        self.isPlaying = isPlaying
        _speed = speed
        self.onBack = onBack
        self.onNext = onNext
        self.onPlayPause = onPlayPause
        self.onRestart = onRestart
        self.onJump = onJump
    }

    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Progress")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(progressText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Slider(
                value: Binding(
                    get: { Double(stepIndex) },
                    set: { onJump(Int($0.rounded())) }
                ),
                in: 0...Double(max(totalSteps, 1)),
                step: 1
            )
            .disabled(isAnimating)
            .accessibilityLabel("Step slider")
            .accessibilityValue("Step \(stepIndex) of \(totalSteps)")

            HStack(spacing: 10) {
                Button(action: onRestart) {
                    Image(systemName: "arrow.counterclockwise")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .disabled(stepIndex == 0 || isAnimating)

                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .disabled(stepIndex == 0 || isAnimating)

                Button(action: onPlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .frame(width: 48, height: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(stepIndex >= totalSteps || isAnimating)

                Button(action: onNext) {
                    Image(systemName: "chevron.right")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .disabled(stepIndex >= totalSteps || isAnimating)

                Picker("Speed", selection: $speed) {
                    ForEach(SolvePlaybackSpeed.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 90)
                .disabled(isAnimating)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#endif
