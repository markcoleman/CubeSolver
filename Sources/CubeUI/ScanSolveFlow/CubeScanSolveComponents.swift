#if canImport(SwiftUI)

import SwiftUI
import CubeCore

struct FaceGridView: View {
    let grid: CubeFaceGrid
    let highlightedIndices: Set<Int>
    let onTap: ((Int) -> Void)?
    private let cellSide: CGFloat = 46

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
                        stickerCell(row: row, column: column, index: index)
                    }
                }
            }
        }
        .accessibilityElement(children: isInteractive ? .contain : .ignore)
        .accessibilityLabel(isInteractive ? "Editable face grid" : "Face grid preview")
    }

    private var isInteractive: Bool {
        onTap != nil
    }

    @ViewBuilder
    private func stickerCell(row: Int, column: Int, index: Int) -> some View {
        let cell = Rectangle()
            .fill(swiftUIColor(for: grid[index]))
            .overlay(
                Rectangle()
                    .stroke(
                        highlightedIndices.contains(index) ? Color.red : Color.black.opacity(0.35),
                        lineWidth: highlightedIndices.contains(index) ? 3 : 1
                    )
            )
            .frame(width: cellSide, height: cellSide)

        if let onTap {
            Button {
                onTap(index)
            } label: {
                cell
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityLabel("Sticker row \(row + 1), column \(column + 1)")
            .accessibilityValue("\(grid[index].rawValue) color")
            .accessibilityHint("Sets this sticker to the selected color.")
            .accessibilityIdentifier("cell_\(row)_\(column)")
        } else {
            cell
        }
    }
}

struct FaceBadgeView: View {
    let face: FaceId
    let isComplete: Bool
    var isCurrent: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isComplete ? Color.green : Color.secondary)
            Text(face.displayName)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .frame(minHeight: 44)
        .background((isCurrent ? Color.blue.opacity(0.15) : Color.clear), in: Capsule())
        .background(.thinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(isCurrent ? Color.blue.opacity(0.45) : Color.clear, lineWidth: 1.5)
        )
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
