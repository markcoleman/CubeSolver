import XCTest
import CubeCore
@testable import CubeScanner

final class ScanSolvePipelineTests: XCTestCase {
    func testHSVClassifierMapsRepresentativeSamples() {
        let classifier = HSVStickerClassifier()

        XCTAssertEqual(classifier.classify(pixel: RGBPixel(red: 0.95, green: 0.95, blue: 0.95)).color, .white)
        XCTAssertEqual(classifier.classify(pixel: RGBPixel(red: 0.95, green: 0.82, blue: 0.15)).color, .yellow)
        XCTAssertEqual(classifier.classify(pixel: RGBPixel(red: 0.88, green: 0.14, blue: 0.12)).color, .red)
        XCTAssertEqual(classifier.classify(pixel: RGBPixel(red: 0.95, green: 0.44, blue: 0.10)).color, .orange)
        XCTAssertEqual(classifier.classify(pixel: RGBPixel(red: 0.12, green: 0.22, blue: 0.85)).color, .blue)
        XCTAssertEqual(classifier.classify(pixel: RGBPixel(red: 0.10, green: 0.68, blue: 0.20)).color, .green)
    }

    func testFaceWarpSamplerCellExtractionMath() throws {
        let frame = try makeSyntheticFrame(
            rows: [
                [RGBPixel(red: 1, green: 0, blue: 0), RGBPixel(red: 0, green: 1, blue: 0), RGBPixel(red: 0, green: 0, blue: 1)],
                [RGBPixel(red: 1, green: 0.5, blue: 0), RGBPixel(red: 1, green: 1, blue: 1), RGBPixel(red: 1, green: 1, blue: 0)],
                [RGBPixel(red: 0, green: 0, blue: 1), RGBPixel(red: 1, green: 0, blue: 0), RGBPixel(red: 0, green: 1, blue: 0)]
            ],
            cellSize: 12
        )

        let sampler = FaceWarpSampler(cellInset: 0.2)
        let fullQuad = FaceQuadrilateral(
            topLeft: NormalizedPoint(x: 0, y: 0),
            topRight: NormalizedPoint(x: 1, y: 0),
            bottomRight: NormalizedPoint(x: 1, y: 1),
            bottomLeft: NormalizedPoint(x: 0, y: 1)
        )

        let center = sampler.sampleCell(frame: frame, quad: fullQuad, row: 1, column: 1)

        XCTAssertEqual(center.red, 1, accuracy: 0.02)
        XCTAssertEqual(center.green, 1, accuracy: 0.02)
        XCTAssertEqual(center.blue, 1, accuracy: 0.02)
    }

    func testDefaultFaceScannerWithStaticFrame() async throws {
        let frame = try makeSyntheticFrame(
            rows: [
                [RGBPixel(red: 0.95, green: 0.10, blue: 0.10), RGBPixel(red: 0.10, green: 0.65, blue: 0.20), RGBPixel(red: 0.10, green: 0.20, blue: 0.85)],
                [RGBPixel(red: 0.95, green: 0.45, blue: 0.12), RGBPixel(red: 0.96, green: 0.96, blue: 0.96), RGBPixel(red: 0.95, green: 0.85, blue: 0.15)],
                [RGBPixel(red: 0.10, green: 0.20, blue: 0.85), RGBPixel(red: 0.95, green: 0.10, blue: 0.10), RGBPixel(red: 0.10, green: 0.65, blue: 0.20)]
            ],
            cellSize: 18
        )

        let scanner = DefaultFaceScanner(
            frameSource: StaticFrameSource(frame: frame),
            quadDetector: FullQuadDetector(),
            warpSampler: FaceWarpSampler(cellInset: 0.15),
            classifier: HSVStickerClassifier(),
            maxScanAttempts: 1,
            minimumMeanConfidence: 0
        )

        let result = try await scanner.scanFace(for: .front)

        XCTAssertEqual(result.id, .front)
        XCTAssertEqual(result.grid[0], .red)
        XCTAssertEqual(result.grid[4], .white)
        XCTAssertEqual(result.grid[5], .yellow)
    }

    private func makeSyntheticFrame(rows: [[RGBPixel]], cellSize: Int) throws -> RGBFrame {
        let width = 3 * cellSize
        let height = 3 * cellSize
        var pixels = Array(repeating: RGBPixel.black, count: width * height)

        for row in 0..<3 {
            for column in 0..<3 {
                let color = rows[row][column]
                let startY = row * cellSize
                let endY = startY + cellSize
                let startX = column * cellSize
                let endX = startX + cellSize

                for y in startY..<endY {
                    for x in startX..<endX {
                        pixels[y * width + x] = color
                    }
                }
            }
        }

        return try RGBFrame(width: width, height: height, pixels: pixels)
    }

    private actor FullQuadDetector: FaceQuadDetecting {
        func detectQuadrilateral(in frame: RGBFrame) async throws -> FaceQuadrilateral? {
            _ = frame
            return FaceQuadrilateral(
                topLeft: NormalizedPoint(x: 0, y: 0),
                topRight: NormalizedPoint(x: 1, y: 0),
                bottomRight: NormalizedPoint(x: 1, y: 1),
                bottomLeft: NormalizedPoint(x: 0, y: 1)
            )
        }
    }
}
