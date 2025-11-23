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
    
    /// Minimum stability duration before auto-capture (seconds) - PROMPT 1
    public var stabilityDuration: TimeInterval = 0.4
    
    /// Debounce delay before accepting a scan (seconds) - PROMPT 1
    public var debounceDelay: TimeInterval = 0.4
    
    /// Number of consecutive stable frames required - PROMPT 1
    public var requiredStableFrames: Int = 8
    
    /// Confidence threshold for auto-capture
    public var autoCaptureThreshold: Float = 0.8
    
    /// Stability movement threshold (normalized coordinates)
    public var stabilityMovementThreshold: Float = 0.02
    
    /// Lighting change threshold for rejecting unstable frames - PROMPT 1
    public var maxBrightnessChange: Float = 0.15
    
    // MARK: - Private Properties
    
    private let faceDetectionService = CubeFaceDetectionService()
    private let colorClassifier = StickerColorClassifier()
    
    private var detectionHistory: [(time: TimeInterval, result: CubeFaceDetectionResult, brightness: Float)] = []
    private var lastCaptureTime: TimeInterval = 0
    private let minTimeBetweenCaptures: TimeInterval = 1.0
    
    // Face detection state
    private var currentFaceEstimate: Face?
    private var faceEstimateConfidence: Float = 0
    
    // PROMPT 1: Stability tracking - made public for UI access
    public var consecutiveStableFrames: Int = 0
    public var isScanning: Bool = false
    
    // PROMPT 2: Duplicate detection
    private var capturedPatterns: [Face: [CubeColor]] = [:]
    
    // PROMPT 3: Face orientation detection
    private var detectedCenterColor: CubeColor?
    
    // PROMPT 9: Capture mode
    public var autoCaptureEnabled: Bool = true
    
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
            
            // Calculate brightness for this frame - PROMPT 1
            let brightness = await calculateFrameBrightness(videoFrame)
            
            // Add to history
            detectionHistory.append((time: timestamp, result: detection, brightness: brightness))
            
            // Keep only recent history (last 2 seconds)
            detectionHistory = detectionHistory.filter { timestamp - $0.time < 2.0 }
            
            // PROMPT 1: Check for lighting changes
            let lightingStable = checkLightingStability()
            
            // Calculate stability
            let positionStability = calculatePositionStability()
            stability = lightingStable ? positionStability : max(0, positionStability - 0.3)
            
            // PROMPT 1: Track consecutive stable frames
            if stability > 0.8 && lightingStable {
                consecutiveStableFrames += 1
                isScanning = consecutiveStableFrames >= requiredStableFrames
            } else {
                consecutiveStableFrames = 0
                isScanning = false
            }
            
            // Determine which face is visible
            await updateFaceEstimate(from: detection, videoFrame: videoFrame)
            
            // PROMPT 1: Auto-capture only if stable for required frames and debounced
            if autoCaptureEnabled && shouldAutoCapture(timestamp: timestamp) {
                await captureCurrentFace(videoFrame: videoFrame, depthFrame: depthFrame, detection: detection)
            }
        } else {
            // No detection - reduce stability
            stability = max(0, stability - 0.1)
            lastDetection = nil
            consecutiveStableFrames = 0
            isScanning = false
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
    
    /// Calculate stability based on recent detection history - PROMPT 1: Enhanced
    private func calculatePositionStability() -> Float {
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
    
    /// PROMPT 1: Check if lighting is stable (no sudden changes)
    private func checkLightingStability() -> Bool {
        guard detectionHistory.count >= 3 else {
            return true // Not enough data
        }
        
        let recentFrames = Array(detectionHistory.suffix(5))
        guard recentFrames.count >= 2 else {
            return true
        }
        
        // Check brightness variance
        let brightnesses = recentFrames.map { $0.brightness }
        let avgBrightness = brightnesses.reduce(0, +) / Float(brightnesses.count)
        
        for brightness in brightnesses {
            if abs(brightness - avgBrightness) > maxBrightnessChange {
                return false
            }
        }
        
        return true
    }
    
    /// PROMPT 1: Calculate frame brightness
    private func calculateFrameBrightness(_ buffer: CVPixelBuffer) async -> Float {
        // Simple approximation: sample center region
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
            return 0.5
        }
        
        // Sample 10x10 grid in center
        var totalBrightness: Float = 0
        var sampleCount: Int = 0
        
        let centerX = width / 2
        let centerY = height / 2
        let sampleSize = min(width, height) / 4
        
        for y in stride(from: centerY - sampleSize/2, to: centerY + sampleSize/2, by: sampleSize/10) {
            for x in stride(from: centerX - sampleSize/2, to: centerX + sampleSize/2, by: sampleSize/10) {
                guard x >= 0 && x < width && y >= 0 && y < height else { continue }
                
                let offset = y * bytesPerRow + x * 4
                let pixel = baseAddress.advanced(by: offset).assumingMemoryBound(to: UInt8.self)
                
                let b = Float(pixel[0]) / 255.0
                let g = Float(pixel[1]) / 255.0
                let r = Float(pixel[2]) / 255.0
                
                // Use perceived brightness formula
                totalBrightness += (0.299 * r + 0.587 * g + 0.114 * b)
                sampleCount += 1
            }
        }
        
        return sampleCount > 0 ? totalBrightness / Float(sampleCount) : 0.5
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
    
    /// PROMPT 3: Determine which face is currently visible using center color
    /// This is enhanced from a simple heuristic to use center tile color detection
    private func updateFaceEstimate(from detection: CubeFaceDetectionResult, videoFrame: CVPixelBuffer) async {
        // First, try to classify the center sticker to determine face
        let centerColor = await colorClassifier.classifyCenterSticker(
            buffer: videoFrame,
            faceRect: detection.boundingBox
        )
        
        detectedCenterColor = centerColor
        
        // Map center color to expected face (Rubik's cube centers are fixed)
        let expectedFace = faceFromCenterColor(centerColor)
        
        // If we haven't captured any faces yet, start with the detected face
        if capturedFaces.isEmpty {
            currentFaceEstimate = expectedFace
            faceEstimateConfidence = detection.confidence
            pendingFace = expectedFace
            return
        }
        
        // Check if this face is already captured - PROMPT 2
        if capturedFaces.keys.contains(expectedFace) {
            // Already captured this face, suggest next one
            currentFaceEstimate = nil
            pendingFace = getNextFaceToCapture()
            faceEstimateConfidence = 0
        } else {
            currentFaceEstimate = expectedFace
            faceEstimateConfidence = detection.confidence
            pendingFace = expectedFace
        }
    }
    
    /// PROMPT 3: Map center color to face
    private func faceFromCenterColor(_ color: CubeColor) -> Face {
        // Standard Rubik's cube color scheme
        switch color {
        case .white:
            return .up
        case .yellow:
            return .down
        case .green:
            return .left
        case .blue:
            return .right
        case .red:
            return .front
        case .orange:
            return .back
        }
    }
    
    /// Check if auto-capture should trigger - PROMPT 1: Enhanced with debounce
    private func shouldAutoCapture(timestamp: TimeInterval) -> Bool {
        guard let face = currentFaceEstimate else { return false }
        
        // Don't capture if already captured
        guard !capturedFaces.keys.contains(face) else { return false }
        
        // PROMPT 1: Check consecutive stable frames requirement
        guard consecutiveStableFrames >= requiredStableFrames else { return false }
        
        // Check stability
        guard stability >= 0.9 else { return false }
        
        // Check confidence
        guard faceEstimateConfidence >= autoCaptureThreshold else { return false }
        
        // PROMPT 1: Check debounce delay
        guard timestamp - lastCaptureTime >= debounceDelay else { return false }
        
        // PROMPT 1: Must be in scanning state
        guard isScanning else { return false }
        
        return true
    }
    
    /// Capture the current face - PROMPT 2: Enhanced with duplicate detection
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
        
        // PROMPT 2: Check for duplicate patterns
        if let duplicateFace = findDuplicatePattern(colors: colors, excluding: face) {
            // This pattern was already scanned for a different face
            // Skip this capture and reset
            currentFaceEstimate = nil
            pendingFace = getNextFaceToCapture()
            detectionHistory = []
            consecutiveStableFrames = 0
            stability = 0
            lastDetection = nil
            return
        }
        
        // Store captured face
        capturedFaces[face] = colors
        capturedPatterns[face] = colors
        lastCaptureTime = Date().timeIntervalSince1970
        
        // Reset for next face
        currentFaceEstimate = nil
        pendingFace = getNextFaceToCapture()
        detectionHistory = []
        consecutiveStableFrames = 0
        stability = 0
        lastDetection = nil
    }
    
    /// PROMPT 2: Find if this color pattern matches an already-captured face
    /// Returns the face that has this pattern, or nil if unique
    private func findDuplicatePattern(colors: [CubeColor], excluding: Face) -> Face? {
        let tolerance = 2 // Allow up to 2 sticker differences for tolerance
        
        for (face, pattern) in capturedPatterns {
            guard face != excluding else { continue }
            
            // Count differences
            var differences = 0
            for i in 0..<min(colors.count, pattern.count) {
                if colors[i] != pattern[i] {
                    differences += 1
                }
            }
            
            // If very similar (within tolerance), it's a duplicate
            if differences <= tolerance {
                return face
            }
        }
        
        return nil
    }
}

#endif
