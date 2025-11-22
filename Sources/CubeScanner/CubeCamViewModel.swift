//
//  CubeCamViewModel.swift
//  CubeSolver - Cube Cam View Model
//
//  Created by GitHub Copilot
//

#if canImport(SwiftUI) && canImport(AVFoundation)

import Foundation
import SwiftUI
import Combine
import CubeCore
#if canImport(UIKit)
import UIKit
#endif

/// View model for Cube Cam auto-scanning experience
@MainActor
public class CubeCamViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current detection status
    @Published public var detectionStatus: DetectionStatus = .preparing
    
    /// Number of faces captured
    @Published public var capturedFaceCount: Int = 0
    
    /// Captured faces (for UI display)
    @Published public var capturedFaces: Set<Face> = []
    
    /// Progress text for user guidance
    @Published public var captureProgressText: String = "Initializing camera..."
    
    /// Last error message
    @Published public var lastErrorMessage: String?
    
    /// Current face being captured
    @Published public var currentFace: Face?
    
    /// Stability indicator (0-1)
    @Published public var stability: Float = 0
    
    /// Detection result for UI overlay
    @Published public var detectionResult: CubeFaceDetectionResult?
    
    /// Completed cube state (when all 6 faces captured)
    @Published public var completedCubeState: CubeState?
    
    /// Trigger for face capture animation
    @Published public var faceCaptured: Bool = false
    
    // MARK: - Private Properties
    
    private let cameraSession = CameraSession()
    private let capturePipeline = CubeCamCapturePipeline()
    
    private var cancellables = Set<AnyCancellable>()
    private var frameProcessingTask: Task<Void, Never>?
    private var lastFaceCount: Int = 0
    private var isProcessingFrames: Bool = false
    
    // MARK: - Animation Constants
    
    private let faceCaptureAnimationDuration: UInt64 = 300_000_000 // 0.3 seconds
    private let successHapticDelay: UInt64 = 200_000_000 // 0.2 seconds
    private let validationFailureRetryDelay: UInt64 = 2_000_000_000 // 2 seconds
    
    // MARK: - Detection Status
    
    public enum DetectionStatus: Equatable {
        case preparing
        case detecting
        case capturing
        case completed
        case error(String)
        
        public static func == (lhs: DetectionStatus, rhs: DetectionStatus) -> Bool {
            switch (lhs, rhs) {
            case (.preparing, .preparing),
                 (.detecting, .detecting),
                 (.capturing, .capturing),
                 (.completed, .completed):
                return true
            case (.error(let msg1), .error(let msg2)):
                return msg1 == msg2
            default:
                return false
            }
        }
    }
    
    // MARK: - Initialization
    
    public init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Start the camera and scanning process
    public func start() async {
        detectionStatus = .preparing
        captureProgressText = "Requesting camera permission..."
        
        // Request camera permission
        let authorized = await cameraSession.requestPermission()
        
        guard authorized else {
            detectionStatus = .error("Camera access denied")
            lastErrorMessage = "Please enable camera access in Settings to use Cube Cam."
            return
        }
        
        // Start camera session
        do {
            try await cameraSession.start()
            detectionStatus = .detecting
            captureProgressText = "Position your cube in the frame"
            
            // Start frame processing
            startFrameProcessing()
        } catch {
            detectionStatus = .error("Camera failed to start")
            lastErrorMessage = error.localizedDescription
        }
    }
    
    /// Stop the camera and scanning process
    public func stop() {
        isProcessingFrames = false
        frameProcessingTask?.cancel()
        frameProcessingTask = nil
        cameraSession.stop()
    }
    
    /// Reset the scanning process
    public func reset() {
        capturePipeline.reset()
        completedCubeState = nil
        capturedFaceCount = 0
        detectionStatus = .detecting
        captureProgressText = "Position your cube in the frame"
        lastErrorMessage = nil
    }
    
    /// Get the camera preview layer
    public func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        return cameraSession.getPreviewLayer()
    }
    
    /// Manually trigger capture of current face
    public func manualCapture() async {
        guard let videoFrame = cameraSession.lastVideoFrame,
              let detection = capturePipeline.lastDetection else {
            return
        }
        
        await capturePipeline.manualCapture(
            videoFrame: videoFrame,
            depthFrame: cameraSession.lastDepthFrame,
            detection: detection
        )
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Bind capture pipeline to view model
        capturePipeline.$capturedFaces
            .sink { [weak self] faces in
                guard let self = self else { return }
                
                let newCount = faces.count
                let oldCount = self.lastFaceCount
                
                self.capturedFaceCount = newCount
                self.capturedFaces = Set(faces.keys)
                self.updateProgressText()
                
                // Trigger haptic feedback and animation when new face captured
                if newCount > oldCount {
                    self.triggerFaceCaptureEffects()
                }
                
                self.lastFaceCount = newCount
                
                // Check if all faces captured
                if faces.count == 6 {
                    self.validateAndComplete(faces: faces)
                }
            }
            .store(in: &cancellables)
        
        capturePipeline.$pendingFace
            .assign(to: &$currentFace)
        
        capturePipeline.$stability
            .assign(to: &$stability)
        
        capturePipeline.$lastDetection
            .assign(to: &$detectionResult)
    }
    
    private func startFrameProcessing() {
        guard !isProcessingFrames else { return }
        isProcessingFrames = true
        
        frameProcessingTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self, self.isProcessingFrames else { return }
                
                // Get latest frames
                guard let videoFrame = await self.cameraSession.lastVideoFrame else {
                    try? await Task.sleep(nanoseconds: 33_000_000) // ~30fps
                    continue
                }
                
                let depthFrame = await self.cameraSession.lastDepthFrame
                let timestamp = Date().timeIntervalSince1970
                
                // Process frame through pipeline
                await self.capturePipeline.processFrame(
                    videoFrame: videoFrame,
                    depthFrame: depthFrame,
                    timestamp: timestamp
                )
                
                // Update status
                await self.updateDetectionStatus()
                
                // Throttle to reasonable frame rate
                try? await Task.sleep(nanoseconds: 33_000_000) // ~30fps
            }
        }
    }
    
    private func updateDetectionStatus() {
        if capturedFaceCount == 6 {
            detectionStatus = .completed
        } else if stability > 0.7 {
            detectionStatus = .capturing
        } else {
            detectionStatus = .detecting
        }
    }
    
    private func updateProgressText() {
        if capturedFaceCount == 0 {
            captureProgressText = "Rotate your cube slowly to capture all sides"
        } else if capturedFaceCount < 6 {
            if let nextFace = capturePipeline.getNextFaceToCapture() {
                captureProgressText = "Captured \(capturedFaceCount)/6 faces. Show \(nextFace.rawValue) face"
            } else {
                captureProgressText = "Captured \(capturedFaceCount)/6 faces. Rotate to next face"
            }
        } else {
            captureProgressText = "All faces captured! Validating..."
        }
    }
    
    private func triggerFaceCaptureEffects() {
        // Trigger haptic feedback
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
        
        // Trigger animation
        faceCaptured = true
        
        // Reset animation trigger after delay
        Task {
            try? await Task.sleep(nanoseconds: faceCaptureAnimationDuration)
            self.faceCaptured = false
        }
    }
    
    private func validateAndComplete(faces: [Face: [CubeColor]]) {
        // Build cube state
        var cubeState = CubeState()
        cubeState.faces = faces
        
        // Validate cube state
        do {
            try CubeValidator.validate(cubeState)
            
            // Success!
            completedCubeState = cubeState
            detectionStatus = .completed
            captureProgressText = "Cube captured successfully!"
            
            // Celebration haptic
            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Add a second success haptic after delay
            Task {
                try? await Task.sleep(nanoseconds: successHapticDelay)
                generator.notificationOccurred(.success)
            }
            #endif
            
        } catch let error as CubeValidationError {
            // Validation failed
            detectionStatus = .error("Invalid cube configuration")
            lastErrorMessage = error.localizedDescription
            captureProgressText = "Validation failed. Please retry."
            
            // Error haptic
            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            #endif
            
            // Reset for retry
            Task {
                try? await Task.sleep(nanoseconds: validationFailureRetryDelay)
                reset()
            }
        } catch {
            detectionStatus = .error("Validation failed")
            lastErrorMessage = "Unknown validation error occurred."
            
            // Error haptic
            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            #endif
        }
    }
    
    deinit {
        stop()
    }
}

#endif
