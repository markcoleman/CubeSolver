#if canImport(Vision) && canImport(CoreVideo)

import Foundation
import Vision
import CoreVideo
import CubeCore

public actor VisionFaceQuadDetector: FaceQuadDetecting {
    private let detectionService = CubeFaceDetectionService()

    public init() {}

    public func detectQuadrilateral(in frame: RGBFrame) async throws -> FaceQuadrilateral? {
        guard let pixelBuffer = frame.pixelBuffer else {
            return nil
        }

        guard let detection = await detectionService.detectCubeFace(in: pixelBuffer),
              detection.corners.count == 4 else {
            return nil
        }

        let topLeft = normalizedPoint(fromVisionPoint: detection.corners[0])
        let topRight = normalizedPoint(fromVisionPoint: detection.corners[1])
        let bottomRight = normalizedPoint(fromVisionPoint: detection.corners[2])
        let bottomLeft = normalizedPoint(fromVisionPoint: detection.corners[3])

        return FaceQuadrilateral(
            topLeft: topLeft,
            topRight: topRight,
            bottomRight: bottomRight,
            bottomLeft: bottomLeft
        )
    }

    /// Vision coordinates are bottom-left origin; scanner sampling is top-left.
    private func normalizedPoint(fromVisionPoint point: CGPoint) -> NormalizedPoint {
        NormalizedPoint(
            x: Double(max(0, min(1, point.x))),
            y: Double(max(0, min(1, 1 - point.y)))
        )
    }
}

#endif
