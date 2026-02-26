import Foundation
import CubeCore

public struct SolveOrientation: Equatable, Sendable {
    public let upColor: CubeColor
    public let frontColor: CubeColor

    public init(upColor: CubeColor, frontColor: CubeColor) {
        self.upColor = upColor
        self.frontColor = frontColor
    }

    public static func from(state: CubeState) -> SolveOrientation? {
        guard let up = state.centerColor(of: .up),
              let front = state.centerColor(of: .front) else {
            return nil
        }
        return SolveOrientation(upColor: up, frontColor: front)
    }
}

public struct MoveInstruction: Equatable, Sendable {
    public let title: String
    public let spokenInstruction: String
    public let hint: String?

    public init(title: String, spokenInstruction: String, hint: String?) {
        self.title = title
        self.spokenInstruction = spokenInstruction
        self.hint = hint
    }
}

public struct MoveInstructionFormatter: Sendable {
    public let orientation: SolveOrientation?

    public init(orientation: SolveOrientation?) {
        self.orientation = orientation
    }

    public func instruction(for move: Move) -> MoveInstruction {
        let faceName = move.affectedFace.spokenName.uppercased()
        let spokenInstruction: String

        switch move.direction {
        case .clockwise:
            spokenInstruction = "Turn the \(faceName) face clockwise 90 degrees."
        case .counterClockwise:
            spokenInstruction = "Turn the \(faceName) face counter-clockwise 90 degrees."
        case .doubleTurn:
            spokenInstruction = "Turn the \(faceName) face 180 degrees."
        }

        return MoveInstruction(
            title: move.notation,
            spokenInstruction: spokenInstruction,
            hint: orientationHint()
        )
    }

    private func orientationHint() -> String? {
        guard let orientation else { return nil }
        return "Hold the cube with the \(orientation.frontColor.name.uppercased()) center facing you and \(orientation.upColor.name.uppercased()) on top."
    }
}

private extension Face {
    var spokenName: String {
        switch self {
        case .up:
            return "up"
        case .down:
            return "down"
        case .left:
            return "left"
        case .right:
            return "right"
        case .front:
            return "front"
        case .back:
            return "back"
        }
    }
}

private extension CubeColor {
    var name: String {
        switch self {
        case .white:
            return "white"
        case .yellow:
            return "yellow"
        case .red:
            return "red"
        case .orange:
            return "orange"
        case .blue:
            return "blue"
        case .green:
            return "green"
        }
    }
}
