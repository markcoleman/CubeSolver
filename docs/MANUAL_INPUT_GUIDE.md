# Manual Cube Input Guide

## Overview

The Manual Input feature allows you to input the exact configuration of a real-life Rubik's Cube into the app, so you can get step-by-step solutions for your physical cube.

## How to Use Manual Input

### 1. Open Manual Input Interface

From the main screen, tap the **"Manual Input"** button to open the manual input interface.

### 2. Understanding the Interface

The manual input screen consists of four main sections:

#### Instructions Card
- Provides quick reference for how to use the interface
- Shows the three-step process: Select Face → Choose Color → Tap Cells

#### Face Selector
- Six buttons representing each face of the cube:
  - **Front (F)** - Typically red in standard orientation
  - **Back (B)** - Typically orange in standard orientation
  - **Left (L)** - Typically green in standard orientation
  - **Right (R)** - Typically blue in standard orientation
  - **Top (U/Up)** - Typically white in standard orientation
  - **Bottom (D/Down)** - Typically yellow in standard orientation

#### Color Picker
- Six colored circles representing the six cube colors:
  - White
  - Yellow
  - Red
  - Orange
  - Blue
  - Green

#### Editable Face Grid
- A 3×3 grid showing the current face
- Each cell can be tapped to set its color

### 3. Input Your Cube Pattern

Follow these steps to input your cube:

1. **Hold your physical cube** in front of you
2. **Select a face** (e.g., Front face)
3. **Choose a color** from the color picker
4. **Tap cells** in the 3×3 grid to set their colors
5. **Repeat** for all six faces

### 4. Tips for Accurate Input

- **Consistent Orientation**: Keep your cube in the same orientation while inputting
  - Choose a reference face (e.g., white on top)
  - Rotate the cube systematically
  
- **Face-by-Face Entry**: Complete one face at a time
  - Start with the top face
  - Move to front, then right, back, left
  - Finish with the bottom face

- **Double-Check**: Verify each face after entry
  - Use the "Reset Face" button if you make a mistake

### 5. Standard Cube Orientation

The app uses this standard orientation:
```
    [White]      (Top)
[Green][Red][Blue][Orange]  (Left, Front, Right, Back)
    [Yellow]     (Bottom)
```

### 6. Reset Face

If you make a mistake while entering a face:
- Tap the **"Reset Face"** button
- This will restore the selected face to its default color

### 7. Complete and Solve

Once you've entered all six faces:
1. Tap **"Done"** or **"Close"** to return to the main screen
2. Tap **"Solve"** to get the solution steps for your cube

## Accessibility Features

The Manual Input interface is fully accessible:

- **VoiceOver Support**: All elements have descriptive labels
- **Accessibility Hints**: Buttons include hints for their actions
- **Cell Identification**: Each grid cell is labeled with its position
- **Color Announcements**: Selected colors are announced

## Common Issues

### Invalid Cube Configuration

If your input creates an invalid cube configuration (e.g., duplicate center pieces), the solver may not be able to solve it. Ensure:
- Each color appears exactly 9 times
- Center pieces match standard orientation
- No duplicate edge or corner pieces

### Difficulty Seeing Colors

If you have difficulty distinguishing colors on your physical cube:
- Use good lighting
- Take a photo for reference
- Consider using a cube with high-contrast stickers

## Example Workflow

1. Scramble your physical Rubik's Cube
2. Open CubeSolver app
3. Tap "Manual Input" button
4. Select "Top" face
5. Look at top of your cube
6. For each cell, select matching color and tap cell
7. Move to next face (Front)
8. Repeat for all six faces
9. Tap "Done"
10. Tap "Solve" to see solution steps
11. Follow the steps to solve your physical cube!

## Advanced Tips

### Speed Entry
- Learn the face selection shortcuts by position
- Use muscle memory for common color positions
- Practice entering a solved cube to build speed

### Verification
After entering all faces, you can:
- Check the cube visualization on the main screen
- Verify the center pieces match your cube
- Use "Reset" if the configuration is wrong

### Pattern Practice
Use Manual Input to:
- Save interesting cube patterns
- Practice specific solving scenarios
- Learn cube algorithms with visual feedback

## Troubleshooting

**Problem**: Colors don't match my cube
- **Solution**: CubeSolver uses standard cube colors. Your cube may have different colors, but the positions should match.

**Problem**: Can't find a specific face
- **Solution**: Use the face icons (F, B, L, R, U, D) and rotate your physical cube to match.

**Problem**: Made a mistake
- **Solution**: Use "Reset Face" to restart the current face, or go back to main screen with "Done" and re-enter.

## Best Practices

1. **Good Lighting**: Work in a well-lit area
2. **Flat Surface**: Place your cube on a flat surface while entering
3. **Systematic Approach**: Always enter faces in the same order
4. **Verify Centers**: Double-check that center pieces match
5. **Take Your Time**: Accuracy is more important than speed

---

For more help, see the [main README](../README.md) or visit the [documentation site](https://markcoleman.github.io/CubeSolver).
