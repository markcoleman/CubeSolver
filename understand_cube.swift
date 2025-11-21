#if canImport(SwiftUI)
//
//  Cube3DView.swift
//  CubeSolver
//
//  3D visualization of Rubik's Cube using SceneKit
//

import SwiftUI
import CubeCore

#if canImport(SceneKit)
import SceneKit

// SceneKit scalar conversion helper (Float on iOS, CGFloat on macOS)
private func scnScalar(_ value: CGFloat) -> SCNFloat { SCNFloat(value) }

/// A 3D interactive view of a Rubik's Cube with rotation animations
public struct Cube3DView: View {
    let cube: RubiksCube
    var autoRotate: Bool = true
    var allowInteraction: Bool = true
    
    public init(cube: RubiksCube, autoRotate: Bool = true, allowInteraction: Bool = true) {
        self.cube = cube
        self.autoRotate = autoRotate
        self.allowInteraction = allowInteraction
    }
    
    public var body: some View {
        GeometryReader { geometry in
            SceneKitView(
                cube: cube,
                autoRotate: autoRotate,
                allowInteraction: allowInteraction,
                size: min(geometry.size.width, geometry.size.height)
            )
        }
    }
}

/// SceneKit view wrapper for displaying the 3D cube
struct SceneKitView: View {
    let cube: RubiksCube
    let autoRotate: Bool
    let allowInteraction: Bool
    let size: CGFloat
    
    #if os(macOS)
    var body: some View {
        Cube3DSceneView(cube: cube, autoRotate: autoRotate, allowInteraction: allowInteraction)
            .frame(width: size, height: size)
    }
    #else
    var body: some View {
        Cube3DSceneView(cube: cube, autoRotate: autoRotate, allowInteraction: allowInteraction)
            .frame(width: size, height: size)
    }
    #endif
}

/// Internal SceneKit view for rendering the 3D cube
#if os(macOS)
struct Cube3DSceneView: NSViewRepresentable {
    let cube: RubiksCube
    let autoRotate: Bool
    let allowInteraction: Bool
    
    func makeNSView(context: Context) -> SCNView {
        let scnView = createSceneView()
        // Initialize colors on first creation
        updateCubeColors(in: scnView.scene!, with: cube)
        return scnView
    }
    
    func updateNSView(_ nsView: SCNView, context: Context) {
        updateCubeColors(in: nsView.scene!, with: cube)
    }
    
    private func createSceneView() -> SCNView {
        let scnView = SCNView()
        scnView.scene = createScene()
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = allowInteraction
        scnView.backgroundColor = .clear
        
        if autoRotate {
            startAutoRotation(for: scnView)
        }
        
        return scnView
    }
}
#else
struct Cube3DSceneView: UIViewRepresentable {
    let cube: RubiksCube
    let autoRotate: Bool
    let allowInteraction: Bool
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = createSceneView()
        // Initialize colors on first creation
        updateCubeColors(in: scnView.scene!, with: cube)
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        updateCubeColors(in: uiView.scene!, with: cube)
    }
    
    private func createSceneView() -> SCNView {
        let scnView = SCNView()
        scnView.scene = createScene()
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = allowInteraction
        scnView.backgroundColor = .clear
        
        if autoRotate {
            startAutoRotation(for: scnView)
        }
        
        return scnView
    }
}
#endif

// MARK: - Scene Creation

private func createScene() -> SCNScene {
    let scene = SCNScene()
    
    // Create the 3D cube structure
    let cubeNode = createCubeNode()
    scene.rootNode.addChildNode(cubeNode)
    
    // Add camera
    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3(x: scnScalar(5), y: scnScalar(5), z: scnScalar(8))
    cameraNode.look(at: SCNVector3(x: scnScalar(0), y: scnScalar(0), z: scnScalar(0)))
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
    directionalLight.position = SCNVector3(x: scnScalar(5), y: scnScalar(10), z: scnScalar(5))
    directionalLight.look(at: SCNVector3(x: scnScalar(0), y: scnScalar(0), z: scnScalar(0)))
    scene.rootNode.addChildNode(directionalLight)
    
    return scene
}

private func createCubeNode() -> SCNNode {
    let containerNode = SCNNode()
    containerNode.name = "cubeContainer"
    
    // Create 3x3x3 grid of cubies (small cubes)
    let cubieSize: CGFloat = 1.0
    let spacing: CGFloat = 0.05
    let totalSize = cubieSize + spacing
    
    for x in 0..<3 {
        for y in 0..<3 {
            for z in 0..<3 {
                // Skip the center cubie (not visible in a real Rubik's cube)
                if x == 1 && y == 1 && z == 1 {
                    continue
                }
                
                let cubie = createCubie(size: cubieSize)
                let xPos = CGFloat(x - 1) * totalSize
                let yPos = CGFloat(y - 1) * totalSize
                let zPos = CGFloat(z - 1) * totalSize
                cubie.position = SCNVector3(x: scnScalar(xPos), y: scnScalar(yPos), z: scnScalar(zPos))
                cubie.name = "cubie_\(x)_\(y)_\(z)"
                
                containerNode.addChildNode(cubie)
            }
        }
    }
    
    return containerNode
}

