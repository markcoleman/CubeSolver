# CubeCam UX Improvements - Visual Guide

This document describes the visual changes and UI components added to enhance the CubeCam scanning experience.

## UI Components Overview

### 1. Scanning Overlay (PROMPT 1)
**Location**: Top center of screen
**Appearance**: 
- Circular progress indicator
- Shows stable frames progress (e.g., "6/8 stable frames")
- Green when ready to scan, yellow when stabilizing
- Glassmorphic card with ultraThinMaterial backdrop

**States**:
- Stabilizing: Yellow icon, frame counter incrementing
- Ready: Green checkmark, "Ready to scan" message

### 2. 3D Cube Mini-Diagram (PROMPT 4)
**Location**: Top center, below progress text
**Appearance**:
- Isometric 3D cube showing 3 visible faces
- Dimensions: 120×120 points
- Shows Top, Front, and Right faces in isometric projection

**Face Colors**:
- ✅ Green with fill: Face captured
- 🔵 Blue pulsing: Next face to scan
- ⚪ Gray dimmed: Not yet scanned

**Label**: Text below showing "Scan [Face Name] Side"

### 3. Warning Overlays (PROMPTS 2, 3, 8)

#### Duplicate Face Warning
- Orange accent color
- Triangle warning icon
- "Duplicate Face Detected" header
- Auto-dismisses after 4 seconds
- Slides in from top

#### Wrong Face Warning
- Blue accent color
- Rotation arrow icon
- Explains which face was detected vs. expected
- Manual dismiss with X button
- Persistent until dismissed

#### Scan Error Overlay
- Red accent color
- Octagon error icon
- Error description
- Recovery suggestion with lightbulb icon
- "Retry" button

### 4. Capture Mode Badge (PROMPT 9)
**Location**: Top right corner
**Appearance**:
- Small pill-shaped badge
- Purple gradient for Auto mode
- Blue gradient for Manual mode
- Icon changes: wand.and.stars (auto) / hand.tap (manual)
- Tappable to toggle modes

### 5. Alignment Guide (PROMPT 9)
**Location**: Full screen overlay
**Appearance** (Manual mode only):
- Dashed square outline (60% of screen)
- Four corner markers with L-shapes
- Center crosshair with circle
- Green when aligned, white when not
- Semi-transparent, doesn't block camera view

### 6. Manual Capture Button (PROMPT 9)
**Location**: Bottom panel, replaces auto-scan indicator
**Appearance**:
- Large blue gradient button
- Camera icon with "Capture Face" text
- When activated: Timer icon with "Capturing..."
- Countdown overlay: Large numbers 3→2→1

**Animation**:
- Number scales in with spring animation
- Fades out after 1 second
- Haptic feedback on capture

### 7. Debug Overlay (PROMPT 10)
**Location**: Top area, below 3D cube indicator
**Appearance**:
- Collapsible panel with ladybug icon
- Green accent color
- Shows when expanded:
  - Stability percentage
  - Stable frames count
  - Brightness level (color-coded)
  - Detected face
  - Center color
  - Captured faces list as pills

**Activation**: Triple-tap anywhere in top area

### 8. Auto-Scan Indicator
**Location**: Bottom panel (auto mode only)
**Appearance**:
- Purple gradient wide button
- Wand icon with "Auto-scanning..." text
- Replaces manual capture button in auto mode
- Non-interactive, informational only

## Layout Structure

```
┌─────────────────────────────────────┐
│ Camera Preview (full screen)       │
│                                     │
│  ┌──────────────────────────┐      │
│  │ "Step 2: Scan Top Face" │      │ <- Progress text
│  │ [Capture Mode Badge]     │      │
│  └──────────────────────────┘      │
│                                     │
│  ┌──────────────────────────┐      │
│  │   [3D Cube Diagram]      │      │ <- 3D visualization
│  │   "Scan Top Side"        │      │
│  └──────────────────────────┘      │
│                                     │
│  ┌──────────────────────────┐      │
│  │ [Scanning Overlay]       │      │ <- Stability indicator
│  │ "6/8 stable frames"      │      │
│  └──────────────────────────┘      │
│                                     │
│  [Debug Overlay] (if enabled)      │
│                                     │
│  [Alignment Guide] (manual mode)   │ <- Semi-transparent
│  [Detection Overlay] (green box)   │ <- Face detection
│                                     │
│ ┌─────────────────────────────────┐│
│ │ Bottom Panel                    ││
│ │ ━━━━━━━━━━━━━━━━━━━━━━ 2/6     ││ <- Progress bar
│ │                                 ││
│ │ [Cancel] [Capture / Auto-scan] ││ <- Buttons
│ └─────────────────────────────────┘│
└─────────────────────────────────────┘
```

## Color Scheme

All components use the glassmorphic design language:

**Backgrounds**:
- `.ultraThinMaterial` - Primary backdrop
- Semi-transparent overlays (0.1-0.2 opacity)

**Accents**:
- 🟢 Green: Success, captured, stable
- 🔵 Blue: Next action, manual mode
- 🟣 Purple: Auto mode
- 🟡 Yellow/Orange: Warning, stabilizing
- 🔴 Red: Error, critical

**Borders**:
- White with 0.2 opacity
- 2-3pt stroke width

**Shadows**:
- Subtle with matching accent color
- 0.3 opacity, 8pt radius

## Animations

1. **Face Capture Flash**: Green screen flash, fades in 0.3s
2. **Warning Slide-In**: Spring animation from top
3. **Countdown Numbers**: Scale + fade, spring effect
4. **3D Cube Pulse**: Next face pulsates at 0.8s intervals
5. **Debug Panel**: Smooth expand/collapse
6. **Progress Indicators**: Smooth value updates with easing

## Typography

**Headers**: Headline weight, semibold
**Body Text**: Subheadline/Body
**Captions**: Caption/Caption2 for small text
**Button Labels**: Semibold weight

## Accessibility Features

All components include:
- VoiceOver labels describing function
- Hints for complex interactions
- Value announcements for dynamic content
- Proper element combining for related groups
- Button traits and disabled states
- Progress announcements

## Dark/Light Mode

All components automatically adapt to color scheme:
- Materials adjust automatically
- Accent colors remain consistent
- Text always readable (white on dark, black on light)
- Shadows adjust intensity

## Responsive Design

Components scale for different devices:
- 3D cube: Fixed 120×120pt on all devices
- Alignment guide: 60% of screen width
- Overlays: Responsive padding
- Bottom panel: Full width with safe area insets
- Text: Supports Dynamic Type

## User Flow Example

1. User opens CubeCam
2. Sees "Step 1: Position cube in frame"
3. 3D diagram shows all faces gray
4. Alignment guide helps center cube (manual mode)
5. Scanning overlay shows "Stabilizing... 3/8 frames"
6. When stable: "Ready to scan" appears
7. Face captured with green flash
8. 3D diagram updates - Front face now green
9. Text updates: "Step 2: Scan Right Side"
10. 3D diagram highlights Right face in blue, pulsing
11. User rotates cube
12. If wrong face shown: Warning overlay appears
13. If duplicate: Different warning appears
14. Process repeats for all 6 faces
15. Completion overlay when done

## Error Recovery Example

1. User scans in poor lighting
2. Error overlay appears: "Lighting is too dark"
3. Shows lightbulb icon with suggestion
4. User taps "Retry"
5. Moves to better lighting
6. Continues scanning

This visual guide provides a complete picture of the enhanced UI without requiring actual screenshots.
