#if canImport(SwiftUI)

import SwiftUI
import CubeCore

public struct ScanWizardView: View {
    @StateObject private var viewModel: CubeScanSolveFlowViewModel
    private let cameraPreview: AnyView?
    @State private var showingManualEdit = false
    @State private var showingSteps = false

    public init(viewModel: CubeScanSolveFlowViewModel, cameraPreview: AnyView? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.cameraPreview = cameraPreview
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Scan -> Validate -> Edit -> Solve")
                        .font(.title2.bold())

                    if let cameraPreview {
                        cameraPreview
                    }

                    ProgressView(value: Double(viewModel.scannedFaces.count), total: Double(viewModel.scanOrder.count)) {
                        Text(viewModel.progressText)
                            .font(.subheadline)
                    }

                    ScanFaceGuidanceView(
                        targetFace: viewModel.currentFaceId,
                        scannedFaces: viewModel.scannedFaces,
                        scanOrder: viewModel.scanOrder,
                        isScanning: viewModel.isBusy
                    )

                    faceStatusRow

                    if let pending = viewModel.pendingFace {
                        FaceConfirmView(
                            face: pending,
                            onConfirm: { viewModel.confirmPendingFace() },
                            onRescan: { viewModel.rejectPendingFaceAndRescan() }
                        )
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Next face: \(viewModel.currentFaceId.displayName) (\(viewModel.currentFaceId.rawValue))")
                                .font(.headline)
                            Text("Keep the \(viewModel.currentFaceId.displayName.lowercased()) face centered, then tap scan.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Button {
                                Task {
                                    await viewModel.scanCurrentFace()
                                }
                            } label: {
                                Label(
                                    viewModel.isBusy
                                        ? "Scanning \(viewModel.currentFaceId.displayName)..."
                                        : "Scan \(viewModel.currentFaceId.displayName) Face",
                                    systemImage: viewModel.isBusy ? "camera.aperture" : "camera"
                                )
                            }
                            .disabled(viewModel.isBusy)
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }

                    if let validationError = viewModel.validationError {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(validationError.message)
                                .font(.subheadline.weight(.semibold))
                            Text(validationError.suggestedFix)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button("Open Manual Edit") {
                                showingManualEdit = true
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))
                    }

                    if viewModel.canStartSolve {
                        Button {
                            Task {
                                await viewModel.solve()
                                showingSteps = viewModel.state == .solved
                            }
                        } label: {
                            Label(viewModel.isBusy ? "Solving..." : "Solve Cube", systemImage: "wand.and.stars")
                        }
                        .disabled(viewModel.isBusy)
                        .buttonStyle(.borderedProminent)
                    }

                    if case .failed(let message) = viewModel.state {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    if !viewModel.solvedMoves.isEmpty {
                        Button("View Step-by-step", systemImage: "list.number") {
                            showingSteps = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .navigationTitle("Cube Scanner")
        }
        .sheet(isPresented: $showingManualEdit) {
            CubeManualEditView(viewModel: viewModel)
        }
        .navigationDestination(isPresented: $showingSteps) {
            SolveStepsView(viewModel: viewModel)
        }
        .onChange(of: viewModel.state) { _, newState in
            if newState == .solved {
                showingSteps = true
            }
        }
    }

    private var faceStatusRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.scanOrder, id: \.self) { face in
                    FaceBadgeView(
                        face: face,
                        isComplete: viewModel.scannedFaces[face] != nil
                    )
                    .onTapGesture {
                        if viewModel.scannedFaces[face] != nil {
                            showingManualEdit = true
                        }
                    }
                }
            }
        }
    }
}

#endif
