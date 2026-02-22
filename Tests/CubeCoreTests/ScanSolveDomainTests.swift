import XCTest
@testable import CubeCore

final class ScanSolveDomainTests: XCTestCase {
    func testCubeFaceGridRejectsInvalidStickerCount() {
        XCTAssertThrowsError(try CubeFaceGrid(stickers: [.white])) { error in
            guard let gridError = error as? CubeFaceGridError else {
                return XCTFail("Expected CubeFaceGridError")
            }
            XCTAssertEqual(gridError, .invalidStickerCount(expected: 9, actual: 1))
        }
    }

    func testCubeStateAssemblerRequiresAllFaces() {
        let assembler = CubeStateAssembler()
        let partial: [FaceId: CubeFaceGrid] = [
            .up: CubeFaceGrid(repeating: .white)
        ]

        XCTAssertThrowsError(try assembler.assemble(from: partial)) { error in
            guard case let CubeStateAssemblyError.missingFaces(missing) = error else {
                return XCTFail("Expected missingFaces")
            }
            XCTAssertTrue(missing.contains(.front))
            XCTAssertTrue(missing.contains(.right))
        }
    }

    func testCubeStateAssemblerBuildsSolvedState() throws {
        let assembler = CubeStateAssembler()
        let state = try assembler.assemble(from: solvedFaceGrids())

        XCTAssertEqual(state.centerColor(of: .up), .white)
        XCTAssertEqual(state.centerColor(of: .right), .blue)
        XCTAssertEqual(state.centerColor(of: .front), .red)
        XCTAssertEqual(state.centerColor(of: .down), .yellow)
        XCTAssertEqual(state.centerColor(of: .left), .green)
        XCTAssertEqual(state.centerColor(of: .back), .orange)
    }

    func testKociembaCodecRoundTripSolvedCube() throws {
        let codec = KociembaCodec()
        let encoded = try codec.encode(CubeState())

        XCTAssertEqual(encoded.count, 54)

        let decoded = try codec.decode(encoded)
        XCTAssertEqual(decoded, CubeState())
    }

    func testMoveNotationCodecRoundTrip() throws {
        let codec = MoveNotationCodec()
        let original: [Move] = [
            Move(turn: .R, amount: .clockwise),
            Move(turn: .U, amount: .counter),
            Move(turn: .F, amount: .double)
        ]

        let text = codec.encode(original)
        let decoded = try codec.decode(text)

        XCTAssertEqual(decoded, original)
    }

    private func solvedFaceGrids() -> [FaceId: CubeFaceGrid] {
        [
            .up: CubeFaceGrid(repeating: .white),
            .right: CubeFaceGrid(repeating: .blue),
            .front: CubeFaceGrid(repeating: .red),
            .down: CubeFaceGrid(repeating: .yellow),
            .left: CubeFaceGrid(repeating: .green),
            .back: CubeFaceGrid(repeating: .orange)
        ]
    }
}
