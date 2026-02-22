import Foundation

public enum KociembaCodecError: Error, LocalizedError, Equatable, Sendable {
    case invalidLength(expected: Int, actual: Int)
    case invalidCharacter(Character)
    case invalidFace(Face)
    case unknownCenterColor(CubeColor)

    public var errorDescription: String? {
        switch self {
        case .invalidLength(let expected, let actual):
            return "Kociemba string must be \(expected) characters, got \(actual)."
        case .invalidCharacter(let character):
            return "Unsupported Kociemba character: \(character)."
        case .invalidFace(let face):
            return "Face \(face.rawValue) does not contain exactly 9 stickers."
        case .unknownCenterColor(let color):
            return "Center mapping missing for color \(color.rawValue)."
        }
    }
}

public struct KociembaCodec: Sendable {
    private static let faceOrder: [FaceId] = [.up, .right, .front, .down, .left, .back]

    public init() {}

    /// Encodes a cube state into URFDLB sticker-letter notation expected by Kociemba style solvers.
    public func encode(_ state: CubeState) throws -> String {
        var colorToFaceLetter: [CubeColor: Character] = [:]

        for id in Self.faceOrder {
            guard let center = state.centerColor(of: id.face) else {
                throw KociembaCodecError.invalidFace(id.face)
            }
            colorToFaceLetter[center] = Character(id.rawValue)
        }

        var encoded = ""
        encoded.reserveCapacity(54)

        for id in Self.faceOrder {
            guard let stickers = state.faces[id.face], stickers.count == 9 else {
                throw KociembaCodecError.invalidFace(id.face)
            }

            for color in stickers {
                guard let faceLetter = colorToFaceLetter[color] else {
                    throw KociembaCodecError.unknownCenterColor(color)
                }
                encoded.append(faceLetter)
            }
        }

        return encoded
    }

    /// Decodes URFDLB sticker notation to a cube state using standard color mapping.
    public func decode(_ kociemba: String) throws -> CubeState {
        let symbols = Array(kociemba)
        guard symbols.count == 54 else {
            throw KociembaCodecError.invalidLength(expected: 54, actual: symbols.count)
        }

        let standardColors: [Character: CubeColor] = [
            "U": .white,
            "R": .blue,
            "F": .red,
            "D": .yellow,
            "L": .green,
            "B": .orange
        ]

        var faces: [Face: [CubeColor]] = [:]
        var cursor = 0

        for id in Self.faceOrder {
            var stickers: [CubeColor] = []
            stickers.reserveCapacity(9)

            for _ in 0..<9 {
                let symbol = symbols[cursor]
                cursor += 1
                guard let color = standardColors[symbol] else {
                    throw KociembaCodecError.invalidCharacter(symbol)
                }
                stickers.append(color)
            }

            faces[id.face] = stickers
        }

        return CubeState(faces: faces)
    }
}

public enum MoveNotationCodecError: Error, LocalizedError, Equatable, Sendable {
    case invalidMoveToken(String)

    public var errorDescription: String? {
        switch self {
        case .invalidMoveToken(let token):
            return "Invalid move token: \(token)."
        }
    }
}

public struct MoveNotationCodec: Sendable {
    public init() {}

    public func encode(_ moves: [Move]) -> String {
        moves.map(\.notation).joined(separator: " ")
    }

    public func decode(_ sequence: String) throws -> [Move] {
        let tokens = sequence
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)

        var moves: [Move] = []
        moves.reserveCapacity(tokens.count)

        for token in tokens {
            guard let move = Move(notation: token) else {
                throw MoveNotationCodecError.invalidMoveToken(token)
            }
            moves.append(move)
        }

        return moves
    }
}
