//
//  StickerColorClassifier.swift
//  CubeSolver - Sticker Color Recognition
//
//  Created by GitHub Copilot
//

#if canImport(CoreVideo) && canImport(CoreGraphics)

import Foundation
import CoreVideo
import CoreGraphics
import CubeCore

/// Service for classifying sticker colors from video frames
public actor StickerColorClassifier {
    
    // MARK: - Configuration
    
    /// Color classification threshold
    public var classificationThreshold: Float = 0.6
    
    /// Use depth data for lighting normalization
    public var useDepthCorrection: Bool = true
    
    // MARK: - Private Properties
    
    // Reference colors in HSB color space for each cube color
    private let referenceColors: [CubeColor: HSBColor] = [
        .white: HSBColor(h: 0, s: 0, b: 0.95),
        .yellow: HSBColor(h: 60, s: 0.85, b: 0.95),
        .red: HSBColor(h: 0, s: 0.85, b: 0.85),
        .orange: HSBColor(h: 30, s: 0.85, b: 0.90),
        .blue: HSBColor(h: 220, s: 0.75, b: 0.80),
        .green: HSBColor(h: 120, s: 0.70, b: 0.70)
    ]
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public Methods
    
    /// Classify sticker colors from a cube face region
    /// - Parameters:
    ///   - buffer: The pixel buffer containing the frame
    ///   - faceRect: The bounding box of the detected cube face (normalized coordinates)
    ///   - depthBuffer: Optional depth buffer for lighting correction
    /// - Returns: Array of 9 classified colors (top-left to bottom-right)
    public func classifyStickers(
        buffer: CVPixelBuffer,
        faceRect: CGRect,
        depthBuffer: CVPixelBuffer? = nil
    ) async -> [CubeColor] {
        // Lock pixel buffer for reading
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
            return Array(repeating: .white, count: 9)
        }
        
        // Convert normalized rect to pixel coordinates
        let pixelRect = CGRect(
            x: faceRect.minX * CGFloat(width),
            y: faceRect.minY * CGFloat(height),
            width: faceRect.width * CGFloat(width),
            height: faceRect.height * CGFloat(height)
        )
        
        // Sample 9 grid points (3x3 grid)
        var colors: [CubeColor] = []
        
        for row in 0..<3 {
            for col in 0..<3 {
                // Calculate sample point (center of each cell)
                let cellWidth = pixelRect.width / 3.0
                let cellHeight = pixelRect.height / 3.0
                
                let sampleX = Int(pixelRect.minX + (CGFloat(col) + 0.5) * cellWidth)
                let sampleY = Int(pixelRect.minY + (CGFloat(row) + 0.5) * cellHeight)
                
                // Sample color at this point
                if let sampledColor = sampleColor(
                    at: CGPoint(x: sampleX, y: sampleY),
                    buffer: buffer,
                    bytesPerRow: bytesPerRow,
                    width: width,
                    height: height,
                    baseAddress: baseAddress
                ) {
                    let normalizedColor = normalizeColor(sampledColor)
                    let classifiedColor = classifyColor(normalizedColor)
                    colors.append(classifiedColor)
                } else {
                    colors.append(.white) // Default
                }
            }
        }
        
        return colors
    }
    
    // MARK: - Private Methods
    
    /// Sample color at a specific point in the buffer
    private func sampleColor(
        at point: CGPoint,
        buffer: CVPixelBuffer,
        bytesPerRow: Int,
        width: Int,
        height: Int,
        baseAddress: UnsafeMutableRawPointer
    ) -> RGBColor? {
        let x = Int(point.x)
        let y = Int(point.y)
        
        guard x >= 0 && x < width && y >= 0 && y < height else {
            return nil
        }
        
        // Calculate offset (assuming BGRA format)
        let offset = y * bytesPerRow + x * 4
        let pixel = baseAddress.advanced(by: offset).assumingMemoryBound(to: UInt8.self)
        
        let b = pixel[0]
        let g = pixel[1]
        let r = pixel[2]
        // let a = pixel[3] // Alpha not needed
        
        return RGBColor(
            r: Float(r) / 255.0,
            g: Float(g) / 255.0,
            b: Float(b) / 255.0
        )
    }
    
    /// Normalize color for lighting conditions
    private func normalizeColor(_ color: RGBColor) -> RGBColor {
        // Simple white balance normalization
        // In production, this would use depth data and ambient light sensors
        
        let max = Swift.max(color.r, color.g, color.b)
        
        // Avoid division by zero
        guard max > 0.1 else {
            return color
        }
        
        // Normalize to brightest channel
        return RGBColor(
            r: color.r / max,
            g: color.g / max,
            b: color.b / max
        )
    }
    
    /// Classify RGB color to cube color
    private func classifyColor(_ rgb: RGBColor) -> CubeColor {
        let hsb = rgbToHSB(rgb)
        
        var bestMatch: CubeColor = .white
        var bestDistance: Float = .infinity
        
        for (cubeColor, refColor) in referenceColors {
            let distance = colorDistance(hsb, refColor)
            
            if distance < bestDistance {
                bestDistance = distance
                bestMatch = cubeColor
            }
        }
        
        return bestMatch
    }
    
    /// Calculate distance between two colors in HSB space
    private func colorDistance(_ color1: HSBColor, _ color2: HSBColor) -> Float {
        // Handle hue wraparound (360 degrees = 0 degrees)
        let hueDiff = min(
            abs(color1.h - color2.h),
            360 - abs(color1.h - color2.h)
        )
        
        // Weighted distance in HSB space
        let hueWeight: Float = 2.0
        let satWeight: Float = 1.0
        let briWeight: Float = 1.0
        
        let distance = sqrt(
            pow(hueDiff / 180.0 * hueWeight, 2) +
            pow((color1.s - color2.s) * satWeight, 2) +
            pow((color1.b - color2.b) * briWeight, 2)
        )
        
        return distance
    }
    
    /// Convert RGB to HSB color space
    private func rgbToHSB(_ rgb: RGBColor) -> HSBColor {
        let r = rgb.r
        let g = rgb.g
        let b = rgb.b
        
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC
        
        // Brightness
        let brightness = maxC
        
        // Saturation
        let saturation = maxC == 0 ? 0 : delta / maxC
        
        // Hue
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
        
        return HSBColor(h: hue, s: saturation, b: brightness)
    }
}

// MARK: - Color Types

/// RGB color representation
private struct RGBColor {
    let r: Float // 0-1
    let g: Float // 0-1
    let b: Float // 0-1
}

/// HSB (Hue-Saturation-Brightness) color representation
private struct HSBColor {
    let h: Float // 0-360 degrees
    let s: Float // 0-1
    let b: Float // 0-1
}

#endif
