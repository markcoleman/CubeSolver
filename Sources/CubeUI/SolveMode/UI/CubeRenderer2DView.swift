#if canImport(SwiftUI)

import SwiftUI
import CubeCore

public struct CubeRenderer2DView: View {
    let state: CubeState
    let highlightedMove: Move?

    public init(state: CubeState, highlightedMove: Move?) {
        self.state = state
        self.highlightedMove = highlightedMove
    }

    public var body: some View {
        GeometryReader { geometry in
            let faceSize = min(geometry.size.width / 4.6, geometry.size.height / 3.6)
            let overlay = highlightedMove.map(MoveOverlayDescriptor.init(move:))

            VStack(spacing: faceSize * 0.08) {
                HStack(spacing: faceSize * 0.08) {
                    Spacer()
                        .frame(width: faceSize)
                    faceView(.up, faceSize: faceSize, overlay: overlay)
                    Spacer()
                        .frame(width: faceSize * 2 + faceSize * 0.08)
                }

                HStack(spacing: faceSize * 0.08) {
                    faceView(.left, faceSize: faceSize, overlay: overlay)
                    faceView(.front, faceSize: faceSize, overlay: overlay)
                    faceView(.right, faceSize: faceSize, overlay: overlay)
                    faceView(.back, faceSize: faceSize, overlay: overlay)
                }

                HStack(spacing: faceSize * 0.08) {
                    Spacer()
                        .frame(width: faceSize)
                    faceView(.down, faceSize: faceSize, overlay: overlay)
                    Spacer()
                        .frame(width: faceSize * 2 + faceSize * 0.08)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func faceView(_ face: Face, faceSize: CGFloat, overlay: MoveOverlayDescriptor?) -> some View {
        let stickers = state.faces[face] ?? Array(repeating: .white, count: 9)
        let isHighlighted = overlay?.face == face

        return ZStack(alignment: .topTrailing) {
            VStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { column in
                            let index = row * 3 + column
                            RoundedRectangle(cornerRadius: 2)
                                .fill(swiftUIColor(for: stickers[safe: index] ?? .white))
                                .frame(width: faceSize / 3.4, height: faceSize / 3.4)
                        }
                    }
                }
            }
            .padding(4)
            .frame(width: faceSize, height: faceSize)
            .background(Color.black.opacity(0.32), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHighlighted ? Color.accentColor : Color.white.opacity(0.2), lineWidth: isHighlighted ? 3 : 1)
            )

            if isHighlighted, let overlay {
                moveOverlayBadge(overlay)
                    .offset(x: 6, y: -6)
            }
        }
    }

    private func moveOverlayBadge(_ overlay: MoveOverlayDescriptor) -> some View {
        HStack(spacing: 4) {
            Image(systemName: overlay.iconName)
                .font(.caption.weight(.bold))
            if overlay.isDoubleTurn {
                Text("2x")
                    .font(.caption2.bold())
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.9), in: Capsule())
    }
}

private struct MoveOverlayDescriptor {
    let face: Face
    let iconName: String
    let isDoubleTurn: Bool

    init(move: Move) {
        self.face = move.affectedFace
        self.isDoubleTurn = move.direction == .doubleTurn
        switch move.direction {
        case .clockwise:
            iconName = "arrow.clockwise"
        case .counterClockwise:
            iconName = "arrow.counterclockwise"
        case .doubleTurn:
            iconName = "arrow.triangle.2.circlepath"
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

#endif
