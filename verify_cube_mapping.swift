#!/usr/bin/env swift

// Verification script for cube coordinate mapping
// This shows what color each cubie face should display for a solved cube

enum FaceColor: String {
    case white = "W"
    case yellow = "Y"
    case red = "R"
    case orange = "O"
    case blue = "B"
    case green = "G"
}

func getCubiePosition(axis: String, layer: Int, row: Int, col: Int) -> (Int, Int, Int) {
    switch axis {
    case "x":
        if layer == 0 {
            // Left Face (x=0, Green)
            return (0, 2 - row, 2 - col)
        } else {
            // Right Face (x=2, Blue)
            return (2, 2 - row, col)
        }
        
    case "y":
        if layer == 2 {
            // Top Face (y=2, White)
            return (col, 2, row)
        } else {
            // Bottom Face (y=0, Yellow)
            return (col, 0, 2 - row)
        }
        
    case "z":
        if layer == 2 {
            // Front Face (z=2, Red)
            return (col, 2 - row, 2)
        } else {
            // Back Face (z=0, Orange)
            return (2 - col, 2 - row, 0)
        }
    default:
        return (0, 0, 0)
    }
}

print("=== SOLVED RUBIK'S CUBE FACE MAPPING ===\n")

let faces: [(String, Int, String, FaceColor, Int)] = [
    ("z", 2, "Front", .red, 4),
    ("z", 0, "Back", .orange, 5),
    ("x", 0, "Left", .green, 1),
    ("x", 2, "Right", .blue, 0),
    ("y", 2, "Top", .white, 2),
    ("y", 0, "Bottom", .yellow, 3)
]

for (axis, layer, name, color, materialIndex) in faces {
    print("=== \(name) Face (Material Index \(materialIndex)) - \(color.rawValue) ===")
    for row in 0..<3 {
        var line = ""
        for col in 0..<3 {
            let (x, y, z) = getCubiePosition(axis: axis, layer: layer, row: row, col: col)
            line += "(\(x),\(y),\(z)) "
        }
        print(line)
    }
    print()
}

print("\n=== CUBIE POSITIONS (x, y, z) ===")
print("Coordinate system:")
print("  x: 0=Left, 1=Middle, 2=Right")
print("  y: 0=Bottom, 1=Middle, 2=Top")
print("  z: 0=Back, 1=Middle, 2=Front")
print("\nEach cubie at position (x,y,z) should show these colors on its faces:")
print("  Material[0] = Right face (+X) - only visible if x=2")
print("  Material[1] = Left face (-X) - only visible if x=0")
print("  Material[2] = Top face (+Y) - only visible if y=2")
print("  Material[3] = Bottom face (-Y) - only visible if y=0")
print("  Material[4] = Front face (+Z) - only visible if z=2")
print("  Material[5] = Back face (-Z) - only visible if z=0")
