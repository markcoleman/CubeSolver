//
//  CameraSession.swift
//  CubeSolver - Camera Session with Depth Support
//
//  Created by GitHub Copilot
//

#if canImport(AVFoundation) && canImport(Combine)

import Foundation
@preconcurrency import AVFoundation
import Combine
#if canImport(CoreVideo)
import CoreVideo
#endif

/// Camera session for Cube Cam with video and depth capture
@MainActor
public final class CameraSession: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current authorization status
    @Published public var authorizationStatus: AVAuthorizationStatus = .notDetermined
    
    /// Session is running
    @Published public var isRunning: Bool = false
    
    /// Last captured video frame
    @Published public var lastVideoFrame: CVPixelBuffer?
    
    /// Last captured depth frame (if available)
    @Published public var lastDepthFrame: CVPixelBuffer?
    
    /// Frame metadata
    @Published public var frameMetadata: FrameMetadata?
    
    // MARK: - Configuration
    
    /// Enable depth capture (requires device with LiDAR or dual camera)
    public var enableDepthCapture: Bool = true
    
    /// Target frame rate
    public var targetFrameRate: Int = 30
    
    // MARK: - Private Properties
    
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.cubesolver.camera.session")

    private struct UncheckedCaptureSession: @unchecked Sendable {
        let value: AVCaptureSession
    }
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    // MARK: - Public Methods
    
    /// Request camera permissions
    public func requestPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        var isAuthorized = status == .authorized
        
        if status == .notDetermined {
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        }
        
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        return isAuthorized
    }
    
    /// Start the camera session
    public func start() async throws {
        guard authorizationStatus == .authorized else {
            throw CameraSessionError.notAuthorized
        }
        
        try await setupSession()
        let session = UncheckedCaptureSession(value: captureSession)
        
        sessionQueue.async {
            session.value.startRunning()
        }
        
        isRunning = true
    }
    
    /// Stop the camera session
    public func stop() {
        let session = UncheckedCaptureSession(value: captureSession)

        sessionQueue.async {
            session.value.stopRunning()
        }
        
        isRunning = false
    }
    
    /// Get the preview layer for displaying camera feed
    public func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }
    
    // MARK: - Private Methods
    
    private func setupSession() async throws {
        // Capture session configuration must be done on the session queue.
        let captureSessionBox = UncheckedCaptureSession(value: captureSession)
        let enableDepth = enableDepthCapture
        
        return try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: CameraSessionError.sessionSetupFailed)
                    return
                }
                let session = captureSessionBox.value

                do {
                    session.beginConfiguration()
                    
                    // Set session preset for high quality
                    if session.canSetSessionPreset(.photo) {
                        session.sessionPreset = .photo
                    }
                    
                    // Add video input
                    try self.addVideoInput(to: session)
                    
                    // Add video output
                    try self.addVideoOutput(to: session)
                    
                    // Add depth output if available and enabled
                    if enableDepth {
                        self.tryAddDepthOutput(to: session)
                    }
                    
                    session.commitConfiguration()
                    continuation.resume()
                } catch {
                    session.commitConfiguration()
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private nonisolated func addVideoInput(to session: AVCaptureSession) throws {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraSessionError.noVideoDevice
        }
        
        // Configure device for optimal scanning
        do {
            try videoDevice.lockForConfiguration()
            
            // Set focus mode to continuous auto-focus
            if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
                videoDevice.focusMode = .continuousAutoFocus
            }
            
            // Set exposure mode to continuous auto-exposure
            if videoDevice.isExposureModeSupported(.continuousAutoExposure) {
                videoDevice.exposureMode = .continuousAutoExposure
            }
            
            // Set white balance to continuous
            if videoDevice.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                videoDevice.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            
            videoDevice.unlockForConfiguration()
        } catch {
            // Configuration failed, but continue anyway
        }
        
        let videoInput = try AVCaptureDeviceInput(device: videoDevice)
        
        guard session.canAddInput(videoInput) else {
            throw CameraSessionError.cannotAddInput
        }
        
        session.addInput(videoInput)
        
    }
    
    private nonisolated func addVideoOutput(to session: AVCaptureSession) throws {
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: sessionQueue)
        
        // Set pixel format for processing
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        guard session.canAddOutput(output) else {
            throw CameraSessionError.cannotAddOutput
        }
        
        session.addOutput(output)
        
        // Set video orientation using modern API
        if let connection = output.connection(with: .video) {
            #if os(iOS)
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90 // Portrait orientation
            }
            #else
            // macOS uses different rotation handling
            if connection.isVideoRotationAngleSupported(0) {
                connection.videoRotationAngle = 0
            }
            #endif
        }
    }
    
    private nonisolated func tryAddDepthOutput(to session: AVCaptureSession) {
        #if os(iOS)
        // Need to get video device info from session inputs
        guard let videoInput = session.inputs.first as? AVCaptureDeviceInput else { return }
        let videoDevice = videoInput.device
        
        // Check if depth data is supported
        let formats = videoDevice.activeFormat.supportedDepthDataFormats
        guard !formats.isEmpty else {
            // Depth not supported on this device
            return
        }
        
        let output = AVCaptureDepthDataOutput()
        output.isFilteringEnabled = true
        output.setDelegate(self, callbackQueue: sessionQueue)
        
        guard session.canAddOutput(output) else {
            return
        }
        
        session.addOutput(output)
        
        // Configure depth/video synchronization
        if let videoOutput = session.outputs.first(where: { $0 is AVCaptureVideoDataOutput }) as? AVCaptureVideoDataOutput,
           let depthConnection = output.connection(with: .depthData),
           let videoConnection = videoOutput.connection(with: .video) {
            depthConnection.isEnabled = true
            videoConnection.isVideoMirrored = false
        }
        #endif
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // Extract metadata
        let metadata = extractMetadata(from: sampleBuffer)
        
        Task { @MainActor in
            self.lastVideoFrame = pixelBuffer
            self.frameMetadata = metadata
        }
    }
    
    private nonisolated func extractMetadata(from sampleBuffer: CMSampleBuffer) -> FrameMetadata {
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        
        // Get orientation from metadata if available
        var orientation: CGImagePropertyOrientation = .right
        if CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) != nil {
            // Extract actual orientation if available
            orientation = .right
        }
        
        return FrameMetadata(
            timestamp: timestamp,
            orientation: orientation,
            exposureDuration: 0.033, // ~30fps default
            brightness: 0.5
        )
    }
}

