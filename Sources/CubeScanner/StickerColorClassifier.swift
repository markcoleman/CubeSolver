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
    
    /// PROMPT 6: Number of sample points per sticker for noise reduction
    public var samplesPerSticker: Int = 9
    
    /// PROMPT 6: Use median filtering to reduce noise
    public var useMedianFiltering: Bool = true
    
    /// Whether to flip Y coordinates (Vision uses bottom-left origin, pixel buffer uses top-left)
    /// Set to true when faceRect comes from Vision framework detection
    public var flipYCoordinates: Bool = true
    
    /// Saturation threshold below which a color is considered "white" regardless of hue
    public var whiteSaturationThreshold: Float = 0.25
    
    /// Brightness threshold above which low-saturation colors are classified as white
    public var whiteBrightnessThreshold: Float = 0.60
    
    // MARK: - Private Properties
    
    // Reference colors in HSB color space for each cube color
    // Tuned thresholds for better discrimination between similar colors
    private let referenceColors: [CubeColor: HSBColor] = [
        .white: HSBColor(h: 0, s: 0.05, b: 0.90),
        .yellow: HSBColor(h: 55, s: 0.80, b: 0.95),
        .red: HSBColor(h: 5, s: 0.85, b: 0.75),
        .orange: HSBColor(h: 25, s: 0.90, b: 0.90),
        .blue: HSBColor(h: 215, s: 0.70, b: 0.75),
        .green: HSBColor(h: 140, s: 0.65, b: 0.65)
    ]
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Configuration Methods
    
    /// Set whether to flip Y coordinates (for Vision framework compatibility)
    /// - Parameter flip: true if using Vision detection (bottom-left origin), false for standard grids
    public func setFlipYCoordinates(_ flip: Bool) {
        self.flipYCoordinates = flip
    }
    
    // MARK: - Public Methods
    
    /// Classify sticker colors from a cube face region
    /// - Parameters:
    ///   - buffer: The pixel buffer containing the frame
    ///   - faceRect: The bounding box of the detected cube face (normalized coordinates)
    ///               Note: Vision framework uses bottom-left origin (0,0), so Y coordinates
    ///               need to be flipped when flipYCoordinates is true (default)
    /// - Returns: Array of 9 classified colors in row-major order (top-left to bottom-right)
    ///            Row 0: indices 0-2, Row 1: indices 3-5, Row 2: indices 6-8
    public func classifyStickers(
        buffer: CVPixelBuffer,
        faceRect: CGRect
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
        // Vision framework uses bottom-left origin (0,0), but pixel buffer uses top-left origin
        // When flipYCoordinates is true, we flip the Y coordinate to match pixel buffer space
        let adjustedFaceRect: CGRect
        if flipYCoordinates {
            // Flip Y: Vision's minY is at bottom, pixel buffer's minY is at top
            // Vision rect: minY is bottom edge, maxY is top edge
            // Pixel buffer: minY is top edge, maxY is bottom edge
            let flippedMinY = 1.0 - faceRect.maxY
            adjustedFaceRect = CGRect(
                x: faceRect.minX,
                y: flippedMinY,
                width: faceRect.width,
                height: faceRect.height
            )
        } else {
            adjustedFaceRect = faceRect
        }
        
        let pixelRect = CGRect(
            x: adjustedFaceRect.minX * CGFloat(width),
            y: adjustedFaceRect.minY * CGFloat(height),
            width: adjustedFaceRect.width * CGFloat(width),
            height: adjustedFaceRect.height * CGFloat(height)
        )
        
        // Sample 9 grid points (3x3 grid)
        var colors: [CubeColor] = []
        
        for row in 0..<3 {
            for col in 0..<3 {
                // PROMPT 6: Sample multiple points inside each sticker
                // Note: 81 total samples (9 per sticker × 9 stickers) is necessary for
                // robust color detection in varying lighting conditions. The performance
                // impact is acceptable as this runs at 30fps and only when cube is detected.
                let cellWidth = pixelRect.width / 3.0
                let cellHeight = pixelRect.height / 3.0
                
                let cellOriginX = pixelRect.minX + CGFloat(col) * cellWidth
                let cellOriginY = pixelRect.minY + CGFloat(row) * cellHeight
                
                // Sample in a 3x3 grid within each sticker (avoiding edges)
                var sampleColors: [RGBColor] = []
                
                for sampleRow in 0..<3 {
                    for sampleCol in 0..<3 {
                        let sampleX = Int(cellOriginX + cellWidth * (CGFloat(sampleCol) + 1) / 4)
                        let sampleY = Int(cellOriginY + cellHeight * (CGFloat(sampleRow) + 1) / 4)
                        
                        if let sampledColor = sampleColor(
                            at: CGPoint(x: sampleX, y: sampleY),
                            buffer: buffer,
                            bytesPerRow: bytesPerRow,
                            width: width,
                            height: height,
                            baseAddress: baseAddress
                        ) {
                            sampleColors.append(sampledColor)
                        }
                    }
                }
                
                // PROMPT 6: Use median color to reduce noise
                let representativeColor = useMedianFiltering 
                    ? medianColor(sampleColors)
                    : averageColor(sampleColors)
                
                // Apply improved color classification with better white detection
                let classifiedColor = classifyColorImproved(representativeColor)
                colors.append(classifiedColor)
            }
        }
        
        return colors
    }
    
    /// PROMPT 3: Classify just the center sticker to determine face orientation
    /// - Parameters:
    ///   - buffer: The pixel buffer containing the frame
    ///   - faceRect: The bounding box of the detected cube face (normalized coordinates)
    ///               Note: Vision framework uses bottom-left origin (0,0), so Y coordinates
    ///               need to be flipped when flipYCoordinates is true (default)
    /// - Returns: The classified color of the center sticker
    public func classifyCenterSticker(
        buffer: CVPixelBuffer,
        faceRect: CGRect
    ) async -> CubeColor {
        // Lock pixel buffer for reading
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
            return .white
        }
        
        // Convert normalized rect to pixel coordinates with Y-flip correction
        let adjustedFaceRect: CGRect
        if flipYCoordinates {
            let flippedMinY = 1.0 - faceRect.maxY
            adjustedFaceRect = CGRect(
                x: faceRect.minX,
                y: flippedMinY,
                width: faceRect.width,
                height: faceRect.height
            )
        } else {
            adjustedFaceRect = faceRect
        }
        
        let pixelRect = CGRect(
            x: adjustedFaceRect.minX * CGFloat(width),
            y: adjustedFaceRect.minY * CGFloat(height),
            width: adjustedFaceRect.width * CGFloat(width),
            height: adjustedFaceRect.height * CGFloat(height)
        )
        
        // Sample center sticker (row 1, col 1 in 3x3 grid)
        // Use multiple samples for more robust center detection
        let cellWidth = pixelRect.width / 3.0
        let cellHeight = pixelRect.height / 3.0
        
        let centerCellX = pixelRect.minX + cellWidth
        let centerCellY = pixelRect.minY + cellHeight
        
        // Sample 9 points within center sticker for robustness
        var sampleColors: [RGBColor] = []
        for sampleRow in 0..<3 {
            for sampleCol in 0..<3 {
                let sampleX = Int(centerCellX + cellWidth * (CGFloat(sampleCol) + 1) / 4)
                let sampleY = Int(centerCellY + cellHeight * (CGFloat(sampleRow) + 1) / 4)
                
                if let sampledColor = sampleColor(
                    at: CGPoint(x: sampleX, y: sampleY),
                    buffer: buffer,
                    bytesPerRow: bytesPerRow,
                    width: width,
                    height: height,
                    baseAddress: baseAddress
                ) {
                    sampleColors.append(sampledColor)
                }
            }
        }
        
        guard !sampleColors.isEmpty else {
            return .white
        }
        
        // Use median color for robustness
        let representativeColor = medianColor(sampleColors)
        return classifyColorImproved(representativeColor)
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
    
    /// PROMPT 6: Enhanced white balance normalization with lighting compensation
    private func normalizeColorWithWhiteBalance(_ color: RGBColor) -> RGBColor {
        // Apply gray world assumption for white balance
        let avg = (color.r + color.g + color.b) / 3.0
        
        guard avg > 0.05 else {
            return color
        }
        
        // Normalize each channel
        var normalized = RGBColor(
            r: color.r / avg,
            g: color.g / avg,
            b: color.b / avg
        )
        
        // Clamp values
        normalized = RGBColor(
            r: min(1.0, max(0.0, normalized.r)),
            g: min(1.0, max(0.0, normalized.g)),
            b: min(1.0, max(0.0, normalized.b))
        )
        
        return normalized
    }
    
    /// PROMPT 6: Calculate median color from samples to reduce noise
    private func medianColor(_ colors: [RGBColor]) -> RGBColor {
        guard !colors.isEmpty else {
            return RGBColor(r: 0.5, g: 0.5, b: 0.5)
        }
        
        let sortedR = colors.map { $0.r }.sorted()
        let sortedG = colors.map { $0.g }.sorted()
        let sortedB = colors.map { $0.b }.sorted()
        
        let midIndex = colors.count / 2
        
        return RGBColor(
            r: sortedR[midIndex],
            g: sortedG[midIndex],
            b: sortedB[midIndex]
        )
    }
    
    /// PROMPT 6: Calculate average color from samples
    private func averageColor(_ colors: [RGBColor]) -> RGBColor {
        guard !colors.isEmpty else {
            return RGBColor(r: 0.5, g: 0.5, b: 0.5)
        }
        
        let sumR = colors.reduce(0.0) { $0 + $1.r }
        let sumG = colors.reduce(0.0) { $0 + $1.g }
        let sumB = colors.reduce(0.0) { $0 + $1.b }
        
        let count = Float(colors.count)
        
        return RGBColor(
            r: sumR / count,
            g: sumG / count,
            b: sumB / count
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
    
    /// Improved color classification with better white detection and color discrimination
    /// This method handles the key issues:
    /// 1. White stickers being misclassified as yellow/orange due to lighting
    /// 2. Blue/green being confused with yellow/orange
    private func classifyColorImproved(_ rgb: RGBColor) -> CubeColor {
        let hsb = rgbToHSB(rgb)
        
        // First, check if this is white - white has low saturation and high brightness
        // This prevents white from being misclassified as yellow or orange
        if hsb.s < whiteSaturationThreshold && hsb.b > whiteBrightnessThreshold {
            return .white
        }
        
        // For colors with moderate saturation, use hue-based discrimination
        // This helps distinguish between colors that could be confused
        if hsb.s >= 0.20 {
            let hue = hsb.h
            
            // Use clear hue boundaries to distinguish colors
            // Red: 340-360 and 0-15
            // Orange: 15-45
            // Yellow: 45-70
            // Green: 70-170
            // Blue: 170-260
            // Red/Purple: 260-340
            
            if (hue >= 340 || hue < 15) && hsb.s > 0.40 {
                return .red
            } else if hue >= 15 && hue < 45 && hsb.s > 0.40 {
                return .orange
            } else if hue >= 45 && hue < 70 && hsb.s > 0.35 {
                return .yellow
            } else if hue >= 70 && hue < 170 {
                return .green
            } else if hue >= 170 && hue < 260 {
                return .blue
            } else if hue >= 260 && hue < 340 && hsb.s > 0.40 {
                // Could be red or purple - use brightness to decide
                return .red
            }
        }
        
        // Fall back to distance-based matching for edge cases
        var bestMatch: CubeColor = .white
        var bestDistance: Float = .infinity
        
        for (cubeColor, refColor) in referenceColors {
            let distance = colorDistanceImproved(hsb, refColor, targetColor: cubeColor)
            
            if distance < bestDistance {
                bestDistance = distance
                bestMatch = cubeColor
            }
        }
        
        return bestMatch
    }
    
    /// Improved distance calculation that handles color discrimination better
    private func colorDistanceImproved(_ color1: HSBColor, _ color2: HSBColor, targetColor: CubeColor) -> Float {
        // Handle hue wraparound (360 degrees = 0 degrees)
        let hueDiff = min(
            abs(color1.h - color2.h),
            360 - abs(color1.h - color2.h)
        )
        
        // Adaptive weights based on the target color
        var hueWeight: Float = 2.5
        var satWeight: Float = 1.5
        var briWeight: Float = 0.8
        
        // For white, saturation is the most important factor
        if targetColor == .white {
            satWeight = 3.0
            hueWeight = 0.3  // Hue is irrelevant for white
            briWeight = 1.0
        }
        
        // For distinguishing yellow from orange, emphasize hue
        if targetColor == .yellow || targetColor == .orange {
            hueWeight = 3.0
            satWeight = 1.0
        }
        
        // For blue vs green distinction, hue is critical
        if targetColor == .blue || targetColor == .green {
            hueWeight = 3.5
            satWeight = 1.0
        }
        
        let distance = sqrt(
            pow(hueDiff / 180.0 * hueWeight, 2) +
            pow((color1.s - color2.s) * satWeight, 2) +
            pow((color1.b - color2.b) * briWeight, 2)
        )
        
        return distance
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
