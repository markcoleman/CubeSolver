#if canImport(SwiftUI)

import SwiftUI
import CubeCore

public struct ScanWizardView: View {
    @StateObject private var viewModel: CubeScanSolveFlowViewModel
    private let cameraPreview: AnyView?
    @State private var showingManualEdit = false
    @State private var showingReview = false
    @State private var showingSolveMode = false
    @State private var manualEditInitialFace: FaceId = .up

    public init(viewModel: CubeScanSolveFlowViewModel, cameraPreview: AnyView? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.cameraPreview = cameraPreview
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if let cameraPreview {
                        cameraSection(cameraPreview)
                    }

                    if showsStandaloneProgressText {
                        Text(viewModel.progressText)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("scanWizardProgress")
                    }

                    ScanFaceGuidanceView(
                        targetFace: viewModel.currentFaceId,
                        scannedFaces: viewModel.scannedFaces,
                        scanOrder: viewModel.scanOrder,
                        isScanning: viewModel.isBusy
                    )

                    if !viewModel.scannedFaces.isEmpty {
                        faceStatusSection
                    }

                    if let validationError = viewModel.validationError {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(validationError.message)
                                .font(.subheadline.weight(.semibold))
                            Text(validationError.suggestedFix)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button("Open Manual Edit") {
                                presentManualEdit(startingAt: viewModel.currentFaceId)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("openManualEditButton")
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))
                    }

