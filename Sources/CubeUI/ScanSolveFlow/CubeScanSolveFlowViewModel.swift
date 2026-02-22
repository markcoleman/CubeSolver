#if canImport(SwiftUI)

import Foundation
import SwiftUI
import CubeCore
import CubeScanner

@MainActor
public final class CubeScanSolveFlowViewModel: ObservableObject {
    public enum FlowState: Equatable {
        case scanning
        case awaitingConfirmation(FaceId)
        case editing
        case readyToSolve
        case solving
        case solved
        case failed(String)
    }

    @Published public private(set) var state: FlowState = .scanning
    @Published public private(set) var scannedFaces: [FaceId: ScannedFaceData] = [:]
    @Published public private(set) var pendingFace: ScannedFaceData?
    @Published public private(set) var validationError: ValidationError?
    @Published public private(set) var solvedMoves: [Move] = []
    @Published public private(set) var currentMoveIndex: Int = 0
    @Published public private(set) var isBusy = false

    public let scanOrder: [FaceId]

    public var currentFaceId: FaceId {
        if let pending = pendingFace {
            return pending.id
        }

        if let missing = scanOrder.first(where: { scannedFaces[$0] == nil }) {
            return missing
        }

        return scanOrder.last ?? .back
    }

    public var progressText: String {
        "\(scannedFaces.count)/\(scanOrder.count) faces"
    }

    public var canStartSolve: Bool {
        scannedFaces.count == scanOrder.count && validationError == nil
    }

    public var currentInstruction: SolutionInstruction? {
        guard !solvedMoves.isEmpty,
              currentMoveIndex > 0,
              currentMoveIndex <= solvedMoves.count else {
            return nil
        }

        return SolutionInstruction(
            index: currentMoveIndex,
            total: solvedMoves.count,
            move: solvedMoves[currentMoveIndex - 1]
        )
    }

    public var solutionText: String {
        MoveNotationCodec().encode(solvedMoves)
    }

    private let scanner: FaceScanner
    private let validator: CubeStateValidating
    private let solver: CubeSolving
    private let assembler = CubeStateAssembler()

    public init(
        scanner: FaceScanner,
        validator: CubeStateValidating = CubeStateValidator(),
        solver: CubeSolving = KociembaCompatibleCubeSolver(),
        scanOrder: [FaceId] = FaceId.guidedScanOrder
    ) {
        self.scanner = scanner
        self.validator = validator
        self.solver = solver
        self.scanOrder = scanOrder
    }

    public func scanCurrentFace() async {
        guard !isBusy else { return }

        isBusy = true
        defer { isBusy = false }

        do {
            let scanned = try await scanner.scanFace(for: currentFaceId)
            pendingFace = scanned
            validationError = nil
            state = .awaitingConfirmation(scanned.id)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    public func confirmPendingFace() {
        guard let pendingFace else { return }

        scannedFaces[pendingFace.id] = pendingFace
        self.pendingFace = nil

        _ = revalidateIfComplete()

        if scannedFaces.count < scanOrder.count {
            state = .scanning
        }
    }

    public func rejectPendingFaceAndRescan() {
        pendingFace = nil
        state = .scanning
    }

    public func openManualEdit() {
        state = .editing
    }

    public func resumeWizard() {
        if canStartSolve {
            state = .readyToSolve
        } else {
            state = .scanning
        }
    }

    public func updateSticker(face: FaceId, index: Int, color: CubeColor) {
        guard var scanned = scannedFaces[face] else { return }
        guard index >= 0, index < CubeFaceGrid.stickerCount else { return }

        scanned.grid[index] = color
        scannedFaces[face] = scanned
        _ = revalidateIfComplete()
    }

    public func resetFace(_ face: FaceId) {
        guard let center = defaultCenterColor(for: face) else { return }
        let replacement = CubeFaceGrid(repeating: center)
        scannedFaces[face] = ScannedFaceData(id: face, grid: replacement, confidence: 1)
        _ = revalidateIfComplete()
    }

    public func markFaceForRescan(_ face: FaceId) {
        scannedFaces.removeValue(forKey: face)
        pendingFace = nil
        validationError = nil
        solvedMoves = []
        currentMoveIndex = 0
        state = .scanning
    }

    public func solve() async {
        guard canStartSolve, !isBusy else { return }

        isBusy = true
        state = .solving
        defer { isBusy = false }

        do {
            let cubeState = try assembler.assemble(from: faceGrids())

            switch validator.validate(state: cubeState) {
            case .failure(let validationError):
                self.validationError = validationError
                state = .editing
                return
            case .success:
                break
            }

            solvedMoves = try await solver.solve(state: cubeState)
            currentMoveIndex = solvedMoves.isEmpty ? 0 : 1
            state = .solved
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    public func restart() {
        state = .scanning
        scannedFaces = [:]
        pendingFace = nil
        validationError = nil
        solvedMoves = []
        currentMoveIndex = 0
    }

    public func nextMove() {
        guard currentMoveIndex < solvedMoves.count else { return }
        currentMoveIndex += 1
    }

    public func previousMove() {
        guard currentMoveIndex > 1 else {
            currentMoveIndex = min(currentMoveIndex, 1)
            return
        }
        currentMoveIndex -= 1
    }

    public func jumpToMove(_ index: Int) {
        guard !solvedMoves.isEmpty else { return }
        currentMoveIndex = max(1, min(index, solvedMoves.count))
    }

    private func faceGrids() -> [FaceId: CubeFaceGrid] {
        scannedFaces.reduce(into: [FaceId: CubeFaceGrid]()) { result, item in
            result[item.key] = item.value.grid
        }
    }

    @discardableResult
    private func revalidateIfComplete() -> Bool {
        guard scannedFaces.count == scanOrder.count else {
            validationError = nil
            state = .scanning
            return false
        }

        do {
            let cubeState = try assembler.assemble(from: faceGrids())
            switch validator.validate(state: cubeState) {
            case .success:
                validationError = nil
                state = .readyToSolve
                return true
            case .failure(let error):
                validationError = error
                state = .editing
                return false
            }
        } catch {
            validationError = ValidationError(
                type: .invalidFace,
                message: error.localizedDescription,
                suggestedFix: "Finish scanning all six faces, then validate again."
            )
            state = .editing
            return false
        }
    }

    private func defaultCenterColor(for face: FaceId) -> CubeColor? {
        switch face {
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
}

#endif
