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

#else

// Placeholder tests for platforms without AVFoundation/Vision
final class CubeScannerTests: XCTestCase {
    func testPlaceholder() {
        XCTAssertTrue(true, "Platform does not support AVFoundation/Vision")
    }
}

#endif
