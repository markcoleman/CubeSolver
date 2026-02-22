import CubeCore

public struct SolveModeDebugFixture: Sendable {
    public let initialState: CubeState
    public let solution: [Move]

    public init(initialState: CubeState, solution: [Move]) {
        self.initialState = initialState
        self.solution = solution
    }

    public static func medium() -> SolveModeDebugFixture {
        fromScramble(baseScramble)
    }

    public static func stress() -> SolveModeDebugFixture {
        fromScramble(baseScramble + baseScramble + baseScramble)
    }

    private static func fromScramble(_ scramble: [Move]) -> SolveModeDebugFixture {
        let initial = CubeReducer.apply(scramble, to: CubeState())
        let solveMoves = scramble.reversed().map(\.inverse)
        return SolveModeDebugFixture(initialState: initial, solution: solveMoves)
    }

    private static let baseScramble: [Move] = [
        Move(turn: .R, amount: .clockwise),
        Move(turn: .U, amount: .counter),
        Move(turn: .F, amount: .double),
        Move(turn: .L, amount: .clockwise),
        Move(turn: .B, amount: .counter),
        Move(turn: .D, amount: .double),
        Move(turn: .R, amount: .double),
        Move(turn: .F, amount: .clockwise),
        Move(turn: .U, amount: .clockwise),
        Move(turn: .L, amount: .counter),
        Move(turn: .B, amount: .double),
        Move(turn: .D, amount: .clockwise),
        Move(turn: .R, amount: .counter),
        Move(turn: .U, amount: .double),
        Move(turn: .F, amount: .counter),
        Move(turn: .L, amount: .double),
        Move(turn: .B, amount: .clockwise),
        Move(turn: .D, amount: .counter),
        Move(turn: .R, amount: .clockwise),
        Move(turn: .U, amount: .clockwise),
        Move(turn: .F, amount: .clockwise),
        Move(turn: .L, amount: .clockwise),
        Move(turn: .B, amount: .clockwise),
        Move(turn: .D, amount: .clockwise)
    ]
}
