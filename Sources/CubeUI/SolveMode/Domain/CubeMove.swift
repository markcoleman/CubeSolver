import Foundation
import CubeCore

public enum CubeMoveParseError: Error, LocalizedError, Equatable, Sendable {
    case invalidTokens([String])

    public var errorDescription: String? {
        switch self {
        case .invalidTokens(let tokens):
            "Invalid move notation: \(tokens.joined(separator: ", "))"
        }
    }
}

public struct CubeMoveParser: Sendable {
    public init() {}

    public func parse(_ notations: [String]) -> Result<[Move], CubeMoveParseError> {
        var moves: [Move] = []
        var invalidTokens: [String] = []

        moves.reserveCapacity(notations.count)

        for token in notations {
            let normalized = token.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalized.isEmpty else { continue }

            guard let move = Move(notation: normalized) else {
                invalidTokens.append(normalized)
                continue
            }
            moves.append(move)
        }

        if invalidTokens.isEmpty {
            return .success(moves)
        }

        return .failure(.invalidTokens(invalidTokens))
    }
}

public enum MoveDirection: Equatable, Sendable {
    case clockwise
    case counterClockwise
    case doubleTurn
}

public extension Move {
    var direction: MoveDirection {
        switch amount {
        case .clockwise:
            return .clockwise
        case .counter:
            return .counterClockwise
        case .double:
            return .doubleTurn
        }
    }

    var affectedFace: Face {
        turn.face
    }
}
