#if canImport(SwiftUI)

import SwiftUI
import CubeCore

public struct CubeManualEditView: View {
    @ObservedObject private var viewModel: CubeScanSolveFlowViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    @State private var selectedFace: FaceId
    @State private var selectedColor: CubeColor = .white

    public init(viewModel: CubeScanSolveFlowViewModel, initialFace: FaceId? = nil) {
        self.viewModel = viewModel
        _selectedFace = State(initialValue: initialFace ?? viewModel.scanOrder.first ?? .up)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    facePicker

                    if let scanned = viewModel.scannedFaces[selectedFace] {
                        Text("Selected color: \(selectedColor.rawValue). Tap any sticker to apply.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        FaceGridView(
                            grid: scanned.grid,
                            highlightedIndices: conflictIndices(for: selectedFace)
                        ) { index in
                            viewModel.updateSticker(face: selectedFace, index: index, color: selectedColor)
                        }
                        .accessibilityIdentifier("editableFaceView")

                        if let error = viewModel.validationError {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(error.message)
                                    .font(.subheadline.weight(.semibold))
                                Text(error.suggestedFix)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(10)
                            .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                        }
                    } else {
                        Text("Face not scanned yet. Capture it first, or switch to a captured face.")
                            .foregroundStyle(.secondary)
                    }

                    colorPalette

                    HStack(spacing: 12) {
                        Button("Reset Face", systemImage: "arrow.counterclockwise") {
                            viewModel.resetFace(selectedFace)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityHint("Resets this face to its default center color.")
                        .accessibilityIdentifier("resetFaceButton")

                        Button("Re-scan Face", systemImage: "camera.rotate") {
                            viewModel.markFaceForRescan(selectedFace)
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .accessibilityHint("Returns to scanning for this face.")
                        .accessibilityIdentifier("rescanFaceButton")
                    }
                }
                .padding()
            }
            .navigationTitle("Manual Edit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        viewModel.resumeWizard()
                        dismiss()
                    }
                    .accessibilityIdentifier("doneButton")
                }
            }
        }
    }

    private var colorPalette: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Input Color")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 46), spacing: 12)], alignment: .leading, spacing: 12) {
                ForEach(CubeColor.allCases, id: \.self) { color in
                    colorButton(for: color)
                }
            }
        }
        .accessibilityIdentifier("colorSelector")
    }

    private var facePicker: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                Picker("Face", selection: $selectedFace) {
                    ForEach(viewModel.scanOrder, id: \.self) { face in
                        Text(face.displayName).tag(face)
                    }
                }
                .pickerStyle(.menu)
            } else {
                Picker("Face", selection: $selectedFace) {
                    ForEach(viewModel.scanOrder, id: \.self) { face in
                        Text(face.displayName).tag(face)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .accessibilityIdentifier("faceSelector")
    }

    private func colorButton(for color: CubeColor) -> some View {
        let isSelected = selectedColor == color

        return Button {
            selectedColor = color
        } label: {
            ZStack {
                Circle()
                    .fill(swiftUIColor(for: color))

                Circle()
                    .stroke(isSelected ? Color.primary : Color.black.opacity(0.2), lineWidth: isSelected ? 3 : 1)

                if isSelected || differentiateWithoutColor {
                    Image(systemName: isSelected ? "checkmark" : "circle")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(selectionIconColor(for: color))
                        .opacity(isSelected ? 1 : 0.4)
                }
            }
            .frame(width: 46, height: 46)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(color.rawValue) color")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Sets the input color for the next sticker.")
        .accessibilityIdentifier("\(color.rawValue)ColorButton")
    }

    private func selectionIconColor(for color: CubeColor) -> Color {
        switch color {
        case .white, .yellow, .orange:
            return .black
        case .red, .blue, .green:
            return .white
        }
    }

    private func conflictIndices(for face: FaceId) -> Set<Int> {
        guard let scanned = viewModel.scannedFaces[face] else { return [] }

        let counts = totalCounts()
        let overflowColors = Set(
            counts
                .filter { $0.value > 9 }
                .map(\.key)
        )

        var indices = Set<Int>()
        for index in 0..<CubeFaceGrid.stickerCount where overflowColors.contains(scanned.grid[index]) {
            indices.insert(index)
        }
        return indices
    }

    private func totalCounts() -> [CubeColor: Int] {
        var counts: [CubeColor: Int] = [:]
        for color in CubeColor.allCases {
            counts[color] = 0
        }

        for scannedFace in viewModel.scannedFaces.values {
            for color in scannedFace.grid.stickers {
                counts[color, default: 0] += 1
            }
        }

        return counts
    }
}

#endif
