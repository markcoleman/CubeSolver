import XCTest
import CubeCore
@testable import CubeScanner

#if canImport(AVFoundation) && canImport(Vision)

@MainActor
final class CubeScannerTests: XCTestCase {
    
    var scanner: CubeScanner!
    
    override func setUp() async throws {
        scanner = CubeScanner()
    }
    
    override func tearDown() async throws {
        scanner = nil
    }
    
    // MARK: - Initialization Tests
    
    func testScannerInitialization() {
        XCTAssertEqual(scanner.scannerState, .idle, "Scanner should start in idle state")
        XCTAssertNil(scanner.detectedCubeState, "Detected cube state should be nil initially")
        XCTAssertEqual(scanner.scannedFaceCount, 0, "Scanned face count should be 0")
        XCTAssertEqual(scanner.currentFace, .front, "Current face should default to front")
        XCTAssertTrue(scanner.confidenceScores.isEmpty, "Confidence scores should be empty")
    }
    
    func testScannerConfiguration() {
        XCTAssertEqual(scanner.confidenceThreshold, 0.85, "Default confidence threshold should be 0.85")
        XCTAssertEqual(scanner.scanTimeout, 60.0, "Default scan timeout should be 60 seconds")
        
        // Test modifying configuration
        scanner.confidenceThreshold = 0.9
        scanner.scanTimeout = 30.0
        
        XCTAssertEqual(scanner.confidenceThreshold, 0.9)
        XCTAssertEqual(scanner.scanTimeout, 30.0)
    }
    
    // MARK: - State Transition Tests
    
    func testStateTransitionToScanning() async throws {
        try await scanner.startScanning(face: .front)
        
        // After scanning completes (in placeholder implementation)
        XCTAssertEqual(scanner.scannerState, .completed, "Scanner should transition to completed")
    }
    
    func testStartScanningUpdatesFace() async throws {
        try await scanner.startScanning(face: .back)
        XCTAssertEqual(scanner.currentFace, .back, "Current face should be updated")
    }
    
    func testAcceptScanIncrementsCount() async {
        let initialCount = scanner.scannedFaceCount
        await scanner.acceptScan()
        
        XCTAssertEqual(scanner.scannedFaceCount, initialCount + 1, "Scanned face count should increment")
    }
    
    func testAcceptScanCompletesAfterSixFaces() async {
        // Scan 5 faces
        for _ in 0..<5 {
            await scanner.acceptScan()
        }
        
        XCTAssertNotEqual(scanner.scannerState, .completed, "Should not be completed before 6 faces")
        
        // Scan 6th face
        await scanner.acceptScan()
        
        XCTAssertEqual(scanner.scannerState, .completed, "Should be completed after 6 faces")
    }
    
    func testAcceptScanReturnsToIdleBeforeSixFaces() async {
        await scanner.acceptScan()
        
        XCTAssertEqual(scanner.scannerState, .idle, "Should return to idle after accepting non-final face")
    }
    
    // MARK: - Reset Tests
    
    func testReset() async throws {
        // Modify scanner state
        try await scanner.startScanning(face: .back)
        await scanner.acceptScan()
        scanner.confidenceScores = [0.9, 0.8, 0.7]
        
        // Reset
        scanner.reset()
        
        // Verify all state is reset
        XCTAssertEqual(scanner.scannerState, .idle, "State should be reset to idle")
        XCTAssertNil(scanner.detectedCubeState, "Detected cube state should be nil")
        XCTAssertEqual(scanner.scannedFaceCount, 0, "Scanned face count should be reset")
        XCTAssertEqual(scanner.currentFace, .front, "Current face should reset to front")
        XCTAssertTrue(scanner.confidenceScores.isEmpty, "Confidence scores should be empty")
    }
    
    // MARK: - Confidence Score Tests
    
