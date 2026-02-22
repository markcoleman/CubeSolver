import Foundation

public enum ValidationErrorType: String, Codable, Sendable {
    case countMismatch
    case nonUniqueCenters
    case invalidFace
    case missingPiece
    case duplicatePiece
    case invalidEdgeOrientation
    case invalidCornerOrientation
    case impossibleParity
}

public struct ValidationError: Error, LocalizedError, Equatable, Sendable {
    public let type: ValidationErrorType
    public let message: String
    public let suggestedFix: String
    public let likelyFaces: [FaceId]

    public init(
        type: ValidationErrorType,
        message: String,
        suggestedFix: String,
        likelyFaces: [FaceId] = []
    ) {
        self.type = type
        self.message = message
        self.suggestedFix = suggestedFix
        self.likelyFaces = likelyFaces
    }

    public var errorDescription: String? {
        message
    }
}

public protocol CubeStateValidating: Sendable {
    func validate(state: CubeState) -> Result<Void, ValidationError>
}

public struct CubeStateValidator: CubeStateValidating {
    public init() {}

    public func validate(state: CubeState) -> Result<Void, ValidationError> {
        if let failure = validateFaceConfiguration(state) {
            return .failure(failure)
        }
        if let failure = validateColorCounts(state) {
            return .failure(failure)
        }
        if let failure = validateCenters(state) {
            return .failure(failure)
        }
        if let failure = validatePieceConstraints(state) {
            return .failure(failure)
        }

        return .success(())
    }

