import Foundation
import CubeCore

public actor CenteredFaceQuadDetector: FaceQuadDetecting {
    public init() {}

    public func detectQuadrilateral(in frame: RGBFrame) async throws -> FaceQuadrilateral? {
        _ = frame
        return .centered
    }
}

public actor DefaultFaceScanner: FaceScanner {
    public var maxScanAttempts: Int
    public var minimumMeanConfidence: Float

    private let frameSource: CameraFrameSource
    private let quadDetector: FaceQuadDetecting
    private let warpSampler: FaceWarpSampler
    private let classifier: StickerColorClassifying

    public init(
        frameSource: CameraFrameSource,
        quadDetector: FaceQuadDetecting = CenteredFaceQuadDetector(),
        warpSampler: FaceWarpSampler = FaceWarpSampler(),
        classifier: StickerColorClassifying = HSVStickerClassifier(),
        maxScanAttempts: Int = 30,
        minimumMeanConfidence: Float = 0.45
    ) {
        self.frameSource = frameSource
        self.quadDetector = quadDetector
        self.warpSampler = warpSampler
        self.classifier = classifier
        self.maxScanAttempts = max(1, maxScanAttempts)
        self.minimumMeanConfidence = max(0, min(1, minimumMeanConfidence))
    }

    public func scanFace(for face: FaceId) async throws -> ScannedFaceData {
        var bestResult: FaceSamplingResult?

        for _ in 0..<maxScanAttempts {
            let frame = try await frameSource.nextFrame()
            guard let quad = try await quadDetector.detectQuadrilateral(in: frame) else {
                continue
            }

            let sampled = try warpSampler.sample(frame: frame, quad: quad, classifier: classifier)

            if sampled.meanConfidence >= minimumMeanConfidence {
                return ScannedFaceData(
                    id: face,
                    grid: sampled.face,
                    confidence: sampled.meanConfidence
                )
            }

            if let currentBest = bestResult {
                if sampled.meanConfidence > currentBest.meanConfidence {
                    bestResult = sampled
                }
            } else {
                bestResult = sampled
            }
        }

        if let fallback = bestResult {
            return ScannedFaceData(
                id: face,
                grid: fallback.face,
                confidence: fallback.meanConfidence
            )
        }

        throw FaceScannerError.noStableFaceDetected(face: face)
    }
}

public actor StaticFrameSource: CameraFrameSource {
    private let frame: RGBFrame

    public init(frame: RGBFrame) {
        self.frame = frame
    }

    public func nextFrame() async throws -> RGBFrame {
        frame
    }
}
