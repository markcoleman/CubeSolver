# Enhanced CubeCam - Visual Flow Diagram

## Component Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     EnhancedCubeCamView                         │
│  (Main SwiftUI View - Integrates all components)               │
└─────────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
        ┌───────────────────┐  ┌──────────────────┐
        │ Camera Preview    │  │  UI Overlays     │
        │ (AVFoundation)    │  │  (SwiftUI)       │
        └───────────────────┘  └──────────────────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    ▼                   ▼                   ▼
        ┌──────────────────┐ ┌────────────────┐ ┌─────────────────┐
        │ Step Guidance    │ │ Mini 3D Cube   │ │ Action Buttons  │
        │ EnhancedScan     │ │ Interactive    │ │ Scan/Next/Done  │
        │ Guidance         │ │ MiniCube       │ │ ScanAction      │
        └──────────────────┘ └────────────────┘ └─────────────────┘
                    │                   │                   │
                    └───────────────────┼───────────────────┘
                                        ▼
                        ┌──────────────────────────┐
                        │ EnhancedCubeCamViewModel │
                        │ (@ObservableObject)      │
                        └──────────────────────────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    ▼                   ▼                   ▼
        ┌──────────────────┐ ┌────────────────┐ ┌─────────────────┐
        │ Face States      │ │ Scan Guidance  │ │ Error Handling  │
        │ [Face:State]     │ │ Current Step   │ │ Error Type      │
        └──────────────────┘ └────────────────┘ └─────────────────┘
```

## User Interaction Flow

```
START
  │
  ▼
┌─────────────────────────────────────┐
│ Camera Permission Request           │
└─────────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────────┐
│ Step 1: "Scan Top Face"             │
│ ┌─────────────────────────────────┐ │
│ │ 🔵 Mini Cube (Top = Blue)       │ │
│ │ ⚪ Other faces = Gray           │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
  │
  ▼ (User positions cube)
┌─────────────────────────────────────┐
│ Scanning...                         │
│ Progress: ████░░░░░░ 40%            │
│ Yellow outline on camera view       │
└─────────────────────────────────────┘
  │
  ▼ (Stable detection)
┌─────────────────────────────────────┐
│ Progress: ██████████ 100%           │
│ Green outline on camera view        │
└─────────────────────────────────────┘
  │
  ▼ AUTO CAPTURE
┌─────────────────────────────────────┐
│ ✅ Success!                         │
│ • Green flash                       │
│ • Checkmark animation               │
│ • Haptic vibration                  │
└─────────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────────┐
│ Mini Cube Updates:                  │
│ 🟢 Top face = Green (captured)     │
│ 🔵 Front face = Blue (next)        │
│ ⚪ Others = Gray                   │
└─────────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────────┐
│ Step 2: "Rotate to show Front"     │
└─────────────────────────────────────┘
  │
  ▼ (Repeat for all 6 faces)
  │
  ▼
┌─────────────────────────────────────┐
│ All 6 Faces Captured!               │
│ • Validation check                  │
│ • Celebration haptics               │
└─────────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────────┐
│ Completion Overlay                  │
│ "Your cube is ready to solve"       │
│ [Continue] button                   │
└─────────────────────────────────────┘
  │
  ▼
END
```

## Error Handling Flow

```
ERROR DETECTED
  │
  ▼
┌─────────────────────────────────────┐
│ Identify Error Type                 │
├─────────────────────────────────────┤
│ • Cube Not Detected                 │
│ • Poor Lighting                     │
│ • Too Much Motion                   │
│ • Duplicate Face                    │
│ • Invalid Colors                    │
│ • Background Clutter                │
└─────────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────────┐
│ Show Error Overlay                  │
│ ┌─────────────────────────────────┐ │
│ │ 🔴 Error Icon & Title           │ │
│ │ Description of issue            │ │
│ │                                 │ │
│ │ 💡 How to fix:                  │ │
│ │ ✓ Step 1                        │ │
│ │ ✓ Step 2                        │ │
│ │ ✓ Step 3                        │ │
│ │                                 │ │
│ │ [Try Again] [Dismiss]           │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
  │
  ├──▶ [Try Again] ──▶ Clear error, continue scanning
  │
  └──▶ [Dismiss] ──▶ Continue with current state
