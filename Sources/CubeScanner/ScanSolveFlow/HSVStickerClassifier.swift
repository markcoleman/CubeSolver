import Foundation
import CubeCore

public struct StickerClassifierCalibration: Sendable {
    public var hueOffsets: [CubeColor: Double]
    public var saturationScale: Double
    public var valueScale: Double
    public var whiteSaturationThreshold: Double
    public var whiteMinimumValue: Double

    public init(
        hueOffsets: [CubeColor: Double] = [:],
        saturationScale: Double = 1,
        valueScale: Double = 1,
        whiteSaturationThreshold: Double = 0.20,
        whiteMinimumValue: Double = 0.45
    ) {
        self.hueOffsets = hueOffsets
        self.saturationScale = saturationScale
        self.valueScale = valueScale
        self.whiteSaturationThreshold = whiteSaturationThreshold
        self.whiteMinimumValue = whiteMinimumValue
    }
}

public struct HSVStickerClassifier: StickerColorClassifying, Sendable {
    public struct Profile: Sendable {
        public let hueCenter: Double
        public let saturation: Double
        public let value: Double

        public init(hueCenter: Double, saturation: Double, value: Double) {
            self.hueCenter = hueCenter
            self.saturation = saturation
            self.value = value
        }
    }

    public var calibration: StickerClassifierCalibration

    private let profiles: [CubeColor: Profile] = [
        .red: Profile(hueCenter: 0, saturation: 0.85, value: 0.78),
        .orange: Profile(hueCenter: 28, saturation: 0.82, value: 0.85),
        .yellow: Profile(hueCenter: 58, saturation: 0.75, value: 0.92),
        .green: Profile(hueCenter: 120, saturation: 0.75, value: 0.62),
        .blue: Profile(hueCenter: 220, saturation: 0.76, value: 0.70)
    ]

    public init(calibration: StickerClassifierCalibration = .init()) {
        self.calibration = calibration
    }

    public func classify(pixel: RGBPixel) -> StickerClassification {
        let hsvRaw = rgbToHSV(pixel)
        let hsv = (
            hue: hsvRaw.hue,
            saturation: max(0, min(1, hsvRaw.saturation * calibration.saturationScale)),
            value: max(0, min(1, hsvRaw.value * calibration.valueScale))
        )

        if hsv.saturation <= calibration.whiteSaturationThreshold,
           hsv.value >= calibration.whiteMinimumValue {
            let saturationScore = 1 - (hsv.saturation / max(calibration.whiteSaturationThreshold, 0.0001))
            let valueScore = min(1, hsv.value)
            let confidence = Float(max(0.3, (saturationScore * 0.65) + (valueScore * 0.35)))
            return StickerClassification(color: .white, confidence: confidence)
        }

        var bestColor: CubeColor = .white
        var bestScore = -Double.infinity

        for (color, profile) in profiles {
            let shiftedCenter = wrappedHue(profile.hueCenter + calibration.hueOffsets[color, default: 0])
            let hueDistance = circularHueDistance(hsv.hue, shiftedCenter) / 180
            let satDistance = abs(hsv.saturation - profile.saturation)
            let valueDistance = abs(hsv.value - profile.value)

            let score = 1.0 - ((hueDistance * 0.65) + (satDistance * 0.2) + (valueDistance * 0.15))
            if score > bestScore {
                bestScore = score
                bestColor = color
            }
        }

        let confidence = Float(max(0.1, min(1, bestScore)))
        return StickerClassification(color: bestColor, confidence: confidence)
    }

    private func rgbToHSV(_ pixel: RGBPixel) -> (hue: Double, saturation: Double, value: Double) {
        let red = Double(pixel.red)
        let green = Double(pixel.green)
        let blue = Double(pixel.blue)

        let maxComponent = max(red, max(green, blue))
        let minComponent = min(red, min(green, blue))
        let delta = maxComponent - minComponent

        var hue = 0.0
        if delta != 0 {
            if maxComponent == red {
                hue = 60 * (((green - blue) / delta).truncatingRemainder(dividingBy: 6))
            } else if maxComponent == green {
                hue = 60 * (((blue - red) / delta) + 2)
            } else {
                hue = 60 * (((red - green) / delta) + 4)
            }
        }

        if hue < 0 {
            hue += 360
        }

        let saturation = maxComponent == 0 ? 0 : delta / maxComponent
        return (hue: hue, saturation: saturation, value: maxComponent)
    }

    private func circularHueDistance(_ a: Double, _ b: Double) -> Double {
        let delta = abs(a - b)
        return min(delta, 360 - delta)
    }

    private func wrappedHue(_ hue: Double) -> Double {
        var value = hue.truncatingRemainder(dividingBy: 360)
        if value < 0 { value += 360 }
        return value
    }
}
