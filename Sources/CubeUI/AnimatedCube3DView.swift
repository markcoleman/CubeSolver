// AnimatedCube3DView.swift
// 3D animated cube view for displaying move-by-move solutions.

#if canImport(SwiftUI)
import SwiftUI
import CubeCore

#if canImport(SceneKit)
import SceneKit

/// A 3D animated cube view that can perform and visualize individual moves.
public struct AnimatedCube3DView: View {
    let cube: RubiksCube
    @Binding var currentMove: Move?
    var onMoveComplete: (() -> Void)?
    
    @State private var isAnimating = false
    
    public init(cube: RubiksCube, currentMove: Binding<Move?>, onMoveComplete: (() -> Void)? = nil) {
        self.cube = cube
        self._currentMove = currentMove
        self.onMoveComplete = onMoveComplete
    }
    
    public var body: some View {
        GeometryReader { geometry in
            AnimatedSceneKitView(
                cube: cube,
                currentMove: $currentMove,
                isAnimating: $isAnimating,
                onMoveComplete: onMoveComplete,
                size: min(geometry.size.width, geometry.size.height)
            )
        }
    }
}

/// SceneKit view wrapper for the animated cube.
struct AnimatedSceneKitView: View {
    let cube: RubiksCube
    @Binding var currentMove: Move?
    @Binding var isAnimating: Bool
    var onMoveComplete: (() -> Void)?
    let size: CGFloat
    
    #if os(macOS)
    var body: some View {
        AnimatedCube3DSceneView(
            cube: cube,
            currentMove: $currentMove,
            isAnimating: $isAnimating,
            onMoveComplete: onMoveComplete
        )
        .frame(width: size, height: size)
    }
    #else
    var body: some View {
        AnimatedCube3DSceneView(
            cube: cube,
            currentMove: $currentMove,
            isAnimating: $isAnimating,
            onMoveComplete: onMoveComplete
        )
        .frame(width: size, height: size)
    }
    #endif
}

/// Coordinator for managing SceneKit animations.
class AnimationCoordinator {
    var onMoveComplete: (() -> Void)?
    
    init(onMoveComplete: (() -> Void)? = nil) {
        self.onMoveComplete = onMoveComplete
    }
    
    @objc func animationDidStop(_ animation: CAAnimation, finished: Bool) {
        if finished {
            onMoveComplete?()
        }
    }
}

// MARK: - SceneKit Representable

#if os(macOS)
struct AnimatedCube3DSceneView: NSViewRepresentable {
    let cube: RubiksCube
    @Binding var currentMove: Move?
    @Binding var isAnimating: Bool
    var onMoveComplete: (() -> Void)?
    
    func makeNSView(context: Context) -> SCNView {
        let scnView = createAnimatedSceneView()
        if let scene = scnView.scene {
            updateCubeColors(in: scene, with: cube)
        }
        return scnView
    }
    
    func updateNSView(_ nsView: SCNView, context: Context) {
        var moveCopy = currentMove
        var animatingCopy = isAnimating
        updateCubeState(in: nsView, cube: cube, currentMove: &moveCopy, isAnimating: &animatingCopy, coordinator: context.coordinator)
        currentMove = moveCopy
        isAnimating = animatingCopy
    }
    
    func makeCoordinator() -> AnimationCoordinator {
        AnimationCoordinator(onMoveComplete: onMoveComplete)
    }
    
    private func createAnimatedSceneView() -> SCNView {
        let scnView = SCNView()
        scnView.scene = createAnimatedScene()
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = true
        scnView.backgroundColor = .clear
        return scnView
    }
}
#else
struct AnimatedCube3DSceneView: UIViewRepresentable {
    let cube: RubiksCube
    @Binding var currentMove: Move?
    @Binding var isAnimating: Bool
    var onMoveComplete: (() -> Void)?
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = createAnimatedSceneView()
        if let scene = scnView.scene {
            updateCubeColors(in: scene, with: cube)
        }
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        var moveCopy = currentMove
        var animatingCopy = isAnimating
        updateCubeState(in: uiView, cube: cube, currentMove: &moveCopy, isAnimating: &animatingCopy, coordinator: context.coordinator)
        currentMove = moveCopy
        isAnimating = animatingCopy
    }
    
    func makeCoordinator() -> AnimationCoordinator {
        AnimationCoordinator(onMoveComplete: onMoveComplete)
    }
    
    private func createAnimatedSceneView() -> SCNView {
        let scnView = SCNView()
        scnView.scene = createAnimatedScene()
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = true
        scnView.backgroundColor = .clear
        return scnView
    }
}
#endif

// MARK: - Scene Setup

