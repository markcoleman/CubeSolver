#if os(iOS) && canImport(SwiftUI) && canImport(AVFoundation)

import SwiftUI
import AVFoundation
import CubeCore
import CubeScanner

/// Composition root for the live scan wizard using CameraSession + Vision detector.
public struct LiveScanWizardContainerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var cameraSession: CameraSession
    @StateObject private var flowViewModel: CubeScanSolveFlowViewModel
    @State private var cameraError: String?
    @State private var isStatusPulseOn = false

    public init() {
        let session = CameraSession()
        let frameSource = CameraSessionFrameSource(cameraSession: session)
        let scanner = DefaultFaceScanner(
            frameSource: frameSource,
            quadDetector: VisionFaceQuadDetector(),
            warpSampler: FaceWarpSampler(cellInset: 0.18),
            classifier: HSVStickerClassifier(),
            maxScanAttempts: 60,
            minimumMeanConfidence: 0.45
        )

        _cameraSession = StateObject(wrappedValue: session)
        _flowViewModel = StateObject(
            wrappedValue: CubeScanSolveFlowViewModel(
                scanner: scanner,
                validator: CubeStateValidator(),
                solver: KociembaCompatibleCubeSolver()
            )
        )
    }

    public var body: some View {
        ScanWizardView(
            viewModel: flowViewModel,
            cameraPreview: AnyView(
                LiveCameraPreviewCard(
                    cameraSession: cameraSession,
                    isRunning: cameraSession.isRunning,
                    isBusy: flowViewModel.isBusy,
                    currentFace: flowViewModel.currentFaceId,
                    pulse: isStatusPulseOn
                )
            )
        )
            .task {
                do {
                    let granted = await cameraSession.requestPermission()
                    guard granted else {
                        cameraError = "Camera permission was denied. Enable it in Settings to scan faces."
                        return
                    }
                    try await cameraSession.start()
                } catch {
                    cameraError = error.localizedDescription
                }
            }
            .alert("Camera Error", isPresented: Binding(
                get: { cameraError != nil },
                set: { show in
                    if !show { cameraError = nil }
                }
            ), actions: {
                Button("OK") { cameraError = nil }
            }, message: {
                Text(cameraError ?? "Unknown camera error")
            })
            .onDisappear {
                cameraSession.stop()
            }
            .onAppear {
                updatePulseAnimation()
            }
            .onChange(of: reduceMotion) { _, _ in
                updatePulseAnimation()
            }
    }

    private func updatePulseAnimation() {
        guard !reduceMotion else {
            isStatusPulseOn = false
            return
        }

        isStatusPulseOn = false
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            isStatusPulseOn = true
        }
    }
}

private struct LiveCameraPreviewCard: View {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    let cameraSession: CameraSession
    let isRunning: Bool
    let isBusy: Bool
    let currentFace: FaceId
    let pulse: Bool

    var body: some View {
        ZStack {
            LiveCameraPreviewView(cameraSession: cameraSession)
                .overlay(Color.black.opacity(cameraOverlayOpacity))
            FaceTargetGridOverlay()
                .padding(20)

            VStack(spacing: 0) {
                LiveCameraStatusBanner(
                    isRunning: isRunning,
                    isBusy: isBusy,
                    currentFace: currentFace,
                    pulse: pulse
                )
                Spacer()
                Text("Align the \(currentFace.displayName.lowercased()) face inside the 3x3 guide")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(capsuleOverlayOpacity), in: Capsule())
                Text("Center color: \(currentFace.expectedCenterColorName)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(capsuleOverlayOpacity - 0.08), in: Capsule())
            }
            .padding(10)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Live camera preview")
        .accessibilityHint("Align the target face inside the guide before scanning.")
        .accessibilityIdentifier("liveCameraPreview")
    }

    private var cameraOverlayOpacity: Double {
        if colorSchemeContrast == .increased {
            return isRunning ? 0.34 : 0.46
        }
        return isRunning ? 0.2 : 0.32
    }

    private var capsuleOverlayOpacity: Double {
        colorSchemeContrast == .increased ? 0.72 : 0.56
    }
}

private struct LiveCameraPreviewView: UIViewRepresentable {
    let cameraSession: CameraSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let preview = CameraPreviewUIView()
        preview.previewLayer = cameraSession.getPreviewLayer()
        return preview
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        if uiView.previewLayer == nil {
            uiView.previewLayer = cameraSession.getPreviewLayer()
        }
    }
}

private struct LiveCameraStatusBanner: View {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    let isRunning: Bool
    let isBusy: Bool
    let currentFace: FaceId
    let pulse: Bool

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(isRunning ? .green : .red)
                .frame(width: 10, height: 10)
                .scaleEffect(isRunning && isBusy ? (pulse ? 1.25 : 0.9) : 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(primaryText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Target face: \(currentFace.displayName) (\(currentFace.rawValue)) - \(currentFace.expectedCenterColorName)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(colorSchemeContrast == .increased ? 1 : 0.9))
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Color.black.opacity(colorSchemeContrast == .increased ? 0.72 : 0.55),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(primaryText)
        .accessibilityValue("Target \(currentFace.displayName) face, center color \(currentFace.expectedCenterColorName)")
    }

    private var primaryText: String {
        if !isRunning {
            return "Camera offline"
        }
        if isBusy {
            return "Scanning in progress"
        }
        return "Camera live - ready to scan"
    }
}

private struct FaceTargetGridOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height) * 0.74
            let cell = side / 3

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        Color.white.opacity(0.9),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
                    .frame(width: side, height: side)

                Path { path in
                    for index in 1..<3 {
                        let offset = -side / 2 + CGFloat(index) * cell
                        path.move(to: CGPoint(x: offset, y: -side / 2))
                        path.addLine(to: CGPoint(x: offset, y: side / 2))
                        path.move(to: CGPoint(x: -side / 2, y: offset))
                        path.addLine(to: CGPoint(x: side / 2, y: offset))
                    }
                }
                .stroke(Color.white.opacity(0.65), lineWidth: 1)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .allowsHitTesting(false)
    }
}

#endif
