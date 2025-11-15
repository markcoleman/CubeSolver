//
//  CubeValidation.swift
//  CubeSolver
//
//  Validation module for Rubik's Cube configurations
//

import Foundation

// MARK: - Validation Errors

/// Errors that can occur during cube validation
enum CubeValidationError: Error, LocalizedError, Equatable {
    case invalidStickerCount(color: CubeColor, count: Int)
    case nonUniqueCenters
    case invalidCornerOrientation
    case invalidEdgeOrientation
    case invalidPermutationParity
    case invalidFaceConfiguration
    
    var errorDescription: String? {
        switch self {
        case .invalidStickerCount(let color, let count):
            if count > 9 {
                return "You have too many stickers of color \(color.rawValue). Expected 9, found \(count)."
            } else {
                return "You have too few stickers of color \(color.rawValue). Expected 9, found \(count)."
            }
        case .nonUniqueCenters:
            return "Center colors must all be unique."
        case .invalidCornerOrientation:
            return "Corner twist error: pattern impossible. The corner pieces cannot be oriented this way on a real cube."
        case .invalidEdgeOrientation:
            return "Edge flip error: pattern impossible. The edge pieces cannot be flipped this way on a real cube."
        case .invalidPermutationParity:
            return "Permutation parity invalid. The pieces cannot be arranged this way on a real cube."
        case .invalidFaceConfiguration:
            return "Invalid face configuration. Each face must have exactly 9 stickers."
        }
    }
}

// MARK: - Cube Pieces

/// Represents a corner piece with its three colors
struct CornerPiece: Equatable {
    let colors: [CubeColor]
    let position: Int
    
    init(colors: [CubeColor], position: Int) {
        self.colors = colors
        self.position = position
    }
}

/// Represents an edge piece with its two colors
struct EdgePiece: Equatable {
    let colors: [CubeColor]
    let position: Int
    
    init(colors: [CubeColor], position: Int) {
        self.colors = colors
        self.position = position
    }
}

// MARK: - Cube Validator

/// Validates Rubik's Cube configurations for basic correctness and physical legality
class CubeValidator {
    
    /// Validate a cube state for all constraints
    /// - Parameter state: The cube state to validate
    /// - Throws: CubeValidationError if validation fails
    static func validate(_ state: CubeState) throws {
        try validateBasic(state)
        try validatePhysicalLegality(state)
    }
    
    // MARK: - Basic Validation
    
    /// Validate basic cube constraints
    /// - Parameter state: The cube state to validate
    /// - Throws: CubeValidationError if basic validation fails
    static func validateBasic(_ state: CubeState) throws {
        // Ensure each face has exactly 9 stickers
        for face in Face.allCases {
            guard let stickers = state.faces[face], stickers.count == 9 else {
                throw CubeValidationError.invalidFaceConfiguration
            }
        }
        
        // Count stickers of each color
        var colorCounts: [CubeColor: Int] = [:]
        for color in CubeColor.allCases {
            colorCounts[color] = 0
        }
        
        for face in Face.allCases {
            if let stickers = state.faces[face] {
                for color in stickers {
                    colorCounts[color, default: 0] += 1
                }
            }
        }
        
        // Validate each color has exactly 9 stickers
        for color in CubeColor.allCases {
            let count = colorCounts[color] ?? 0
            if count != 9 {
                throw CubeValidationError.invalidStickerCount(color: color, count: count)
            }
        }
        
        // Validate all center stickers are unique
        var centerColors: Set<CubeColor> = []
        for face in Face.allCases {
            if let center = state.centerColor(of: face) {
                if centerColors.contains(center) {
                    throw CubeValidationError.nonUniqueCenters
                }
                centerColors.insert(center)
            }
        }
        
        if centerColors.count != 6 {
            throw CubeValidationError.nonUniqueCenters
        }
    }
    
    // MARK: - Physical Legality Validation
    
    /// Validate physical legality of cube configuration
    /// - Parameter state: The cube state to validate
    /// - Throws: CubeValidationError if physical validation fails
    static func validatePhysicalLegality(_ state: CubeState) throws {
        let corners = extractCorners(from: state)
        let edges = extractEdges(from: state)
        
        // Validate corner orientation
        let cornerOrientationSum = calculateCornerOrientationSum(corners, state: state)
        if cornerOrientationSum % 3 != 0 {
            throw CubeValidationError.invalidCornerOrientation
        }
        
        // Validate edge orientation
        let edgeOrientationSum = calculateEdgeOrientationSum(edges, state: state)
        if edgeOrientationSum % 2 != 0 {
            throw CubeValidationError.invalidEdgeOrientation
        }
        
        // Validate permutation parity
        let cornerParity = calculatePermutationParity(corners)
        let edgeParity = calculatePermutationParity(edges)
        if cornerParity != edgeParity {
            throw CubeValidationError.invalidPermutationParity
        }
    }
    
