# API Documentation

## Overview

CubeSolver provides a clean and simple API for working with Rubik's Cubes. The core functionality is divided into several modules:

- **RubiksCube**: The cube model and rotation operations
- **CubeSolver**: Solving algorithms and scramble generation
- **CubeViewModel**: SwiftUI ViewModel for UI state management
- **UI Components**: Reusable glassmorphic UI components

---

## RubiksCube Module

### FaceColor

An enumeration representing the six colors on a Rubik's Cube.

```swift
enum FaceColor: String, CaseIterable {
    case white = "W"
    case yellow = "Y"
    case red = "R"
    case orange = "O"
    case blue = "B"
    case green = "G"
}
```

### CubeFace

Represents a single face of the Rubik's Cube (3x3 grid).

```swift
struct CubeFace {
    var colors: [[FaceColor]]
    
    init(color: FaceColor)
    mutating func rotateClockwise()
    mutating func rotateCounterClockwise()
}
```

**Methods:**
- `rotateClockwise()`: Rotates the face 90° clockwise
- `rotateCounterClockwise()`: Rotates the face 90° counter-clockwise (3 clockwise rotations)

### RubiksCube

The main cube structure representing a complete 3x3x3 Rubik's Cube.

```swift
struct RubiksCube {
    var front: CubeFace
    var back: CubeFace
    var left: CubeFace
    var right: CubeFace
    var top: CubeFace
    var bottom: CubeFace
    
    var isSolved: Bool { get }
}
```

**Properties:**
- `isSolved`: Returns `true` if the cube is in a solved state

**Rotation Methods:**
- `mutating func rotateFront()`: Rotates the front face clockwise
- `mutating func rotateBack()`: Rotates the back face clockwise
- `mutating func rotateLeft()`: Rotates the left face clockwise
- `mutating func rotateRight()`: Rotates the right face clockwise
- `mutating func rotateTop()`: Rotates the top face clockwise
- `mutating func rotateBottom()`: Rotates the bottom face clockwise

**Example:**
```swift
var cube = RubiksCube()
cube.rotateFront()
cube.rotateRight()
cube.rotateTop()
print(cube.isSolved) // false
```

---

## CubeSolver Module

### CubeSolver

A static class providing solving algorithms and utility functions.

```swift
class CubeSolver {
    static func solve(cube: inout RubiksCube) -> [String]
    static func scramble(moves: Int = 20) -> [String]
    static func applyScramble(cube: inout RubiksCube, scramble: [String])
}
```

**Methods:**

#### `solve(cube:)`
Solves the Rubik's Cube and returns the solution steps.

```swift
var cube = RubiksCube()
// ... scramble the cube ...
let solution = CubeSolver.solve(cube: &cube)
// solution: ["F - Rotate front face clockwise", ...]
```

**Parameters:**
- `cube`: An inout RubiksCube to solve

**Returns:**
- An array of strings describing each solution step

#### `scramble(moves:)`
Generates a random scramble sequence.

```swift
let scramble = CubeSolver.scramble(moves: 20)
// scramble: ["F - Rotate front face clockwise", ...]
```

**Parameters:**
- `moves`: Number of random moves to generate (default: 20)

**Returns:**
- An array of strings describing each scramble move

#### `applyScramble(cube:scramble:)`
Applies a scramble sequence to a cube.

```swift
var cube = RubiksCube()
let scramble = CubeSolver.scramble(moves: 15)
CubeSolver.applyScramble(cube: &cube, scramble: scramble)
```

**Parameters:**
- `cube`: An inout RubiksCube to scramble
- `scramble`: Array of move descriptions

---

## CubeViewModel

An `ObservableObject` for managing cube state in SwiftUI.

```swift
class CubeViewModel: ObservableObject {
    @Published var cube: RubiksCube
    @Published var solutionSteps: [String]
    
    func scramble()
    func solve()
    func reset()
}
```

**Properties:**
- `cube`: The current RubiksCube state
- `solutionSteps`: Array of solution step descriptions

**Methods:**

#### `scramble()`
Scrambles the cube with 20 random moves.

```swift
let viewModel = CubeViewModel()
viewModel.scramble()
```

#### `solve()`
Solves the current cube and populates `solutionSteps`.

```swift
viewModel.solve()
print(viewModel.solutionSteps)
```

#### `reset()`
Resets the cube to a solved state and clears solution steps.

```swift
viewModel.reset()
```

**Example Usage:**
```swift
struct ContentView: View {
    @StateObject private var cubeViewModel = CubeViewModel()
    
    var body: some View {
        VStack {
            CubeView(cube: cubeViewModel.cube)
            
            Button("Scramble") {
                cubeViewModel.scramble()
            }
            
            Button("Solve") {
                cubeViewModel.solve()
            }
            
            Button("Reset") {
                cubeViewModel.reset()
            }
        }
    }
}
```

---

## UI Components

### CubeView

A SwiftUI view that visualizes the Rubik's Cube.

```swift
struct CubeView: View {
    let cube: RubiksCube
}
```

**Usage:**
```swift
CubeView(cube: myRubiksCube)
    .frame(width: 400, height: 400)
```

### GlassmorphicButton

A glassmorphic-styled button component.

```swift
struct GlassmorphicButton: View {
    let title: String
    let icon: String
    let action: () -> Void
}
```

**Usage:**
```swift
GlassmorphicButton(title: "Solve", icon: "checkmark.circle") {
    // Action
}
```

### GlassmorphicCard

A glassmorphic-styled card container.

```swift
struct GlassmorphicCard<Content: View>: View {
    init(@ViewBuilder content: () -> Content)
}
```

**Usage:**
```swift
GlassmorphicCard {
    VStack {
        Text("Card Content")
    }
    .padding()
}
```

---

## Platform Support

### iOS/iPadOS
- Minimum version: iOS 17.0
- Supports all iPhone and iPad models
- Optimized layouts for different screen sizes

### macOS
- Minimum version: macOS 14.0
- Native macOS app with Mac Catalyst
- Glassmorphic design optimized for macOS

---

## Error Handling

Currently, the API does not throw errors. All operations are safe and well-defined. Future versions may include:

- Invalid cube state detection
- Unsolvable configuration warnings
- Performance optimization options

---

## Performance Considerations

- All cube operations are O(1) complexity
- Solving algorithm has linear time complexity
- UI updates are optimized with SwiftUI's diffing
- Suitable for real-time interactive applications

---

## Thread Safety

- `RubiksCube` and `CubeFace` are value types (struct) and are thread-safe by default
- `CubeViewModel` is an `ObservableObject` and should be used on the main thread
- UI updates automatically dispatch to the main thread

---

## Future API Extensions

Planned additions:
- Advanced solving algorithms (Kociemba)
- Custom cube size support (2x2, 4x4, etc.)
- Move notation parsing (standard cube notation)
- Solution optimization
- Performance metrics

---

For more information, see the [README](../README.md) or visit the [documentation site](https://markcoleman.github.io/CubeSolver).
