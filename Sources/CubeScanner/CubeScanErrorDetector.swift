//
//  CubeScanErrorDetector.swift
//  CubeSolver - PROMPT 8: Error Detection and Recovery
//
//  Created by GitHub Copilot
//

#if canImport(CoreVideo)

import Foundation
import CoreVideo
import CubeCore

/// PROMPT 8: Service for detecting scanning errors and suggesting recovery
public actor CubeScanErrorDetector {
    
    // MARK: - Error Types
    
    public enum ScanError: Error, LocalizedError {
        case poorLighting(brightness: Float)
        case unreadableColors
        case invalidFaceLayout
        case impossiblePattern
        case movingTooFast
        
        public var errorDescription: String? {
            switch self {
            case .poorLighting(let brightness):
                if brightness < 0.3 {
                    return "Lighting is too dark. Try scanning in a brighter area."
                } else {
                    return "Lighting is too bright. Try reducing glare or shadows."
                }
            case .unreadableColors:
                return "We couldn't read that side—try again with better lighting and hold the cube steady."
            case .invalidFaceLayout:
                return "The face layout appears invalid. Make sure you're scanning a 3×3 cube face."
            case .impossiblePattern:
                return "This color pattern is impossible for a Rubik's cube. Please rescan."
            case .movingTooFast:
                return "Please slow down—move the cube more slowly for better detection."
            }
        }
        
        public var recoverySuggestion: String? {
            switch self {
            case .poorLighting:
                return "Move to a well-lit area with even lighting"
            case .unreadableColors:
                return "Ensure good lighting and hold steady"
            case .invalidFaceLayout:
                return "Check cube orientation and try again"
            case .impossiblePattern:
                return "Rescan this face carefully"
            case .movingTooFast:
                return "Move the cube more slowly"
            }
        }
    }
    
    // MARK: - Configuration
    
    /// Minimum acceptable brightness
    public var minBrightness: Float = 0.25
    
    /// Maximum acceptable brightness
    public var maxBrightness: Float = 0.85
    
    /// Minimum confidence for color classification
    public var minColorConfidence: Float = 0.7
    
    // MARK: - Public Methods
    
    /// Validate lighting conditions
    public func validateLighting(brightness: Float) -> ScanError? {
        if brightness < minBrightness {
            return .poorLighting(brightness: brightness)
        } else if brightness > maxBrightness {
            return .poorLighting(brightness: brightness)
        }
        return nil
    }
    
    /// Validate that colors are readable
    public func validateColors(_ colors: [CubeColor]) -> ScanError? {
        // Check if all colors are the same (likely misread)
        let uniqueColors = Set(colors)
        if uniqueColors.count == 1 {
            return .unreadableColors
        }
        
        // Check if we have too many of the same color
        let colorCounts = colors.reduce(into: [:]) { counts, color in
            counts[color, default: 0] += 1
        }
        
        // In a valid face, no color should appear more than 9 times
        // and the center color should appear at least once
        if let maxCount = colorCounts.values.max(), maxCount > 5 {
            return .unreadableColors
        }
        
        return nil
    }
    
    /// Validate face layout (must be 3×3 grid)
    public func validateFaceLayout(_ colors: [CubeColor]) -> ScanError? {
        guard colors.count == 9 else {
            return .invalidFaceLayout
        }
        return nil
    }
    
    /// Detect if cube is moving too fast
    public func detectMotion(
        currentPosition: CGPoint,
        previousPositions: [CGPoint],
        timeInterval: TimeInterval
    ) -> ScanError? {
        guard !previousPositions.isEmpty else { return nil }
        
        // Calculate average movement
        let movements = previousPositions.map { prev in
            let dx = currentPosition.x - prev.x
            let dy = currentPosition.y - prev.y
            return sqrt(dx * dx + dy * dy)
        }
        
        // Guard against empty movements array (shouldn't happen, but be safe)
        guard !movements.isEmpty else { return nil }
        
        let avgMovement = movements.reduce(0, +) / Float(movements.count)
        
        // If movement is too large, cube is moving too fast
        if avgMovement > 0.1 { // 10% of screen in short time
            return .movingTooFast
        }
        
        return nil
    }
    
    /// Validate complete cube state
    public func validateCubeState(_ state: CubeState) -> ScanError? {
        // Check that we have all 6 faces
        guard state.faces.count == 6 else {
            return .invalidFaceLayout
        }
        
        // Check each face has 9 stickers
        for (_, stickers) in state.faces {
            guard stickers.count == 9 else {
                return .invalidFaceLayout
            }
        }
        
        // Check color counts (each color should appear exactly 9 times)
        var colorCounts: [CubeColor: Int] = [:]
        for (_, stickers) in state.faces {
            for color in stickers {
                colorCounts[color, default: 0] += 1
            }
        }
        
        for (_, count) in colorCounts {
            if count != 9 {
                return .impossiblePattern
            }
        }
        
        return nil
    }
}

#endif
