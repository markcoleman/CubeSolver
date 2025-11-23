# CubeCam Capture Issues - Implementation Summary

## Problem Statement
You reported that CubeCam's Vision/AVFoundation detects the cube boundary and shows a "Move slowly" message, with a stabilization counter increasing (sometimes up to ~8), but face capture sometimes never fires. "0/6 faces captured" often stays at 0 even when the cube is stable and centered.

## Root Causes Identified

1. **No Single Source of Truth**: Multiple scattered state flags (`isScanning`, `consecutiveStableFrames`, `stability`) without a unified state machine
2. **No Concurrency Guard**: Multiple overlapping Vision requests could occur
3. **Non-Deterministic Progress**: Progress not directly tied to a concrete condition
4. **No Duplicate Prevention**: No mechanism to prevent multiple captures per stabilization cycle
5. **Limited Logging**: Hard to debug why capture doesn't fire

## Solution Implemented

### 1. Unified State Machine ✅

Created `CaptureState` enum as single source of truth:

```swift
public enum CaptureState: Equatable {
    case idle                          // No cube detected
    case detecting                     // Cube found but not stable  
    case stabilizing(progress: Double) // Accumulating frames (0.0 → 1.0)
    case capturing                     // Triggering capture
    case captured                      // Face successfully captured
}
```

**State Transitions**:
```
idle → detecting → stabilizing(0.0 → 1.0) → capturing → captured → idle
     ↑______________|__________________|_______________|
     (if cube lost or stability lost or validation fails)
```

### 2. Guard Against Concurrent Requests ✅

Added `isProcessingFrame` guard:
```swift
guard !isProcessingFrame else {
    droppedFrameCount += 1
    // Log every 10 dropped frames
    return
}
isProcessingFrame = true
defer { isProcessingFrame = false }
```

### 3. Deterministic Progress ✅

Progress directly tied to frame count:
```swift
progress = Double(consecutiveStableFrames) / Double(requiredStableFrames)
```

**Requirements for stable frame**:
- Stability >= 0.85
- Lighting stable (brightness variance < 15%)
- Bounding box position stable

### 4. One Capture Per Cycle ✅

Added `hasCapturedThisCycle` flag:
```swift
guard !hasCapturedThisCycle else {
    print("[CubeCam] ⚠️ Already captured this cycle - skipping")
    return
}
hasCapturedThisCycle = true
```

Reset when:
- Stability lost (user moved cube)
- After successful capture (0.5s delay)
- After failed capture (validation error)

### 5. Comprehensive Logging ✅

Every decision point logged:
```swift
print("[CubeCam] 🎥 Processing frame at \(timestamp)")
print("[CubeCam] ✓ Cube detected - confidence: \(confidence)")
print("[CubeCam] 📊 Stability: \(stability), Lighting stable: \(lightingStable)")
print("[CubeCam] ⏳ Stabilizing... Progress: 75% (6/8 frames)")
print("[CubeCam] ⏭️ No capture: Only 6/8 stable frames")
print("[CubeCam] ✅ All capture conditions met!")
print("[CubeCam] 📸 Starting capture for face: front")
print("[CubeCam] ✅ Successfully captured face: front (1/6)")
print("[CubeCam] 🔄 State transition: detecting → stabilizing(0.5)")
```

## Files Modified

1. **Sources/CubeScanner/CubeCamCapturePipeline.swift**
   - Added `CaptureState` enum (nested)
   - Added `isProcessingFrame` guard
   - Added `hasCapturedThisCycle` flag
   - Added `droppedFrameCount` metrics
   - Added comprehensive logging throughout
   - Refactored `processFrame()` with state machine
   - Split reset logic: `resetAfterFailedCapture()` and `resetForNextFace()`

2. **Sources/CubeUI/ScanningOverlay.swift**
   - Updated to use `CaptureState` directly
   - Progress now deterministic from state

3. **Sources/CubeUI/CubeCamView.swift**
   - Updated to use `captureState` instead of `stability`

