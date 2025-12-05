//
//  CubeImageAnalyzer.swift
//  CubeSolver - Static Image Cube Analysis
//
//  Provides Vision-based cube face detection and color classification
//  for static images (photos). Uses rectangle detection to automatically
//  locate and crop to the cube face before color analysis.
//
//  Logic adapted from Tests/CubeReader.swift to provide automatic cube
//  detection and accurate color classification for the capture features.
//
//  Created by GitHub Copilot
//

#if canImport(Vision) && canImport(CoreGraphics)

import Foundation
import Vision
import CoreGraphics
import ImageIO
import CubeCore

// MARK: - CubeImageAnalyzer

/// Analyzes static images to detect cube faces and classify sticker colors.
///
/// This analyzer combines Vision framework rectangle detection with
/// color classification to automatically locate cube faces in images
/// and extract the 3x3 grid of sticker colors.
///
/// ## Usage
/// ```swift
/// let analyzer = CubeImageAnalyzer()
/// if let result = await analyzer.analyzeImage(cgImage) {
///     print("Detected colors: \(result.colors)")
/// }
/// ```
///
/// ## Features
/// - Automatic cube face detection using Vision rectangle detection
/// - Smart cropping to detected cube region
/// - 3x3 grid color sampling with configurable inset
/// - RGB Euclidean distance-based color classification
/// - Confidence scoring based on detection quality
public actor CubeImageAnalyzer {
    
    // MARK: - Types
    
    /// Result of cube image analysis
    public struct AnalysisResult: Sendable {
        /// The 9 detected sticker colors in row-major order (top-left to bottom-right)
        public let colors: [CubeColor]
        
        /// The detected cube face bounding box in pixel coordinates
        public let detectedRect: CGRect
        
        /// Overall confidence of the detection (0-1)
        public let confidence: Float
        
        /// Whether the cube was auto-detected (true) or fallback was used (false)
        public let wasAutoDetected: Bool
        
        /// Initialize a new analysis result
        public init(colors: [CubeColor], detectedRect: CGRect, confidence: Float, wasAutoDetected: Bool) {
            self.colors = colors
            self.detectedRect = detectedRect
            self.confidence = confidence
            self.wasAutoDetected = wasAutoDetected
        }
    }
    
    /// RGB color representation for internal calculations
    private struct RGB {
        let r: CGFloat
        let g: CGFloat
        let b: CGFloat
    }
    
    // MARK: - Configuration
    
    /// Minimum aspect ratio for cube detection (width/height)
    public var minimumAspectRatio: Float = 0.8
    
    /// Maximum aspect ratio for cube detection (width/height)
    public var maximumAspectRatio: Float = 1.2
    
    /// Minimum size of detected rectangle as fraction of image (0-1)
    public var minimumSize: Float = 0.2
    
    /// Maximum number of rectangle observations to consider
    public var maximumObservations: Int = 3
    
    /// Minimum confidence for rectangle detection
    public var minimumConfidence: Float = 0.5
    
    /// Inset fraction for color sampling within each cell (reduces edge effects)
    public var sampleInsetFraction: CGFloat = 0.02
    
    // MARK: - Configuration Setters (for testing)
    
    public func setMinimumAspectRatio(_ value: Float) {
        minimumAspectRatio = value
    }
    
    public func setMaximumAspectRatio(_ value: Float) {
        maximumAspectRatio = value
    }
    
    public func setMinimumSize(_ value: Float) {
        minimumSize = value
    }
    
    public func setMaximumObservations(_ value: Int) {
        maximumObservations = value
    }
    
    public func setMinimumConfidence(_ value: Float) {
        minimumConfidence = value
    }
    
    // MARK: - Reference Colors
    
    /// Reference RGB colors for classification
    private let referenceColors: [(CubeColor, RGB)] = [
        (.white, RGB(r: 0.9, g: 0.9, b: 0.9)),
        (.yellow, RGB(r: 0.95, g: 0.85, b: 0.15)),
        (.blue, RGB(r: 0.1, g: 0.2, b: 0.8)),
        (.green, RGB(r: 0.1, g: 0.6, b: 0.2)),
        (.red, RGB(r: 0.8, g: 0.1, b: 0.1)),
        (.orange, RGB(r: 0.95, g: 0.45, b: 0.1))
    ]
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public Methods
    
    /// Analyze a CGImage to detect cube face and classify sticker colors.
    ///
    /// This method performs automatic cube face detection using Vision framework,
    /// crops to the detected region, and samples colors in a 3x3 grid.
    ///
    /// - Parameter image: The CGImage to analyze
    /// - Returns: Analysis result with detected colors, or nil if analysis fails
    public func analyzeImage(_ image: CGImage) async -> AnalysisResult? {
        // Detect cube face rectangle
        let detectionResult = detectCubeRect(in: image)
        
        let samplingImage: CGImage
        let detectedRect: CGRect
        let wasAutoDetected: Bool
        let confidence: Float
        
        if let result = detectionResult {
            // Use detected region
            guard let cropped = image.cropping(to: result.rect) else {
                return nil
            }
            samplingImage = cropped
            detectedRect = result.rect
            wasAutoDetected = true
            confidence = result.confidence
        } else {
            // Fallback: use entire image
            samplingImage = image
            detectedRect = CGRect(x: 0, y: 0, width: CGFloat(image.width), height: CGFloat(image.height))
            wasAutoDetected = false
            confidence = 0.5 // Lower confidence for fallback
        }
        
        // Sample colors from 3x3 grid
        let colors = sampleGridColors(from: samplingImage)
        
        return AnalysisResult(
            colors: colors,
            detectedRect: detectedRect,
            confidence: confidence,
            wasAutoDetected: wasAutoDetected
        )
    }
    
    /// Analyze a CGImage within a specific region (for manual region selection).
    ///
    /// - Parameters:
    ///   - image: The CGImage to analyze
    ///   - region: The region to analyze (in pixel coordinates)
    /// - Returns: Analysis result with detected colors, or nil if analysis fails
    public func analyzeRegion(_ image: CGImage, region: CGRect) async -> AnalysisResult? {
        guard let cropped = image.cropping(to: region) else {
            return nil
        }
        
        let colors = sampleGridColors(from: cropped)
        
        return AnalysisResult(
            colors: colors,
            detectedRect: region,
            confidence: 0.7, // Medium confidence for manual selection
            wasAutoDetected: false
        )
    }
    
    // MARK: - Private Methods - Detection
    
    /// Detection result from Vision framework
    private struct DetectionResult {
        let rect: CGRect
        let confidence: Float
    }
    
    /// Detect the cube face rectangle in an image using Vision framework.
    private func detectCubeRect(in image: CGImage) -> DetectionResult? {
        let request = VNDetectRectanglesRequest()
        request.minimumAspectRatio = minimumAspectRatio
        request.maximumAspectRatio = maximumAspectRatio
        request.minimumSize = minimumSize
        request.maximumObservations = maximumObservations
        request.minimumConfidence = minimumConfidence
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let best = request.results?.first else {
                return nil
            }
            
            let bbox = best.boundingBox
            let width = CGFloat(image.width)
            let height = CGFloat(image.height)
            
            // Convert normalized coordinates to pixel coordinates
            // Note: Vision uses bottom-left origin, CGImage uses top-left
            let rect = CGRect(
                x: bbox.minX * width,
                y: (1 - bbox.maxY) * height,
                width: bbox.width * width,
                height: bbox.height * height
            )
            
            // Force to square to align with cube face
            let side = min(rect.width, rect.height)
            let square = CGRect(
                x: rect.midX - side / 2,
                y: rect.midY - side / 2,
                width: side,
                height: side
            )
            
            // Clamp to image bounds
            let imageBounds = CGRect(origin: .zero, size: CGSize(width: width, height: height))
            let clamped = square.intersection(imageBounds)
            
            guard !clamped.isNull else {
                return nil
            }
            
            return DetectionResult(rect: clamped, confidence: best.confidence)
            
        } catch {
            return nil
        }
    }
    
    // MARK: - Private Methods - Color Sampling
    
    /// Sample colors from a 3x3 grid in the image.
    private func sampleGridColors(from image: CGImage) -> [CubeColor] {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let gridSize = 3
        
        var result: [CubeColor] = []
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let cellRect = CGRect(
                    x: CGFloat(col) * width / CGFloat(gridSize),
                    y: CGFloat(row) * height / CGFloat(gridSize),
                    width: width / CGFloat(gridSize),
                    height: height / CGFloat(gridSize)
                ).insetBy(dx: width * sampleInsetFraction, dy: height * sampleInsetFraction)
                
                if let rgb = averageColor(in: image, rect: cellRect) {
                    result.append(classifyColor(rgb))
                } else {
                    result.append(.white) // Default fallback
                }
            }
        }
        
        return result
    }
    
    /// Calculate the average color in a rectangular region of an image.
    private func averageColor(in image: CGImage, rect: CGRect) -> RGB? {
        guard let cropped = image.cropping(to: rect) else {
            return nil
        }
        
        // Create a 1x1 context and draw the cropped image scaled down
        // This effectively gives us the average color
        guard let context = CGContext(
            data: nil,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        context.interpolationQuality = .high
        context.draw(cropped, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        
        guard let data = context.data else {
            return nil
        }
        
        let pixel = data.bindMemory(to: UInt8.self, capacity: 4)
        return RGB(
            r: CGFloat(pixel[0]) / 255.0,
            g: CGFloat(pixel[1]) / 255.0,
            b: CGFloat(pixel[2]) / 255.0
        )
    }
    
    /// Classify an RGB color to the closest cube color using Euclidean distance.
    private func classifyColor(_ rgb: RGB) -> CubeColor {
        func distance(_ lhs: RGB, _ rhs: RGB) -> CGFloat {
            let dr = lhs.r - rhs.r
            let dg = lhs.g - rhs.g
            let db = lhs.b - rhs.b
            return sqrt(dr * dr + dg * dg + db * db)
        }
        
        return referenceColors.min(by: { distance(rgb, $0.1) < distance(rgb, $1.1) })?.0 ?? .white
    }
}

#endif
