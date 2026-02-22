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

            FaceGridView(grid: face.grid)

            Text("Confidence: \(Int(face.confidence * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("Re-scan", systemImage: "arrow.counterclockwise") {
                    onRescan()
                }
                .buttonStyle(.bordered)

                Button("Looks Good", systemImage: "checkmark") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#endif