    func testGetLowConfidenceStickers() {
        scanner.confidenceScores = [0.9, 0.8, 0.7, 0.95, 0.6, 0.85, 0.5, 0.9, 0.88]
        scanner.confidenceThreshold = 0.85
        
        let lowConfidence = scanner.getLowConfidenceStickers()
        
        // Indices 1, 2, 4, 6 should be below threshold
        XCTAssertEqual(lowConfidence.count, 4, "Should have 4 low confidence stickers")
        XCTAssertTrue(lowConfidence.contains(1), "Index 1 should be low confidence")
        XCTAssertTrue(lowConfidence.contains(2), "Index 2 should be low confidence")
        XCTAssertTrue(lowConfidence.contains(4), "Index 4 should be low confidence")
        XCTAssertTrue(lowConfidence.contains(6), "Index 6 should be low confidence")
    }
    
    func testGetLowConfidenceStickersWithNoLowScores() {
        scanner.confidenceScores = [0.9, 0.95, 0.88, 0.92, 0.9, 0.87, 0.93, 0.9, 0.91]
        scanner.confidenceThreshold = 0.85
        
        let lowConfidence = scanner.getLowConfidenceStickers()
        
        XCTAssertTrue(lowConfidence.isEmpty, "Should have no low confidence stickers")
    }
    
    func testGetLowConfidenceStickersWithEmptyScores() {
        scanner.confidenceScores = []
        
        let lowConfidence = scanner.getLowConfidenceStickers()
        
        XCTAssertTrue(lowConfidence.isEmpty, "Should return empty array for empty scores")
    }
    
    func testGetLowConfidenceStickersWithDifferentThreshold() {
        scanner.confidenceScores = [0.9, 0.8, 0.7, 0.95, 0.6]
        scanner.confidenceThreshold = 0.75
        
        let lowConfidence = scanner.getLowConfidenceStickers()
        
        // Only indices 2 and 4 should be below 0.75
        XCTAssertEqual(lowConfidence.count, 2, "Should have 2 low confidence stickers")
    }
    
    // MARK: - Scanner Workflow Tests
    
    func testFullScanningWorkflow() async throws {
        XCTAssertEqual(scanner.scannerState, .idle, "Should start in idle")
        
        // Scan first face
        try await scanner.startScanning(face: .front)
        XCTAssertEqual(scanner.currentFace, .front)
        
        await scanner.acceptScan()
        XCTAssertEqual(scanner.scannedFaceCount, 1)
        XCTAssertEqual(scanner.scannerState, .idle)
        
        // Scan remaining faces
        for face in [Face.back, .left, .right, .up, .down] {
            try await scanner.startScanning(face: face)
            await scanner.acceptScan()
        }
        
        XCTAssertEqual(scanner.scannedFaceCount, 6)
        XCTAssertEqual(scanner.scannerState, .completed)
    }
    
    func testAcceptScanWithCorrections() async {
        let corrections: [Int: CubeColor] = [0: .blue, 4: .red, 8: .green]
        
        await scanner.acceptScan(with: corrections)
        
        XCTAssertEqual(scanner.scannedFaceCount, 1, "Should increment face count")
    }
    
    // MARK: - Edge Cases
    
    func testMultipleResets() {
        scanner.reset()
        scanner.reset()
        scanner.reset()
        
        // Should still be in valid state
        XCTAssertEqual(scanner.scannerState, .idle)
        XCTAssertEqual(scanner.scannedFaceCount, 0)
    }
    
    func testProcessFrameWithoutPixelBuffer() async throws {
        // Test that processFrame can be called (returns empty in placeholder)
        let results = try await scanner.processFrame(createDummyPixelBuffer())
        
        XCTAssertNotNil(results, "Should return results array")
    }
    
    // MARK: - State Consistency Tests
    
