#if canImport(SwiftUI)

import SwiftUI
import CubeCore

public struct CubeRenderer3DView: View {
    @ObservedObject private var bridge: SolveModeRendererBridge
    private let allowInteraction: Bool

    public init(bridge: SolveModeRendererBridge, allowInteraction: Bool = true) {
        self.bridge = bridge
        self.allowInteraction = allowInteraction
    }

    public var body: some View {
        #if canImport(SceneKit)
        ZStack(alignment: .topTrailing) {
            AnimatedCube3DView(
                cube: bridge.state.toRubiksCube(),
                currentMove: Binding(
                    get: { bridge.activeAnimationMove },
                    set: { newValue in
                        guard bridge.activeAnimationMove != newValue else { return }
                        bridge.activeAnimationMove = newValue
                    }
                )
            )
            .allowsHitTesting(allowInteraction)
            .accessibilityLabel("3D cube visualization")

            if let move = bridge.highlightedMove {
                faceBadge(for: move)
                    .padding(12)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        #else
        CubeRenderer2DView(state: bridge.state, highlightedMove: bridge.highlightedMove)
        #endif
    }

    private func faceBadge(for move: Move) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("Turning \(move.affectedFace.displayName)")
                .font(.caption.weight(.semibold))
            Text(move.notation)
                .font(.title3.monospaced().weight(.bold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .foregroundStyle(.white)
        .background(Color.accentColor.opacity(0.92), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current move \(move.notation)")
    }
}

private extension Face {
    var displayName: String {
        switch self {
        case .up:
            return "UP"
        case .down:
            return "DOWN"
        case .left:
            return "LEFT"
        case .right:
            return "RIGHT"
        case .front:
            return "FRONT"
        case .back:
            return "BACK"
        }
    }
}

#endif
