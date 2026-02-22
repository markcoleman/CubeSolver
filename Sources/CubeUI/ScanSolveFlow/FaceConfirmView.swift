#if canImport(SwiftUI)

import SwiftUI
import CubeCore

public struct FaceConfirmView: View {
    let face: ScannedFaceData
    let onConfirm: () -> Void
    let onRescan: () -> Void

    public init(face: ScannedFaceData, onConfirm: @escaping () -> Void, onRescan: @escaping () -> Void) {
        self.face = face
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
