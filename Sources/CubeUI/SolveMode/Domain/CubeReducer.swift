import Foundation
import CubeCore

/// Pure reducer helpers for deterministic cube state transitions in Solve Mode.
public enum CubeReducer {
    public static func apply(_ move: Move, to state: CubeState) -> CubeState {
        CubeState.apply(move: move, to: state)
    }

    public static func apply(_ moves: [Move], to state: CubeState) -> CubeState {
        moves.reduce(state) { partialState, move in
            apply(move, to: partialState)
        }
    }

    public static func invert(_ move: Move) -> Move {
        move.inverse
    }
}

public extension Move {
    var inverse: Move {
        let inverseAmount: Amount
        switch amount {
        case .clockwise:
            inverseAmount = .counter
        case .counter:
            inverseAmount = .clockwise
        case .double:
            inverseAmount = .double
        }

        return Move(turn: turn, amount: inverseAmount)
    }
}
