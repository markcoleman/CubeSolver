#if canImport(SwiftUI)
//
//  AnimatedCube3DView.swift
//  CubeSolver
//
//  3D animated cube view for displaying move-by-move solutions
//

import SwiftUI
import CubeCore

#if canImport(SceneKit)
import SceneKit

/// A 3D animated cube view that can perform and visualize individual moves
public struct AnimatedCube3DView: View {
    let cube: RubiksCube
    @Binding var currentMove: Move?
    var onMoveComplete: (() -> Void)?
    
    @State private var isAnimating = false
    
    init(cube: RubiksCube, currentMove: Binding<Move?>, onMoveComplete: (() -> Void)? = nil) {
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

/// SceneKit view wrapper for animated cube
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

/// Coordinator for managing animations
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

/// Internal SceneKit view for rendering and animating the 3D cube
#if os(macOS)
struct AnimatedCube3DSceneView: NSViewRepresentable {
    let cube: RubiksCube
    @Binding var currentMove: Move?
    @Binding var isAnimating: Bool
    var onMoveComplete: (() -> Void)?
    
    func makeNSView(context: Context) -> SCNView {
        let scnView = createAnimatedSceneView()
        // Initialize colors on first creation
        if let scene = scnView.scene {
            updateCubeColors(in: scene, with: cube)
        }
        return scnView
    }
    
    func updateNSView(_ nsView: SCNView, context: Context) {
        var moveCopy = currentMove
        var animatingCopy = isAnimating
        updateCubeState(in: nsView, cube: cube, currentMove: &moveCopy, isAnimating: &animatingCopy, coordinator: context.coordinator)
        // write back any changes
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
        // Initialize colors on first creation
        if let scene = scnView.scene {
            updateCubeColors(in: scene, with: cube)
        }
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        var moveCopy = currentMove
        var animatingCopy = isAnimating
        updateCubeState(in: uiView, cube: cube, currentMove: &moveCopy, isAnimating: &animatingCopy, coordinator: context.coordinator)
        // write back any changes
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
    
    // Create the 3D cube structure
    let cubeNode = createAnimatedCubeNode()
    scene.rootNode.addChildNode(cubeNode)
    
    // Add camera
    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3(x: 5, y: 5, z: 8)
    cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))
    scene.rootNode.addChildNode(cameraNode)
    
    // Add ambient light
    let ambientLight = SCNNode()
    ambientLight.light = SCNLight()
    ambientLight.light!.type = .ambient
    ambientLight.light!.color = platformColor(white: 0.6, alpha: 1.0)
    scene.rootNode.addChildNode(ambientLight)
    
    // Add directional light
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
    
    // Create 3x3x3 grid of cubies
    let cubieSize: CGFloat = 1.0
    let spacing: CGFloat = 0.05
    let totalSize = cubieSize + spacing
    
    for x in 0..<3 {
        for y in 0..<3 {
            for z in 0..<3 {
                // Skip the center cubie
                if x == 1 && y == 1 && z == 1 {
                    continue
                }
                
                let cubie = createAnimatedCubie(size: cubieSize)
                cubie.position = canonicalCubiePosition(x: x, y: y, z: z, totalSize: totalSize)
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

@MainActor
private func updateCubeState(in sceneView: SCNView, cube: RubiksCube, currentMove: inout Move?, isAnimating: inout Bool, coordinator: AnimationCoordinator) {
    guard let scene = sceneView.scene else { return }
    
    // Local setter to avoid capturing inout in escaping closures
    var isAnimatingLocal = isAnimating
    func setIsAnimating(_ value: Bool) {
        isAnimatingLocal = value
    }
    var currentMoveLocal = currentMove
    func consumeCurrentMove() {
        currentMoveLocal = nil
    }
    
    // Update colors
    updateCubeColors(in: scene, with: cube)
    
    // Animate move if needed
    if let move = currentMoveLocal, !isAnimatingLocal {
        setIsAnimating(true)
        consumeCurrentMove()
        animateMove(in: scene, move: move, coordinator: coordinator) {
            setIsAnimating(false)
        }
    }
    
    // Avoid rebinding unchanged values to prevent update feedback loops.
    if currentMove != currentMoveLocal {
        currentMove = currentMoveLocal
    }
    if isAnimating != isAnimatingLocal {
        isAnimating = isAnimatingLocal
    }
}

private func updateCubeColors(in scene: SCNScene, with cube: RubiksCube) {
    guard let containerNode = scene.rootNode.childNode(withName: "cubeContainer", recursively: false) else {
        return
    }
    
    // Update all face colors (same as Cube3DView)
    // SCNBox material indices: 0=Front(+Z), 1=Right(+X), 2=Back(-Z), 3=Left(-X), 4=Top(+Y), 5=Bottom(-Y)
    updateFaceColors(containerNode, face: cube.front, x: nil, y: nil, z: 1, faceIndex: 0)
    updateFaceColors(containerNode, face: cube.back, x: nil, y: nil, z: -1, faceIndex: 2)
    updateFaceColors(containerNode, face: cube.left, x: -1, y: nil, z: nil, faceIndex: 3)
    updateFaceColors(containerNode, face: cube.right, x: 1, y: nil, z: nil, faceIndex: 1)
    updateFaceColors(containerNode, face: cube.top, x: nil, y: 1, z: nil, faceIndex: 4)
    updateFaceColors(containerNode, face: cube.bottom, x: nil, y: -1, z: nil, faceIndex: 5)
}

private func updateFaceColors(_ containerNode: SCNNode, face: CubeFace, x: Int?, y: Int?, z: Int?, faceIndex: Int) {
    for row in 0..<3 {
        for col in 0..<3 {
            let (cubeX, cubeY, cubeZ) = getFacePosition(x: x, y: y, z: z, row: row, col: col)
            
            if let cubieNode = containerNode.childNode(withName: "cubie_\(cubeX)_\(cubeY)_\(cubeZ)", recursively: false),
               let box = cubieNode.geometry as? SCNBox {
                let color = colorForFaceColor(face.colors[row][col])
                box.materials[faceIndex].diffuse.contents = color
            }
        }
    }
}

private func getFacePosition(x: Int?, y: Int?, z: Int?, row: Int, col: Int) -> (Int, Int, Int) {
    if let x = x {
        let yPos = 2 - row
        let zPos = x == -1 ? 2 - col : col
        return (x == -1 ? 0 : 2, yPos, zPos)
    } else if let y = y {
        let xPos = col
        let zPos = y == 1 ? row : 2 - row
        return (xPos, y == -1 ? 0 : 2, zPos)
    } else if let z = z {
        let xPos = z == -1 ? 2 - col : col
        let yPos = 2 - row
        return (xPos, yPos, z == -1 ? 0 : 2)
    }
    return (0, 0, 0)
}

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

// MARK: - Move Animation

private func animateMove(in scene: SCNScene, move: Move, coordinator: AnimationCoordinator, completion: @escaping () -> Void) {
    guard let containerNode = scene.rootNode.childNode(withName: "cubeContainer", recursively: false) else {
        return
    }
    
    // Determine which layer to rotate based on the move
    let (axis, angle) = getMoveAnimation(for: move)
    
    // Get cubies to rotate
    let cubiesToRotate = getCubiesForMove(containerNode, move: move)
    guard !cubiesToRotate.isEmpty else {
        completion()
        return
    }
    
    // Create a temporary parent node for the layer being rotated
    let layerNode = SCNNode()
    layerNode.name = "tempLayer"
    layerNode.position = SCNVector3Zero
    scene.rootNode.addChildNode(layerNode)

    // Reparent cubies to the layer node, preserving world position
    for cubie in cubiesToRotate {
        guard cubie.parent != nil else {
            // Skip cubies without a parent to avoid inconsistent state
            continue
        }

        let worldTransform = cubie.presentation.worldTransform
        cubie.removeFromParentNode()
        layerNode.addChildNode(cubie)
        cubie.transform = layerNode.convertTransform(worldTransform, from: nil)
    }

    // Create rotation animation for the entire layer
    let duration: TimeInterval = 0.5
    let rotation = SCNAction.rotate(by: angle, around: axis, duration: duration)
    rotation.timingMode = .easeInEaseOut

    // Rotate the layer node (which rotates all cubies as a group)
    layerNode.runAction(rotation) {
        // Reparent cubies back to container with updated transforms.
        for cubie in layerNode.childNodes {
            let worldTransform = cubie.presentation.worldTransform
            cubie.removeFromParentNode()
            containerNode.addChildNode(cubie)
            cubie.transform = containerNode.convertTransform(worldTransform, from: nil)
        }

        // Snap back to canonical grid/orientation so each move starts from an exact baseline.
        snapCubiesToCanonicalGrid(in: containerNode)

        layerNode.removeFromParentNode()
        coordinator.animationDidStop(CAAnimation(), finished: true)
        completion()
    }
}

private func getMoveAnimation(for move: Move) -> (SCNVector3, CGFloat) {
    let baseAngle: CGFloat = move.amount == .double ? .pi : (.pi / 2)
    let sign: CGFloat = move.amount == .counter ? -1 : 1

    switch move.turn {
    case .R:
        return (SCNVector3(1, 0, 0), sign * baseAngle)
    case .L:
        return (SCNVector3(1, 0, 0), -sign * baseAngle)
    case .U:
        return (SCNVector3(0, 1, 0), sign * baseAngle)
    case .D:
        return (SCNVector3(0, 1, 0), -sign * baseAngle)
    case .F:
        return (SCNVector3(0, 0, 1), sign * baseAngle)
    case .B:
        return (SCNVector3(0, 0, 1), -sign * baseAngle)
    }
}

private func getCubiesForMove(_ containerNode: SCNNode, move: Move) -> [SCNNode] {
    var cubies: [SCNNode] = []

    for x in 0..<3 {
        for y in 0..<3 {
            for z in 0..<3 {
                if x == 1 && y == 1 && z == 1 { continue }

                let shouldInclude: Bool
                switch move.turn {
                case .R:
                    shouldInclude = x == 2
                case .L:
                    shouldInclude = x == 0
                case .U:
                    shouldInclude = y == 2
                case .D:
                    shouldInclude = y == 0
                case .F:
                    shouldInclude = z == 2
                case .B:
                    shouldInclude = z == 0
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

private func snapCubiesToCanonicalGrid(in containerNode: SCNNode) {
    let totalSize: CGFloat = 1.0 + 0.05
    for cubie in containerNode.childNodes {
        guard let name = cubie.name,
              let coordinates = cubieCoordinates(from: name) else {
            continue
        }

        cubie.eulerAngles = SCNVector3Zero
        cubie.position = canonicalCubiePosition(
            x: coordinates.x,
            y: coordinates.y,
            z: coordinates.z,
            totalSize: totalSize
        )
    }
}

private func cubieCoordinates(from name: String) -> (x: Int, y: Int, z: Int)? {
    let parts = name.split(separator: "_")
    guard parts.count == 4,
          let x = Int(parts[1]),
          let y = Int(parts[2]),
          let z = Int(parts[3]) else {
        return nil
    }
    return (x, y, z)
}

private func canonicalCubiePosition(x: Int, y: Int, z: Int, totalSize: CGFloat) -> SCNVector3 {
    let xPos = CGFloat(x - 1) * totalSize
    let yPos = CGFloat(y - 1) * totalSize
    let zPos = CGFloat(z - 1) * totalSize

#if os(macOS)
    return SCNVector3(x: xPos, y: yPos, z: zPos)
#else
    return SCNVector3(x: Float(xPos), y: Float(yPos), z: Float(zPos))
#endif
}

// MARK: - Platform Compatibility

#if os(macOS)
private typealias platformColor = NSColor
#else
private typealias platformColor = UIColor
#endif

struct AnimatedCube3DView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State var move: Move? = nil
        var body: some View {
            AnimatedCube3DView(
                cube: RubiksCube(),
                currentMove: $move
            )
            .frame(width: 400, height: 400)
            .adaptiveBackground()
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}

#endif // canImport(SceneKit)
#endif // canImport(SwiftUI)
