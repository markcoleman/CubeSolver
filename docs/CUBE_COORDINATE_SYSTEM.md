# Rubik's Cube 3D Coordinate System

## Overview
This document describes how the 2D face arrays map to 3D cubie positions in the SceneKit visualization.

## Coordinate System

### Cubie Positions
Cubies are positioned at integer coordinates (x, y, z) where each value is 0, 1, or 2:
- **x-axis**: 0 (left) → 2 (right)
- **y-axis**: 0 (bottom) → 2 (top)
- **z-axis**: 0 (back) → 2 (front)

The center cubie (1, 1, 1) is skipped as it's not visible in a real Rubik's cube.

### Face Layers
Each face corresponds to a layer of 9 cubies:

| Face   | Color  | Layer      | SCNBox Material Index |
|--------|--------|------------|-----------------------|
| Top    | White  | y = 2      | 2                     |
| Bottom | Yellow | y = 0      | 3                     |
| Front  | Red    | z = 2      | 4                     |
| Back   | Orange | z = 0      | 5                     |
| Left   | Green  | x = 0      | 1                     |
| Right  | Blue   | x = 2      | 0                     |

## Face Array to Cubie Position Mapping

Each face is represented as a 3×3 array where:
- **row 0** = top edge of the face (when viewed from outside)
- **row 2** = bottom edge of the face
- **col 0** = left edge of the face
- **col 2** = right edge of the face

### X-Axis Faces (Left/Right)

**Left Face (x=0, Green)** - Looking from the left side:
```
row\col  0    1    2
   0   (0,2,2) (0,2,1) (0,2,0)
   1   (0,1,2) (0,1,1) (0,1,0)
   2   (0,0,2) (0,0,1) (0,0,0)
```
Mapping: (x, y, z) = (0, 2-row, 2-col)

**Right Face (x=2, Blue)** - Looking from the right side:
```
row\col  0    1    2
   0   (2,2,0) (2,2,1) (2,2,2)
   1   (2,1,0) (2,1,1) (2,1,2)
   2   (2,0,0) (2,0,1) (2,0,2)
```
Mapping: (x, y, z) = (2, 2-row, col)

### Y-Axis Faces (Top/Bottom)

**Top Face (y=2, White)** - Looking from above:
```
row\col  0    1    2
   0   (0,2,0) (1,2,0) (2,2,0)
   1   (0,2,1) (1,2,1) (2,2,1)
   2   (0,2,2) (1,2,2) (2,2,2)
```
Mapping: (x, y, z) = (col, 2, row)

**Bottom Face (y=0, Yellow)** - Looking from below:
```
row\col  0    1    2
   0   (0,0,2) (1,0,2) (2,0,2)
   1   (0,0,1) (1,0,1) (2,0,1)
   2   (0,0,0) (1,0,0) (2,0,0)
```
Mapping: (x, y, z) = (col, 0, 2-row)

### Z-Axis Faces (Front/Back)

**Front Face (z=2, Red)** - Looking from the front:
```
row\col  0    1    2
   0   (0,2,2) (1,2,2) (2,2,2)
   1   (0,1,2) (1,1,2) (2,1,2)
   2   (0,0,2) (1,0,2) (2,0,2)
```
Mapping: (x, y, z) = (col, 2-row, 2)

**Back Face (z=0, Orange)** - Looking from the back:
```
row\col  0    1    2
   0   (2,2,0) (1,2,0) (0,2,0)
   1   (2,1,0) (1,1,0) (0,1,0)
   2   (2,0,0) (1,0,0) (0,0,0)
```
Mapping: (x, y, z) = (2-col, 2-row, 0)

## SCNBox Material Indices

SCNBox materials are indexed as follows:
- 0: Right face (+X direction)
- 1: Left face (-X direction)
- 2: Top face (+Y direction)
- 3: Bottom face (-Y direction)
- 4: Front face (+Z direction)
- 5: Back face (-Z direction)

## Implementation

The mapping is implemented in `getCubiePosition()` function in `Cube3DView.swift` and `getAnimatedCubiePosition()` in `AnimatedCube3DView.swift`.

Each face's colors are applied to the appropriate SCNBox material index for cubies in that layer.