    public func validateOrThrow(state: CubeState) throws {
        switch validate(state: state) {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    private func validateFaceConfiguration(_ state: CubeState) -> ValidationError? {
        for face in Face.allCases {
            guard let stickers = state.faces[face] else {
                return ValidationError(
                    type: .invalidFace,
                    message: "Face \(face.rawValue) is missing.",
                    suggestedFix: "Re-scan this face or fill it in manually.",
                    likelyFaces: [FaceId(face: face)]
                )
            }
            guard stickers.count == CubeFaceGrid.stickerCount else {
                return ValidationError(
                    type: .invalidFace,
                    message: "Face \(face.rawValue) has \(stickers.count) stickers; expected 9.",
                    suggestedFix: "Use manual edit to correct this face.",
                    likelyFaces: [FaceId(face: face)]
                )
            }
        }
        return nil
    }

    private func validateColorCounts(_ state: CubeState) -> ValidationError? {
        var counts: [CubeColor: Int] = [:]
        for color in CubeColor.allCases {
            counts[color] = 0
        }

        for face in Face.allCases {
            guard let stickers = state.faces[face] else { continue }
            for sticker in stickers {
                counts[sticker, default: 0] += 1
            }
        }

        for color in CubeColor.allCases {
            let count = counts[color, default: 0]
            if count != 9 {
                let direction = count > 9 ? "too many" : "too few"
                return ValidationError(
                    type: .countMismatch,
                    message: "Color \(color.rawValue) has \(count) stickers; this is \(direction) (expected 9).",
                    suggestedFix: "Open manual edit and rebalance sticker colors to exactly 9 each."
                )
            }
        }

        return nil
    }

    private func validateCenters(_ state: CubeState) -> ValidationError? {
        var centers: Set<CubeColor> = []
        for face in Face.allCases {
            guard let center = state.centerColor(of: face) else {
                return ValidationError(
                    type: .invalidFace,
                    message: "Face \(face.rawValue) has no center sticker.",
                    suggestedFix: "Re-scan or edit that face center.",
                    likelyFaces: [FaceId(face: face)]
                )
            }
            centers.insert(center)
        }

        if centers.count != Face.allCases.count {
            return ValidationError(
                type: .nonUniqueCenters,
                message: "Center colors must be unique across all six faces.",
                suggestedFix: "Check center stickers first; one face center is likely misclassified."
            )
        }

        return nil
    }

    private func validatePieceConstraints(_ state: CubeState) -> ValidationError? {
        let centerColors = Face.allCases.reduce(into: [Face: CubeColor]()) { result, face in
            if let center = state.centerColor(of: face) {
                result[face] = center
            }
        }

        guard centerColors.count == Face.allCases.count else {
            return ValidationError(
                type: .invalidFace,
                message: "Cannot evaluate piece constraints without all center colors.",
                suggestedFix: "Ensure each scanned face includes a center sticker."
            )
        }

        let edgeValidation = validateEdges(state: state, centers: centerColors)
        if let error = edgeValidation.error {
            return error
        }

        let cornerValidation = validateCorners(state: state, centers: centerColors)
        if let error = cornerValidation.error {
            return error
        }

        guard edgeValidation.orientationSum % 2 == 0 else {
            return ValidationError(
                type: .invalidEdgeOrientation,
                message: "Edge orientation is impossible for a physical 3x3 cube.",
                suggestedFix: "A flipped edge is likely mis-scanned. Re-scan front/back adjacent edges."
            )
        }

        guard cornerValidation.orientationSum % 3 == 0 else {
            return ValidationError(
                type: .invalidCornerOrientation,
                message: "Corner orientation is impossible for a physical 3x3 cube.",
                suggestedFix: "A twisted corner is likely mis-scanned. Re-scan top-layer corners or edit manually."
            )
        }

        let edgeParity = parity(of: edgeValidation.permutation)
        let cornerParity = parity(of: cornerValidation.permutation)
        guard edgeParity == cornerParity else {
            return ValidationError(
                type: .impossibleParity,
                message: "Piece permutation parity is impossible on a real cube.",
                suggestedFix: "At least one piece is incorrect. Re-scan the most uncertain face and validate again."
            )
        }

        return nil
    }
}

private extension CubeStateValidator {
    struct StickerRef {
        let face: Face
        let index: Int
    }

    struct EdgeDefinition {
        let name: String
        let stickers: [StickerRef]
    }

    struct CornerDefinition {
        let name: String
        let stickers: [StickerRef]
    }

    struct PieceValidation {
        let permutation: [Int]
        let orientationSum: Int
        let error: ValidationError?
    }

    static let edgeDefinitions: [EdgeDefinition] = [
        EdgeDefinition(name: "UR", stickers: [StickerRef(face: .up, index: 5), StickerRef(face: .right, index: 1)]),
        EdgeDefinition(name: "UF", stickers: [StickerRef(face: .up, index: 7), StickerRef(face: .front, index: 1)]),
        EdgeDefinition(name: "UL", stickers: [StickerRef(face: .up, index: 3), StickerRef(face: .left, index: 1)]),
        EdgeDefinition(name: "UB", stickers: [StickerRef(face: .up, index: 1), StickerRef(face: .back, index: 1)]),
        EdgeDefinition(name: "DR", stickers: [StickerRef(face: .down, index: 5), StickerRef(face: .right, index: 7)]),
        EdgeDefinition(name: "DF", stickers: [StickerRef(face: .down, index: 1), StickerRef(face: .front, index: 7)]),
        EdgeDefinition(name: "DL", stickers: [StickerRef(face: .down, index: 3), StickerRef(face: .left, index: 7)]),
        EdgeDefinition(name: "DB", stickers: [StickerRef(face: .down, index: 7), StickerRef(face: .back, index: 7)]),
        EdgeDefinition(name: "FR", stickers: [StickerRef(face: .front, index: 5), StickerRef(face: .right, index: 3)]),
        EdgeDefinition(name: "FL", stickers: [StickerRef(face: .front, index: 3), StickerRef(face: .left, index: 5)]),
        EdgeDefinition(name: "BL", stickers: [StickerRef(face: .back, index: 5), StickerRef(face: .left, index: 3)]),
        EdgeDefinition(name: "BR", stickers: [StickerRef(face: .back, index: 3), StickerRef(face: .right, index: 5)])
    ]

    static let cornerDefinitions: [CornerDefinition] = [
        CornerDefinition(name: "URF", stickers: [StickerRef(face: .up, index: 8), StickerRef(face: .right, index: 0), StickerRef(face: .front, index: 2)]),
        CornerDefinition(name: "UFL", stickers: [StickerRef(face: .up, index: 6), StickerRef(face: .front, index: 0), StickerRef(face: .left, index: 2)]),
        CornerDefinition(name: "ULB", stickers: [StickerRef(face: .up, index: 0), StickerRef(face: .left, index: 0), StickerRef(face: .back, index: 2)]),
        CornerDefinition(name: "UBR", stickers: [StickerRef(face: .up, index: 2), StickerRef(face: .back, index: 0), StickerRef(face: .right, index: 2)]),
        CornerDefinition(name: "DFR", stickers: [StickerRef(face: .down, index: 2), StickerRef(face: .front, index: 8), StickerRef(face: .right, index: 6)]),
        CornerDefinition(name: "DLF", stickers: [StickerRef(face: .down, index: 0), StickerRef(face: .left, index: 8), StickerRef(face: .front, index: 6)]),
        CornerDefinition(name: "DBL", stickers: [StickerRef(face: .down, index: 6), StickerRef(face: .back, index: 8), StickerRef(face: .left, index: 6)]),
        CornerDefinition(name: "DRB", stickers: [StickerRef(face: .down, index: 8), StickerRef(face: .right, index: 8), StickerRef(face: .back, index: 6)])
    ]

    func validateEdges(state: CubeState, centers: [Face: CubeColor]) -> PieceValidation {
        var expectedPieceIndexByKey: [String: Int] = [:]

        for (index, definition) in Self.edgeDefinitions.enumerated() {
            let colors = definition.stickers.compactMap { centers[$0.face] }
            expectedPieceIndexByKey[pieceKey(colors)] = index
        }

        var seenIndices = Set<Int>()
        var permutation: [Int] = []
        permutation.reserveCapacity(Self.edgeDefinitions.count)
        var orientationSum = 0

        for definition in Self.edgeDefinitions {
            let observed = observedColors(for: definition.stickers, from: state)
            let key = pieceKey(observed.colors)

            guard let pieceIndex = expectedPieceIndexByKey[key] else {
                return PieceValidation(
                    permutation: permutation,
                    orientationSum: orientationSum,
                    error: ValidationError(
                        type: .missingPiece,
                        message: "Edge piece at \(definition.name) has impossible colors \(rawKey(observed.colors)).",
                        suggestedFix: "Re-scan the faces around \(definition.name) or edit those stickers manually.",
                        likelyFaces: observed.faces.map(FaceId.init(face:))
                    )
                )
            }

            if seenIndices.contains(pieceIndex) {
                return PieceValidation(
                    permutation: permutation,
                    orientationSum: orientationSum,
                    error: ValidationError(
                        type: .duplicatePiece,
                        message: "Duplicate edge piece detected near \(definition.name).",
                        suggestedFix: "Open manual edit and correct one of the duplicate edge colors.",
                        likelyFaces: observed.faces.map(FaceId.init(face:))
                    )
                )
            }

            seenIndices.insert(pieceIndex)
            permutation.append(pieceIndex)
            orientationSum += edgeOrientation(for: observed, centers: centers)
        }

        if seenIndices.count != Self.edgeDefinitions.count {
            return PieceValidation(
                permutation: permutation,
                orientationSum: orientationSum,
                error: ValidationError(
                    type: .missingPiece,
                    message: "At least one edge piece is missing from the scanned pattern.",
                    suggestedFix: "Re-scan uncertain faces, especially where colors look noisy."
                )
            )
        }

        return PieceValidation(permutation: permutation, orientationSum: orientationSum, error: nil)
    }

    func validateCorners(state: CubeState, centers: [Face: CubeColor]) -> PieceValidation {
        var expectedPieceIndexByKey: [String: Int] = [:]

        for (index, definition) in Self.cornerDefinitions.enumerated() {
            let colors = definition.stickers.compactMap { centers[$0.face] }
            expectedPieceIndexByKey[pieceKey(colors)] = index
        }

        var seenIndices = Set<Int>()
        var permutation: [Int] = []
        permutation.reserveCapacity(Self.cornerDefinitions.count)
        var orientationSum = 0

        for definition in Self.cornerDefinitions {
            let observed = observedColors(for: definition.stickers, from: state)
            let key = pieceKey(observed.colors)

            guard let pieceIndex = expectedPieceIndexByKey[key] else {
                return PieceValidation(
                    permutation: permutation,
                    orientationSum: orientationSum,
                    error: ValidationError(
                        type: .missingPiece,
                        message: "Corner piece at \(definition.name) has impossible colors \(rawKey(observed.colors)).",
                        suggestedFix: "Re-scan or manually fix the corner touching \(definition.name).",
                        likelyFaces: observed.faces.map(FaceId.init(face:))
                    )
                )
            }

            if seenIndices.contains(pieceIndex) {
                return PieceValidation(
                    permutation: permutation,
                    orientationSum: orientationSum,
                    error: ValidationError(
                        type: .duplicatePiece,
                        message: "Duplicate corner piece detected near \(definition.name).",
                        suggestedFix: "Use manual edit on the corner around \(definition.name).",
                        likelyFaces: observed.faces.map(FaceId.init(face:))
                    )
                )
            }

            seenIndices.insert(pieceIndex)
            permutation.append(pieceIndex)
            orientationSum += cornerOrientation(for: observed, centers: centers)
        }

        if seenIndices.count != Self.cornerDefinitions.count {
            return PieceValidation(
                permutation: permutation,
                orientationSum: orientationSum,
                error: ValidationError(
                    type: .missingPiece,
                    message: "At least one corner piece is missing from the scanned pattern.",
                    suggestedFix: "Re-scan uncertain corners and validate again."
                )
            )
        }

        return PieceValidation(permutation: permutation, orientationSum: orientationSum, error: nil)
    }

    func observedColors(
        for stickers: [StickerRef],
        from state: CubeState
    ) -> (colors: [CubeColor], faces: [Face]) {
        var colors: [CubeColor] = []
        var faces: [Face] = []

        for sticker in stickers {
            let color = state.getSticker(face: sticker.face, index: sticker.index) ?? .white
            colors.append(color)
            faces.append(sticker.face)
        }

        return (colors, faces)
    }

    func edgeOrientation(
        for observed: (colors: [CubeColor], faces: [Face]),
        centers: [Face: CubeColor]
    ) -> Int {
        guard let upColor = centers[.up],
              let downColor = centers[.down],
              let frontColor = centers[.front],
              let backColor = centers[.back] else {
            return 0
        }

        if let index = observed.colors.firstIndex(where: { $0 == upColor || $0 == downColor }) {
            let face = observed.faces[index]
            return (face == .up || face == .down) ? 0 : 1
        }

        if let index = observed.colors.firstIndex(where: { $0 == frontColor || $0 == backColor }) {
            let face = observed.faces[index]
            return (face == .front || face == .back) ? 0 : 1
        }

        return 0
    }

    func cornerOrientation(
        for observed: (colors: [CubeColor], faces: [Face]),
        centers: [Face: CubeColor]
    ) -> Int {
        guard let upColor = centers[.up], let downColor = centers[.down] else {
            return 0
        }

        guard let index = observed.colors.firstIndex(where: { $0 == upColor || $0 == downColor }) else {
            return 0
        }

        switch observed.faces[index] {
        case .up, .down:
            return 0
        case .left, .right:
            return 1
        case .front, .back:
            return 2
        }
    }

    func parity(of permutation: [Int]) -> Int {
        guard !permutation.isEmpty else { return 0 }

        var visited = Array(repeating: false, count: permutation.count)
        var swaps = 0

        for index in permutation.indices where !visited[index] {
            var cycleLength = 0
            var cursor = index

            while !visited[cursor] {
                visited[cursor] = true
                cycleLength += 1
                cursor = permutation[cursor]
            }

            if cycleLength > 1 {
                swaps += cycleLength - 1
            }
        }

        return swaps % 2
    }

    func pieceKey(_ colors: [CubeColor]) -> String {
        colors.map(\.rawValue).sorted().joined(separator: "")
    }

    func rawKey(_ colors: [CubeColor]) -> String {
        colors.map(\.rawValue).joined(separator: "")
    }
}
