#if canImport(SwiftUI)

import SwiftUI
import CubeCore

public struct FaceConfirmView: View {
    let face: ScannedFaceData
    let centerMismatch: CubeScanSolveFlowViewModel.PendingCenterMismatch?
    let onConfirm: () -> Void
    let onRescan: () -> Void

    public init(
        face: ScannedFaceData,
        centerMismatch: CubeScanSolveFlowViewModel.PendingCenterMismatch? = nil,
        onConfirm: @escaping () -> Void,
        onRescan: @escaping () -> Void
    ) {
        self.face = face
        self.centerMismatch = centerMismatch
        self.onConfirm = onConfirm
        self.onRescan = onRescan
    }

    public var body: some View {
        VStack(spacing: 20) {
            Text("Confirm \(face.id.displayName) Face")
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)

            FaceGridView(grid: face.grid)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Captured \(face.id.displayName) face preview")
                .accessibilityValue("Confidence \(Int(face.confidence * 100)) percent")
                .accessibilityIdentifier("capturedFacePreview")

            Text("Confidence: \(Int(face.confidence * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Capture confidence")
                .accessibilityValue("\(Int(face.confidence * 100)) percent")

            if let mismatch = centerMismatch {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Center sticker mismatch")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(swiftUIColor(for: mismatch.expectedCenter))
                            .frame(width: 12, height: 12)
                        Text("Expected: \(mismatch.expectedCenter.rawValue.capitalized)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {
                        Circle()
                            .fill(swiftUIColor(for: mismatch.detectedCenter))
                            .frame(width: 12, height: 12)
                        Text("Detected: \(mismatch.detectedCenter.rawValue.capitalized)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("For reliable solves, this face cannot be accepted. Rotate and re-scan this face.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.11), in: RoundedRectangle(cornerRadius: 10))
            }

            HStack(spacing: 12) {
                Button("Re-scan", systemImage: "arrow.counterclockwise") {
                    onRescan()
                }
                .buttonStyle(.bordered)
                .accessibilityHint("Discard this capture and scan this face again.")
                .accessibilityIdentifier("rescanPendingFaceButton")

                Button("Looks Good", systemImage: "checkmark") {
                    onConfirm()
                }
                .disabled(centerMismatch != nil)
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Accept this face and continue.")
                .accessibilityIdentifier("confirmPendingFaceButton")
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#endif
