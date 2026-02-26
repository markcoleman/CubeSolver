#if canImport(SwiftUI)

import Foundation
import SwiftUI
import CubeCore

@MainActor
public final class SolveModeRendererBridge: ObservableObject, CubeRenderer {
    @Published public private(set) var state: CubeState
    @Published public private(set) var highlightedMove: Move?
    @Published public var activeAnimationMove: Move?

    public init(initialState: CubeState) {
        self.state = initialState
    }

    public func setState(_ state: CubeState) {
        self.state = state
    }

    public func highlight(move: Move) {
        highlightedMove = move
        activeAnimationMove = move
    }

    public func clearHighlight() {
        highlightedMove = nil
        activeAnimationMove = nil
    }
}

#endif
