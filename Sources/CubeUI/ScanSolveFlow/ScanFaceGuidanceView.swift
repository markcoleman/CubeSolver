#if canImport(SwiftUI)

import SwiftUI
import CubeCore

struct ScanFaceGuidanceView: View {
    let targetFace: FaceId
    let scannedFaces: [FaceId: ScannedFaceData]
    let scanOrder: [FaceId]
    let isScanning: Bool

    var body: some View {
        HStack(spacing: 14) {
            RotatingScanCubeView(
                targetFace: targetFace,
                scannedFaces: scannedFaces,
                isScanning: isScanning,
                showsFaceLabels: true,
                autoRotate: true
            )
            .frame(width: 132, height: 112)

            VStack(alignment: .leading, spacing: 6) {
                Text("Next: \(targetFace.displayName) (\(targetFace.rawValue))")
                    .font(.headline)

                HStack(spacing: 8) {
                    Circle()
                        .fill(swiftUIColor(for: targetFace.expectedCenterColor))
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.primary.opacity(0.25), lineWidth: 1))
                    Text("Center should be \(targetFace.expectedCenterColorName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(turnHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Drag cube to rotate. Double-tap to reset.")
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.9))
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Scan guidance")
        .accessibilityValue("Target \(targetFace.displayName) face, center color \(targetFace.expectedCenterColorName).")
        .accessibilityIdentifier("scanFaceGuidanceCard")
    }

    private var previousCompletedFace: FaceId? {
        guard let currentIndex = scanOrder.firstIndex(of: targetFace),
              currentIndex > 0 else {
            return nil
        }

        let completedFaces = Set(scannedFaces.keys)

        for index in stride(from: currentIndex - 1, through: 0, by: -1) {
            let candidate = scanOrder[index]
            if completedFaces.contains(candidate) {
                return candidate
            }
        }

        return nil
    }

    private var turnHint: String {
        guard let previous = previousCompletedFace else {
            return "Start by showing the \(targetFace.displayName.lowercased()) center directly to the camera."
        }

        switch (previous, targetFace) {
        case (.up, .right):
            return "From Up, rotate the cube so the right side faces the camera."
        case (.right, .front):
            return "From Right, turn the cube slightly left to bring Front toward the camera."
        case (.front, .down):
            return "From Front, tilt the cube upward to reveal the Down face."
        case (.down, .left):
            return "From Down, rotate the cube so the left side faces the camera."
        case (.left, .back):
            return "From Left, rotate another quarter turn to show the Back face."
        default:
            return "Rotate until the \(targetFace.expectedCenterColorName.lowercased()) center sticker is in the guide."
        }
    }
}

extension FaceId {
    var expectedCenterColor: CubeColor {
        switch self {
        case .up:
            return .white
        case .right:
            return .blue
        case .front:
            return .red
        case .down:
            return .yellow
        case .left:
            return .green
        case .back:
            return .orange
        }
    }

    var expectedCenterColorName: String {
        switch expectedCenterColor {
        case .white:
            return "White"
        case .yellow:
            return "Yellow"
        case .red:
            return "Red"
        case .orange:
            return "Orange"
        case .blue:
            return "Blue"
        case .green:
            return "Green"
        }
    }
}

#endif