private func createAnimatedScene() -> SCNScene {
    let scene = SCNScene()
    
    let cubeNode = createAnimatedCubeNode()
    scene.rootNode.addChildNode(cubeNode)
    
    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3(x: 5, y: 5, z: 8)
    cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))
    scene.rootNode.addChildNode(cameraNode)
    
    let ambientLight = SCNNode()
    ambientLight.light = SCNLight()
    ambientLight.light!.type = .ambient
    ambientLight.light!.color = platformColor(white: 0.6, alpha: 1.0)
    scene.rootNode.addChildNode(ambientLight)
    
    let directionalLight = SCNNode()
    directionalLight.light = SCNLight()
    directionalLight.light!.type = .directional
    directionalLight.light!.color = platformColor(white: 0.8, alpha: 1.0)
    directionalLight.position = SCNVector3(x: 5, y: 10, z: 5)
    directionalLight.look(at: SCNVector3(x: 0, y: 0, z: 0))
    scene.rootNode.addChildNode(directionalLight)
    
    return scene
}

private func createAnimatedCubeNode() -> SCNNode {
    let containerNode = SCNNode()
    containerNode.name = "cubeContainer"
    
    let cubieSize: CGFloat = 1.0
    let spacing: CGFloat = 0.05
    let totalSize = cubieSize + spacing
    
    for x in 0..<3 {
        for y in 0..<3 {
            for z in 0..<3 {
                if x == 1 && y == 1 && z == 1 { continue }
                
                let cubie = createAnimatedCubie(size: cubieSize)
                let xPos = CGFloat(x - 1) * totalSize
                let yPos = CGFloat(y - 1) * totalSize
                let zPos = CGFloat(z - 1) * totalSize
#if os(macOS)
                cubie.position = SCNVector3(x: xPos, y: yPos, z: zPos)
#else
                cubie.position = SCNVector3(x: Float(xPos), y: Float(yPos), z: Float(zPos))
#endif
                cubie.name = "cubie_\(x)_\(y)_\(z)"
                containerNode.addChildNode(cubie)
            }
        }
    }
    
    return containerNode
}

private func createAnimatedCubie(size: CGFloat) -> SCNNode {
    let cubie = SCNNode()
    let box = SCNBox(width: size, height: size, length: size, chamferRadius: 0.05)
    
    let materials = (0..<6).map { _ -> SCNMaterial in
        let material = SCNMaterial()
        material.diffuse.contents = platformColor.black
        material.specular.contents = platformColor(white: 0.6, alpha: 1.0)
        material.shininess = 0.5
        return material
    }
    box.materials = materials
    
    cubie.geometry = box
    return cubie
}

// MARK: - Update and Animation

private func updateCubeState(in sceneView: SCNView, cube: RubiksCube, currentMove: inout Move?, isAnimating: inout Bool, coordinator: AnimationCoordinator) {
    guard let scene = sceneView.scene else { return }
    
    var isAnimatingLocal = isAnimating
    func setIsAnimating(_ value: Bool) { isAnimatingLocal = value }
    var currentMoveLocal = currentMove
    func clearCurrentMove() { currentMoveLocal = nil }
    
    updateCubeColors(in: scene, with: cube)
    
    if let move = currentMoveLocal, !isAnimatingLocal {
        setIsAnimating(true)
        animateMove(in: scene, move: move, coordinator: coordinator) {
            setIsAnimating(false)
            clearCurrentMove()
        }
    }
    
    currentMove = currentMoveLocal
    isAnimating = isAnimatingLocal
}

private func updateCubeColors(in scene: SCNScene, with cube: RubiksCube) {
    guard let containerNode = scene.rootNode.childNode(withName: "cubeContainer", recursively: false) else {
        return
    }
    
    // SCNBox materials: [0]=Right(+X), [1]=Left(-X), [2]=Top(+Y), [3]=Bottom(-Y), [4]=Front(+Z), [5]=Back(-Z)
    
    for x in 0..<3 {
        for y in 0..<3 {
            for z in 0..<3 {
                if x == 1 && y == 1 && z == 1 { continue }
                
                guard let cubieNode = containerNode.childNode(withName: "cubie_\(x)_\(y)_\(z)", recursively: false),
                      let box = cubieNode.geometry as? SCNBox else {
                    continue
                }
                
                // LEFT face (x=0): materials[1]
                if x == 0 {
                    let row = 2 - y
                    let col = 2 - z
                    box.materials[1].diffuse.contents = colorForFaceColor(cube.left.colors[row][col])
                }
                
                // RIGHT face (x=2): materials[0]
                if x == 2 {
                    let row = 2 - y
                    let col = z
                    box.materials[0].diffuse.contents = colorForFaceColor(cube.right.colors[row][col])
                }
                
                // TOP face (y=2): materials[2]
                if y == 2 {
                    let row = z
                    let col = x
                    box.materials[2].diffuse.contents = colorForFaceColor(cube.top.colors[row][col])
                }
                
                // BOTTOM face (y=0): materials[3]
                if y == 0 {
                    let row = 2 - z
                    let col = x
                    box.materials[3].diffuse.contents = colorForFaceColor(cube.bottom.colors[row][col])
                }
                
                // FRONT face (z=2): materials[4]
                if z == 2 {
                    let row = 2 - y
                    let col = x
                    box.materials[4].diffuse.contents = colorForFaceColor(cube.front.colors[row][col])
                }
                
                // BACK face (z=0): materials[5]
                if z == 0 {
                    let row = 2 - y
                    let col = 2 - x
                    box.materials[5].diffuse.contents = colorForFaceColor(cube.back.colors[row][col])
                }
            }
        }
    }
}

