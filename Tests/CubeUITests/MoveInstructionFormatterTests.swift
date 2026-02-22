import XCTest
@testable import CubeCore
@testable import CubeUI

final class MoveInstructionFormatterTests: XCTestCase {
    func testInstructionFormattingForAllFaces() {
        let formatter = MoveInstructionFormatter(orientation: nil)
        let expectedFaces: [Turn: String] = [
            .U: "UP",
            .D: "DOWN",
            .L: "LEFT",
            .R: "RIGHT",
            .F: "FRONT",
            .B: "BACK"
        ]

        for turn in Turn.allCases {
            let instruction = formatter.instruction(for: Move(turn: turn, amount: .clockwise))
            let expectedFace = expectedFaces[turn] ?? ""
            XCTAssertEqual(
                instruction.spokenInstruction,
                "Turn the \(expectedFace) face clockwise 90 degrees."
            )
        }
    }

    func testClockwiseInstructionFormatting() {
        let formatter = MoveInstructionFormatter(orientation: nil)

        let instruction = formatter.instruction(for: Move(turn: .R, amount: .clockwise))

        XCTAssertEqual(instruction.title, "R")
        XCTAssertEqual(instruction.spokenInstruction, "Turn the RIGHT face clockwise 90 degrees.")
    }

    func testCounterClockwiseInstructionFormatting() {
        let formatter = MoveInstructionFormatter(orientation: nil)

        let instruction = formatter.instruction(for: Move(turn: .U, amount: .counter))

        XCTAssertEqual(instruction.title, "U'")
        XCTAssertEqual(instruction.spokenInstruction, "Turn the UP face counter-clockwise 90 degrees.")
    }

    func testDoubleTurnInstructionFormatting() {
        let formatter = MoveInstructionFormatter(orientation: nil)

        let instruction = formatter.instruction(for: Move(turn: .F, amount: .double))

        XCTAssertEqual(instruction.title, "F2")
        XCTAssertEqual(instruction.spokenInstruction, "Turn the FRONT face 180 degrees.")
    }

    func testOrientationHintIsIncludedWhenAvailable() {
        let orientation = SolveOrientation(upColor: .white, frontColor: .green)
        let formatter = MoveInstructionFormatter(orientation: orientation)

        let instruction = formatter.instruction(for: Move(turn: .L, amount: .clockwise))

        XCTAssertEqual(
            instruction.hint,
            "Hold the cube with the GREEN center facing you and WHITE on top."
        )
    }
}
