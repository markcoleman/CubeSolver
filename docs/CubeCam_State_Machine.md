# CubeCam Capture State Machine

## Overview

The CubeCam capture pipeline uses a deterministic state machine to ensure reliable face detection and capture. This document explains the state transitions and debugging approach.

## State Diagram

```
┌─────────┐
│  idle   │ ◄─────────────────────────┐
└────┬────┘                            │
     │ cube detected                   │
     ▼                                 │
┌─────────────┐                        │
│  detecting  │                        │
└──────┬──────┘                        │
       │ stability >= 0.85             │
       │ lighting stable               │
       ▼                                │
┌──────────────────┐                   │
│  stabilizing(p)  │                   │
│  p = 0.0 → 1.0   │                   │
└────────┬─────────┘                   │
         │ p >= 1.0                    │
         │ all conditions met          │
         ▼                              │
    ┌──────────┐                       │
    │capturing │                       │
    └────┬─────┘                       │
         │ success                     │
         ▼                              │
    ┌─────────┐                        │
    │captured │ ───────────────────────┘
    └─────────┘      reset after 0.5s
```

## States

### 1. `idle`
- **Meaning**: No cube detected in frame
- **Next States**: `detecting` (when cube appears)
- **UI**: Shows "Position cube" message

### 2. `detecting`
- **Meaning**: Cube detected but not yet stable
- **Conditions**: 
  - Cube bounding box found by Vision
  - Stability < 0.85 OR lighting unstable
- **Next States**: 
  - `stabilizing(0.0)` (when stability conditions met)
  - `idle` (if cube lost)
- **UI**: Shows "Detecting..." with progress at 0%

### 3. `stabilizing(progress: Double)`
- **Meaning**: Cube is stable, accumulating consecutive stable frames
- **Progress Calculation**: `consecutiveStableFrames / requiredStableFrames`
- **Conditions for progress**:
  - Stability >= 0.85
  - Lighting stable (brightness variance < 15%)
  - Consecutive frames without movement
- **Next States**:
  - `capturing` (when progress >= 1.0 and auto-capture enabled)
  - `detecting` (if stability lost)
  - `idle` (if cube lost)
- **UI**: Shows progress bar and "Stabilizing... X/8 frames"

### 4. `capturing`
- **Meaning**: Capture triggered, processing colors
- **Next States**: 
  - `captured` (on success)
  - `detecting` (on validation failure)
- **UI**: Shows "Capturing..." briefly

### 5. `captured`
- **Meaning**: Face successfully captured
- **Duration**: 0.5 seconds
- **Next States**: `idle` (after reset)
- **UI**: Shows "Captured!" with checkmark

## Key Guards and Conditions

### Concurrent Request Prevention
```swift
guard !isProcessingFrame else { return }
isProcessingFrame = true
defer { isProcessingFrame = false }
```
- Prevents overlapping Vision requests
- Ensures deterministic behavior

### One Capture Per Cycle
```swift
guard !hasCapturedThisCycle else { return }
hasCapturedThisCycle = true
```
- Prevents multiple captures for same stabilization
- Reset when stability lost or after capture

### Auto-Capture Conditions
All must be true:
1. `currentFaceEstimate` is not nil
2. Face not already captured
3. `consecutiveStableFrames >= requiredStableFrames` (default: 8)
4. `stability >= 0.85`
5. `faceEstimateConfidence >= autoCaptureThreshold` (default: 0.8)
6. Time since last capture >= `debounceDelay` (default: 0.4s)
7. `isScanning == true`
8. `captureState == .stabilizing(progress: 1.0)`
9. `!hasCapturedThisCycle`

## Logging

The state machine logs all transitions and conditions:

```swift
print("[CubeCam] 🎥 Processing frame at \(timestamp)")
print("[CubeCam] ✓ Cube detected - confidence: \(detection.confidence)")
print("[CubeCam] 📊 Stability: \(stability), Lighting stable: \(lightingStable)")
print("[CubeCam] ⏳ Stabilizing... Progress: 75% (6/8 frames)")
print("[CubeCam] ✅ All capture conditions met!")
print("[CubeCam] 📸 Starting capture for face: front")
print("[CubeCam] ✅ Successfully captured face: front (1/6)")
print("[CubeCam] 🔄 State transition: detecting → stabilizing(progress: 0.5)")
```

### Log Emoji Legend
- 🎥 Frame processing
- ✓ Detection success
- ❌ Detection failure
- 📊 Stability metrics
- ⏳ Stabilizing progress
- ⏭️ Capture skipped (with reason)
- ✅ Success
- 📸 Capture started
- ⚠️ Warning
- 🔄 State transition/reset

## Debugging Tips

### Issue: "0/6 faces captured" stays at 0

1. **Check logging output** for:
   - Are frames being processed? (🎥 messages)
   - Is cube detected? (✓ Cube detected)
   - What's the stability value? (📊 Stability)
   - Is it stabilizing? (⏳ Stabilizing)
   - Why is capture being skipped? (⏭️ No capture)

2. **Common causes**:
   - Stability never reaches 0.85
   - Lighting unstable (brightness changing)
   - Never reaches 8 consecutive stable frames
   - Face already captured (duplicate detection)
   - Confidence too low
   - Debounce delay not met

### Issue: Progress bar increases but capture never fires

**Check the `shouldAutoCapture()` conditions**:
- Look for "⏭️ No capture" messages
- Each message shows which condition failed
- Example: "⏭️ No capture: Only 6/8 stable frames"

### Issue: Multiple captures of same face

**Should not happen** with new state machine:
- `hasCapturedThisCycle` prevents duplicates
- Check for "⚠️ Already captured this cycle" message

### Issue: Capture fires too quickly

**Adjust parameters**:
```swift
pipeline.requiredStableFrames = 12  // default: 8
pipeline.debounceDelay = 0.6        // default: 0.4
pipeline.stabilityDuration = 0.6    // default: 0.4
```

## Configuration

### Default Values
- `stabilityDuration: 0.4s` - Time window for stability calculation
- `debounceDelay: 0.4s` - Minimum time between captures
- `requiredStableFrames: 8` - Consecutive stable frames needed
- `autoCaptureThreshold: 0.8` - Minimum confidence for auto-capture
- `stabilityMovementThreshold: 0.02` - Max position variance (2% of frame)
- `maxBrightnessChange: 0.15` - Max lighting variance (15%)

### Tuning for Different Scenarios

**Fast capture (less stable)**:
```swift
pipeline.requiredStableFrames = 5
pipeline.debounceDelay = 0.2
```

**Very stable capture (more reliable)**:
```swift
pipeline.requiredStableFrames = 12
pipeline.debounceDelay = 0.6
pipeline.autoCaptureThreshold = 0.9
```

**Poor lighting conditions**:
```swift
pipeline.maxBrightnessChange = 0.25
pipeline.requiredStableFrames = 10
```

## Testing

Run tests with:
```bash
swift test --filter CubeCamCapturePipelineTests
```

Key test areas:
1. State equality and transitions
2. Reset behavior
3. Configuration changes
4. Next face selection
5. Auto-capture flags

## Related Files

- **Core Logic**: `Sources/CubeScanner/CubeCamCapturePipeline.swift`
- **UI Overlay**: `Sources/CubeUI/ScanningOverlay.swift`
- **View Model**: `Sources/CubeScanner/CubeCamViewModel.swift`
- **Tests**: `Tests/CubeScannerTests/CubeScannerTests.swift`