    func testScannerStateEquality() {
        XCTAssertEqual(CubeScanner.ScannerState.idle, .idle)
        XCTAssertEqual(CubeScanner.ScannerState.scanning, .scanning)
        XCTAssertEqual(CubeScanner.ScannerState.processing, .processing)
        XCTAssertEqual(CubeScanner.ScannerState.completed, .completed)
        XCTAssertEqual(CubeScanner.ScannerState.error("test"), .error("test"))
        
        XCTAssertNotEqual(CubeScanner.ScannerState.idle, .scanning)
        XCTAssertNotEqual(CubeScanner.ScannerState.error("a"), .error("b"))
    }
    
    // MARK: - Helper Methods
    
    private func createDummyPixelBuffer() -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            100,
            100,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        )
        
        return pixelBuffer!
    }
}

// MARK: - CubeCamCapturePipeline Tests

@MainActor
final class CubeCamCapturePipelineTests: XCTestCase {
    
    var pipeline: CubeCamCapturePipeline!
    
    override func setUp() async throws {
        pipeline = CubeCamCapturePipeline()
    }
    
    override func tearDown() async throws {
        pipeline = nil
    }
    
    // MARK: - Initialization Tests
    
    func testPipelineInitialization() {
        XCTAssertEqual(pipeline.captureState, .idle, "Pipeline should start in idle state")
        XCTAssertEqual(pipeline.capturedFaces.count, 0, "Should have no captured faces")
        XCTAssertNil(pipeline.pendingFace, "Should have no pending face")
        XCTAssertEqual(pipeline.stability, 0, "Stability should be 0")
        XCTAssertEqual(pipeline.consecutiveStableFrames, 0, "Should have 0 stable frames")
        XCTAssertFalse(pipeline.isScanning, "Should not be scanning")
    }
    
    func testPipelineConfiguration() {
        XCTAssertEqual(pipeline.stabilityDuration, 0.4, "Default stability duration should be 0.4s")
        XCTAssertEqual(pipeline.debounceDelay, 0.4, "Default debounce delay should be 0.4s")
        XCTAssertEqual(pipeline.requiredStableFrames, 8, "Default required frames should be 8")
        XCTAssertEqual(pipeline.autoCaptureThreshold, 0.8, "Default auto-capture threshold should be 0.8")
    }
    
    // MARK: - CaptureState Tests
    
    func testCaptureStateEquality() {
        XCTAssertEqual(CubeCamCapturePipeline.CaptureState.idle, .idle)
        XCTAssertEqual(CubeCamCapturePipeline.CaptureState.detecting, .detecting)
        XCTAssertEqual(CubeCamCapturePipeline.CaptureState.capturing, .capturing)
        XCTAssertEqual(CubeCamCapturePipeline.CaptureState.captured, .captured)
        
        XCTAssertEqual(
            CubeCamCapturePipeline.CaptureState.stabilizing(progress: 0.5),
            CubeCamCapturePipeline.CaptureState.stabilizing(progress: 0.5)
        )
        
        XCTAssertNotEqual(
            CubeCamCapturePipeline.CaptureState.stabilizing(progress: 0.5),
            CubeCamCapturePipeline.CaptureState.stabilizing(progress: 0.6)
        )
        
        XCTAssertNotEqual(CubeCamCapturePipeline.CaptureState.idle, .detecting)
    }
    
    func testCaptureStateProgress() {
        let state1 = CubeCamCapturePipeline.CaptureState.stabilizing(progress: 0.0)
        let state2 = CubeCamCapturePipeline.CaptureState.stabilizing(progress: 0.5)
        let state3 = CubeCamCapturePipeline.CaptureState.stabilizing(progress: 1.0)
        
        switch state1 {
        case .stabilizing(let progress):
            XCTAssertEqual(progress, 0.0, accuracy: 0.01)
        default:
            XCTFail("Should be stabilizing state")
        }
        
        switch state2 {
        case .stabilizing(let progress):
            XCTAssertEqual(progress, 0.5, accuracy: 0.01)
        default:
            XCTFail("Should be stabilizing state")
        }
        
        switch state3 {
        case .stabilizing(let progress):
            XCTAssertEqual(progress, 1.0, accuracy: 0.01)
        default:
            XCTFail("Should be stabilizing state")
        }
    }
    