                    if case .failed(let message) = viewModel.state {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    if !viewModel.solvedMoves.isEmpty {
                        Button("View Solution Steps", systemImage: "list.number") {
                            showingSolveMode = true
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("viewStepByStepButton")
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if showsBottomCapturePanel {
                    captureActionPanel
                }
            }
            .navigationTitle("Scan Cube")
        }
        .sheet(isPresented: $showingManualEdit, onDismiss: {
            viewModel.resumeWizard()
        }) {
            CubeManualEditView(viewModel: viewModel, initialFace: manualEditInitialFace)
        }
        .sheet(isPresented: $showingReview) {
            CubeReviewGateView(
                viewModel: viewModel,
                onConfirmReview: {
                    viewModel.confirmReview()
                    showingReview = false
                },
                onEditFace: { face in
                    showingReview = false
                    presentManualEdit(startingAt: face)
                },
                onRescanFace: { face in
                    viewModel.markFaceForRescan(face)
                    showingReview = false
                }
            )
            .interactiveDismissDisabled(viewModel.needsReview)
        }
        .navigationDestination(isPresented: $showingSolveMode) {
            if let solvedInitialState = viewModel.solvedInitialState {
                SolveModeView(
                    state: solvedInitialState,
                    solution: viewModel.solvedMoves,
                    requireOrientationConfirmation: false
                )
            } else {
                ContentUnavailableView(
                    "Solve data unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Re-run solve to open guided solve mode.")
                )
            }
        }
        .onChange(of: viewModel.state) { _, newState in
            if newState == .solved {
                showingSolveMode = true
            }
        }
        .onChange(of: viewModel.needsReview) { _, needsReview in
            if needsReview && !showingReview {
                showingReview = true
            }
        }
    }

    private var faceStatusSection: some View {
        faceStatusRow
    }

    private var faceStatusRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.scanOrder, id: \.self) { face in
                    let isComplete = viewModel.scannedFaces[face] != nil
                    let isCurrent = face == viewModel.currentFaceId

                    Button {
                        presentManualEdit(startingAt: face)
                    } label: {
                        FaceBadgeView(
                            face: face,
                            isComplete: isComplete,
                            isCurrent: isCurrent
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!isComplete)
                    .accessibilityLabel("\(face.displayName) face")
                    .accessibilityValue(isComplete ? "Captured" : "Not captured")
                    .accessibilityHint(
                        isComplete
                            ? "Opens manual edit for this face."
                            : "Capture this face to enable editing."
                    )
                    .accessibilityIdentifier("scanFaceBadge_\(face.rawValue)")
                }
            }
        }
        .accessibilityIdentifier("scanFaceStatusRow")
    }

    private var captureActionPanel: some View {
        Group {
            if let pending = viewModel.pendingFace {
                FaceConfirmView(
                    face: pending,
                    centerMismatch: viewModel.pendingCenterMismatch,
                    onConfirm: { viewModel.confirmPendingFace() },
                    onRescan: { viewModel.rejectPendingFaceAndRescan() }
                )
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Divider()
                }
            } else if viewModel.scannedFaces.count == viewModel.scanOrder.count {
                VStack(alignment: .leading, spacing: 4) {
                    Text("All faces captured")
                        .font(.headline)
                    Text(
                        viewModel.needsReview
                            ? "Review your cube to continue."
                            : "Ready to solve."
                    )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if viewModel.needsReview {
                        Button("Open Review", systemImage: "square.grid.3x3") {
                            showingReview = true
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("reviewAllFacesButton")
                    } else if viewModel.canStartSolve {
                        Button {
                            Task {
                                await viewModel.solve()
                                showingSolveMode = viewModel.state == .solved
                            }
                        } label: {
                            Label(viewModel.isBusy ? "Solving..." : "Solve Cube", systemImage: "wand.and.stars")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(viewModel.isBusy)
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("solveCubeButton")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Divider()
                }
            } else if cameraPreview == nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next: \(viewModel.currentFaceId.displayName) face")
                        .font(.headline)
                    Button {
                        Task {
                            await viewModel.scanCurrentFace()
                        }
                    } label: {
                        Label(viewModel.isBusy ? "Scanning..." : "Scan Face", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(viewModel.isBusy)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("scanCurrentFaceButton")
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Divider()
                }
            }
        }
    }

    @ViewBuilder
    private func cameraSection(_ preview: AnyView) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            preview
                .accessibilityIdentifier("scanWizardCameraPreview")

            if showsCaptureDock {
                captureDock
            }
        }
    }

    private var captureDock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(viewModel.progressText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("scanWizardProgress")

                    HStack(spacing: 6) {
                        Text("Next: \(viewModel.currentFaceId.displayName)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Circle()
                            .fill(swiftUIColor(for: viewModel.currentFaceId.expectedCenterColor))
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(Color.primary.opacity(0.25), lineWidth: 1))

                        Text(viewModel.currentFaceId.expectedCenterColorName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 8)

                Button {
                    Task {
                        await viewModel.scanCurrentFace()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.82)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Circle()
                            .stroke(Color.white.opacity(0.85), lineWidth: 2)
                            .padding(6)

                        if viewModel.isBusy {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "camera.fill")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 58, height: 58)
                }
                .disabled(viewModel.isBusy)
                .accessibilityLabel(viewModel.isBusy ? "Scanning current face" : "Capture current face")
                .accessibilityHint("Captures the \(viewModel.currentFaceId.displayName.lowercased()) face.")
                .accessibilityIdentifier("scanCurrentFaceButton")
            }

            ProgressView(
                value: Double(viewModel.scannedFaces.count),
                total: Double(viewModel.scanOrder.count)
            )
            .tint(.blue)
            .accessibilityValue("\(viewModel.progressText) captured")
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .accessibilityIdentifier("scanCaptureDock")
    }

    private var showsCaptureDock: Bool {
        cameraPreview != nil
            && viewModel.pendingFace == nil
            && viewModel.scannedFaces.count < viewModel.scanOrder.count
    }

    private var showsStandaloneProgressText: Bool {
        !(cameraPreview != nil && showsCaptureDock)
    }

    private var showsBottomCapturePanel: Bool {
        viewModel.pendingFace != nil
            || viewModel.scannedFaces.count == viewModel.scanOrder.count
            || cameraPreview == nil
    }

    private func presentManualEdit(startingAt face: FaceId?) {
        manualEditInitialFace = face ?? viewModel.currentFaceId
        viewModel.openManualEdit()
        showingManualEdit = true
    }
}

#endif