    // MARK: - Piece Extraction
    
    /// Extract corner pieces from cube state
    private static func extractCorners(from state: CubeState) -> [CornerPiece] {
        var corners: [CornerPiece] = []
        
        // Define the 8 corner positions by their sticker indices on three adjacent faces
        // Corner 0: UFR (Up-Front-Right)
        if let upColors = state.faces[.up],
           let frontColors = state.faces[.front],
           let rightColors = state.faces[.right] {
            corners.append(CornerPiece(colors: [upColors[8], frontColors[2], rightColors[0]], position: 0))
        }
        
        // Corner 1: UFL (Up-Front-Left)
        if let upColors = state.faces[.up],
           let frontColors = state.faces[.front],
           let leftColors = state.faces[.left] {
            corners.append(CornerPiece(colors: [upColors[6], frontColors[0], leftColors[2]], position: 1))
        }
        
        // Corner 2: UBL (Up-Back-Left)
        if let upColors = state.faces[.up],
           let backColors = state.faces[.back],
           let leftColors = state.faces[.left] {
            corners.append(CornerPiece(colors: [upColors[0], backColors[2], leftColors[0]], position: 2))
        }
        
        // Corner 3: UBR (Up-Back-Right)
        if let upColors = state.faces[.up],
           let backColors = state.faces[.back],
           let rightColors = state.faces[.right] {
            corners.append(CornerPiece(colors: [upColors[2], backColors[0], rightColors[2]], position: 3))
        }
        
        // Corner 4: DFR (Down-Front-Right)
        if let downColors = state.faces[.down],
           let frontColors = state.faces[.front],
           let rightColors = state.faces[.right] {
            corners.append(CornerPiece(colors: [downColors[2], frontColors[8], rightColors[6]], position: 4))
        }
        
        // Corner 5: DFL (Down-Front-Left)
        if let downColors = state.faces[.down],
           let frontColors = state.faces[.front],
           let leftColors = state.faces[.left] {
            corners.append(CornerPiece(colors: [downColors[0], frontColors[6], leftColors[8]], position: 5))
        }
        
        // Corner 6: DBL (Down-Back-Left)
        if let downColors = state.faces[.down],
           let backColors = state.faces[.back],
           let leftColors = state.faces[.left] {
            corners.append(CornerPiece(colors: [downColors[6], backColors[8], leftColors[6]], position: 6))
        }
        
        // Corner 7: DBR (Down-Back-Right)
        if let downColors = state.faces[.down],
           let backColors = state.faces[.back],
           let rightColors = state.faces[.right] {
            corners.append(CornerPiece(colors: [downColors[8], backColors[6], rightColors[8]], position: 7))
        }
        
        return corners
    }
    
    /// Extract edge pieces from cube state
    private static func extractEdges(from state: CubeState) -> [EdgePiece] {
        var edges: [EdgePiece] = []
        
        // Define the 12 edge positions by their sticker indices on two adjacent faces
        // Edge 0: UF (Up-Front)
        if let upColors = state.faces[.up],
           let frontColors = state.faces[.front] {
            edges.append(EdgePiece(colors: [upColors[7], frontColors[1]], position: 0))
        }
        
        // Edge 1: UL (Up-Left)
        if let upColors = state.faces[.up],
           let leftColors = state.faces[.left] {
            edges.append(EdgePiece(colors: [upColors[3], leftColors[1]], position: 1))
        }
        
        // Edge 2: UB (Up-Back)
        if let upColors = state.faces[.up],
           let backColors = state.faces[.back] {
            edges.append(EdgePiece(colors: [upColors[1], backColors[1]], position: 2))
        }
        
        // Edge 3: UR (Up-Right)
        if let upColors = state.faces[.up],
           let rightColors = state.faces[.right] {
            edges.append(EdgePiece(colors: [upColors[5], rightColors[1]], position: 3))
        }
        
        // Edge 4: DF (Down-Front)
        if let downColors = state.faces[.down],
           let frontColors = state.faces[.front] {
            edges.append(EdgePiece(colors: [downColors[1], frontColors[7]], position: 4))
        }
        
        // Edge 5: DL (Down-Left)
        if let downColors = state.faces[.down],
           let leftColors = state.faces[.left] {
            edges.append(EdgePiece(colors: [downColors[3], leftColors[7]], position: 5))
        }
        
        // Edge 6: DB (Down-Back)
        if let downColors = state.faces[.down],
           let backColors = state.faces[.back] {
            edges.append(EdgePiece(colors: [downColors[7], backColors[7]], position: 6))
        }
        
        // Edge 7: DR (Down-Right)
        if let downColors = state.faces[.down],
           let rightColors = state.faces[.right] {
            edges.append(EdgePiece(colors: [downColors[5], rightColors[7]], position: 7))
        }
        
        // Edge 8: FR (Front-Right)
        if let frontColors = state.faces[.front],
           let rightColors = state.faces[.right] {
            edges.append(EdgePiece(colors: [frontColors[5], rightColors[3]], position: 8))
        }
        
        // Edge 9: FL (Front-Left)
        if let frontColors = state.faces[.front],
           let leftColors = state.faces[.left] {
            edges.append(EdgePiece(colors: [frontColors[3], leftColors[5]], position: 9))
        }
        
        // Edge 10: BL (Back-Left)
        if let backColors = state.faces[.back],
           let leftColors = state.faces[.left] {
            edges.append(EdgePiece(colors: [backColors[5], leftColors[3]], position: 10))
        }
        
        // Edge 11: BR (Back-Right)
        if let backColors = state.faces[.back],
           let rightColors = state.faces[.right] {
            edges.append(EdgePiece(colors: [backColors[3], rightColors[5]], position: 11))
        }
        
        return edges
    }
    