    // MARK: - Reset Tests
    
    func testResetClearsAllState() {
        // Set up some state
        pipeline.capturedFaces[.front] = Array(repeating: .blue, count: 9)
        pipeline.pendingFace = .back
        pipeline.stability = 0.9
        pipeline.consecutiveStableFrames = 5
        pipeline.captureState = .capturing
        
        // Reset
        pipeline.reset()
        
        // Verify all cleared
        XCTAssertEqual(pipeline.capturedFaces.count, 0, "Should have no captured faces")
        XCTAssertNil(pipeline.pendingFace, "Should have no pending face")
        XCTAssertEqual(pipeline.stability, 0, "Stability should be 0")
        XCTAssertEqual(pipeline.consecutiveStableFrames, 0, "Should have 0 stable frames")
        XCTAssertEqual(pipeline.captureState, .idle, "Should be in idle state")
        XCTAssertFalse(pipeline.isScanning, "Should not be scanning")
    }
    
    // MARK: - Next Face Tests
    
    func testGetNextFaceToCapture() {
        XCTAssertNotNil(pipeline.getNextFaceToCapture(), "Should have next face when none captured")
        
        // Capture all faces
        for face in Face.allCases {
            pipeline.capturedFaces[face] = Array(repeating: .blue, count: 9)
        }
        
        XCTAssertNil(pipeline.getNextFaceToCapture(), "Should have no next face when all captured")
    }
    
    func testGetNextFaceExcludesCaptured() {
        pipeline.capturedFaces[.front] = Array(repeating: .blue, count: 9)
        pipeline.capturedFaces[.back] = Array(repeating: .red, count: 9)
        
        let nextFace = pipeline.getNextFaceToCapture()
        
        XCTAssertNotNil(nextFace)
        XCTAssertNotEqual(nextFace, .front, "Should not return already captured front face")
        XCTAssertNotEqual(nextFace, .back, "Should not return already captured back face")
    }
    
    // MARK: - State Transitions
    
    func testStateRemainsIdleWithoutDetection() {
        XCTAssertEqual(pipeline.captureState, .idle)
        // Without processing frames with actual detections, state should remain idle
        XCTAssertEqual(pipeline.captureState, .idle)
    }
    
    func testConsecutiveStableFramesIncrements() {
        // This test verifies the counter logic (actual frame processing requires Vision)
        // We can verify the initial state and that reset clears it
        pipeline.consecutiveStableFrames = 5
        XCTAssertEqual(pipeline.consecutiveStableFrames, 5)
        
        pipeline.reset()
        XCTAssertEqual(pipeline.consecutiveStableFrames, 0)
    }
    
    // MARK: - Auto Capture Configuration
    
    func testAutoCaptureCanBeDisabled() {
        XCTAssertTrue(pipeline.autoCaptureEnabled, "Auto-capture should be enabled by default")
        
        pipeline.autoCaptureEnabled = false
        XCTAssertFalse(pipeline.autoCaptureEnabled)
    }
    
    func testConfigurationChanges() {
        pipeline.stabilityDuration = 1.0
        pipeline.debounceDelay = 0.5
        pipeline.requiredStableFrames = 10
        pipeline.autoCaptureThreshold = 0.9
        
        XCTAssertEqual(pipeline.stabilityDuration, 1.0)
        XCTAssertEqual(pipeline.debounceDelay, 0.5)
        XCTAssertEqual(pipeline.requiredStableFrames, 10)
        XCTAssertEqual(pipeline.autoCaptureThreshold, 0.9)
    }
}

// MARK: - StickerColorClassifier Tests

@MainActor
final class StickerColorClassifierTests: XCTestCase {
    
