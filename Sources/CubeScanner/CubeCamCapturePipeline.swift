//
//  CubeCamCapturePipeline.swift
//  CubeSolver - Auto-Capture Pipeline with Rotation Tracking
//
//  Created by GitHub Copilot
//

#if canImport(CoreVideo)

import Foundation
import CoreVideo
import CubeCore

/// Pipeline for automatic cube face capture with rotation tracking
@MainActor
public class CubeCamCapturePipeline: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Captured faces and their colors
    @Published public var capturedFaces: [Face: [CubeColor]] = [:]
    
    /// Current face being tracked/captured
    @Published public var pendingFace: Face?
    
    /// Stability indicator (0-1, 1 = fully stable)
    @Published public var stability: Float = 0
    
    /// Last detection result
    @Published public var lastDetection: CubeFaceDetectionResult?
    
    // MARK: - Configuration
    
    /// Minimum stability duration before auto-capture (seconds)
    public var stabilityDuration: TimeInterval = 0.5
    
    /// Confidence threshold for auto-capture
    public var autoCaptureThreshold: Float = 0.8
    
    /// Stability movement threshold (normalized coordinates)
    public var stabilityMovementThreshold: Float = 0.02
    
    // MARK: - Private Properties
    
    private let faceDetectionService = CubeFaceDetectionService()
    private let colorClassifier = StickerColorClassifier()
    
    private var detectionHistory: [(time: TimeInterval, result: CubeFaceDetectionResult)] = []
    private var lastCaptureTime: TimeInterval = 0
    private let minTimeBetweenCaptures: TimeInterval = 1.0
    
    // Face detection state
    private var currentFaceEstimate: Face?
    private var faceEstimateConfidence: Float = 0
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public Methods
    
    /// Process a new video frame
    /// - Parameters:
    ///   - videoFrame: The video pixel buffer
    ///   - depthFrame: Optional depth pixel buffer
    ///   - timestamp: Frame timestamp
    public func processFrame(
        videoFrame: CVPixelBuffer,
        depthFrame: CVPixelBuffer?,
        timestamp: TimeInterval
    ) async {
        // Detect cube face
        if let detection = await faceDetectionService.detectCubeFace(in: videoFrame) {
            lastDetection = detection
            
            // Add to history
            detectionHistory.append((time: timestamp, result: detection))
            
            // Keep only recent history (last 2 seconds)
            detectionHistory = detectionHistory.filter { timestamp - $0.time < 2.0 }
            
            // Calculate stability
            stability = calculateStability()
            
            // Determine which face is visible
            updateFaceEstimate(from: detection)
            
            // Auto-capture if stable and confident
            if shouldAutoCapture(timestamp: timestamp) {
                await captureCurrentFace(videoFrame: videoFrame, depthFrame: depthFrame, detection: detection)
            }
        } else {
            // No detection - reduce stability
            stability = max(0, stability - 0.1)
            lastDetection = nil
        }
    }
    
    /// Manually capture the current detected face
    /// - Parameters:
    ///   - videoFrame: The video pixel buffer
    ///   - depthFrame: Optional depth pixel buffer
    ///   - detection: Current detection result
    public func manualCapture(
        videoFrame: CVPixelBuffer,
        depthFrame: CVPixelBuffer?,
        detection: CubeFaceDetectionResult
    ) async {
        guard let face = currentFaceEstimate else { return }
        
        await captureCurrentFace(videoFrame: videoFrame, depthFrame: depthFrame, detection: detection)
    }
    
    /// Reset the capture pipeline
    public func reset() {
        capturedFaces = [:]
        pendingFace = nil
        stability = 0
        lastDetection = nil
        detectionHistory = []
        currentFaceEstimate = nil
        faceEstimateConfidence = 0
    }
    
    /// Get the next face that needs to be captured
    public func getNextFaceToCapture() -> Face? {
        let allFaces: [Face] = [.up, .down, .front, .back, .left, .right]
        return allFaces.first { !capturedFaces.keys.contains($0) }
    }
    
    // MARK: - Private Methods
    
    /// Calculate stability based on recent detection history
    private func calculateStability() -> Float {
        guard detectionHistory.count >= 5 else {
            return 0
        }
        
        // Get recent detections (last 0.5 seconds)
        let currentTime = detectionHistory.last?.time ?? 0
        let recentDetections = detectionHistory.filter { currentTime - $0.time < stabilityDuration }
        
        guard recentDetections.count >= 3 else {
            return 0
        }
        
        // Calculate position variance
        var positions: [CGPoint] = []
        for detection in recentDetections {
            positions.append(detection.result.center)
        }
        
        let variance = calculatePositionVariance(positions)
        
        // Convert variance to stability (inverse relationship)
        let maxVariance: Float = 0.05 // 5% of frame
        let normalizedVariance = min(1.0, variance / maxVariance)
        let stability = 1.0 - normalizedVariance
        
        return stability
    }
    
    /// Calculate position variance
    private func calculatePositionVariance(_ positions: [CGPoint]) -> Float {
        guard !positions.isEmpty else { return 1.0 }
        
        // Calculate mean position
        let meanX = positions.reduce(0.0) { $0 + $1.x } / CGFloat(positions.count)
        let meanY = positions.reduce(0.0) { $0 + $1.y } / CGFloat(positions.count)
        
        // Calculate variance
        var variance: Float = 0
        for pos in positions {
            let dx = Float(pos.x - meanX)
            let dy = Float(pos.y - meanY)
            variance += dx * dx + dy * dy
        }
        variance /= Float(positions.count)
        
        return sqrt(variance)
    }
    
    /// Determine which face is currently visible
    /// This is a simplified heuristic - in production would use pose estimation
    private func updateFaceEstimate(from detection: CubeFaceDetectionResult) {
        // Simple heuristic based on position in frame
        let center = detection.center
        
        // If we haven't captured any faces yet, start with front
        if capturedFaces.isEmpty {
            currentFaceEstimate = .front
            faceEstimateConfidence = detection.confidence
            pendingFace = .front
            return
        }
        
        // Try to determine face based on captured faces and position
        let nextFace = getNextFaceToCapture()
        currentFaceEstimate = nextFace
        faceEstimateConfidence = detection.confidence
        pendingFace = nextFace
    }
    
    /// Check if auto-capture should trigger
    private func shouldAutoCapture(timestamp: TimeInterval) -> Bool {
        guard let face = currentFaceEstimate else { return false }
        
        // Don't capture if already captured
        guard !capturedFaces.keys.contains(face) else { return false }
        
        // Check stability
        guard stability >= 0.9 else { return false }
        
        // Check confidence
        guard faceEstimateConfidence >= autoCaptureThreshold else { return false }
        
        // Check time since last capture
        guard timestamp - lastCaptureTime >= minTimeBetweenCaptures else { return false }
        
        return true
    }
    
    /// Capture the current face
    private func captureCurrentFace(
        videoFrame: CVPixelBuffer,
        depthFrame: CVPixelBuffer?,
        detection: CubeFaceDetectionResult
    ) async {
        guard let face = currentFaceEstimate else { return }
        
        // Classify sticker colors
        let colors = await colorClassifier.classifyStickers(
            buffer: videoFrame,
            faceRect: detection.boundingBox
        )
        
        // Store captured face
        capturedFaces[face] = colors
        lastCaptureTime = Date().timeIntervalSince1970
        
        // Reset for next face
        currentFaceEstimate = nil
        pendingFace = getNextFaceToCapture()
        detectionHistory = []
        stability = 0
        lastDetection = nil
    }
}

#endif
