//
//  EnhancedCubeCamViewModel.swift
//  CubeSolver - Enhanced Cube Cam View Model with UX Improvements
//
//  Created by GitHub Copilot
//

#if os(iOS)

import Foundation
import SwiftUI
import Combine
import CubeCore
import UIKit
import AVFoundation
import CoreVideo

/// Enhanced view model for CubeCam with improved UX and step-by-step guidance
@MainActor
public final class EnhancedCubeCamViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// State for each face
    @Published public var faceStates: [Face: FaceScanState] = [:]
    
    /// Current step guidance
    @Published public var currentGuidance: ScanStepGuidance?
    
    /// Last scan result (for feedback)
    @Published public var lastScanResult: ScanResult?
    
    /// Current error (if any)
    @Published public var currentError: ScanErrorType?
    
    /// Overall scan completion status
    @Published public var isComplete: Bool = false
    
    /// Completed cube state
    @Published public var completedCubeState: CubeState?
    
    /// Number of faces captured
    @Published public var capturedCount: Int = 0
    
    /// Current stability (0-1)
    @Published public var stability: Float = 0
    
    /// Last detection result for overlay
    @Published public var detectionResult: CubeFaceDetectionResult?
    
    /// Frame metadata
    @Published public var frameMetadata: FrameMetadata?

    /// Current video frame size used for camera overlay coordinate mapping.
    @Published public var videoFrameSize: CGSize = .zero

    /// Warning when the detected face likely duplicates one already captured.
    @Published public var duplicateFaceWarning: String?
    
    // MARK: - Private Properties
    
    public let cameraSession = CameraSession()
    public let capturePipeline = CubeCamCapturePipeline()
    
    private var cancellables = Set<AnyCancellable>()
    private var frameProcessingTask: Task<Void, Never>?
    private var isProcessingFrames: Bool = false
    
    // Face capture order (recommended sequence)
    private let recommendedFaceOrder: [Face] = [.up, .front, .right, .back, .left, .down]
    
    // MARK: - Initialization
    
    public init() {
        setupBindings()
        initializeFaceStates()
        updateGuidance()
    }
    
    // MARK: - Public Methods
    
    /// Start the camera and scanning process
    public func start() async {
        // Request camera permission
        let authorized = await cameraSession.requestPermission()
        
        guard authorized else {
            currentError = .cubeNotDetected
            return
        }
        
        // Start camera session
        do {
            try await cameraSession.start()
            startFrameProcessing()
        } catch {
            currentError = .cubeNotDetected
        }
    }
    
    /// Stop the camera and scanning process
    @MainActor public func stop() {
        isProcessingFrames = false
        frameProcessingTask?.cancel()
        frameProcessingTask = nil
        cameraSession.stop()
    }
    
    /// Reset scanning to start over
    public func reset() {
        capturePipeline.reset()
        initializeFaceStates()
        completedCubeState = nil
        capturedCount = 0
        isComplete = false
        lastScanResult = nil
        currentError = nil
        duplicateFaceWarning = nil
        updateGuidance()
    }
    
    /// Rescan a specific face
    public func rescanFace(_ face: Face) {
        // Remove the face from captured faces
        capturePipeline.capturedFaces.removeValue(forKey: face)
        
        // Update state
        faceStates[face] = .notScanned
        capturedCount = capturePipeline.capturedFaces.count
        isComplete = false
        
        // Update guidance to focus on this face
        if let stepNumber = recommendedFaceOrder.firstIndex(of: face) {
            currentGuidance = ScanStepGuidance.guidance(for: face, stepNumber: stepNumber + 1)
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Move to next face after successful capture
    public func moveToNextFace() {
        updateGuidance()
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Get the camera preview layer
    public func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        return cameraSession.getPreviewLayer()
    }
    
    /// Manually trigger capture
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
    
    /// Get next recommended face to scan
    public func nextFaceToScan() -> Face? {
        for face in recommendedFaceOrder {
            if faceStates[face] != .captured {
                return face
            }
        }
        return nil
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Monitor face captures
        capturePipeline.$capturedFaces
            .sink { [weak self] faces in
                guard let self = self else { return }
                
                let oldCount = self.capturedCount
                let newCount = faces.count
                
                self.capturedCount = newCount
                
                // Update face states
                for face in Face.allCases {
                    if faces.keys.contains(face) {
                        if self.faceStates[face] != .captured {
                            // Face was just captured
                            self.faceStates[face] = .captured
                            self.lastScanResult = .success(face: face)
                            
                            // Update guidance for next face
                            Task { @MainActor [weak self] in
                                try? await Task.sleep(nanoseconds: 1_500_000_000)
                                guard let self else { return }
                                self.lastScanResult = nil
                                self.updateGuidance()
                            }
                        }
                    }
                }
                
                // Check completion
                if newCount == 6 {
                    self.validateAndComplete(faces: faces)
                }
            }
            .store(in: &cancellables)
        
        // Monitor stability
        capturePipeline.$stability
            .sink { [weak self] stability in
                guard let self = self else { return }
                self.stability = stability
                
                // Update scanning state for current face
                if let nextFace = self.nextFaceToScan(),
                   stability > 0.3,
                   self.faceStates[nextFace] != .captured {
                    let progress = min(stability, 1.0)
                    self.faceStates[nextFace] = .scanning(progress: progress)
                }
            }
            .store(in: &cancellables)
        
        // Monitor detection results
        capturePipeline.$lastDetection
            .assign(to: &$detectionResult)

        capturePipeline.$duplicateFaceWarning
            .assign(to: &$duplicateFaceWarning)
        
        // Monitor errors
        capturePipeline.$currentError
            .sink { [weak self] error in
                guard let self = self, let error = error else { return }
                
                // Map scan errors to UI error types
                switch error {
                case .poorLighting:
                    self.currentError = .poorLighting
                case .movingTooFast:
                    self.currentError = .tooMuchMotion
                case .invalidFaceLayout:
                    self.currentError = .cubeNotDetected
                case .unreadableColors:
                    self.currentError = .invalidColors
                case .impossiblePattern:
                    self.currentError = .invalidColors
                }
            }
            .store(in: &cancellables)
    }
    
    private func initializeFaceStates() {
        for face in Face.allCases {
            faceStates[face] = .notScanned
        }
    }
    
    private func updateGuidance() {
        guard let nextFace = nextFaceToScan() else {
            currentGuidance = nil
            return
        }
        
        let stepNumber = capturedCount + 1
        currentGuidance = ScanStepGuidance.guidance(for: nextFace, stepNumber: stepNumber)
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
                
                self.videoFrameSize = CGSize(
                    width: CVPixelBufferGetWidth(videoFrame),
                    height: CVPixelBufferGetHeight(videoFrame)
                )

                let depthFrame = await self.cameraSession.lastDepthFrame
                let timestamp = Date().timeIntervalSince1970
                
                // Update frame metadata
                self.frameMetadata = await self.cameraSession.frameMetadata
                
                // Process frame
                await self.capturePipeline.processFrame(
                    videoFrame: videoFrame,
                    depthFrame: depthFrame,
                    timestamp: timestamp
                )
                
                // Throttle to reasonable frame rate
                try? await Task.sleep(nanoseconds: 33_000_000) // ~30fps
            }
        }
    }
    
    private func validateAndComplete(faces: [Face: [CubeColor]]) {
        // Build cube state
        var cubeState = CubeState()
        cubeState.faces = faces
        
        // Validate
        do {
            try CubeValidator.validate(cubeState)
            
            // Success!
            completedCubeState = cubeState
            isComplete = true
            
            // Celebration haptics
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 200_000_000)
                generator.notificationOccurred(.success)
            }
            
        } catch {
            // Validation failed - show error
            currentError = .invalidColors
            
            // Error haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
            // Reset after delay
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                self?.reset()
            }
        }
    }
    
    deinit {
        isProcessingFrames = false
        frameProcessingTask?.cancel()
        frameProcessingTask = nil
        let session = cameraSession
        Task { @MainActor in
            session.stop()
        }
    }
}

#endif
