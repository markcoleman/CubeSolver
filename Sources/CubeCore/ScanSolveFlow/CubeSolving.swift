import Foundation

/// Async solver abstraction used by the scan -> solve flow.
///
/// Note: A legacy class named `CubeSolver` already exists in this module,
/// so this protocol uses a distinct name to preserve backward compatibility.
public protocol CubeSolving: Sendable {
    func solve(state: CubeState) async throws -> [Move]
}

public enum CubeSolvingError: Error, LocalizedError, Equatable, Sendable {
    case validationFailed(ValidationError)
    case invalidMoveFormat(String)

    public var errorDescription: String? {
        switch self {
        case .validationFailed(let error):
            return error.message
        case .invalidMoveFormat(let token):
            return "Solver returned an invalid move token: \(token)."
        }
    }
}

public struct AnyCubeSolver: CubeSolving {
    private let solveHandler: @Sendable (CubeState) async throws -> [Move]

    public init<S: CubeSolving>(_ solver: S) {
        self.solveHandler = solver.solve
    }

    public init(_ solveHandler: @escaping @Sendable (CubeState) async throws -> [Move]) {
        self.solveHandler = solveHandler
    }

    public func solve(state: CubeState) async throws -> [Move] {
        try await solveHandler(state)
    }
}

public struct EnhancedSearchCubeSolver: CubeSolving {
    public let validationMode: CubeValidationMode

    public init(validationMode: CubeValidationMode = .basic) {
        self.validationMode = validationMode
    }

    public func solve(state: CubeState) async throws -> [Move] {
        try await EnhancedCubeSolver.solveCubeAsync(from: state, validationMode: validationMode)
    }
}

/// Kociemba-compatible wrapper.
///
/// This currently delegates to `EnhancedSearchCubeSolver` to keep the project
/// dependency-free. Swap the internals with a two-phase engine later without
/// changing callers.
public struct KociembaCompatibleCubeSolver: CubeSolving {
    private let fallback: AnyCubeSolver
    private let notationCodec = MoveNotationCodec()

    public init(fallback: AnyCubeSolver = AnyCubeSolver(EnhancedSearchCubeSolver())) {
        self.fallback = fallback
    }

    public func solve(state: CubeState) async throws -> [Move] {
        let moves = try await fallback.solve(state: state)

        // Defensive check that all moves remain valid standard notation.
        for move in moves {
            guard Move(notation: move.notation) != nil else {
                throw CubeSolvingError.invalidMoveFormat(move.notation)
            }
        }

        _ = notationCodec.encode(moves)
        return moves
    }
}

public struct SolutionInstruction: Equatable, Sendable {
    public let index: Int
    public let total: Int
    public let move: Move

    public init(index: Int, total: Int, move: Move) {
        self.index = index
        self.total = total
        self.move = move
    }

    public var progressText: String {
        "\(index)/\(total)"
    }

    public var headline: String {
        move.notation
    }

    public var explanation: String {
        switch move.amount {
        case .clockwise:
            return "Turn the \(faceName) face clockwise."
        case .counter:
            return "Turn the \(faceName) face counter-clockwise."
        case .double:
            return "Turn the \(faceName) face twice (180 degrees)."
        }
    }

    private var faceName: String {
        switch move.turn {
        case .U: return "top"
        case .D: return "bottom"
        case .L: return "left"
        case .R: return "right"
        case .F: return "front"
        case .B: return "back"
        }
    }
}
