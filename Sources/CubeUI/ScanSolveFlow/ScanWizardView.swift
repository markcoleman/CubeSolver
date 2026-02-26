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
                VStack(alignment: .leading, spacing: 18) {
                    Text("Scan Cube")
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("scanWizardTitle")

                    Text("Capture each face, then review before solving.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let cameraPreview {
                        cameraPreview
                            .accessibilityIdentifier("scanWizardCameraPreview")
                    }

                    ProgressView(value: Double(viewModel.scannedFaces.count), total: Double(viewModel.scanOrder.count)) {
                        Text(viewModel.progressText)
                            .font(.subheadline)
                    }
                    .accessibilityValue("\(viewModel.progressText) captured")
                    .accessibilityIdentifier("scanWizardProgress")

                    ScanFaceGuidanceView(
                        targetFace: viewModel.currentFaceId,
                        scannedFaces: viewModel.scannedFaces,
                        scanOrder: viewModel.scanOrder,
                        isScanning: viewModel.isBusy
                    )

                    faceStatusSection

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

                    if viewModel.canStartSolve {
                        Button {
                            Task {
                                await viewModel.solve()
                                showingSolveMode = viewModel.state == .solved
                            }
                        } label: {
                            Label(viewModel.isBusy ? "Solving..." : "Solve Cube", systemImage: "wand.and.stars")
                        }
                        .disabled(viewModel.isBusy)
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("solveCubeButton")
                    } else if viewModel.needsReview {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Review required")
                                .font(.subheadline.weight(.semibold))
                            Text("Review all faces before solving.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button("Review All Faces", systemImage: "square.grid.3x3") {
                                showingReview = true
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("reviewAllFacesButton")
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.11), in: RoundedRectangle(cornerRadius: 14))
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
                .padding()
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                captureActionPanel
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Captured Faces")
                .font(.headline)

            Text("Tap a captured face to edit.")
                .font(.caption)
                .foregroundStyle(.secondary)

            faceStatusRow
        }
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
        VStack(spacing: 10) {
            if let pending = viewModel.pendingFace {
                FaceConfirmView(
                    face: pending,
                    centerMismatch: viewModel.pendingCenterMismatch,
                    onConfirm: { viewModel.confirmPendingFace() },
                    onRescan: { viewModel.rejectPendingFaceAndRescan() }
                )
            } else if viewModel.scannedFaces.count == viewModel.scanOrder.count {
                VStack(alignment: .leading, spacing: 4) {
                    Text("All faces captured")
                        .font(.headline)
                    Text(
                        viewModel.needsReview
                            ? "Review your cube to continue."
                            : "Review complete. You can solve now."
                    )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if viewModel.needsReview {
                        Button("Open Review", systemImage: "square.grid.3x3") {
                            showingReview = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next: \(viewModel.currentFaceId.displayName) face")
                        .font(.headline)
                    Text("Center the \(viewModel.currentFaceId.displayName.lowercased()) face, then scan.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        Task {
                            await viewModel.scanCurrentFace()
                        }
                    } label: {
                        Label(
                            viewModel.isBusy
                                ? "Scanning..."
                                : "Scan Face",
                            systemImage: viewModel.isBusy ? "camera.aperture" : "camera"
                        )
                    }
                    .disabled(viewModel.isBusy)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("scanCurrentFaceButton")
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private func presentManualEdit(startingAt face: FaceId?) {
        manualEditInitialFace = face ?? viewModel.currentFaceId
        viewModel.openManualEdit()
        showingManualEdit = true
    }
}

#endif
