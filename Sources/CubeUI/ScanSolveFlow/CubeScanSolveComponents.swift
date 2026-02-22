#if canImport(SwiftUI)

import SwiftUI
import CubeCore

struct FaceGridView: View {
    let grid: CubeFaceGrid
    let highlightedIndices: Set<Int>
    let onTap: ((Int) -> Void)?

    init(grid: CubeFaceGrid, highlightedIndices: Set<Int> = [], onTap: ((Int) -> Void)? = nil) {
        self.grid = grid
        self.highlightedIndices = highlightedIndices
        self.onTap = onTap
    }

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { column in
                        let index = row * 3 + column
                        Rectangle()
                            .fill(swiftUIColor(for: grid[index]))
                            .overlay(
                                Rectangle()
                                    .stroke(highlightedIndices.contains(index) ? Color.red : Color.black.opacity(0.35), lineWidth: highlightedIndices.contains(index) ? 3 : 1)
                            )
                            .frame(width: 42, height: 42)
                            .onTapGesture {
                                onTap?(index)
                            }
                    }
                }
            }
        }
    }
}

struct FaceBadgeView: View {
    let face: FaceId
    let isComplete: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text(face.rawValue)
                .font(.caption.monospaced().bold())
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isComplete ? Color.green : Color.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.thinMaterial, in: Capsule())
    }
}

func swiftUIColor(for color: CubeColor) -> Color {
    switch color {
    case .white:
        return Color.white
    case .yellow:
        return Color.yellow
    case .red:
        return Color.red
    case .orange:
        return Color.orange
    case .blue:
        return Color.blue
    case .green:
        return Color.green
    }
}

#endif
