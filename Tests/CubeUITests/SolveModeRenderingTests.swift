#if canImport(SwiftUI)

import SwiftUI
import XCTest
@testable import CubeCore
@testable import CubeUI

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class SolveModeRenderingTests: XCTestCase {
    func testSolveModeViewRendersCurrentMoveAndProgress() {
        let view = SolveModeView(
            state: CubeState(),
            solution: [
                Move(turn: .R, amount: .clockwise),
                Move(turn: .U, amount: .counter),
                Move(turn: .F, amount: .double)
            ]
        )
        .frame(width: 390, height: 820)

        let imageData = pngData(for: view)

        XCTAssertNotNil(imageData)
        XCTAssertGreaterThan(imageData?.count ?? 0, 5_000)
    }

    func testCubeRenderer2DHighlightProducesDifferentSnapshot() {
        let state = CubeState()
        let plain = CubeRenderer2DView(state: state, highlightedMove: nil)
            .frame(width: 360, height: 260)

        let highlighted = CubeRenderer2DView(
            state: state,
            highlightedMove: Move(turn: .R, amount: .clockwise)
        )
        .frame(width: 360, height: 260)

        let plainData = pngData(for: plain)
        let highlightedData = pngData(for: highlighted)

        XCTAssertNotNil(plainData)
        XCTAssertNotNil(highlightedData)
        XCTAssertNotEqual(plainData, highlightedData)
    }

    private func pngData<V: View>(for view: V) -> Data? {
        let renderer = ImageRenderer(content: view)

        #if canImport(UIKit)
        return renderer.uiImage?.pngData()
        #elseif canImport(AppKit)
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
        #else
        return nil
        #endif
    }
}

#endif
