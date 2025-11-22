//
//  CubeFaceDetectionService.swift
//  CubeSolver - Vision-Based Face Detection
//
//  Created by GitHub Copilot
//

#if canImport(Vision) && canImport(CoreVideo)

import Foundation
import Vision
import CoreVideo
import CoreGraphics
import CubeCore

/// Service for detecting cube faces in video frames using Vision framework
public actor CubeFaceDetectionService {
    
    // MARK: - Configuration
    
    /// Minimum confidence threshold for detection
    public var confidenceThreshold: Float = 0.7
    
    /// Minimum size (as fraction of frame) for cube detection
    public var minCubeSize: CGFloat = 0.15
    
    /// Maximum size (as fraction of frame) for cube detection
    public var maxCubeSize: CGFloat = 0.85
    
    // MARK: - Private Properties
    
    private var lastDetectionTime: TimeInterval = 0
    private let minDetectionInterval: TimeInterval = 0.05 // 20 fps max
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public Methods
    
    /// Detect cube face in a video frame
    /// - Parameter buffer: The pixel buffer to analyze
    /// - Returns: Detection result with bounding box and confidence, or nil if no cube detected
    public func detectCubeFace(in buffer: CVPixelBuffer) async -> CubeFaceDetectionResult? {
        let currentTime = Date().timeIntervalSince1970
        
        // Throttle detection rate
        guard currentTime - lastDetectionTime >= minDetectionInterval else {
            return nil
        }
        
        lastDetectionTime = currentTime
        
        // Detect rectangles using Vision
        let request = VNDetectRectanglesRequest()
        request.minimumAspectRatio = 0.8 // Nearly square
        request.maximumAspectRatio = 1.2 // Nearly square
        request.minimumSize = Float(minCubeSize)
        request.maximumObservations = 5 // Find top 5 rectangles
        request.minimumConfidence = confidenceThreshold
        
        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let observations = request.results, !observations.empty else {
                return nil
            }
            
            // Find the best rectangle that looks like a cube face
            if let bestObservation = findBestCubeFaceCandidate(observations) {
                let boundingBox = bestObservation.boundingBox
                let confidence = bestObservation.confidence
                
                return CubeFaceDetectionResult(
                    boundingBox: boundingBox,
                    confidence: confidence,
                    corners: extractCorners(from: bestObservation)
                )
            }
        } catch {
            // Detection failed
            return nil
        }
        
        return nil
    }
    
    // MARK: - Private Methods
    
    /// Find the best cube face candidate from detected rectangles
    private func findBestCubeFaceCandidate(_ observations: [VNRectangleObservation]) -> VNRectangleObservation? {
        var bestCandidate: VNRectangleObservation?
        var bestScore: Float = 0
        
        for observation in observations {
            let score = scoreCubeFaceCandidate(observation)
            
            if score > bestScore {
                bestScore = score
                bestCandidate = observation
            }
        }
        
        return bestCandidate
    }
    
    /// Score a rectangle as a cube face candidate
    /// Considers: confidence, aspect ratio, size, and position
    private func scoreCubeFaceCandidate(_ observation: VNRectangleObservation) -> Float {
        var score = observation.confidence
        
        // Prefer rectangles with aspect ratio close to 1:1
        let width = observation.boundingBox.width
        let height = observation.boundingBox.height
        let aspectRatio = width / height
        let aspectRatioScore = 1.0 - abs(aspectRatio - 1.0)
        score *= Float(aspectRatioScore)
        
        // Prefer rectangles in the center of the frame
        let centerX = observation.boundingBox.midX
        let centerY = observation.boundingBox.midY
        let centerDistanceFromMiddle = sqrt(pow(centerX - 0.5, 2) + pow(centerY - 0.5, 2))
        let centerScore = 1.0 - centerDistanceFromMiddle
        score *= Float(centerScore) * 0.5 + 0.5 // Weight center score less
        
        // Prefer medium-sized rectangles (not too small, not too large)
        let size = width * height
        let idealSize = 0.3 // 30% of frame
        let sizeScore = 1.0 - abs(size - idealSize) / idealSize
        score *= Float(max(0.5, sizeScore))
        
        return score
    }
    
    /// Extract corner points from rectangle observation
    private func extractCorners(from observation: VNRectangleObservation) -> [CGPoint] {
        return [
            observation.topLeft,
            observation.topRight,
            observation.bottomRight,
            observation.bottomLeft
        ]
    }
}

// MARK: - Detection Result

/// Result of cube face detection
public struct CubeFaceDetectionResult: Sendable {
    /// Normalized bounding box (0-1 coordinate space)
    public let boundingBox: CGRect
    
    /// Detection confidence (0-1)
    public let confidence: Float
    
    /// Corner points of the detected rectangle (in normalized coordinates)
    public let corners: [CGPoint]
    
    /// Center point of the detected face
    public var center: CGPoint {
        return CGPoint(
            x: boundingBox.midX,
            y: boundingBox.midY
        )
    }
    
    public init(boundingBox: CGRect, confidence: Float, corners: [CGPoint]) {
        self.boundingBox = boundingBox
        self.confidence = confidence
        self.corners = corners
    }
}

#endif
