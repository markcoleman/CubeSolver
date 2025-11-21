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
    
    // Map cube faces to cubie positions and colors
    // SCNBox material indices: 0=Front(+Z), 1=Right(+X), 2=Back(-Z), 3=Left(-X), 4=Top(+Y), 5=Bottom(-Y)
    // Front face (z=1, red) - maps to SCNBox material index 0
    updateFaceColors(containerNode, face: cube.front, x: nil, y: nil, z: 1, faceIndex: 0)
    // Back face (z=-1, orange) - maps to SCNBox material index 2
    updateFaceColors(containerNode, face: cube.back, x: nil, y: nil, z: -1, faceIndex: 2)
    // Left face (x=-1, green) - maps to SCNBox material index 3
    updateFaceColors(containerNode, face: cube.left, x: -1, y: nil, z: nil, faceIndex: 3)
    // Right face (x=1, blue) - maps to SCNBox material index 1
    updateFaceColors(containerNode, face: cube.right, x: 1, y: nil, z: nil, faceIndex: 1)
    // Top face (y=1, white) - maps to SCNBox material index 4
    updateFaceColors(containerNode, face: cube.top, x: nil, y: 1, z: nil, faceIndex: 4)
    // Bottom face (y=-1, yellow) - maps to SCNBox material index 5
    updateFaceColors(containerNode, face: cube.bottom, x: nil, y: -1, z: nil, faceIndex: 5)
}

private func updateFaceColors(_ containerNode: SCNNode, face: CubeFace, x: Int?, y: Int?, z: Int?, faceIndex: Int) {
    for row in 0..<3 {
        for col in 0..<3 {
            let (cubeX, cubeY, cubeZ) = getFacePosition(x: x, y: y, z: z, row: row, col: col)
            
            if let cubieNode = containerNode.childNode(withName: "cubie_\(cubeX)_\(cubeY)_\(cubeZ)", recursively: false),
               let box = cubieNode.geometry as? SCNBox,
               faceIndex < box.materials.count {
                let color = colorForFaceColor(face.colors[row][col])
                // Directly modify the material (materials are reference types)
                box.materials[faceIndex].diffuse.contents = color
            }
        }
    }
}

private func getFacePosition(x: Int?, y: Int?, z: Int?, row: Int, col: Int) -> (Int, Int, Int) {
    if let x = x {
        // Left or Right face
        let yPos = 2 - row  // Flip for correct orientation
        let zPos = x == -1 ? 2 - col : col  // Flip for left face
        return (x == -1 ? 0 : 2, yPos, zPos)
    } else if let y = y {
        // Top or Bottom face
        let xPos = col
        let zPos = y == 1 ? row : 2 - row  // Flip for bottom face
        return (xPos, y == -1 ? 0 : 2, zPos)
    } else if let z = z {
        // Front or Back face
        let xPos = z == -1 ? 2 - col : col  // Flip for back face
        let yPos = 2 - row  // Flip for correct orientation
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