private func createCubie(size: CGFloat) -> SCNNode {
    let cubie = SCNNode()
    let box = SCNBox(width: size, height: size, length: size, chamferRadius: 0.05)
    
    // Create materials for each face
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

private func updateCubeColors(in scene: SCNScene, with cube: RubiksCube) {
    guard let containerNode = scene.rootNode.childNode(withName: "cubeContainer", recursively: false) else {
        return
    }
    
    // SIMPLE DIRECT APPROACH: Paint each cubie based on its 3D position
    // SCNBox materials: [0]=Right(+X), [1]=Left(-X), [2]=Top(+Y), [3]=Bottom(-Y), [4]=Front(+Z), [5]=Back(-Z)
    
    for x in 0..<3 {
        for y in 0..<3 {
            for z in 0..<3 {
                // Skip center cubie
                if x == 1 && y == 1 && z == 1 { continue }
                
                guard let cubieNode = containerNode.childNode(withName: "cubie_\(x)_\(y)_\(z)", recursively: false),
                      let box = cubieNode.geometry as? SCNBox else {
                    continue
                }
                
                // Paint each visible face of this cubie
                
                // LEFT face (x=0): materials[1]
                if x == 0 {
                    let row = 2 - y  // y=2→row 0 (top), y=0→row 2 (bottom)
                    let col = 2 - z  // z=2→col 2 (front/right side of left face), z=0→col 0 (back/left side)
                    box.materials[1].diffuse.contents = colorForFaceColor(cube.left.colors[row][col])
                }
                
                // RIGHT face (x=2): materials[0]
                if x == 2 {
                    let row = 2 - y  // y=2→row 0 (top), y=0→row 2 (bottom)
                    let col = z      // z=0→col 0 (back/left side of right face), z=2→col 2 (front/right side)
                    box.materials[0].diffuse.contents = colorForFaceColor(cube.right.colors[row][col])
                }
                
                // TOP face (y=2): materials[2]
                if y == 2 {
                    let row = z      // z=0→row 0 (back), z=2→row 2 (front)
                    let col = x      // x=0→col 0 (left), x=2→col 2 (right)
                    box.materials[2].diffuse.contents = colorForFaceColor(cube.top.colors[row][col])
                }
                
                // BOTTOM face (y=0): materials[3]
                if y == 0 {
                    let row = 2 - z  // z=2→row 0 (front when looking up), z=0→row 2 (back)
                    let col = x      // x=0→col 0 (left), x=2→col 2 (right)
                    box.materials[3].diffuse.contents = colorForFaceColor(cube.bottom.colors[row][col])
                }
                
                // FRONT face (z=2): materials[4]
                if z == 2 {
                    let row = 2 - y  // y=2→row 0 (top), y=0→row 2 (bottom)
                    let col = x      // x=0→col 0 (left), x=2→col 2 (right)
                    box.materials[4].diffuse.contents = colorForFaceColor(cube.front.colors[row][col])
                }
                
                // BACK face (z=0): materials[5]
                if z == 0 {
                    let row = 2 - y  // y=2→row 0 (top), y=0→row 2 (bottom)
                    let col = 2 - x  // x=2→col 0 (left when viewing from back), x=0→col 2 (right)
                    box.materials[5].diffuse.contents = colorForFaceColor(cube.back.colors[row][col])
                }
            }
        }
    }
}

private func getCubiePosition(axis: Axis, layer: Int, row: Int, col: Int) -> (Int, Int, Int) {
    // row 0 is top of face, row 2 is bottom
    // col 0 is left of face, col 2 is right
    
    switch axis {
    case .x: // Left or Right face
        // When looking at left (x=0) or right (x=2) face from outside:
        // row maps to y (inverted: row 0 = y 2)
        // col maps to z (left face inverted: col 0 = z 2 for x=0, col 0 = z 0 for x=2)
        let yPos = 2 - row
        let zPos = layer == 0 ? (2 - col) : col
        return (layer, yPos, zPos)
        
    case .y: // Top or Bottom face
        // When looking at top (y=2) from above or bottom (y=0) from below:
        // row maps to z (top: row 0 = z 0, bottom: row 0 = z 2)
        // col maps to x (col 0 = x 0)
        let xPos = col
        let zPos = layer == 2 ? row : (2 - row)
        return (xPos, layer, zPos)
        
    case .z: // Front or Back face
        // When looking at front (z=2) or back (z=0) from outside:
        // row maps to y (inverted: row 0 = y 2)
        // col maps to x (back face inverted: col 0 = x 2 for z=0, col 0 = x 0 for z=2)
        let yPos = 2 - row
        let xPos = layer == 0 ? (2 - col) : col
        return (xPos, yPos, layer)
    }
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

private func startAutoRotation(for sceneView: SCNView) {
    guard let cubeContainer = sceneView.scene?.rootNode.childNode(withName: "cubeContainer", recursively: false) else {
        return
    }
    
    // Create rotation animation
    let rotation = CABasicAnimation(keyPath: "rotation")
    rotation.toValue = NSValue(scnVector4: SCNVector4(x: scnScalar(0), y: scnScalar(1), z: scnScalar(0), w: scnScalar(CGFloat.pi * 2)))
    rotation.duration = 10.0
    rotation.repeatCount = .infinity
    cubeContainer.addAnimation(rotation, forKey: "rotation")
}

// MARK: - Platform Compatibility

#if os(macOS)
private typealias platformColor = NSColor
#else
private typealias platformColor = UIColor
#endif

#Preview {
    Cube3DView(cube: RubiksCube())
        .frame(width: 400, height: 400)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.2, green: 0.15, blue: 0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
}

#endif // canImport(SceneKit)
#endif // canImport(SwiftUI)
