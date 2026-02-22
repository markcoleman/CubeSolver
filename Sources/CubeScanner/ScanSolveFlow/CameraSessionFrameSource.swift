#if canImport(AVFoundation) && canImport(CoreVideo)

import Foundation
import AVFoundation
import CubeCore

public actor CameraSessionFrameSource: CameraFrameSource {
    private let cameraSession: CameraSession
    public var maxPollingAttempts = 60
    public var pollingIntervalNanos: UInt64 = 33_000_000

    public init(cameraSession: CameraSession) {
        self.cameraSession = cameraSession
    }

    public func nextFrame() async throws -> RGBFrame {
        for _ in 0..<maxPollingAttempts {
            if let pixelBuffer = await MainActor.run(body: { cameraSession.lastVideoFrame }),
               let frame = RGBFrame.make(from: pixelBuffer) {
                return frame
            }
            try await Task.sleep(nanoseconds: pollingIntervalNanos)
        }

        throw FaceScannerError.scannerUnavailable
    }
}

#endif