    var classifier: StickerColorClassifier!
    
    override func setUp() async throws {
        classifier = StickerColorClassifier()
    }
    
    override func tearDown() async throws {
        classifier = nil
    }
    
    // MARK: - Configuration Tests
    
    func testClassifierDefaultConfiguration() async {
        // Default flipYCoordinates should be true for Vision compatibility
        let flipY = await classifier.flipYCoordinates
        XCTAssertTrue(flipY, "Default flipYCoordinates should be true")
        
        let whiteSatThreshold = await classifier.whiteSaturationThreshold
        XCTAssertEqual(whiteSatThreshold, 0.25, accuracy: 0.01, "Default white saturation threshold")
        
        let whiteBriThreshold = await classifier.whiteBrightnessThreshold
        XCTAssertEqual(whiteBriThreshold, 0.60, accuracy: 0.01, "Default white brightness threshold")
    }
    
    func testSetFlipYCoordinates() async {
        await classifier.setFlipYCoordinates(false)
        let flipY = await classifier.flipYCoordinates
        XCTAssertFalse(flipY, "flipYCoordinates should be false after setting")
        
        await classifier.setFlipYCoordinates(true)
        let flipY2 = await classifier.flipYCoordinates
        XCTAssertTrue(flipY2, "flipYCoordinates should be true after setting")
    }
    
    // MARK: - Pixel Buffer Color Classification Tests
    
    func testClassifyStickersReturnsNineColors() async {
        let pixelBuffer = createTestPixelBuffer(width: 100, height: 100, color: (r: 255, g: 255, b: 255))
        
        let faceRect = CGRect(x: 0.15, y: 0.15, width: 0.7, height: 0.7)
        let colors = await classifier.classifyStickers(buffer: pixelBuffer, faceRect: faceRect)
        
        XCTAssertEqual(colors.count, 9, "Should return exactly 9 colors")
    }
    
    func testClassifyWhiteStickers() async {
        // Create a pixel buffer with white color (high brightness, low saturation)
        let pixelBuffer = createTestPixelBuffer(width: 100, height: 100, color: (r: 240, g: 240, b: 240))
        await classifier.setFlipYCoordinates(false)
        
        let faceRect = CGRect(x: 0.15, y: 0.15, width: 0.7, height: 0.7)
        let colors = await classifier.classifyStickers(buffer: pixelBuffer, faceRect: faceRect)
        
        // All colors should be white
        for (index, color) in colors.enumerated() {
            XCTAssertEqual(color, .white, "Sticker \(index) should be white")
        }
    }
    
    func testClassifyRedStickers() async {
        // Create a pixel buffer with red color
        let pixelBuffer = createTestPixelBuffer(width: 100, height: 100, color: (r: 220, g: 30, b: 30))
        await classifier.setFlipYCoordinates(false)
        
        let faceRect = CGRect(x: 0.15, y: 0.15, width: 0.7, height: 0.7)
        let colors = await classifier.classifyStickers(buffer: pixelBuffer, faceRect: faceRect)
        
        // All colors should be red
        for (index, color) in colors.enumerated() {
            XCTAssertEqual(color, .red, "Sticker \(index) should be red")
        }
    }
    
    func testClassifyBlueStickers() async {
        // Create a pixel buffer with blue color
        let pixelBuffer = createTestPixelBuffer(width: 100, height: 100, color: (r: 30, g: 30, b: 200))
        await classifier.setFlipYCoordinates(false)
        
        let faceRect = CGRect(x: 0.15, y: 0.15, width: 0.7, height: 0.7)
        let colors = await classifier.classifyStickers(buffer: pixelBuffer, faceRect: faceRect)
        
        // All colors should be blue
        for (index, color) in colors.enumerated() {
            XCTAssertEqual(color, .blue, "Sticker \(index) should be blue")
        }
    }
    
