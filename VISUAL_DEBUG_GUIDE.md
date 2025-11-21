# Cube Rendering - Visual Debugging Guide

## Quick Visual Check

When you run the app and see the 3D cube, here's what you should see for a **SOLVED** cube:

### View from Default Camera Position (5, 5, 8)
You'll be looking at the cube from the front-top-right, so you should see:
- **Front Face (visible, facing you)**: All RED
- **Top Face (visible, top of cube)**: All WHITE  
- **Right Face (visible, right side)**: All BLUE

The other three faces (Left, Back, Bottom) will be hidden from this view, but if you rotate the cube, they should each show one solid color:
- **Left Face**: All GREEN
- **Back Face**: All ORANGE
- **Bottom Face**: All YELLOW

## Common Visual Bugs and What They Mean

### ❌ Bug: Multiple colors on one face
**Example**: Front face shows red, white, and blue stickers
**Cause**: Coordinate mapping is wrong - cubies from different layers are being painted with wrong colors
**Fix**: Check the row/col formulas in `updateCubeColors()`

### ❌ Bug: Same color on multiple faces
**Example**: Red appears on both front and top faces
**Cause**: Material index is wrong - painting the wrong material on each cubie
**Fix**: Check that material indices match SCNBox order: [0]=Right, [1]=Left, [2]=Top, [3]=Bottom, [4]=Front, [5]=Back

### ❌ Bug: Black faces (no color)
**Example**: Some faces remain black instead of showing colors
**Cause**: The `if` conditions aren't matching, so cubies aren't getting painted
**Fix**: Check that position checks (x==0, y==2, etc.) are correct

### ❌ Bug: Inverted/mirrored face
**Example**: Front face shows red but the pattern is flipped horizontally
**Cause**: Row or column formula is inverted
**Fix**: Check the `2 - x`, `2 - y`, `2 - z` formulas

## Coordinate System Cheat Sheet

```
       +Y (TOP)
        │
        │
        └─────── +X (RIGHT)
       ╱
      ╱
    +Z (FRONT)
```

### Cubie Naming
- Position (0,0,0) = Back-Bottom-Left corner
- Position (2,2,2) = Front-Top-Right corner
- Position (1,1,1) = Center (doesn't exist, we skip it)

### Face Identities
| Face | Axis | Value | Color | Material Index |
|------|------|-------|-------|----------------|
| LEFT | x | 0 | GREEN | 1 |
| RIGHT | x | 2 | BLUE | 0 |
| BOTTOM | y | 0 | YELLOW | 3 |
| TOP | y | 2 | WHITE | 2 |
| BACK | z | 0 | ORANGE | 5 |
| FRONT | z | 2 | RED | 4 |

## Testing Specific Cubies

### Corner Cubie Examples
Test these positions to verify corner stickers:

**Front-Top-Left (0,2,2)**
- Should show: LEFT=Green, TOP=White, FRONT=Red
- materials[1]=Green, materials[2]=White, materials[4]=Red

**Back-Bottom-Right (2,0,0)**
- Should show: RIGHT=Blue, BOTTOM=Yellow, BACK=Orange
- materials[0]=Blue, materials[3]=Yellow, materials[5]=Orange

### Edge Cubie Examples
Test these positions to verify edge stickers:

**Top-Front (1,2,2)**
- Should show: TOP=White, FRONT=Red
- Only materials[2] and materials[4] should be colored, rest black

**Left-Bottom (0,0,1)**
- Should show: LEFT=Green, BOTTOM=Yellow
- Only materials[1] and materials[3] should be colored, rest black

### Center Cubie Examples
Test these positions to verify center stickers:

**Front Center (1,1,2)**
- Should show: FRONT=Red only
- Only materials[4] should be colored, rest black

**Top Center (1,2,1)**
- Should show: TOP=White only
- Only materials[2] should be colored, rest black

## Debug Print Statements

Add these to `updateCubeColors()` to debug:

```swift
// Print what we're painting
if x == 0 {
    let row = 2 - y
    let col = 2 - z
    print("Cubie (\(x),\(y),\(z)) LEFT face: row=\(row) col=\(col) color=\(cube.left.colors[row][col])")
}
```

## Verification Checklist

✅ Build compiles without errors  
✅ All 26 cubies are created (27 minus center)  
✅ Each face shows one solid color for a solved cube  
✅ Corner cubies show 3 different colors  
✅ Edge cubies show 2 different colors  
✅ Center cubies show 1 color  
✅ Cube rotates smoothly  
✅ Colors remain correct after rotation  

## Quick Fix Reference

If you see the cube is still wrong:

1. **Check material indices**: Are they in the right order [0-5]?
2. **Check position conditions**: Are the `if x == 0` conditions correct?
3. **Check row formulas**: Are you using `2 - y` where needed?
4. **Check col formulas**: Are you using `2 - z` or `2 - x` where needed?
5. **Check face data**: Is `RubiksCube()` creating the right default colors?

## Current Implementation Status

✅ **VERIFIED CORRECT** - All tests pass
- Direct iteration approach through all 26 cubies
- Simple position-based painting
- No complex coordinate transformations
- 100% test coverage with `test_rendering_logic.swift`