```

## Rescan Flow

```
USER TAPS FACE ON MINI CUBE
  │
  ▼
┌─────────────────────────────────────┐
│ Haptic Feedback (tap)               │
│ Face state → notScanned             │
└─────────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────────┐
│ Update Mini Cube Display            │
│ Tapped face: 🟢 → ⚪ (gray)       │
└─────────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────────┐
│ Update Guidance                     │
│ "Scan the [Face Name] face"         │
└─────────────────────────────────────┘
  │
  ▼
CONTINUE SCANNING (same as normal flow)
```

## State Transitions

```
FaceScanState Transitions:

notScanned ──▶ scanning(0.0) ──▶ scanning(0.5) ──▶ scanning(1.0) ──▶ captured
    ▲             │                                                        │
    │             │                                                        │
    │             ▼                                                        │
    │          error ─────────────────────────────────────────────────────┘
    │             │
    └─────────────┘ (user taps to rescan)

Color Coding:
  notScanned      → ⚪ Gray
  scanning(p)     → 🟡 Yellow (or 🔵 Blue if next)
  captured        → 🟢 Green with checkmark
  error(msg)      → 🔴 Red
```

## Data Flow

```
┌──────────────┐
│ Camera       │
│ Session      │
└──────────────┘
       │
       │ CVPixelBuffer
       ▼
┌──────────────┐
│ Capture      │
│ Pipeline     │
└──────────────┘
       │
       │ Detection Results
       ▼
┌──────────────┐         ┌──────────────┐
│ Enhanced     │◀────────│ Face States  │
│ ViewModel    │ updates │ Dictionary   │
└──────────────┘         └──────────────┘
       │
       │ @Published properties
       ▼
┌──────────────┐
│ SwiftUI      │
│ Views        │
└──────────────┘
       │
       │ User Actions
       ▼
┌──────────────┐
│ ViewModel    │
│ Methods      │
│ • rescanFace │
│ • nextFace   │
│ • reset      │
└──────────────┘
```

## Mini 3D Cube Layout

```
Isometric View of Cube:

        ┌─────────┐
       ╱         ╱│
      ╱   TOP   ╱ │
     ╱    🟢   ╱  │
    ╱─────────╱   │ RIGHT
   │         │    │  🔵
   │  FRONT  │    ╱
   │   ⚪    │   ╱
   │         │  ╱
   └─────────┘─╱

Face States:
• 🟢 Top: Captured (green with ✓)
• 🔵 Right: Next to scan (pulsing blue)
• ⚪ Front: Not scanned (gray)

Hidden faces (Back, Left, Down) accessible by tapping
```

## Button States

```
Action Buttons:

When scanning (< 6 faces):
┌──────────────┬──────────────┐
│ Scan Again   │  Next Face   │
│ (enabled)    │  (depends)   │
└──────────────┴──────────────┘
        │              │
        │              └─▶ Enabled when stable
        │
        └─▶ Always enabled

When complete (6 faces):
┌─────────────────────────────┐
│    Finish Scanning          │
│    (green, enabled)         │
└─────────────────────────────┘

Cancel button always visible below
```

## Performance Metrics

```
Frame Processing Pipeline:

Camera          Throttle       Pipeline         UI Update
30-60 FPS   →   30 FPS    →   Detection    →   60 FPS
                                                Animations

Timing:
• Camera frame: ~16ms (60fps)
• Processing: ~33ms (throttled)
• UI render: ~16ms (60fps)
• Total latency: ~50ms

Memory:
• Base app: ~50MB
• Camera session: ~30MB
• Enhanced state: ~0.2MB
• Total: ~80MB
```

## Color Palette

```
Visual Design Colors:

Success States:
  Green:     #00CC44 (primary)
             #00AA33 (secondary)

Warning States:
  Yellow:    #FFB800
  Orange:    #FF9500

Error States:
  Red:       #FF3B30

Info States:
  Blue:      #007AFF
  Purple:    #AF52DE

Neutral:
  Gray:      #8E8E93
  White:     #FFFFFF (opacity 0.9)

Glassmorphic:
  Backdrop:  ultraThinMaterial
  Border:    white.opacity(0.2)
  Shadow:    black.opacity(0.3)
```
