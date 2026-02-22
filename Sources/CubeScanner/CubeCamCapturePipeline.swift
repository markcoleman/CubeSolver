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
#if canImport(OSLog)
import OSLog
#endif

/// Pipeline for automatic cube face capture with rotation tracking
@MainActor
public final class CubeCamCapturePipeline: ObservableObject {
    private static let defaultCaptureOrder: [Face] = [.up, .front, .right, .back, .left, .down]
    
    // MARK: - Nested Types
    
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
        
        /// Tolerance for comparing progress values
        private static let progressEqualityTolerance: Double = 0.01
        
        public static func == (lhs: CaptureState, rhs: CaptureState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle),
                 (.detecting, .detecting),
                 (.capturing, .capturing),
                 (.captured, .captured):
                return true
            case let (.stabilizing(p1), .stabilizing(p2)):
                return abs(p1 - p2) < progressEqualityTolerance
            default:
                return false
            }
        }
    }
    
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

    /// Warning message shown when a face appears to be a duplicate of one already captured.
    @Published public var duplicateFaceWarning: String?
    
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
    
    /// Delay before resetting state after successful capture (seconds)
    public var captureResetDelay: TimeInterval = 0.5

    /// Stability threshold used to count a frame toward capture readiness.
    public var stableFrameThreshold: Float = 0.7

    /// Whether capture order is mandatory (`true`) or only used as guidance (`false`).
    public var enforceCaptureOrder: Bool = false
    
    // MARK: - Private Properties
    
    private let faceDetectionService = CubeFaceDetectionService()
    private let colorClassifier = StickerColorClassifier()
    private let errorDetector = CubeScanErrorDetector()
    #if canImport(OSLog)
    private let logger = Logger(subsystem: "com.cubesolver.scanner", category: "CubeCamCapturePipeline")
    #endif
    
    private var detectionHistory: [(time: TimeInterval, result: CubeFaceDetectionResult, brightness: Float)] = []
    private var lastCaptureTime: TimeInterval = 0
    
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
    
    // Metrics: Track dropped frames for monitoring
    private var droppedFrameCount: Int = 0
    
    // Brightness sampling cache
    private var brightnessSampleCoordinates: [(x: Int, y: Int)]?
    
    // PROMPT 2: Duplicate detection
    private var capturedPatterns: [Face: [CubeColor]] = [:]
    
    // PROMPT 3: Face orientation detection
    private var detectedCenterColor: CubeColor?

    // Confidence smoothing state
    private var lastEstimatedFace: Face?
    private var consistentFaceEstimateCount: Int = 0
    private var smoothedFaceEstimateConfidence: Float = 0

    // Retry/backoff state
    private var autoCaptureBackoffUntil: TimeInterval = 0
    private var autoCaptureSuspendedFaces: Set<Face> = []
    
    // PROMPT 9: Capture mode
    public var autoCaptureEnabled: Bool = true

    /// Enable detailed diagnostics logging for per-frame scanning behavior.
    public var isVerboseLoggingEnabled: Bool = false

    /// Deterministic order used by auto-capture.
    public var captureOrder: [Face] = defaultCaptureOrder {
        didSet {
            let normalized = Self.normalizedCaptureOrder(from: captureOrder)
            if normalized != captureOrder {
                captureOrder = normalized
            }
        }
    }

    /// Exponential moving-average alpha used to smooth face estimate confidence.
    public var faceConfidenceSmoothingAlpha: Float = 0.35 {
        didSet {
            faceConfidenceSmoothingAlpha = min(max(faceConfidenceSmoothingAlpha, 0), 1)
        }
    }

    /// Number of consecutive frames required before face confidence reaches full weight.
    public var minimumConsistentFaceFrames: Int = 3 {
        didSet {
            minimumConsistentFaceFrames = max(1, minimumConsistentFaceFrames)
        }
    }

    /// Maximum number of auto-capture retries per face before auto mode pauses for that face.
    public var maxAutoCaptureRetriesPerFace: Int = 3 {
        didSet {
            maxAutoCaptureRetriesPerFace = max(1, maxAutoCaptureRetriesPerFace)
        }
    }

    /// Base delay (seconds) for exponential retry backoff after failed auto-capture.
    public var retryBackoffBaseDelay: TimeInterval = 0.35 {
        didSet {
            retryBackoffBaseDelay = max(0, retryBackoffBaseDelay)
        }
    }

    /// Upper bound (seconds) for retry backoff delay.
    public var maxRetryBackoffDelay: TimeInterval = 2.0 {
        didSet {
            maxRetryBackoffDelay = max(0, maxRetryBackoffDelay)
        }
    }

    /// Current retry counts by face for diagnostics and UI hints.
    @Published public private(set) var retryCountsByFace: [Face: Int] = [:]
    
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
            droppedFrameCount += 1
            if droppedFrameCount % 10 == 0 {
                logWarning("[CubeCam] Dropped \(droppedFrameCount) frames due to concurrent processing")
            }
            return
        }
        
        isProcessingFrame = true
        defer {
            isProcessingFrame = false
        }
        
        logDebug("[CubeCam] 🎥 Processing frame at \(timestamp)")
        
        // Detect cube face
        if let detection = await faceDetectionService.detectCubeFace(in: videoFrame) {
            logDebug("[CubeCam] ✓ Cube detected - confidence: \(detection.confidence)")
            lastDetection = detection
            
            // Calculate brightness for this frame - PROMPT 1
            let brightness = calculateFrameBrightness(videoFrame)
            
            // Add to history
            detectionHistory.append((time: timestamp, result: detection, brightness: brightness))
            
            // Keep only recent history (last 2 seconds)
            detectionHistory = detectionHistory.filter { timestamp - $0.time < 2.0 }
            
            // PROMPT 1: Check for lighting changes
            let lightingStable = checkLightingStability()
            
            // Calculate stability
            let positionStability = calculatePositionStability()
            stability = lightingStable ? positionStability : max(0, positionStability - 0.3)
            
            logDebug("[CubeCam] 📊 Stability: \(stability), Lighting stable: \(lightingStable)")
            
            // Determine which face is visible
            await updateFaceEstimate(from: detection, videoFrame: videoFrame)
            
            // STATE MACHINE: Update state based on stability
            updateCaptureState(stability: stability, lightingStable: lightingStable)
            
            // PROMPT 1: Auto-capture only if in stabilizing state and conditions met
            if autoCaptureEnabled && shouldAutoCapture(timestamp: timestamp) {
                logDebug("[CubeCam] 🎯 Auto-capture conditions met - triggering capture")
                await captureCurrentFace(
                    videoFrame: videoFrame,
                    depthFrame: depthFrame,
                    detection: detection,
                    timestamp: timestamp
                )
            }
        } else {
            logDebug("[CubeCam] ❌ No cube detected")
            // No detection - reduce stability and reset state
            stability = max(0, stability - 0.1)
            lastDetection = nil
            consecutiveStableFrames = 0
            isScanning = false
            currentFaceEstimate = nil
            faceEstimateConfidence = 0
            lastEstimatedFace = nil
            consistentFaceEstimateCount = 0
            smoothedFaceEstimateConfidence = 0
            pendingFace = getNextFaceToCapture()
            
            // Reset to idle or detecting
            if captureState != .captured {
                captureState = .idle
                logDebug("[CubeCam] 🔄 State: idle (no detection)")
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
        guard currentFaceEstimate != nil else { return }
        
        await captureCurrentFace(
            videoFrame: videoFrame,
            depthFrame: depthFrame,
            detection: detection,
            timestamp: Date().timeIntervalSince1970
        )
    }
    
    /// Reset the capture pipeline
    public func reset() {
        logDebug("[CubeCam] 🔄 Resetting pipeline")
        capturedFaces = [:]
        capturedPatterns = [:]
        pendingFace = nil
        stability = 0
        lastDetection = nil
        currentError = nil
        duplicateFaceWarning = nil
        detectionHistory = []
        currentFaceEstimate = nil
        faceEstimateConfidence = 0
        consecutiveStableFrames = 0
        isScanning = false
        captureState = .idle
        hasCapturedThisCycle = false
        droppedFrameCount = 0
        retryCountsByFace = [:]
        autoCaptureBackoffUntil = 0
        autoCaptureSuspendedFaces = []
        lastEstimatedFace = nil
        consistentFaceEstimateCount = 0
        smoothedFaceEstimateConfidence = 0
    }
    
    /// Get the next face that needs to be captured
    public func getNextFaceToCapture() -> Face? {
        captureOrder.first { !capturedFaces.keys.contains($0) }
    }
    
    // MARK: - Private Methods
    
    /// Update capture state machine based on current conditions
    private func updateCaptureState(stability: Float, lightingStable: Bool) {
        let oldState = captureState
        
        // PROMPT 1: Track consecutive stable frames
        if stability >= stableFrameThreshold && lightingStable {
            consecutiveStableFrames += 1
            isScanning = consecutiveStableFrames >= requiredStableFrames
            
            // Calculate progress (0.0 to 1.0)
            let progress = min(1.0, Double(consecutiveStableFrames) / Double(requiredStableFrames))
            
            if consecutiveStableFrames >= requiredStableFrames {
                // Ready to capture
                if !hasCapturedThisCycle {
                    captureState = .stabilizing(progress: 1.0)
                    logDebug("[CubeCam] ✓ Stabilized! Progress: 100% (\(consecutiveStableFrames)/\(requiredStableFrames) frames)")
                } else {
                    captureState = .captured
                }
            } else {
                // Still stabilizing
                captureState = .stabilizing(progress: progress)
                logDebug("[CubeCam] ⏳ Stabilizing... Progress: \(Int(progress * 100))% (\(consecutiveStableFrames)/\(requiredStableFrames) frames)")
            }
        } else {
            // Not stable - reset
            if consecutiveStableFrames > 0 {
                logDebug("[CubeCam] ⚠️ Lost stability - resetting (was at \(consecutiveStableFrames) frames)")
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
            logDebug("[CubeCam] 🔄 State transition: \(oldState) → \(captureState)")
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
        let maxVariance: Float = max(stabilityMovementThreshold, 0.0001)
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
    private func calculateFrameBrightness(_ buffer: CVPixelBuffer) -> Float {
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
        updateSmoothedFaceConfidence(face: expectedFace, detectionConfidence: detection.confidence)

        let targetFace = getNextFaceToCapture()
        pendingFace = targetFace

        guard targetFace != nil else {
            currentFaceEstimate = nil
            faceEstimateConfidence = 0
            return
        }

        // If this face is already captured, clear estimate and wait for the pending face.
        guard !capturedFaces.keys.contains(expectedFace) else {
            currentFaceEstimate = nil
            faceEstimateConfidence = 0
            return
        }

        currentFaceEstimate = expectedFace
        faceEstimateConfidence = smoothedFaceEstimateConfidence
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
            logDebug("[CubeCam] ⏭️ No capture: No face estimate")
            return false
        }

        // Auto-capture follows a deterministic face order.
        guard let targetFace = getNextFaceToCapture() else {
            logDebug("[CubeCam] ⏭️ No capture: No pending face")
            return false
        }
        guard !enforceCaptureOrder || face == targetFace else {
            logDebug("[CubeCam] ⏭️ No capture: Waiting for \(targetFace), currently seeing \(face)")
            return false
        }
        
        // Don't capture if already captured this face
        guard !capturedFaces.keys.contains(face) else {
            logDebug("[CubeCam] ⏭️ No capture: Face \(face) already captured")
            return false
        }

        guard !autoCaptureSuspendedFaces.contains(face) else {
            logDebug("[CubeCam] ⏭️ No capture: Auto-capture paused for \(face) after repeated failures")
            return false
        }

        guard timestamp >= autoCaptureBackoffUntil else {
            let remaining = autoCaptureBackoffUntil - timestamp
            logDebug("[CubeCam] ⏭️ No capture: Retry backoff active (\(remaining)s remaining)")
            return false
        }
        
        // GUARD: Only capture once per stabilization cycle
        guard !hasCapturedThisCycle else {
            logDebug("[CubeCam] ⏭️ No capture: Already captured this cycle")
            return false
        }
        
        // PROMPT 1: Check consecutive stable frames requirement
        guard consecutiveStableFrames >= requiredStableFrames else {
            logDebug("[CubeCam] ⏭️ No capture: Only \(consecutiveStableFrames)/\(requiredStableFrames) stable frames")
            return false
        }
        
        // Check stability against configured frame threshold.
        guard stability >= stableFrameThreshold else {
            logDebug("[CubeCam] ⏭️ No capture: Stability too low (\(stability) < \(stableFrameThreshold))")
            return false
        }
        
        // Check confidence
        guard faceEstimateConfidence >= autoCaptureThreshold else {
            logDebug("[CubeCam] ⏭️ No capture: Confidence too low (\(faceEstimateConfidence) < \(autoCaptureThreshold))")
            return false
        }
        
        // PROMPT 1: Check debounce delay
        guard timestamp - lastCaptureTime >= debounceDelay else {
            let remaining = debounceDelay - (timestamp - lastCaptureTime)
            logDebug("[CubeCam] ⏭️ No capture: Debounce delay (\(remaining)s remaining)")
            return false
        }
        
        // PROMPT 1: Must be in scanning state
        guard isScanning else {
            logDebug("[CubeCam] ⏭️ No capture: Not in scanning state")
            return false
        }
        
        // Check state machine
        guard case .stabilizing(let progress) = captureState, progress >= 1.0 else {
            logDebug("[CubeCam] ⏭️ No capture: Not in stabilizing(1.0) state - current: \(captureState)")
            return false
        }
        
        logDebug("[CubeCam] ✅ All capture conditions met!")
        return true
    }
    
    /// Capture the current face - PROMPT 2: Enhanced with duplicate detection, PROMPT 8: Error validation
    private func captureCurrentFace(
        videoFrame: CVPixelBuffer,
        depthFrame _: CVPixelBuffer?,
        detection: CubeFaceDetectionResult,
        timestamp: TimeInterval
    ) async {
        guard let face = currentFaceEstimate else {
            logWarning("[CubeCam] Cannot capture: No face estimate")
            return
        }
        
        // GUARD: Prevent multiple captures in same cycle
        guard !hasCapturedThisCycle else {
            logDebug("[CubeCam] ⚠️ Already captured this cycle - skipping")
            return
        }
        
        logDebug("[CubeCam] 📸 Starting capture for face: \(face)")
        
        // Mark as capturing to prevent duplicates
        hasCapturedThisCycle = true
        captureState = .capturing
        duplicateFaceWarning = nil
        
        // PROMPT 8: Validate lighting
        let brightness = detectionHistory.last?.brightness ?? 0.5
        if let lightingError = await errorDetector.validateLighting(brightness: brightness) {
            logWarning("[CubeCam] Lighting validation failed: \(lightingError)")
            currentError = lightingError
            resetAfterFailedCapture(face: face, timestamp: timestamp)
            return
        }
        
        // Classify sticker colors
        let colors = await colorClassifier.classifyStickers(
            buffer: videoFrame,
            faceRect: detection.boundingBox
        )
        
        logDebug("[CubeCam] 🎨 Classified \(colors.count) stickers")
        
        // PROMPT 8: Validate colors are readable
        if let colorError = await errorDetector.validateColors(colors) {
            logWarning("[CubeCam] Color validation failed: \(colorError)")
            currentError = colorError
            resetAfterFailedCapture(face: face, timestamp: timestamp)
            return
        }
        
        // PROMPT 8: Validate face layout
        if let layoutError = await errorDetector.validateFaceLayout(colors) {
            logWarning("[CubeCam] Face layout validation failed: \(layoutError)")
            currentError = layoutError
            resetAfterFailedCapture(face: face, timestamp: timestamp)
            return
        }
        
        // PROMPT 2: Check for duplicate patterns
        if let duplicateFace = findDuplicatePattern(colors: colors, excluding: face) {
            logWarning("[CubeCam] Duplicate pattern detected - matches face: \(duplicateFace)")
            duplicateFaceWarning = "That looks like the \(faceDisplayName(duplicateFace)) face you already scanned. Rotate to a different side."
            // This pattern was already scanned for a different face
            // Skip this capture and reset
            resetAfterFailedCapture(face: face, timestamp: timestamp)
            return
        }
        
        // Store captured face
        capturedFaces[face] = colors
        capturedPatterns[face] = colors
        lastCaptureTime = timestamp
        clearCaptureRetryState(for: face)
        
        logNotice("[CubeCam] Successfully captured face: \(face) (\(capturedFaces.count)/6)")
        
        // Clear any errors
        currentError = nil
        duplicateFaceWarning = nil
        
        // Update state to captured
        captureState = .captured
        
        // Reset for next face after a brief delay
        Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(self.captureResetDelay * 1_000_000_000))
            self.resetForNextFace()
        }
    }
    
    /// Reset state after a failed capture attempt
    private func resetAfterFailedCapture(face: Face, timestamp: TimeInterval) {
        logWarning("[CubeCam] Resetting after failed capture")
        recordCaptureFailure(for: face, timestamp: timestamp)
        hasCapturedThisCycle = false
        consecutiveStableFrames = 0
        stability = 0
        captureState = .detecting
        detectionHistory = []
    }
    
    /// Reset for next face after successful capture
    private func resetForNextFace() {
        logDebug("[CubeCam] 🔄 Resetting for next face")
        currentFaceEstimate = nil
        pendingFace = getNextFaceToCapture()
        detectionHistory = []
        consecutiveStableFrames = 0
        stability = 0
        lastDetection = nil
        hasCapturedThisCycle = false
        captureState = .idle
        duplicateFaceWarning = nil
    }
    
    /// PROMPT 2: Find if this color pattern matches an already-captured face
    /// Returns the face that has this pattern, or nil if unique
    private func findDuplicatePattern(colors: [CubeColor], excluding: Face) -> Face? {
        guard colors.count == 9 else {
            return nil
        }

        // Require center sticker match and near-identical full pattern to avoid false positives.
        let tolerance = 1
        
        for (face, pattern) in capturedPatterns {
            guard face != excluding else { continue }
            guard pattern.count == colors.count else { continue }
            guard pattern[4] == colors[4] else { continue }
            
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

    private func faceDisplayName(_ face: Face) -> String {
        switch face {
        case .up: return "top"
        case .down: return "bottom"
        case .left: return "left"
        case .right: return "right"
        case .front: return "front"
        case .back: return "back"
        }
    }

    private static func normalizedCaptureOrder(from order: [Face]) -> [Face] {
        var seen: Set<Face> = []
        var normalized: [Face] = []

        for face in order where !seen.contains(face) {
            seen.insert(face)
            normalized.append(face)
        }

        for face in defaultCaptureOrder where !seen.contains(face) {
            seen.insert(face)
            normalized.append(face)
        }

        return normalized
    }

    private func updateSmoothedFaceConfidence(face: Face, detectionConfidence: Float) {
        let clamped = min(max(detectionConfidence, 0), 1)

        if lastEstimatedFace == face {
            consistentFaceEstimateCount += 1
        } else {
            lastEstimatedFace = face
            consistentFaceEstimateCount = 1
            smoothedFaceEstimateConfidence = clamped
        }

        let consistencyWeight = min(
            1.0,
            Float(consistentFaceEstimateCount) / Float(max(1, minimumConsistentFaceFrames))
        )
        let weightedConfidence = clamped * consistencyWeight
        let alpha = min(max(faceConfidenceSmoothingAlpha, 0), 1)

        smoothedFaceEstimateConfidence =
            (alpha * weightedConfidence) + ((1 - alpha) * smoothedFaceEstimateConfidence)
    }

    private func recordCaptureFailure(for face: Face, timestamp: TimeInterval) {
        let newCount = retryCountsByFace[face, default: 0] + 1
        retryCountsByFace[face] = newCount

        let exponent = max(0, newCount - 1)
        let rawBackoff = retryBackoffBaseDelay * pow(2.0, Double(exponent))
        let cappedBackoff = min(maxRetryBackoffDelay, rawBackoff)
        autoCaptureBackoffUntil = max(autoCaptureBackoffUntil, timestamp + cappedBackoff)

        if newCount >= maxAutoCaptureRetriesPerFace {
            autoCaptureSuspendedFaces.insert(face)
            logWarning("[CubeCam] Auto-capture paused for \(face) after \(newCount) failed attempts")
        } else {
            logWarning("[CubeCam] Auto-capture retry \(newCount)/\(maxAutoCaptureRetriesPerFace) for \(face)")
        }
    }

    private func clearCaptureRetryState(for face: Face) {
        retryCountsByFace[face] = nil
        autoCaptureSuspendedFaces.remove(face)
        if retryCountsByFace.isEmpty {
            autoCaptureBackoffUntil = 0
        }
    }

    private func logDebug(_ message: String) {
        guard isVerboseLoggingEnabled else { return }
        #if canImport(OSLog)
        logger.debug("\(message, privacy: .public)")
        #else
        print(message)
        #endif
    }

    private func logNotice(_ message: String) {
        #if canImport(OSLog)
        logger.notice("\(message, privacy: .public)")
        #else
        print(message)
        #endif
    }

    private func logWarning(_ message: String) {
        #if canImport(OSLog)
        logger.warning("\(message, privacy: .public)")
        #else
        print("WARNING: \(message)")
        #endif
    }
}

#endif
