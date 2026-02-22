import Foundation
import CubeCore

public actor SimulatedFaceScanner: FaceScanner {
    private var scriptedFaces: [FaceId: ScannedFaceData]
    private var delayNanos: UInt64

    public init(scriptedFaces: [FaceId: ScannedFaceData], delayNanos: UInt64 = 0) {
        self.scriptedFaces = scriptedFaces
        self.delayNanos = delayNanos
    }

    public func setDelayNanos(_ nanos: UInt64) {
        delayNanos = nanos
    }

    public func setFace(_ face: ScannedFaceData) {
        scriptedFaces[face.id] = face
    }

    public func scanFace(for face: FaceId) async throws -> ScannedFaceData {
        if delayNanos > 0 {
            try await Task.sleep(nanoseconds: delayNanos)
        }

        guard let scripted = scriptedFaces[face] else {
            throw FaceScannerError.noStableFaceDetected(face: face)
        }

        return scripted
    }
}
