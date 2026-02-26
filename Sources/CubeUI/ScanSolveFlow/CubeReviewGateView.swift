#if canImport(SwiftUI)

import SwiftUI
import CubeCore

public struct CubeReviewGateView: View {
    @ObservedObject private var viewModel: CubeScanSolveFlowViewModel
    private let onConfirmReview: () -> Void
    private let onEditFace: (FaceId) -> Void
    private let onRescanFace: (FaceId) -> Void

    @State private var selectedFaceForActions: FaceId?
    @State private var showingFaceActions = false

    public init(
        viewModel: CubeScanSolveFlowViewModel,
        onConfirmReview: @escaping () -> Void,
        onEditFace: @escaping (FaceId) -> Void,
        onRescanFace: @escaping (FaceId) -> Void
    ) {
        self.viewModel = viewModel
        self.onConfirmReview = onConfirmReview
        self.onEditFace = onEditFace
        self.onRescanFace = onRescanFace
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Review every captured face before solving.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Tap any face to edit stickers or re-scan that side.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    cubeNet
                }
                .padding()
            }
            .navigationTitle("Review Faces")
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 8) {
                    Button {
                        onConfirmReview()
                    } label: {
                        Label("All Faces Verified", systemImage: "checkmark.seal.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.needsReview)
                    .accessibilityIdentifier("confirmFaceReviewButton")
                }
                .padding()
                .background(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Divider()
                }
            }
        }
        .confirmationDialog(
            "Face Actions",
            isPresented: $showingFaceActions,
            titleVisibility: .visible
        ) {
            if let selectedFaceForActions {
                Button("Edit \(selectedFaceForActions.displayName) Face") {
                    onEditFace(selectedFaceForActions)
                }

                Button("Re-scan \(selectedFaceForActions.displayName) Face") {
                    onRescanFace(selectedFaceForActions)
                }
            }

            Button("Cancel", role: .cancel) {}
        }
    }

    private var cubeNet: some View {
        let tileWidth: CGFloat = 94
        let spacing: CGFloat = 10
        let netWidth = (tileWidth * 4) + (spacing * 3)
        let inset = tileWidth + spacing

        return ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: spacing) {
                HStack(spacing: spacing) {
                    Spacer().frame(width: inset)
                    faceTile(for: .up, width: tileWidth)
                    Spacer().frame(width: inset * 2 + tileWidth + spacing)
                }

                HStack(spacing: spacing) {
                    faceTile(for: .left, width: tileWidth)
                    faceTile(for: .front, width: tileWidth)
                    faceTile(for: .right, width: tileWidth)
                    faceTile(for: .back, width: tileWidth)
                }

                HStack(spacing: spacing) {
                    Spacer().frame(width: inset)
                    faceTile(for: .down, width: tileWidth)
                    Spacer().frame(width: inset * 2 + tileWidth + spacing)
                }
            }
            .frame(minWidth: netWidth + (inset * 2), alignment: .leading)
            .padding(.vertical, 6)
        }
    }

    private func faceTile(for face: FaceId, width: CGFloat) -> some View {
        let scanned = viewModel.scannedFaces[face]
        let isCaptured = scanned != nil
        let centerMatches = scanned?.grid.center == face.expectedCenterColor

        return Button {
            selectedFaceForActions = face
            showingFaceActions = true
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(face.displayName)
                        .font(.caption.weight(.semibold))
                    Spacer(minLength: 0)
                    if isCaptured {
                        Image(systemName: centerMatches ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(centerMatches ? .green : .orange)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                if let scanned {
                    FaceGridView(grid: scanned.grid)
                        .scaleEffect(0.45, anchor: .topLeading)
                        .frame(width: 62, height: 62, alignment: .topLeading)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.18))
                        .frame(width: 62, height: 62)
                }

                Text(isCaptured ? "Captured" : "Missing")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(8)
            .frame(width: width, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor(for: isCaptured, centerMatches: centerMatches), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isCaptured)
        .accessibilityIdentifier("reviewFaceTile_\(face.rawValue)")
    }

    private func borderColor(for isCaptured: Bool, centerMatches: Bool?) -> Color {
        guard isCaptured else { return .red.opacity(0.45) }
        return centerMatches == true ? .green.opacity(0.5) : .orange.opacity(0.6)
    }
}

#endif