// MARK: - AVCaptureDepthDataOutputDelegate

#if os(iOS)
extension CameraSession: AVCaptureDepthDataOutputDelegate {
    nonisolated public func depthDataOutput(
        _ output: AVCaptureDepthDataOutput,
        didOutput depthData: AVDepthData,
        timestamp: CMTime,
        connection: AVCaptureConnection
    ) {
        // Convert depth data to pixel buffer
        let depthPixelBuffer = depthData.depthDataMap
        
        Task { @MainActor in
            self.lastDepthFrame = depthPixelBuffer
        }
    }
}
#endif

// MARK: - Supporting Types

/// Metadata about a captured frame
public struct FrameMetadata: Sendable {
    public let timestamp: TimeInterval
    public let orientation: CGImagePropertyOrientation
    public let exposureDuration: TimeInterval
    public let brightness: Float
    
    public init(timestamp: TimeInterval, orientation: CGImagePropertyOrientation, exposureDuration: TimeInterval, brightness: Float) {
        self.timestamp = timestamp
        self.orientation = orientation
        self.exposureDuration = exposureDuration
        self.brightness = brightness
    }
}

/// Camera session errors
public enum CameraSessionError: Error, LocalizedError {
    case notAuthorized
    case noVideoDevice
    case cannotAddInput
    case cannotAddOutput
    case sessionSetupFailed
    
    public var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Camera access not authorized. Please enable camera access in Settings."
        case .noVideoDevice:
            return "No video camera found on this device."
        case .cannotAddInput:
            return "Cannot add camera input to session."
        case .cannotAddOutput:
            return "Cannot add video output to session."
        case .sessionSetupFailed:
            return "Failed to setup camera session."
        }
    }
}

#endif
