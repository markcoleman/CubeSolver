import Foundation
import CubeCore

@MainActor
public protocol CubeRenderer: AnyObject {
    func setState(_ state: CubeState)
    func highlight(move: Move)
    func clearHighlight()
}

@MainActor
public protocol CubeMoveAnimator {
    func animate(move: Move, on renderer: CubeRenderer, completion: @escaping @Sendable () -> Void)
}

public protocol ConfigurableCubeMoveAnimator: CubeMoveAnimator, AnyObject {
    var speedMultiplier: Double { get set }
}

@MainActor
public final class TimedCubeMoveAnimator: ConfigurableCubeMoveAnimator {
    public var speedMultiplier: Double = 1.0

    private let baseDuration: TimeInterval
    private let queue: DispatchQueue

    public init(baseDuration: TimeInterval = 0.55, queue: DispatchQueue = .main) {
        self.baseDuration = max(0.05, baseDuration)
        self.queue = queue
    }

    public func animate(move: Move, on renderer: CubeRenderer, completion: @escaping @Sendable () -> Void) {
        renderer.highlight(move: move)

        let multiplier = max(0.1, speedMultiplier)
        let delay = baseDuration / multiplier

        queue.asyncAfter(deadline: .now() + delay) {
            Task { @MainActor in
                completion()
            }
        }
    }
}
