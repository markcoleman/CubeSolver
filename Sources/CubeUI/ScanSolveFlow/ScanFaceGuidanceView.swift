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

                RotationCoachBadge(cue: rotationCue)

                Text(rotationCue.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Drag mini cube to inspect orientation. Double-tap to reset.")
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

    private var rotationCue: RotationCue {
        guard let previous = previousCompletedFace else {
            return RotationCue(
                symbol: "viewfinder.circle.fill",
                headline: "Show \(targetFace.displayName) Face",
                detail: "Start by showing the \(targetFace.displayName.lowercased()) center directly to the camera."
            )
        }

        switch (previous, targetFace) {
        case (.up, .right):
            return RotationCue(
                symbol: "arrow.uturn.right.circle.fill",
                headline: "Rotate Right 90°",
                detail: turnHint
            )
        case (.right, .front), (.down, .left), (.left, .back):
            return RotationCue(
                symbol: "arrow.uturn.left.circle.fill",
                headline: "Rotate Left 90°",
                detail: turnHint
            )
        case (.front, .down):
            return RotationCue(
                symbol: "arrow.up.circle.fill",
                headline: "Tilt Up 90°",
                detail: turnHint
            )
        default:
            return RotationCue(
                symbol: "arrow.triangle.2.circlepath.circle.fill",
                headline: "Rotate to Match Center",
                detail: turnHint
            )
        }
    }
}

private struct RotationCue: Equatable {
    let symbol: String
    let headline: String
    let detail: String
}

private struct RotationCoachBadge: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let cue: RotationCue
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: cue.symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.blue)
                .scaleEffect(reduceMotion ? 1 : (pulse ? 1.09 : 0.96))

            Text(cue.headline)
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.12), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.blue.opacity(0.35), lineWidth: 1)
        )
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
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
