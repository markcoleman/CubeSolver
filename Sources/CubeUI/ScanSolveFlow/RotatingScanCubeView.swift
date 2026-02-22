#if canImport(SwiftUI)

import SwiftUI
import CubeCore

struct RotatingScanCubeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let targetFace: FaceId
    let scannedFaces: [FaceId: ScannedFaceData]
    let isScanning: Bool
    var showsFaceLabels: Bool = true
    var autoRotate: Bool = true

    @State private var committedYaw: Double = 0
    @State private var committedPitch: Double?
    @GestureState private var dragInteraction: DragInteraction = .inactive

    var body: some View {
        let liveYawOffset = committedYaw + (Double(dragInteraction.translation.width) * 0.012)
        let basePitch = committedPitch ?? defaultPitch
        let livePitch = clampedPitch(basePitch - (Double(dragInteraction.translation.height) * 0.010))

        return TimelineView(
            .animation(
                minimumInterval: 1.0 / 24.0,
                paused: !autoRotate || reduceMotion || dragInteraction.isActive
            )
        ) { timeline in
            Canvas { context, size in
                drawCube(
                    in: context,
                    size: size,
                    at: timeline.date.timeIntervalSinceReferenceDate,
                    manualYaw: liveYawOffset,
                    manualPitch: livePitch
                )
            }
        }
        .contentShape(Rectangle())
        .highPriorityGesture(rotateGesture)
        .onTapGesture(count: 2) {
            withAnimation(.easeOut(duration: 0.2)) {
                committedYaw = 0
                committedPitch = nil
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("3D cube scan preview")
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(
            reduceMotion
                ? "Drag to rotate the cube. Motion effects are reduced."
                : "Drag to rotate the cube. Double tap to reset orientation."
        )
    }

    private func drawCube(
        in context: GraphicsContext,
        size: CGSize,
        at timestamp: TimeInterval,
        manualYaw: Double,
        manualPitch: Double
    ) {
        let elapsed = timestamp.truncatingRemainder(dividingBy: 18)
        let spinYaw = autoRotate ? (elapsed / 18) * (.pi * 2) : 0
        let yaw = spinYaw + manualYaw
        let pitch = manualPitch
        let pulse = CGFloat(0.5 + 0.5 * sin(timestamp * 3.2))

        let projections = projectedFaces(size: size, yaw: yaw, pitch: pitch)

        for projection in projections.sorted(by: { $0.depth < $1.depth }) {
            let facePath = Path { path in
                path.move(to: projection.points[0])
                path.addLine(to: projection.points[1])
                path.addLine(to: projection.points[2])
                path.addLine(to: projection.points[3])
                path.closeSubpath()
            }

            let faceGrid = scannedFaces[projection.id]?.grid
            drawFaceStickers(
                projection: projection,
                faceGrid: faceGrid,
                in: context
            )

            let borderColor: Color
            let borderWidth: CGFloat

            if projection.id == targetFace {
                borderColor = .blue
                borderWidth = 2.2 + pulse * 1.2
            } else if faceGrid != nil {
                borderColor = .green
                borderWidth = 1.8
            } else {
                borderColor = .secondary.opacity(0.5)
                borderWidth = 1.0
            }

            context.stroke(facePath, with: .color(borderColor), lineWidth: borderWidth)

            if showsFaceLabels {
                let center = projection.points.centerPoint
                context.draw(
                    Text(projection.id.rawValue)
                        .font(.caption2.monospaced().weight(.bold))
                        .foregroundColor(.white),
                    at: center
                )
            }
        }
    }

    private func drawFaceStickers(
        projection: FaceProjection,
        faceGrid: CubeFaceGrid?,
        in context: GraphicsContext
    ) {
        for row in 0..<3 {
            for column in 0..<3 {
                let u0 = CGFloat(column) / 3
                let u1 = CGFloat(column + 1) / 3
                let v0 = CGFloat(row) / 3
                let v1 = CGFloat(row + 1) / 3

                let p00 = bilinear(projection.points, u: u0, v: v0)
                let p10 = bilinear(projection.points, u: u1, v: v0)
                let p11 = bilinear(projection.points, u: u1, v: v1)
                let p01 = bilinear(projection.points, u: u0, v: v1)

                let cellPath = Path { path in
                    path.move(to: p00)
                    path.addLine(to: p10)
                    path.addLine(to: p11)
                    path.addLine(to: p01)
                    path.closeSubpath()
                }

                let index = row * 3 + column
                let stickerColor = faceGrid?[index] ?? projection.id.expectedCenterColor
                let opacity: CGFloat = faceGrid == nil ? 0.30 : 0.92

                context.fill(cellPath, with: .color(swiftUIColor(for: stickerColor).opacity(opacity)))
                context.stroke(cellPath, with: .color(.black.opacity(0.22)), lineWidth: 0.55)
            }
        }
    }

    private func projectedFaces(size: CGSize, yaw: Double, pitch: Double) -> [FaceProjection] {
        let cameraDistance = 4.5
        let scale = min(size.width, size.height) * 0.31

        func project(_ point: Vec3) -> CGPoint {
            let perspective = cameraDistance / (cameraDistance - point.z)
            return CGPoint(
                x: size.width * 0.5 + CGFloat(point.x * perspective) * scale,
                y: size.height * 0.52 - CGFloat(point.y * perspective) * scale
            )
        }

        return FaceId.allCases.compactMap { id in
            let definition = FaceDefinition.definition(for: id)
            let rotatedCorners = definition.corners.map { $0.rotated(yaw: yaw, pitch: pitch) }
            let rotatedNormal = definition.normal.rotated(yaw: yaw, pitch: pitch)

            guard rotatedNormal.z > 0.01 else {
                return nil
            }

            let points = rotatedCorners.map(project)
            let depth = rotatedCorners.map(\.z).reduce(0, +) / 4

            return FaceProjection(id: id, points: points, depth: depth)
        }
    }

    private func bilinear(_ corners: [CGPoint], u: CGFloat, v: CGFloat) -> CGPoint {
        let top = corners[0].lerp(to: corners[1], t: u)
        let bottom = corners[3].lerp(to: corners[2], t: u)
        return top.lerp(to: bottom, t: v)
    }

    private var accessibilityValue: String {
        let scanned = scannedFaces.keys.map(\.rawValue).sorted().joined(separator: ", ")
        if scanned.isEmpty {
            return "No scanned faces yet. Target is \(targetFace.displayName)."
        }
        return "Scanned faces: \(scanned). Target is \(targetFace.displayName)."
    }

    private var defaultPitch: Double {
        isScanning ? -0.52 : -0.45
    }

    private var rotateGesture: some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .local)
            .updating($dragInteraction) { value, state, _ in
                state = DragInteraction(translation: value.translation, isActive: true)
            }
            .onEnded { value in
                committedYaw = normalizedAngle(committedYaw + (Double(value.translation.width) * 0.012))
                let startingPitch = committedPitch ?? defaultPitch
                committedPitch = clampedPitch(startingPitch - (Double(value.translation.height) * 0.010))
            }
    }

    private func clampedPitch(_ value: Double) -> Double {
        // Allow users to rotate far enough to inspect top/bottom guidance faces.
        min(max(value, -1.12), 1.12)
    }

    private func normalizedAngle(_ value: Double) -> Double {
        let full = Double.pi * 2
        var angle = value.truncatingRemainder(dividingBy: full)
        if angle > Double.pi {
            angle -= full
        } else if angle < -Double.pi {
            angle += full
        }
        return angle
    }
}

