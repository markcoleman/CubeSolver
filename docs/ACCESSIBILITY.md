# Accessibility Guide

> **CubeSolver is committed to being accessible to everyone.** This guide explains our accessibility features and how to use them effectively.

## Table of Contents

- [Overview](#overview)
- [Accessibility Features](#accessibility-features)
  - [VoiceOver Support](#voiceover-support)
  - [Dynamic Type](#dynamic-type)
  - [Color Contrast](#color-contrast)
  - [Reduce Motion](#reduce-motion)
  - [Keyboard Navigation](#keyboard-navigation-macos)
- [Using CubeSolver with VoiceOver](#using-cubesolver-with-voiceover)
- [Accessibility Testing](#accessibility-testing)
- [Reporting Accessibility Issues](#reporting-accessibility-issues)

## Overview

CubeSolver is designed to be fully accessible to all users, including those using assistive technologies like VoiceOver, Switch Control, and keyboard navigation.

**Accessibility Standards:**
- Follows WCAG 2.1 Level AA guidelines
- Full VoiceOver compatibility
- Dynamic Type support across all screens
- Keyboard navigation on macOS
- Reduced motion alternatives

## Accessibility Features

### VoiceOver Support

All interactive elements in CubeSolver have been configured with:
- **Accessibility Labels**: Clear, descriptive labels for all UI elements
- **Accessibility Hints**: Additional context for complex interactions
- **Accessibility Traits**: Proper traits (button, header, etc.) for each element
- **Accessibility Values**: Dynamic values that update based on app state

### Main Screen Accessibility

#### Title
- **Label**: "Rubik's Cube Solver"
- **Trait**: Header
- Announces as a primary heading

#### Cube Visualization
- **Label**: "Rubik's Cube"
- **Value**: "Solved" or "Scrambled" (updates dynamically)
- Provides current cube state information

#### Control Buttons

**Manual Input Button**
- **Label**: "Manual Input"
- **Hint**: "Opens the manual cube input interface"
- **Action**: Presents manual input sheet

**Scramble Button**
- **Label**: "Scramble"
- **Hint**: "Scrambles the cube with random moves"
- **Action**: Randomizes cube configuration

**Solve Button**
- **Label**: "Solve"
- **Hint**: "Solves the current cube configuration"
- **Action**: Generates solution steps

**Reset Button**
- **Label**: "Reset"
- **Hint**: "Resets the cube to solved state"
- **Action**: Returns cube to initial state

#### Solution Steps
- **Label**: "Solution steps"
- **Value**: Number of steps (e.g., "8 steps")
- Each step announced as "Step 1: F - Rotate front face clockwise"

### Manual Input Screen Accessibility

#### Face Selector
Each face button has:
- **Label**: Face name (e.g., "Front face")
- **Trait**: Button
- **Selected State**: Announced when selected

Available faces:
- Front face
- Back face
- Left face
- Right face
- Top face
- Bottom face

#### Color Picker
Each color button has:
- **Label**: Color name (e.g., "Red color")
- **Trait**: Button
- **Selected State**: Announced when selected

Available colors:
- White color
- Yellow color
- Red color
- Orange color
- Blue color
- Green color

#### Editable Face Grid
Each cell in the 3×3 grid has:
- **Label**: Position (e.g., "Cell row 1, column 1")
- **Value**: Current color (e.g., "Red color")
- **Hint**: "Tap to set to selected color"
- **Action**: Sets cell to currently selected color

#### Action Buttons

**Reset Face Button**
- **Label**: "Reset Face"
- **Hint**: "Resets the selected face to its original state"

**Done Button**
- **Label**: "Done"
- **Hint**: "Closes the manual input view"

**Close Button**
- **Label**: "Close"
- Alternative dismissal method

## Using CubeSolver with VoiceOver

### Basic Navigation

1. **Enable VoiceOver**: Settings → Accessibility → VoiceOver
2. **Navigate**: Swipe right to move forward, left to move backward
3. **Activate**: Double-tap to activate the current element
4. **Explore**: Touch the screen to hear what's under your finger

### Scrambling the Cube

1. Swipe to "Scramble button"
2. Double-tap to activate
3. VoiceOver will announce the cube is now scrambled

### Solving the Cube

1. Swipe to "Solve button"
2. Double-tap to activate
3. Navigate to "Solution steps" to hear all steps
4. Each step will be announced individually

### Manual Input Workflow

**Complete workflow for entering a real-world cube:**

1. **Open Manual Input**
   - Navigate to "Manual Input button"
   - VoiceOver announces: "Manual Input, button, Opens the manual cube input interface"
   - Double-tap to activate
   
2. **Select First Face (e.g., Front)**
   - Swipe right to face selector
   - VoiceOver announces: "Front face, button"
   - Double-tap to select
   - VoiceOver confirms: "Front face, button, selected"
   
3. **Choose a Color**
   - Navigate to color picker section
   - Swipe through colors (White, Yellow, Red, Orange, Blue, Green)
   - For example: "Red color, button"
   - Double-tap to select color
   - VoiceOver confirms: "Red color, button, selected"
   
4. **Fill in Grid Cells**
   - Navigate to the 3×3 grid
   - VoiceOver announces each cell: "Cell row 1, column 1, White color, button"
   - Double-tap on any cell to set it to the selected color
   - VoiceOver confirms the color change
   - Continue for all 9 cells
   
5. **Repeat for Each Face**
   - Select next face (Back, Left, Right, Top, Bottom)
   - Choose appropriate colors
   - Fill in all cells
   - Complete all 6 faces
   
6. **Finish and Return**
   - Navigate to "Done button"
   - VoiceOver announces: "Done, button, Closes the manual input view"
   - Double-tap to return to main screen
   - Your cube configuration is now ready to solve

**Tips for VoiceOver Users:**
- Use the rotor to navigate by "Buttons" for faster access
- Double-tap with two fingers to pause VoiceOver temporarily if needed
- If you make a mistake, use "Reset Face button" to start that face over
- The center sticker of each face determines its color (center never moves)

## Dynamic Type Support

CubeSolver supports Dynamic Type for text scaling:
- All text respects user's preferred text size
- Layout adapts to larger text sizes
- No loss of functionality at any text size

To adjust text size:
1. Settings → Accessibility → Display & Text Size
2. Adjust "Larger Text" slider
3. CubeSolver will automatically update

## Keyboard Navigation (macOS)

On macOS, CubeSolver supports full keyboard navigation:

- **Tab**: Move to next element
- **Shift+Tab**: Move to previous element
- **Space**: Activate button
- **Escape**: Dismiss sheets/modals
- **Arrow Keys**: Navigate within grids

## Color Contrast

All UI elements meet WCAG 2.1 AA standards for color contrast:
- Text on backgrounds: Minimum 4.5:1 ratio
- Large text: Minimum 3:1 ratio
- Interactive elements: Clear visual indicators

## Reduce Motion

CubeSolver respects the "Reduce Motion" accessibility setting:
- Animations are simplified or removed
- Transitions are instantaneous
- No parallax or floating effects

To enable Reduce Motion:
1. Settings → Accessibility → Motion
2. Enable "Reduce Motion"

## Testing Your Accessibility

### VoiceOver Gestures

- **Two-finger swipe up**: Read all from current position
- **Two-finger swipe down**: Read all from top
- **Three-finger swipe left/right**: Scroll pages
- **Two-finger double-tap**: Activate/deactivate action

### Rotor (VoiceOver)

Use the rotor to navigate by:
- Headings
- Buttons
- Containers
- Text fields

To use rotor:
1. Rotate two fingers on screen
2. Select category (e.g., "Buttons")
3. Swipe up/down to jump between elements

## Accessibility Identifiers (for Testing)

For automated testing, all elements have accessibility identifiers:

**Main Screen**
- `mainTitle`
- `cubeView`
- `manualInputButton`
- `scrambleButton`
- `solveButton`
- `resetButton`
- `solutionStepsView`

**Manual Input Screen**
- `manualInputTitle`
- `faceSelector`
- `colorSelector`
- `editableFaceView`
- `cell_[row]_[col]` (e.g., `cell_0_0`)
- `resetFaceButton`
- `doneButton`
- `closeButton`

**Color Buttons**
- `WColorButton` (White)
- `YColorButton` (Yellow)
- `RColorButton` (Red)
- `OColorButton` (Orange)
- `BColorButton` (Blue)
- `GColorButton` (Green)

## Reporting Accessibility Issues

If you encounter any accessibility issues:

1. Check this guide for proper usage
2. Ensure assistive technologies are properly configured
3. Report issues on GitHub with:
   - Description of the problem
   - Steps to reproduce
   - Assistive technology version
   - iOS/macOS version
   - Expected vs. actual behavior

## Best Practices for All Users

- Use the app in good lighting conditions
- Ensure screen brightness is adequate
- Take breaks during extended use
- Use assistive touch if needed
- Enable any accessibility features that help you

## Additional Resources

- [Apple Accessibility Guide](https://www.apple.com/accessibility/)
- [VoiceOver User Guide](https://support.apple.com/guide/iphone/voiceover-iph3e2e415f)
- [iOS Accessibility Features](https://support.apple.com/accessibility/ios)
- [macOS Accessibility Features](https://support.apple.com/accessibility/mac)

---

CubeSolver is committed to being accessible to everyone. We continuously improve our accessibility support based on user feedback.