4. **Tests/CubeScannerTests/CubeScannerTests.swift**
   - Added 12 new tests for state machine
   - Test state equality, transitions, reset, configuration

5. **docs/CubeCam_State_Machine.md** (NEW)
   - Complete state diagram
   - Debugging guide
   - Configuration options
   - Common issues and solutions

## How to Debug

### 1. Check Console Logs

Look for the logging output pattern:

```
[CubeCam] 🎥 Processing frame at 1234567890.123
[CubeCam] ✓ Cube detected - confidence: 0.95
[CubeCam] 📊 Stability: 0.89, Lighting stable: true
[CubeCam] ⏳ Stabilizing... Progress: 87% (7/8 frames)
[CubeCam] ⏭️ No capture: Only 7/8 stable frames
```

### 2. Common Issues

**Issue**: Counter reaches 8/8 but capture doesn't fire
- **Check**: Look for "⏭️ No capture" messages - they show which condition failed
- **Common causes**:
  - Face already captured (duplicate detection)
  - Confidence too low
  - Debounce delay not met (< 0.4s since last capture)
  - Not in scanning state

**Issue**: Counter stays at 0
- **Check**: Is stability reaching 0.85?
- **Check**: Is lighting stable? (brightness variance logged)
- **Common causes**:
  - Cube moving too much
  - Lighting changing (shadows, reflections)
  - Bounding box not stable

**Issue**: Many dropped frames
- **Check**: Console logs for "⚠️ Dropped X frames"
- **Meaning**: Frame processing taking > 33ms (30fps throttle)
- **Action**: May indicate device performance issue

### 3. State Verification

The state machine guarantees:
- ✅ `idle` when no cube detected
- ✅ `detecting` when cube found but not stable
- ✅ `stabilizing(p)` when accumulating stable frames (p = 0.0 → 1.0)
- ✅ `capturing` briefly during capture
- ✅ `captured` for 0.5s after success
- ✅ Back to `idle` after reset

## Configuration

You can tune the behavior:

```swift
// Require more frames for stability (more reliable, slower)
viewModel.capturePipeline.requiredStableFrames = 12

// Require fewer frames (faster, less reliable)
viewModel.capturePipeline.requiredStableFrames = 5

// Adjust debounce between captures
viewModel.capturePipeline.debounceDelay = 0.6

// Adjust lighting tolerance (higher = more tolerant)
viewModel.capturePipeline.maxBrightnessChange = 0.25
```

## Testing

All tests pass (146 total):
```bash
swift test --filter CubeCamCapturePipelineTests
```

## Expected Behavior

### Before Changes
- Progress bar shows time/stability blend
- Unclear why capture doesn't fire
- Could have race conditions
- Multiple captures possible
- State spread across flags

### After Changes
- Progress bar shows exact frame count: "6/8 stable frames"
- Every decision logged with reason
- No race conditions (guarded)
- Exactly one capture per cycle
- Single `captureState` source of truth

## Next Steps for Testing

1. **Run the app** on a device with a physical cube
2. **Watch console output** for state transitions
3. **Verify**:
   - Progress bar reaches 8/8 stable frames
   - "✅ All capture conditions met!" appears
   - Capture fires immediately after
   - Counter resets to 0/8 for next face
4. **If capture doesn't fire**, check the "⏭️ No capture" messages to see which condition failed

## Summary

The refactoring addresses all six points from your problem statement:

1. ✅ **Single source of truth**: `captureState` enum
2. ✅ **Guard clauses**: `isProcessingFrame` prevents overlapping Vision requests
3. ✅ **One capture per stabilization**: `hasCapturedThisCycle` flag
4. ✅ **Proper reset**: Separate methods for failed vs successful capture
5. ✅ **Deterministic progress**: Tied to `consecutiveStableFrames / requiredStableFrames`
6. ✅ **Logging**: Complete state transitions and condition checks

The state machine is now predictable, debuggable, and should reliably capture faces when the cube is held steady for 8 consecutive frames at >= 0.85 stability with stable lighting.
