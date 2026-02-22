#if canImport(SwiftUI)

import XCTest
@testable import CubeCore
@testable import CubeScanner
@testable import CubeUI

@MainActor
final class ScanSolveFlowIntegrationTests: XCTestCase {
    func testFullFlowWithMockScanner() async {
        let scanner = SimulatedFaceScanner(scriptedFaces: solvedScannedFaces())
        let viewModel = CubeScanSolveFlowViewModel(
            scanner: scanner,
            validator: CubeStateValidator(),
            solver: KociembaCompatibleCubeSolver()
        )

        for _ in viewModel.scanOrder {
            await viewModel.scanCurrentFace()
            XCTAssertNotNil(viewModel.pendingFace)
            viewModel.confirmPendingFace()
        }

        XCTAssertTrue(viewModel.canStartSolve)
        XCTAssertNil(viewModel.validationError)

        await viewModel.solve()

        XCTAssertEqual(viewModel.state, .solved)
        XCTAssertTrue(viewModel.solvedMoves.isEmpty)
    }

    func testInvalidMockScanTransitionsToManualEditAndRecovers() async {
        var invalidFaces = solvedScannedFaces()
        var front = invalidFaces[.front]!
        front.grid[0] = .blue
        invalidFaces[.front] = front

        let scanner = SimulatedFaceScanner(scriptedFaces: invalidFaces)
        let viewModel = CubeScanSolveFlowViewModel(
            scanner: scanner,
            validator: CubeStateValidator(),
            solver: KociembaCompatibleCubeSolver()
        )

        for _ in viewModel.scanOrder {
            await viewModel.scanCurrentFace()
            viewModel.confirmPendingFace()
        }

        XCTAssertEqual(viewModel.validationError?.type, .countMismatch)
        XCTAssertEqual(viewModel.state, .editing)

        viewModel.updateSticker(face: .front, index: 0, color: .red)

        XCTAssertNil(viewModel.validationError)
        XCTAssertEqual(viewModel.state, .readyToSolve)
    }

    private func solvedScannedFaces() -> [FaceId: ScannedFaceData] {
        [
            .up: ScannedFaceData(id: .up, grid: CubeFaceGrid(repeating: .white), confidence: 1),
            .right: ScannedFaceData(id: .right, grid: CubeFaceGrid(repeating: .blue), confidence: 1),
            .front: ScannedFaceData(id: .front, grid: CubeFaceGrid(repeating: .red), confidence: 1),
            .down: ScannedFaceData(id: .down, grid: CubeFaceGrid(repeating: .yellow), confidence: 1),
            .left: ScannedFaceData(id: .left, grid: CubeFaceGrid(repeating: .green), confidence: 1),
            .back: ScannedFaceData(id: .back, grid: CubeFaceGrid(repeating: .orange), confidence: 1)
        ]
    }
}

#endif