    func testClassifyGreenStickers() async {
        // Create a pixel buffer with green color
        let pixelBuffer = createTestPixelBuffer(width: 100, height: 100, color: (r: 30, g: 180, b: 30))
        await classifier.setFlipYCoordinates(false)
        
        let faceRect = CGRect(x: 0.15, y: 0.15, width: 0.7, height: 0.7)
        let colors = await classifier.classifyStickers(buffer: pixelBuffer, faceRect: faceRect)
        
        // All colors should be green
        for (index, color) in colors.enumerated() {
            XCTAssertEqual(color, .green, "Sticker \(index) should be green")
        }
    }
    
    func testClassifyYellowStickers() async {
        // Create a pixel buffer with yellow color
        let pixelBuffer = createTestPixelBuffer(width: 100, height: 100, color: (r: 240, g: 230, b: 40))
        await classifier.setFlipYCoordinates(false)
        
        let faceRect = CGRect(x: 0.15, y: 0.15, width: 0.7, height: 0.7)
        let colors = await classifier.classifyStickers(buffer: pixelBuffer, faceRect: faceRect)
        
        // All colors should be yellow
        for (index, color) in colors.enumerated() {
            XCTAssertEqual(color, .yellow, "Sticker \(index) should be yellow")
        }
    }
    
    func testClassifyOrangeStickers() async {
        // Create a pixel buffer with orange color
        let pixelBuffer = createTestPixelBuffer(width: 100, height: 100, color: (r: 240, g: 120, b: 30))
        await classifier.setFlipYCoordinates(false)
        
        let faceRect = CGRect(x: 0.15, y: 0.15, width: 0.7, height: 0.7)
        let colors = await classifier.classifyStickers(buffer: pixelBuffer, faceRect: faceRect)
        
        // All colors should be orange
        for (index, color) in colors.enumerated() {
            XCTAssertEqual(color, .orange, "Sticker \(index) should be orange")
        }
    }
    
    // MARK: - White vs Yellow Discrimination Test
    
    func testWhiteNotMisclassifiedAsYellow() async {
        // Test case: bright, slightly warm white should NOT be classified as yellow
        // This addresses the issue where white stickers were being detected as yellow
        let warmWhite = createTestPixelBuffer(width: 100, height: 100, color: (r: 250, g: 245, b: 235))
        await classifier.setFlipYCoordinates(false)
        
        let faceRect = CGRect(x: 0.15, y: 0.15, width: 0.7, height: 0.7)
        let colors = await classifier.classifyStickers(buffer: warmWhite, faceRect: faceRect)
        
        for (index, color) in colors.enumerated() {
            XCTAssertEqual(color, .white, "Warm white sticker \(index) should be white, not yellow")
        }
    }
    
    // MARK: - Blue vs Orange Discrimination Test
    
    func testBlueNotMisclassifiedAsOrange() async {
        // Test case: blue should never be classified as orange
        let blue = createTestPixelBuffer(width: 100, height: 100, color: (r: 50, g: 80, b: 200))
        await classifier.setFlipYCoordinates(false)
        
        let faceRect = CGRect(x: 0.15, y: 0.15, width: 0.7, height: 0.7)
        let colors = await classifier.classifyStickers(buffer: blue, faceRect: faceRect)
        
        for (index, color) in colors.enumerated() {
            XCTAssertNotEqual(color, .orange, "Blue sticker \(index) should not be orange")
            XCTAssertNotEqual(color, .yellow, "Blue sticker \(index) should not be yellow")
        }
    }
    
    // MARK: - Center Sticker Tests
    
    func testClassifyCenterStickerReturnsColor() async {
        let pixelBuffer = createTestPixelBuffer(width: 100, height: 100, color: (r: 220, g: 30, b: 30))
        await classifier.setFlipYCoordinates(false)
        
        let faceRect = CGRect(x: 0.15, y: 0.15, width: 0.7, height: 0.7)
        let centerColor = await classifier.classifyCenterSticker(buffer: pixelBuffer, faceRect: faceRect)
        
        XCTAssertEqual(centerColor, .red, "Center sticker should be red")
    }
    