    // MARK: - Orientation Calculation
    
    /// Calculate corner orientation sum
    /// For a valid cube, the sum of corner orientations mod 3 must be 0
    private static func calculateCornerOrientationSum(_ corners: [CornerPiece], state: CubeState) -> Int {
        var sum = 0
        
        // Get U/D face colors (they define vertical axis)
        guard let upCenter = state.centerColor(of: .up),
              let downCenter = state.centerColor(of: .down) else {
            return 0
        }
        
        for corner in corners {
            // Orientation: 0 if U/D color on U/D face, 1 if twisted clockwise, 2 if counter-clockwise
            let orientation = getCornerOrientation(corner, upDownColors: (upCenter, downCenter))
            sum += orientation
        }
        
        return sum
    }
    
    /// Get orientation of a corner piece (0, 1, or 2)
    private static func getCornerOrientation(_ corner: CornerPiece, upDownColors: (CubeColor, CubeColor)) -> Int {
        // Check which position the U/D color is in
        for (index, color) in corner.colors.enumerated() {
            if color == upDownColors.0 || color == upDownColors.1 {
                return index // 0 = correct, 1 = twisted CW, 2 = twisted CCW
            }
        }
        return 0
    }
    
    /// Calculate edge orientation sum
    /// For a valid cube, the sum of edge orientations mod 2 must be 0
    private static func calculateEdgeOrientationSum(_ edges: [EdgePiece], state: CubeState) -> Int {
        var sum = 0
        
        // Get F/B face colors (they define front-back axis)
        guard let frontCenter = state.centerColor(of: .front),
              let backCenter = state.centerColor(of: .back) else {
            return 0
        }
        
        for edge in edges {
            // Orientation: 0 if edge is in correct orientation, 1 if flipped
            let orientation = getEdgeOrientation(edge, frontBackColors: (frontCenter, backCenter))
            sum += orientation
        }
        
        return sum
    }
    
    /// Get orientation of an edge piece (0 or 1)
    private static func getEdgeOrientation(_ edge: EdgePiece, frontBackColors: (CubeColor, CubeColor)) -> Int {
        // For edges in the U/D layers, check if F/B color is in the correct position
        // For edges in the middle layer, check if F/B color is on F/B face
        // Simplified: if F/B color is in first position when it belongs to UD edge, it's oriented
        
        let hasFrontBackColor = edge.colors.contains(frontBackColors.0) || edge.colors.contains(frontBackColors.1)
        
        if edge.position < 4 || edge.position >= 4 && edge.position < 8 {
            // U or D layer edge
            if hasFrontBackColor {
                // F/B color should be in position 1 (second position)
                return (edge.colors[1] == frontBackColors.0 || edge.colors[1] == frontBackColors.1) ? 0 : 1
            }
        } else {
            // Middle layer edge
            if hasFrontBackColor {
                // F/B color should be in position 0 (first position)
                return (edge.colors[0] == frontBackColors.0 || edge.colors[0] == frontBackColors.1) ? 0 : 1
            }
        }
        
        return 0
    }
    
    // MARK: - Permutation Parity
    
    /// Calculate permutation parity for a set of pieces
    /// Returns 0 for even parity, 1 for odd parity
    private static func calculatePermutationParity<T: Equatable>(_ pieces: [T]) -> Int {
        var parity = 0
        var visited = Array(repeating: false, count: pieces.count)
        
        for i in 0..<pieces.count {
            if !visited[i] {
                var cycleLength = 0
                var j = i
                
                while !visited[j] {
                    visited[j] = true
                    cycleLength += 1
                    
                    // Find next element in cycle
                    var found = false
                    for k in 0..<pieces.count {
                        if !visited[k] && pieces[j] == pieces[k] {
                            j = k
                            found = true
                            break
                        }
                    }
                    
                    if !found {
                        break
                    }
                }
                
                if cycleLength > 1 {
                    parity ^= (cycleLength - 1) % 2
                }
            }
        }
        
        return parity
    }
}
