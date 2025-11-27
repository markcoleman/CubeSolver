//
//  AppleIntelligenceColorClassifier.swift
//  CubeSolver - Vision Framework Color Detection
//
//  Created by GitHub Copilot
//

import Foundation
import CoreVideo
import CoreGraphics
import CubeCore

#if canImport(Vision) && canImport(CoreVideo) && swift(>=5.9)

import Vision

/// Color classifier that uses Vision framework's on-device capabilities for enhanced color detection.
///
/// This classifier leverages `VNGenerateDominantColorsRequest` (iOS 17+) to detect
/// dominant colors in each sticker region. It provides more accurate color detection under
/// varying lighting conditions compared to simple HSB-based classification.
///
/// If Vision-based detection fails for any sticker, the classifier falls back to the
/// HSB-based `StickerColorClassifier` for that sticker.
public actor AppleIntelligenceColorClassifier {
    
    // MARK: - Private Properties
    
    /// Fallback classifier for when Vision detection fails
    private let fallbackClassifier = StickerColorClassifier()
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public Methods
    
    /// Classify sticker colors from a cube face region using Vision framework
    /// - Parameters:
    ///   - buffer: The pixel buffer containing the frame
    ///   - faceRect: The bounding box of the detected cube face (normalized coordinates)
    /// - Returns: Array of 9 classified colors in row-major order (top-left to bottom-right)
    public func classifyStickers(
        buffer: CVPixelBuffer,
        faceRect: CGRect
    ) async -> [CubeColor] {
        var colors: [CubeColor] = []
        
        // Pre-compute fallback colors in case Vision fails for any sticker
        // This is more efficient than calling the fallback classifier multiple times
        var fallbackColors: [CubeColor]?
        
        // Process each of the 9 stickers in the 3x3 grid
        for row in 0..<3 {
            for col in 0..<3 {
                // Calculate the normalized rect for this sticker
                let stickerRect = calculateStickerRect(row: row, col: col, within: faceRect)
                
                // Try Vision-based detection first
                if let color = await classifySingleSticker(buffer: buffer, stickerRect: stickerRect) {
                    colors.append(color)
                } else {
                    // Fallback to HSB classifier for this sticker
                    // Compute fallback colors lazily (only once if needed)
                    if fallbackColors == nil {
                        fallbackColors = await fallbackClassifier.classifyStickers(
                            buffer: buffer,
                            faceRect: faceRect
                        )
                    }
                    
                    // Calculate the sticker index (row-major order)
                    let index = row * 3 + col
                    if let fb = fallbackColors, index < fb.count {
                        colors.append(fb[index])
                    } else {
                        colors.append(.white)
                    }
                }
            }
        }
        
        return colors
    }
    
    /// Classify just the center sticker to determine face orientation
    /// - Parameters:
    ///   - buffer: The pixel buffer containing the frame
    ///   - faceRect: The bounding box of the detected cube face (normalized coordinates)
    /// - Returns: The classified color of the center sticker
    public func classifyCenterSticker(
        buffer: CVPixelBuffer,
        faceRect: CGRect
    ) async -> CubeColor {
        // Center sticker is at row 1, col 1
        let centerRect = calculateStickerRect(row: 1, col: 1, within: faceRect)
        
        if let color = await classifySingleSticker(buffer: buffer, stickerRect: centerRect) {
            return color
        }
        
        // Fallback to HSB classifier
        return await fallbackClassifier.classifyCenterSticker(buffer: buffer, faceRect: faceRect)
    }
    
    // MARK: - Private Methods
    
    /// Calculate the normalized rect for a single sticker within the face region
    private func calculateStickerRect(row: Int, col: Int, within faceRect: CGRect) -> CGRect {
        let cellWidth = faceRect.width / 3.0
        let cellHeight = faceRect.height / 3.0
        
        // Add a small margin (10%) to avoid edges and focus on the center of each sticker
        let margin = 0.1
        let marginX = cellWidth * margin
        let marginY = cellHeight * margin
        
        return CGRect(
            x: faceRect.minX + CGFloat(col) * cellWidth + marginX,
            y: faceRect.minY + CGFloat(row) * cellHeight + marginY,
            width: cellWidth - 2 * marginX,
            height: cellHeight - 2 * marginY
        )
    }
    
    /// Classify a single sticker using Vision framework
    private func classifySingleSticker(
        buffer: CVPixelBuffer,
        stickerRect: CGRect
    ) async -> CubeColor? {
        // Create the dominant color analysis request
        let request = VNGenerateDominantColorsRequest()
        
        // Set the region of interest to the sticker area
        // Note: Vision's regionOfInterest uses normalized coordinates (0-1) with origin at bottom-left.
        // The input stickerRect is already in normalized coordinates from calculateStickerRect.
        request.regionOfInterest = stickerRect
        
        // Create request handler
        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let observation = request.results?.first else {
                return nil
            }
            
            // Get the most dominant color
            guard let dominantColor = observation.dominantColors.first else {
                return nil
            }
            
            // Convert the dominant color to a cube color
            return mapToCubeColor(dominantColor)
        } catch {
            // Vision request failed, return nil to trigger fallback
            return nil
        }
    }
    
    /// Map a Vision dominant color observation to a CubeColor
    private func mapToCubeColor(_ colorInfo: VNDominantColors.DominantColor) -> CubeColor {
        // Get the CGColor from the observation
        let cgColor = colorInfo.color
        
        // Convert to RGB components
        guard let components = cgColor.components, components.count >= 3 else {
            return .white
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        // Convert RGB to HSB for classification
        let hsb = rgbToHSB(r: r, g: g, b: b)
        
        // Classify based on HSB values
        return classifyFromHSB(hue: hsb.h, saturation: hsb.s, brightness: hsb.b)
    }
    
    /// Convert RGB (0-1) to HSB color space
    private func rgbToHSB(r: Float, g: Float, b: Float) -> (h: Float, s: Float, b: Float) {
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC
        
        // Brightness
        let brightness = maxC
        
        // Saturation
        let saturation = maxC == 0 ? 0 : delta / maxC
        
        // Hue calculation based on standard RGB to HSB conversion
        // The modulo 6 represents the 6 sectors of the HSB color wheel (60° each)
        var hue: Float = 0
        if delta != 0 {
            if maxC == r {
                hue = 60 * (((g - b) / delta).truncatingRemainder(dividingBy: 6))
            } else if maxC == g {
                hue = 60 * (((b - r) / delta) + 2)
            } else {
                hue = 60 * (((r - g) / delta) + 4)
            }
        }
        
        if hue < 0 {
            hue += 360
        }
        
        return (h: hue, s: saturation, b: brightness)
    }
    
    /// Classify a color from HSB values to a CubeColor
    private func classifyFromHSB(hue: Float, saturation: Float, brightness: Float) -> CubeColor {
        // White: Low saturation, high brightness
        if saturation < 0.2 && brightness > 0.7 {
            return .white
        }
        
        // Black or very dark colors - likely white in poor lighting
        if brightness < 0.2 {
            return .white
        }
        
        // Yellow: Hue around 45-70, high saturation and brightness
        if hue >= 40 && hue <= 75 && saturation > 0.4 {
            return .yellow
        }
        
        // Orange: Hue around 15-40
        if hue >= 15 && hue < 40 && saturation > 0.4 {
            return .orange
        }
        
        // Red: Hue around 0-15 or 340-360 (red wraps around the hue wheel)
        if ((hue >= 0 && hue < 15) || (hue >= 340 && hue <= 360)) && saturation > 0.4 {
            return .red
        }
        
        // Green: Hue around 80-160
        if hue >= 80 && hue <= 160 && saturation > 0.3 {
            return .green
        }
        
        // Blue: Hue around 180-260
        if hue >= 180 && hue <= 260 && saturation > 0.3 {
            return .blue
        }
        
        // Default to white for ambiguous cases
        return .white
    }
}

#else

// Fallback implementation for platforms or toolchains that do not include
// `VNGenerateDominantColorsRequest` (iOS 17+ / macOS 14+ SDKs). This simply
// delegates to the HSB-based `StickerColorClassifier` so callers can keep
// using the same API surface without conditional compilation.
public actor AppleIntelligenceColorClassifier {
    private let fallbackClassifier = StickerColorClassifier()

    public init() {}

    public func classifyStickers(buffer: CVPixelBuffer, faceRect: CGRect) async -> [CubeColor] {
        await fallbackClassifier.classifyStickers(buffer: buffer, faceRect: faceRect)
    }

    public func classifyCenterSticker(buffer: CVPixelBuffer, faceRect: CGRect) async -> CubeColor {
        await fallbackClassifier.classifyCenterSticker(buffer: buffer, faceRect: faceRect)
    }
}

#endif
