import Foundation
import CubeCore

public struct FaceWarpSampler: Sendable {
    /// Samples each sticker using this inset factor to avoid edge glare.
    public var cellInset: Double

    public init(cellInset: Double = 0.18) {
        self.cellInset = max(0, min(0.4, cellInset))
    }

    public func sample(
        frame: RGBFrame,
        quad: FaceQuadrilateral,
        classifier: StickerColorClassifying
    ) throws -> FaceSamplingResult {
        var colors: [CubeColor] = []
        var confidences: [Float] = []

        colors.reserveCapacity(9)
        confidences.reserveCapacity(9)

        for row in 0..<3 {
            for column in 0..<3 {
                let representative = sampleCell(
                    frame: frame,
                    quad: quad,
                    row: row,
                    column: column
                )

                let classified = classifier.classify(pixel: representative)
                colors.append(classified.color)
                confidences.append(classified.confidence)
            }
        }

        let face = try CubeFaceGrid(stickers: colors)
        let averageConfidence = confidences.reduce(0, +) / Float(max(1, confidences.count))

        return FaceSamplingResult(
            face: face,
            stickerConfidences: confidences,
            meanConfidence: averageConfidence,
            quadrilateral: quad
        )
    }

    public func sampleCell(
        frame: RGBFrame,
        quad: FaceQuadrilateral,
        row: Int,
        column: Int
    ) -> RGBPixel {
        let gridOriginU = Double(column) / 3
        let gridOriginV = Double(row) / 3
        let sampleRange = [cellInset, 0.5, 1 - cellInset]

        var samples: [RGBPixel] = []
        samples.reserveCapacity(sampleRange.count * sampleRange.count)

        for sampleV in sampleRange {
            for sampleU in sampleRange {
                let u = gridOriginU + sampleU / 3
                let v = gridOriginV + sampleV / 3
                let point = quad.point(u: u, v: v)
                let x = Int((point.x * Double(frame.width - 1)).rounded())
                let y = Int((point.y * Double(frame.height - 1)).rounded())
                samples.append(frame.pixel(x: x, y: y))
            }
        }

        return average(samples)
    }

    public func average(_ pixels: [RGBPixel]) -> RGBPixel {
        guard !pixels.isEmpty else { return .black }

        let sum = pixels.reduce((red: Float(0), green: Float(0), blue: Float(0))) { partial, pixel in
            (
                red: partial.red + pixel.red,
                green: partial.green + pixel.green,
                blue: partial.blue + pixel.blue
            )
        }

        let count = Float(pixels.count)
        return RGBPixel(red: sum.red / count, green: sum.green / count, blue: sum.blue / count)
    }
}
