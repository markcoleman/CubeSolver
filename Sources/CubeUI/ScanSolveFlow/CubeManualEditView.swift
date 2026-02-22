#if canImport(SwiftUI)

import SwiftUI
import CubeCore

public struct CubeManualEditView: View {
    @ObservedObject private var viewModel: CubeScanSolveFlowViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFace: FaceId = .up
    @State private var selectedColor: CubeColor = .white

    public init(viewModel: CubeScanSolveFlowViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Face", selection: $selectedFace) {
                        ForEach(viewModel.scanOrder, id: \.self) { face in
                            Text(face.displayName).tag(face)
                        }
                    }
                    .pickerStyle(.segmented)

                    if let scanned = viewModel.scannedFaces[selectedFace] {
                        Text("Tap a sticker to set \(selectedColor.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        FaceGridView(
                            grid: scanned.grid,
                            highlightedIndices: conflictIndices(for: selectedFace)
                        ) { index in
                            viewModel.updateSticker(face: selectedFace, index: index, color: selectedColor)
                        }

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
                        Text("Face not scanned yet.")
                            .foregroundStyle(.secondary)
                    }

                    colorPalette

                    HStack(spacing: 12) {
                        Button("Reset Face", systemImage: "arrow.counterclockwise") {
                            viewModel.resetFace(selectedFace)
                        }
                        .buttonStyle(.bordered)

                        Button("Re-scan Face", systemImage: "camera.rotate") {
                            viewModel.markFaceForRescan(selectedFace)
                            dismiss()
                        }
                        .buttonStyle(.bordered)
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
                }
            }
        }
    }

    private var colorPalette: some View {
        HStack(spacing: 10) {
            ForEach(CubeColor.allCases, id: \.self) { color in
                Circle()
                    .fill(swiftUIColor(for: color))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Circle()
                            .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                    )
                    .onTapGesture {
                        selectedColor = color
                    }
                    .accessibilityLabel("Set color \(color.rawValue)")
            }
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