private func animateMove(in scene: SCNScene, move: Move, coordinator: AnimationCoordinator, completion: @escaping () -> Void) {
    guard let containerNode = scene.rootNode.childNode(withName: "cubeContainer", recursively: false) else {
        completion()
        return
    }
    
    let (axis, _, angle) = getMoveAnimation(for: move)
    let cubiesToRotate = getCubiesForMove(containerNode, move: move)
    let duration: TimeInterval = 0.5
    
    SCNTransaction.begin()
    SCNTransaction.animationDuration = duration
    SCNTransaction.completionBlock = {
        coordinator.animationDidStop(CAAnimation(), finished: true)
        completion()
    }
    
    for cubie in cubiesToRotate {
        let rotation = SCNAction.rotate(by: CGFloat(angle), around: axis, duration: duration)
        cubie.runAction(rotation)
    }
    
    SCNTransaction.commit()
}

private func getMoveAnimation(for move: Move) -> (SCNVector3, CGFloat, CGFloat) {
    let text = String(describing: move).uppercased()
    let faceChar: Character? = ["R","L","U","D","F","B"].first { text.contains(String($0)) }
    let isDouble = text.contains("2")
    let baseAngle: CGFloat = isDouble ? .pi : (.pi / 2)
    let isPrime = text.contains("'") || text.contains("CCW") || text.contains("COUNTER") || text.contains("PRIME")
    let sign: CGFloat = isPrime ? -1 : 1
    
    switch faceChar {
    case "R":
        return (SCNVector3(1, 0, 0), sign, sign * baseAngle)
    case "L":
        return (SCNVector3(1, 0, 0), -sign, -sign * baseAngle)
    case "U":
        return (SCNVector3(0, 1, 0), sign, sign * baseAngle)
    case "D":
        return (SCNVector3(0, 1, 0), -sign, -sign * baseAngle)
    case "F":
        return (SCNVector3(0, 0, 1), sign, sign * baseAngle)
    case "B":
        return (SCNVector3(0, 0, 1), -sign, -sign * baseAngle)
    default:
        return (SCNVector3(0, 0, 1), 1, .pi / 2)
    }
}

private func getCubiesForMove(_ containerNode: SCNNode, move: Move) -> [SCNNode] {
    var cubies: [SCNNode] = []
    
    let text = String(describing: move).uppercased()
    let faceChar: Character? = ["R","L","U","D","F","B"].first { text.contains(String($0)) }
    
    for x in 0..<3 {
        for y in 0..<3 {
            for z in 0..<3 {
                if x == 1 && y == 1 && z == 1 { continue }
                
                let shouldInclude: Bool
                switch faceChar {
                case "R":
                    shouldInclude = x == 2
                case "L":
                    shouldInclude = x == 0
                case "U":
                    shouldInclude = y == 2
                case "D":
                    shouldInclude = y == 0
                case "F":
                    shouldInclude = z == 2
                case "B":
                    shouldInclude = z == 0
                default:
                    shouldInclude = false
                }
                
                if shouldInclude,
                   let cubie = containerNode.childNode(withName: "cubie_\(x)_\(y)_\(z)", recursively: false) {
                    cubies.append(cubie)
                }
            }
        }
    }
    
    return cubies
}

// MARK: - Shared Helpers

private func colorForFaceColor(_ faceColor: FaceColor) -> Any {
    switch faceColor {
    case .white:
        return platformColor.white
    case .yellow:
        return platformColor.yellow
    case .red:
        return platformColor.red
    case .orange:
        return platformColor.orange
    case .blue:
        return platformColor.blue
    case .green:
        return platformColor.green
    }
}

#if os(macOS)
private typealias platformColor = NSColor
#else
private typealias platformColor = UIColor
#endif

#endif // canImport(SceneKit)
#endif // canImport(SwiftUI)
