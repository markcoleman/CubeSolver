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

/// Capture state machine for deterministic flow
public enum CaptureState: Equatable {
    /// Idle - waiting for cube detection
    case idle
    
    /// Detecting - cube found but not yet stable
    case detecting
    
    /// Stabilizing - cube is stable, accumulating frames
    case stabilizing(progress: Double)
    
    /// Capturing - triggering capture (one-time state)
    case capturing
    
    /// Captured - face successfully captured
    case captured
    
    public static func == (lhs: CaptureState, rhs: CaptureState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.detecting, .detecting),
             (.capturing, .capturing),
             (.captured, .captured):
            return true
        case let (.stabilizing(p1), .stabilizing(p2)):
            return abs(p1 - p2) < 0.01
        default:
            return false
        }
    }
}

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
    
    /// PROMPT 8: Current scan error (if any)
    @Published public var currentError: CubeScanErrorDetector.ScanError?
    
    /// Single source of truth for capture state
    @Published public var captureState: CaptureState = .idle
    
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
    private let errorDetector = CubeScanErrorDetector()
    
    private var detectionHistory: [(time: TimeInterval, result: CubeFaceDetectionResult, brightness: Float)] = []
    private var lastCaptureTime: TimeInterval = 0
    private let minTimeBetweenCaptures: TimeInterval = 1.0
    
    // Face detection state
    private var currentFaceEstimate: Face?
    private var faceEstimateConfidence: Float = 0
    
    // PROMPT 1: Stability tracking - made public for UI access
    public var consecutiveStableFrames: Int = 0
    public var isScanning: Bool = false
    
    // Guard against concurrent frame processing
    private var isProcessingFrame: Bool = false
    
    // Track if we've already triggered capture for this stabilization cycle
    private var hasCapturedThisCycle: Bool = false
    
    // Brightness sampling cache
    private var brightnessSampleCoordinates: [(x: Int, y: Int)]?
    
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
        // GUARD: Prevent overlapping Vision requests
        guard !isProcessingFrame else {
            print("[CubeCam] ⚠️ Skipping frame - already processing")
            return
        }
        
        isProcessingFrame = true
        defer {
            isProcessingFrame = false
        }
        
        print("[CubeCam] 🎥 Processing frame at \(timestamp)")
        
        // Detect cube face
        if let detection = await faceDetectionService.detectCubeFace(in: videoFrame) {
            print("[CubeCam] ✓ Cube detected - confidence: \(detection.confidence)")
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
            
            print("[CubeCam] 📊 Stability: \(stability), Lighting stable: \(lightingStable)")
            
            // Determine which face is visible
            await updateFaceEstimate(from: detection, videoFrame: videoFrame)
            
            // STATE MACHINE: Update state based on stability
            await updateCaptureState(stability: stability, lightingStable: lightingStable, timestamp: timestamp)
            
            // PROMPT 1: Auto-capture only if in stabilizing state and conditions met
            if autoCaptureEnabled && shouldAutoCapture(timestamp: timestamp) {
                print("[CubeCam] 🎯 Auto-capture conditions met - triggering capture")
                await captureCurrentFace(videoFrame: videoFrame, depthFrame: depthFrame, detection: detection)
            }
        } else {
            print("[CubeCam] ❌ No cube detected")
            // No detection - reduce stability and reset state
            stability = max(0, stability - 0.1)
            lastDetection = nil
            consecutiveStableFrames = 0
            isScanning = false
            
            // Reset to idle or detecting
            if captureState != .captured {
                captureState = .idle
                print("[CubeCam] 🔄 State: idle (no detection)")
            }
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
        print("[CubeCam] 🔄 Resetting pipeline")
        capturedFaces = [:]
        pendingFace = nil
        stability = 0
        lastDetection = nil
        detectionHistory = []
        currentFaceEstimate = nil
        faceEstimateConfidence = 0
        consecutiveStableFrames = 0
        isScanning = false
        captureState = .idle
        hasCapturedThisCycle = false
    }
    
    /// Get the next face that needs to be captured
    public func getNextFaceToCapture() -> Face? {
        let allFaces: [Face] = [.up, .down, .front, .back, .left, .right]
        return allFaces.first { !capturedFaces.keys.contains($0) }
    }
    
    // MARK: - Private Methods
    
    /// Update capture state machine based on current conditions
    private func updateCaptureState(stability: Float, lightingStable: Bool, timestamp: TimeInterval) async {
        let oldState = captureState
        
        // PROMPT 1: Track consecutive stable frames
        // Threshold aligned with auto-capture threshold to ensure frames counted as stable will trigger capture
        if stability >= 0.85 && lightingStable {
            consecutiveStableFrames += 1
            isScanning = consecutiveStableFrames >= requiredStableFrames
            
            // Calculate progress (0.0 to 1.0)
            let progress = min(1.0, Double(consecutiveStableFrames) / Double(requiredStableFrames))
            
            if consecutiveStableFrames >= requiredStableFrames {
                // Ready to capture
                if !hasCapturedThisCycle {
                    captureState = .stabilizing(progress: 1.0)
                    print("[CubeCam] ✓ Stabilized! Progress: 100% (\(consecutiveStableFrames)/\(requiredStableFrames) frames)")
                } else {
                    captureState = .captured
                }
            } else {
                // Still stabilizing
                captureState = .stabilizing(progress: progress)
                print("[CubeCam] ⏳ Stabilizing... Progress: \(Int(progress * 100))% (\(consecutiveStableFrames)/\(requiredStableFrames) frames)")
            }
        } else {
            // Not stable - reset
            if consecutiveStableFrames > 0 {
                print("[CubeCam] ⚠️ Lost stability - resetting (was at \(consecutiveStableFrames) frames)")
            }
            consecutiveStableFrames = 0
            isScanning = false
            hasCapturedThisCycle = false
            
            if captureState != .captured {
                captureState = .detecting
            }
        }
        
        // Log state transitions
        if oldState != captureState {
            print("[CubeCam] 🔄 State transition: \(oldState) → \(captureState)")
        }
    }
    
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
    
    /// PROMPT 1: Calculate frame brightness with cached sample coordinates
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
        
        // Initialize sample coordinates if not cached
        if brightnessSampleCoordinates == nil {
            let centerX = width / 2
            let centerY = height / 2
            let sampleSize = min(width, height) / 4
            let stepSize = sampleSize / 10
            
            var coords: [(x: Int, y: Int)] = []
            for y in stride(from: centerY - sampleSize/2, to: centerY + sampleSize/2, by: stepSize) {
                for x in stride(from: centerX - sampleSize/2, to: centerX + sampleSize/2, by: stepSize) {
                    if x >= 0 && x < width && y >= 0 && y < height {
                        coords.append((x, y))
                    }
                }
            }
            brightnessSampleCoordinates = coords
        }
        
        // Sample using cached coordinates
        var totalBrightness: Float = 0
        var sampleCount: Int = 0
        
        for coord in brightnessSampleCoordinates ?? [] {
            let offset = coord.y * bytesPerRow + coord.x * 4
            let pixel = baseAddress.advanced(by: offset).assumingMemoryBound(to: UInt8.self)
            
            let b = Float(pixel[0]) / 255.0
            let g = Float(pixel[1]) / 255.0
            let r = Float(pixel[2]) / 255.0
            
            // Use perceived brightness formula
            totalBrightness += (0.299 * r + 0.587 * g + 0.114 * b)
            sampleCount += 1
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
        guard let face = currentFaceEstimate else {
            print("[CubeCam] ⏭️ No capture: No face estimate")
            return false
        }
        
        // Don't capture if already captured this face
        guard !capturedFaces.keys.contains(face) else {
            print("[CubeCam] ⏭️ No capture: Face \(face) already captured")
            return false
        }
        
        // GUARD: Only capture once per stabilization cycle
        guard !hasCapturedThisCycle else {
            print("[CubeCam] ⏭️ No capture: Already captured this cycle")
            return false
        }
        
        // PROMPT 1: Check consecutive stable frames requirement
        guard consecutiveStableFrames >= requiredStableFrames else {
            print("[CubeCam] ⏭️ No capture: Only \(consecutiveStableFrames)/\(requiredStableFrames) stable frames")
            return false
        }
        
        // Check stability - lowered threshold to match consecutive frame threshold
        guard stability >= 0.85 else {
            print("[CubeCam] ⏭️ No capture: Stability too low (\(stability) < 0.85)")
            return false
        }
        
        // Check confidence
        guard faceEstimateConfidence >= autoCaptureThreshold else {
            print("[CubeCam] ⏭️ No capture: Confidence too low (\(faceEstimateConfidence) < \(autoCaptureThreshold))")
            return false
        }
        
        // PROMPT 1: Check debounce delay
        guard timestamp - lastCaptureTime >= debounceDelay else {
            let remaining = debounceDelay - (timestamp - lastCaptureTime)
            print("[CubeCam] ⏭️ No capture: Debounce delay (\(remaining)s remaining)")
            return false
        }
        
        // PROMPT 1: Must be in scanning state
        guard isScanning else {
            print("[CubeCam] ⏭️ No capture: Not in scanning state")
            return false
        }
        
        // Check state machine
        guard case .stabilizing(let progress) = captureState, progress >= 1.0 else {
            print("[CubeCam] ⏭️ No capture: Not in stabilizing(1.0) state - current: \(captureState)")
            return false
        }
        
        print("[CubeCam] ✅ All capture conditions met!")
        return true
    }
    
    /// Capture the current face - PROMPT 2: Enhanced with duplicate detection, PROMPT 8: Error validation
    private func captureCurrentFace(
        videoFrame: CVPixelBuffer,
        depthFrame: CVPixelBuffer?,
        detection: CubeFaceDetectionResult
    ) async {
        guard let face = currentFaceEstimate else {
            print("[CubeCam] ❌ Cannot capture: No face estimate")
            return
        }
        
        // GUARD: Prevent multiple captures in same cycle
        guard !hasCapturedThisCycle else {
            print("[CubeCam] ⚠️ Already captured this cycle - skipping")
            return
        }
        
        print("[CubeCam] 📸 Starting capture for face: \(face)")
        
        // Mark as capturing to prevent duplicates
        hasCapturedThisCycle = true
        captureState = .capturing
        
        // PROMPT 8: Validate lighting
        let brightness = detectionHistory.last?.brightness ?? 0.5
        if let lightingError = await errorDetector.validateLighting(brightness: brightness) {
            print("[CubeCam] ❌ Lighting validation failed: \(lightingError)")
            currentError = lightingError
            resetAfterFailedCapture()
            return
        }
        
        // Classify sticker colors
        let colors = await colorClassifier.classifyStickers(
            buffer: videoFrame,
            faceRect: detection.boundingBox
        )
        
        print("[CubeCam] 🎨 Classified \(colors.count) stickers")
        
        // PROMPT 8: Validate colors are readable
        if let colorError = await errorDetector.validateColors(colors) {
            print("[CubeCam] ❌ Color validation failed: \(colorError)")
            currentError = colorError
            resetAfterFailedCapture()
            return
        }
        
        // PROMPT 8: Validate face layout
        if let layoutError = await errorDetector.validateFaceLayout(colors) {
            print("[CubeCam] ❌ Layout validation failed: \(layoutError)")
            currentError = layoutError
            resetAfterFailedCapture()
            return
        }
        
        // PROMPT 2: Check for duplicate patterns
        if let duplicateFace = findDuplicatePattern(colors: colors, excluding: face) {
            print("[CubeCam] ⚠️ Duplicate pattern detected - matches face: \(duplicateFace)")
            // This pattern was already scanned for a different face
            // Skip this capture and reset
            resetAfterFailedCapture()
            return
        }
        
        // Store captured face
        capturedFaces[face] = colors
        capturedPatterns[face] = colors
        lastCaptureTime = Date().timeIntervalSince1970
        
        print("[CubeCam] ✅ Successfully captured face: \(face) (\(capturedFaces.count)/6)")
        
        // Clear any errors
        currentError = nil
        
        // Update state to captured
        captureState = .captured
        
        // Reset for next face after a brief delay
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await resetForNextFace()
        }
    }
    
    /// Reset state after a failed capture attempt
    private func resetAfterFailedCapture() {
        print("[CubeCam] 🔄 Resetting after failed capture")
        hasCapturedThisCycle = false
        consecutiveStableFrames = 0
        stability = 0
        captureState = .detecting
        detectionHistory = []
    }
    
    /// Reset for next face after successful capture
    private func resetForNextFace() {
        print("[CubeCam] 🔄 Resetting for next face")
        currentFaceEstimate = nil
        pendingFace = getNextFaceToCapture()
        detectionHistory = []
        consecutiveStableFrames = 0
        stability = 0
        lastDetection = nil
        hasCapturedThisCycle = false
        captureState = .idle
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