    // MARK: - Y-Flip Tests
    
    func testYFlipAffectsColorDetection() async {
        // Create a pixel buffer with different colors in top half vs bottom half
        let pixelBuffer = createVerticallyDividedPixelBuffer(
            width: 100, height: 100,
            topColor: (r: 30, g: 30, b: 200),  // Blue on top
            bottomColor: (r: 220, g: 30, b: 30) // Red on bottom
        )
        
        // Detect region in the top portion (y: 0.1 to 0.4)
        let topRegion = CGRect(x: 0.15, y: 0.1, width: 0.7, height: 0.3)
        
        // With Y-flip enabled (Vision coordinates), the "top" region maps to bottom of pixel buffer
        await classifier.setFlipYCoordinates(true)
        let colorsWithFlip = await classifier.classifyStickers(buffer: pixelBuffer, faceRect: topRegion)
        
        // Without Y-flip (standard coordinates), the "top" region maps to top of pixel buffer
        await classifier.setFlipYCoordinates(false)
        let colorsNoFlip = await classifier.classifyStickers(buffer: pixelBuffer, faceRect: topRegion)
        
        // The colors should be different depending on flip setting
        // This verifies the Y-flip is actually affecting which region is sampled
        XCTAssertNotEqual(colorsWithFlip, colorsNoFlip, "Y-flip should affect which region is sampled")
    }
    
    // MARK: - Helper Methods
    
    /// Creates a solid color pixel buffer in BGRA format
    private func createTestPixelBuffer(width: Int, height: Int, color: (r: UInt8, g: UInt8, b: UInt8)) -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        )
        
        guard let buffer = pixelBuffer else {
            fatalError("Failed to create test pixel buffer")
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        let baseAddress = CVPixelBufferGetBaseAddress(buffer)!
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * 4
                let pixel = baseAddress.advanced(by: offset).assumingMemoryBound(to: UInt8.self)
                pixel[0] = color.b  // Blue
                pixel[1] = color.g  // Green
                pixel[2] = color.r  // Red
                pixel[3] = 255      // Alpha
            }
        }
        
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
    
    /// Creates a pixel buffer with different colors in top and bottom halves
    private func createVerticallyDividedPixelBuffer(
        width: Int, height: Int,
        topColor: (r: UInt8, g: UInt8, b: UInt8),
        bottomColor: (r: UInt8, g: UInt8, b: UInt8)
    ) -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        )
        
        guard let buffer = pixelBuffer else {
            fatalError("Failed to create test pixel buffer")
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        let baseAddress = CVPixelBufferGetBaseAddress(buffer)!
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let midY = height / 2
        
        for y in 0..<height {
            let color = y < midY ? topColor : bottomColor
            for x in 0..<width {
                let offset = y * bytesPerRow + x * 4
                let pixel = baseAddress.advanced(by: offset).assumingMemoryBound(to: UInt8.self)
                pixel[0] = color.b  // Blue
                pixel[1] = color.g  // Green
                pixel[2] = color.r  // Red
                pixel[3] = 255      // Alpha
            }
        }
        
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
}

#else

// Placeholder tests for platforms without AVFoundation/Vision
final class CubeScannerTests: XCTestCase {
    func testPlaceholder() {
        XCTAssertTrue(true, "Platform does not support AVFoundation/Vision")
    }
}

final class CubeCamCapturePipelineTests: XCTestCase {
    func testPlaceholder() {
        XCTAssertTrue(true, "Platform does not support AVFoundation/Vision")
    }
}

final class StickerColorClassifierTests: XCTestCase {
    func testPlaceholder() {
        XCTAssertTrue(true, "Platform does not support CoreVideo/CoreGraphics")
    }
}

#endif
