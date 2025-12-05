//
//  ModernColorClassifier.swift
//  CubeSolver - Modern iOS 26 Color Classification
//
//  Uses Vision framework's CalculateImageAestheticsScoresRequest and
//  Core Image for modern on-device color detection with Swift 6 concurrency.
//
//  Created by GitHub Copilot
//

#if canImport(Vision) && canImport(CoreImage) && canImport(CoreVideo)

import Foundation
import Vision
import CoreImage
import CoreVideo
import CubeCore

// MARK: - ModernColorClassifier

/// Modern iOS 26 color classifier using Vision framework and Core Image.
///
/// This classifier leverages:
/// - `CalculateImageAestheticsScoresRequest` for image quality assessment
/// - Core Image for advanced color analysis with CIFilter
/// - Swift 6 async/await concurrency patterns
/// - Actor-based thread safety
///
/// The classifier analyzes each sticker region using Core Image's color
/// analysis capabilities combined with Vision's image quality scoring.
public actor ModernColorClassifier: Sendable {
    
    // MARK: - Types
    
    /// Result of color classification with confidence score
    public struct ClassificationResult: Sendable {
        public let colors: [CubeColor]
        public let confidenceScores: [Float]
        public let imageQualityScore: Float?
        public let isUtilityImage: Bool
    }
    
    /// Color sample from image analysis
    private struct ColorSample: Sendable {
        let red: Float
        let green: Float
        let blue: Float
        let brightness: Float
    }
    
    // MARK: - Configuration
    
    /// Minimum image quality score for reliable detection (-1 to 1)
    public var minimumQualityScore: Float = -0.5
    
    /// Number of sample points per sticker for robust detection
    public var samplesPerSticker: Int = 9
    
    /// Enable image quality assessment using Vision
    public var enableQualityAssessment: Bool = true
    
    // MARK: - Configuration Setters (for testing)
    
    public func setMinimumQualityScore(_ value: Float) {
        minimumQualityScore = value
    }
    
    public func setSamplesPerSticker(_ value: Int) {
        samplesPerSticker = value
    }
    
    public func setEnableQualityAssessment(_ value: Bool) {
        enableQualityAssessment = value
    }
    
    // MARK: - Private Properties
    
    /// Core Image context for efficient processing
    private let ciContext: CIContext
    
    /// Reference colors in HSB space for cube color matching
    private let referenceColors: [CubeColor: (h: Float, s: Float, b: Float)] = [
        .white: (h: 0, s: 0, b: 0.95),
        .yellow: (h: 60, s: 0.85, b: 0.95),
        .red: (h: 0, s: 0.85, b: 0.85),
        .orange: (h: 30, s: 0.85, b: 0.90),
        .blue: (h: 220, s: 0.75, b: 0.80),
        .green: (h: 120, s: 0.70, b: 0.70)
    ]
    
    // MARK: - Initialization
    
    public init() {
        // Create Core Image context with Metal acceleration when available
        self.ciContext = CIContext(options: [
            .useSoftwareRenderer: false,
            .priorityRequestLow: false
        ])
    }
    
    // MARK: - Public Methods
    
    /// Classify sticker colors from a pixel buffer using modern Vision and Core Image APIs.
    ///
    /// - Parameters:
    ///   - buffer: CVPixelBuffer containing the image frame
    ///   - faceRect: Normalized bounding box of the cube face (0-1 coordinates)
    /// - Returns: ClassificationResult containing colors, confidence scores, and quality metrics
    public func classifyStickers(
        buffer: CVPixelBuffer,
        faceRect: CGRect
    ) async -> ClassificationResult {
        // Create CIImage from pixel buffer for modern processing
        let ciImage = CIImage(cvPixelBuffer: buffer)
        
        // Assess image quality if enabled
        var qualityScore: Float? = nil
        var isUtility = false
        
        if enableQualityAssessment {
            let quality = await assessImageQuality(ciImage: ciImage)
            qualityScore = quality.score
            isUtility = quality.isUtility
        }
        
        // Extract colors for each sticker in the 3x3 grid
        var colors: [CubeColor] = []
        var confidences: [Float] = []
        
        let imageWidth = CGFloat(CVPixelBufferGetWidth(buffer))
        let imageHeight = CGFloat(CVPixelBufferGetHeight(buffer))
        
        // Convert normalized rect to pixel coordinates
        let pixelRect = CGRect(
            x: faceRect.minX * imageWidth,
            y: faceRect.minY * imageHeight,
            width: faceRect.width * imageWidth,
            height: faceRect.height * imageHeight
        )
        
        for row in 0..<3 {
            for col in 0..<3 {
                let (color, confidence) = await classifySingleSticker(
                    ciImage: ciImage,
                    pixelRect: pixelRect,
                    row: row,
                    col: col
                )
                colors.append(color)
                confidences.append(confidence)
            }
        }
        
        return ClassificationResult(
            colors: colors,
            confidenceScores: confidences,
            imageQualityScore: qualityScore,
            isUtilityImage: isUtility
        )
    }
    
    /// Simplified classification returning just colors (for backward compatibility)
    public func classifyStickers(
        buffer: CVPixelBuffer,
        faceRect: CGRect
    ) async -> [CubeColor] {
        let result: ClassificationResult = await classifyStickers(buffer: buffer, faceRect: faceRect)
        return result.colors
    }
    
    /// Classify just the center sticker to determine face orientation
    public func classifyCenterSticker(
        buffer: CVPixelBuffer,
        faceRect: CGRect
    ) async -> CubeColor {
        let ciImage = CIImage(cvPixelBuffer: buffer)
        
        let imageWidth = CGFloat(CVPixelBufferGetWidth(buffer))
        let imageHeight = CGFloat(CVPixelBufferGetHeight(buffer))
        
        let pixelRect = CGRect(
            x: faceRect.minX * imageWidth,
            y: faceRect.minY * imageHeight,
            width: faceRect.width * imageWidth,
            height: faceRect.height * imageHeight
        )
        
        let (color, _) = await classifySingleSticker(
            ciImage: ciImage,
            pixelRect: pixelRect,
            row: 1,
            col: 1
        )
        
        return color
    }
    
    // MARK: - Private Methods
    
    /// Assess image quality using Vision's CalculateImageAestheticsScoresRequest
    private func assessImageQuality(ciImage: CIImage) async -> (score: Float, isUtility: Bool) {
        do {
            let request = CalculateImageAestheticsScoresRequest()
            let observation = try await request.perform(on: ciImage)
            return (Float(observation.overallScore), observation.isUtility)
        } catch {
            // If quality assessment fails, return neutral values
            return (0, false)
        }
    }
    
    /// Classify a single sticker at the given grid position
    private func classifySingleSticker(
        ciImage: CIImage,
        pixelRect: CGRect,
        row: Int,
        col: Int
    ) async -> (CubeColor, Float) {
        let cellWidth = pixelRect.width / 3.0
        let cellHeight = pixelRect.height / 3.0
        
        let cellOriginX = pixelRect.minX + CGFloat(col) * cellWidth
        let cellOriginY = pixelRect.minY + CGFloat(row) * cellHeight
        
        // Sample multiple points within the sticker for robust detection
        var samples: [ColorSample] = []
        
        // Sample in a 3x3 grid within each sticker (avoiding edges)
        for sampleRow in 0..<3 {
            for sampleCol in 0..<3 {
                let sampleX = cellOriginX + cellWidth * (CGFloat(sampleCol) + 1) / 4
                let sampleY = cellOriginY + cellHeight * (CGFloat(sampleRow) + 1) / 4
                
                if let sample = extractColorSample(
                    from: ciImage,
                    at: CGPoint(x: sampleX, y: sampleY)
                ) {
                    samples.append(sample)
                }
            }
        }
        
        guard !samples.isEmpty else {
            return (.white, 0.0)
        }
        
        // Calculate median color from samples for noise reduction
        let medianSample = calculateMedianSample(samples)
        
        // Apply white balance normalization
        let normalizedSample = applyWhiteBalance(medianSample)
        
        // Classify to cube color
        let (color, confidence) = matchToCubeColor(normalizedSample)
        
        return (color, confidence)
    }
    
    /// Extract color sample from CIImage at specified point
    private func extractColorSample(
        from ciImage: CIImage,
        at point: CGPoint
    ) -> ColorSample? {
        // Create a 1x1 region around the sample point
        let sampleRect = CGRect(x: point.x - 0.5, y: point.y - 0.5, width: 1, height: 1)
        
        // Crop to the sample region
        let croppedImage = ciImage.cropped(to: sampleRect)
        
        // Use CIAreaAverage filter for accurate color sampling
        guard let avgFilter = CIFilter(name: "CIAreaAverage") else {
            return nil
        }
        avgFilter.setValue(croppedImage, forKey: kCIInputImageKey)
        avgFilter.setValue(CIVector(cgRect: sampleRect), forKey: kCIInputExtentKey)
        
        guard let outputImage = avgFilter.outputImage else {
            return nil
        }
        
        // Render to get pixel data
        var bitmap = [UInt8](repeating: 0, count: 4)
        ciContext.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: ciImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        )
        
        let red = Float(bitmap[0]) / 255.0
        let green = Float(bitmap[1]) / 255.0
        let blue = Float(bitmap[2]) / 255.0
        let brightness = max(red, green, blue)
        
        return ColorSample(red: red, green: green, blue: blue, brightness: brightness)
    }
    
    /// Calculate median sample from array of samples
    private func calculateMedianSample(_ samples: [ColorSample]) -> ColorSample {
        let sortedR = samples.map { $0.red }.sorted()
        let sortedG = samples.map { $0.green }.sorted()
        let sortedB = samples.map { $0.blue }.sorted()
        
        let midIndex = samples.count / 2
        
        let red = sortedR[midIndex]
        let green = sortedG[midIndex]
        let blue = sortedB[midIndex]
        
        return ColorSample(
            red: red,
            green: green,
            blue: blue,
            brightness: max(red, green, blue)
        )
    }
    
    /// Apply white balance normalization using gray world assumption
    private func applyWhiteBalance(_ sample: ColorSample) -> ColorSample {
        let avg = (sample.red + sample.green + sample.blue) / 3.0
        
        guard avg > 0.05 else {
            return sample
        }
        
        let normalizedR = min(1.0, max(0.0, sample.red / avg))
        let normalizedG = min(1.0, max(0.0, sample.green / avg))
        let normalizedB = min(1.0, max(0.0, sample.blue / avg))
        
        return ColorSample(
            red: normalizedR,
            green: normalizedG,
            blue: normalizedB,
            brightness: max(normalizedR, normalizedG, normalizedB)
        )
    }
    
    /// Match color sample to closest cube color
    private func matchToCubeColor(_ sample: ColorSample) -> (CubeColor, Float) {
        let hsb = rgbToHSB(r: sample.red, g: sample.green, b: sample.blue)
        
        var bestMatch: CubeColor = .white
        var bestDistance: Float = .infinity
        
        for (cubeColor, refColor) in referenceColors {
            let distance = colorDistance(
                h1: hsb.h, s1: hsb.s, b1: hsb.b,
                h2: refColor.h, s2: refColor.s, b2: refColor.b
            )
            
            if distance < bestDistance {
                bestDistance = distance
                bestMatch = cubeColor
            }
        }
        
        // Calculate confidence as inverse of distance (normalized)
        let confidence = max(0.0, min(1.0, 1.0 - (bestDistance / 2.0)))
        
        return (bestMatch, confidence)
    }
    
    /// Calculate weighted distance between two HSB colors
    private func colorDistance(
        h1: Float, s1: Float, b1: Float,
        h2: Float, s2: Float, b2: Float
    ) -> Float {
        // Handle hue wraparound (360 degrees = 0 degrees)
        let hueDiff = min(abs(h1 - h2), 360 - abs(h1 - h2))
        
        let hueWeight: Float = 2.0
        let satWeight: Float = 1.0
        let briWeight: Float = 1.0
        
        return sqrt(
            pow(hueDiff / 180.0 * hueWeight, 2) +
            pow((s1 - s2) * satWeight, 2) +
            pow((b1 - b2) * briWeight, 2)
        )
    }
    
    /// Convert RGB to HSB color space
    private func rgbToHSB(r: Float, g: Float, b: Float) -> (h: Float, s: Float, b: Float) {
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC
        
        let brightness = maxC
        let saturation = maxC == 0 ? 0 : delta / maxC
        
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
}

#endif