private struct DragInteraction {
    var translation: CGSize
    var isActive: Bool

    static let inactive = DragInteraction(translation: .zero, isActive: false)
}

private struct FaceProjection {
    let id: FaceId
    let points: [CGPoint]
    let depth: Double
}

private struct FaceDefinition {
    let corners: [Vec3]
    let normal: Vec3

    static func definition(for face: FaceId) -> FaceDefinition {
        switch face {
        case .up:
            return FaceDefinition(
                corners: [
                    Vec3(-1, 1, -1),
                    Vec3(1, 1, -1),
                    Vec3(1, 1, 1),
                    Vec3(-1, 1, 1)
                ],
                normal: Vec3(0, 1, 0)
            )
        case .down:
            return FaceDefinition(
                corners: [
                    Vec3(-1, -1, 1),
                    Vec3(1, -1, 1),
                    Vec3(1, -1, -1),
                    Vec3(-1, -1, -1)
                ],
                normal: Vec3(0, -1, 0)
            )
        case .front:
            return FaceDefinition(
                corners: [
                    Vec3(-1, 1, 1),
                    Vec3(1, 1, 1),
                    Vec3(1, -1, 1),
                    Vec3(-1, -1, 1)
                ],
                normal: Vec3(0, 0, 1)
            )
        case .back:
            return FaceDefinition(
                corners: [
                    Vec3(1, 1, -1),
                    Vec3(-1, 1, -1),
                    Vec3(-1, -1, -1),
                    Vec3(1, -1, -1)
                ],
                normal: Vec3(0, 0, -1)
            )
        case .right:
            return FaceDefinition(
                corners: [
                    Vec3(1, 1, 1),
                    Vec3(1, 1, -1),
                    Vec3(1, -1, -1),
                    Vec3(1, -1, 1)
                ],
                normal: Vec3(1, 0, 0)
            )
        case .left:
            return FaceDefinition(
                corners: [
                    Vec3(-1, 1, -1),
                    Vec3(-1, 1, 1),
                    Vec3(-1, -1, 1),
                    Vec3(-1, -1, -1)
                ],
                normal: Vec3(-1, 0, 0)
            )
        }
    }
}

private struct Vec3 {
    var x: Double
    var y: Double
    var z: Double

    init(_ x: Double, _ y: Double, _ z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    func rotated(yaw: Double, pitch: Double) -> Vec3 {
        let cosy = cos(yaw)
        let siny = sin(yaw)
        let x1 = (x * cosy) + (z * siny)
        let z1 = (-x * siny) + (z * cosy)

        let cosp = cos(pitch)
        let sinp = sin(pitch)
        let y2 = (y * cosp) - (z1 * sinp)
        let z2 = (y * sinp) + (z1 * cosp)

        return Vec3(x1, y2, z2)
    }
}

private extension Array where Element == CGPoint {
    var centerPoint: CGPoint {
        guard count == 4 else {
            return .zero
        }

        let x = (self[0].x + self[1].x + self[2].x + self[3].x) / 4
        let y = (self[0].y + self[1].y + self[2].y + self[3].y) / 4
        return CGPoint(x: x, y: y)
    }
}

private extension CGPoint {
    func lerp(to other: CGPoint, t: CGFloat) -> CGPoint {
        CGPoint(
            x: x + (other.x - x) * t,
            y: y + (other.y - y) * t
        )
    }
}

#endif
