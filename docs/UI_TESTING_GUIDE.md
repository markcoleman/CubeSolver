# UI Testing Guide

This guide explains how to run and create UI tests for CubeSolver, including screenshot capture functionality.

## Overview

CubeSolver includes a comprehensive UI test suite that:
- Validates all user interface elements
- Tests complete user workflows
- Captures screenshots for documentation
- Validates accessibility features
- Ensures consistent behavior across platforms

## Running UI Tests

### In Xcode

1. Open `CubeSolver.xcodeproj` in Xcode
2. Select the `CubeSolverUITests` scheme
3. Choose a simulator or device
4. Press `Cmd + U` or Product → Test
5. Tests will run automatically

### From Command Line

```bash
# Run all UI tests
xcodebuild test -project CubeSolver.xcodeproj \
  -scheme CubeSolverUITests \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test
xcodebuild test -project CubeSolver.xcodeproj \
  -scheme CubeSolverUITests \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:CubeSolverUITests/testMainInterfaceElements
```

## Test Suite Organization

### Test Files

- `CubeSolver/UITests/CubeSolverUITests.swift` - Main UI test suite

### Test Categories

#### 1. Main Interface Tests
Tests for the primary app interface.

**testMainInterfaceElements**
- Validates all UI elements exist
- Checks button labels and identifiers
- Captures main interface screenshot

**testScrambleFlow**
- Tests scramble functionality
- Captures before and after screenshots
- Validates cube state change

**testSolveFlow**
- Tests solve functionality
- Validates solution steps appear
- Captures solution screenshot

**testResetFlow**
- Tests reset functionality
- Validates cube returns to solved state
- Captures reset state screenshot

#### 2. Manual Input Tests
Tests for the manual cube input feature.

**testManualInputInterface**
- Validates manual input UI elements
- Checks face selector exists
- Checks color picker exists
- Checks editable grid exists
- Captures manual input screenshot

**testManualInputColorSelection**
- Tests color selection workflow
- Validates color button interactions
- Captures color selection screenshot

#### 3. Accessibility Tests
Tests for accessibility compliance.

**testAccessibilityLabels**
- Validates all accessibility identifiers
- Checks main UI elements
- Verifies button accessibility

**testAccessibilityHints**
- Tests button hittability
- Validates interactive elements
- Ensures VoiceOver compatibility

#### 4. Screenshot Gallery Tests
Comprehensive screenshot capture for documentation.

**testScreenshotGallery**
- Captures initial state
- Captures scrambled state
- Captures solution display
- Captures manual input interface
- Creates numbered gallery

## Screenshot Capture

### How Screenshots Are Captured

Screenshots are captured using XCTest's built-in screenshot functionality:

```swift
let screenshot = app.screenshot()
let attachment = XCTAttachment(screenshot: screenshot)
attachment.name = "ScreenshotName"
attachment.lifetime = .keepAlways
add(attachment)
```

### Screenshot Locations

Screenshots are saved to:
- **Xcode**: Test Results → Attachments
- **Command Line**: DerivedData test results

### Viewing Screenshots

**In Xcode:**
1. Run tests
2. Open Test Navigator (Cmd + 6)
3. Click on a test
4. Expand test result
5. Click on screenshot attachment

**Exporting Screenshots:**
1. Right-click on attachment
2. Select "Export"
3. Choose destination

### Screenshot Naming Convention

Screenshots are named descriptively:
- `MainInterface` - Initial app screen
- `SolvedCube` - Cube in solved state
- `ScrambledCube` - Cube after scrambling
- `SolutionSteps` - Solution display
- `ResetCube` - Cube after reset
- `ManualInputInterface` - Manual input screen
- `ColorSelected` - After color selection
- `01_InitialState` - Gallery screenshot 1
- `02_Scrambled` - Gallery screenshot 2
- etc.

## Writing New UI Tests

### Basic Test Structure

```swift
func testYourFeature() throws {
    // 1. Setup - Get UI elements
    let button = app.buttons["buttonIdentifier"]
    
    // 2. Action - Perform interaction
    XCTAssertTrue(button.exists)
    button.tap()
    
    // 3. Wait - Allow UI to update
    Thread.sleep(forTimeInterval: 0.5)
    
    // 4. Verify - Check expected results
    let resultElement = app.otherElements["resultIdentifier"]
    XCTAssertTrue(resultElement.exists)
    
    // 5. Screenshot - Capture state
    let screenshot = app.screenshot()
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = "YourFeature"
    attachment.lifetime = .keepAlways
    add(attachment)
}
```

### Finding UI Elements

**By Accessibility Identifier:**
```swift
app.buttons["scrambleButton"]
app.otherElements["cubeView"]
app.staticTexts["mainTitle"]
```

**By Label:**
```swift
app.buttons["Scramble"]
app.staticTexts["Rubik's Cube Solver"]
```

**By Type:**
```swift
app.buttons.firstMatch
app.textFields.element(boundBy: 0)
```

### Common UI Test Patterns

**Tap a Button:**
```swift
let button = app.buttons["buttonIdentifier"]
XCTAssertTrue(button.exists)
button.tap()
```

**Wait for Element:**
```swift
let element = app.otherElements["elementIdentifier"]
XCTAssertTrue(element.waitForExistence(timeout: 2))
```

**Verify Element Exists:**
```swift
XCTAssertTrue(app.buttons["buttonIdentifier"].exists)
```

**Check Element Label:**
```swift
let title = app.staticTexts["mainTitle"]
XCTAssertEqual(title.label, "Expected Text")
```

**Verify Element is Hittable:**
```swift
XCTAssertTrue(app.buttons["button"].isHittable)
```

## Best Practices

### 1. Use Accessibility Identifiers

Always add accessibility identifiers to UI elements:
```swift
.accessibilityIdentifier("uniqueIdentifier")
```

### 2. Wait for UI Updates

After interactions, wait for UI to update:
```swift
Thread.sleep(forTimeInterval: 0.5)
// or
element.waitForExistence(timeout: 2)
```

### 3. Clean Test State

Each test should start from a clean state:
```swift
override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launch()
}
```

### 4. Descriptive Test Names

Use clear, descriptive test names:
```swift
func testUserCanScrambleAndSolveCube() throws {
    // Test code
}
```

### 5. Screenshot Everything

Capture screenshots for:
- Initial state
- After user actions
- Error states
- Final results

### 6. Test Real Workflows

Test complete user journeys, not just individual features:
```swift
func testCompleteScrambleAndSolveWorkflow() throws {
    // 1. Verify initial state
    // 2. Scramble cube
    // 3. Verify scrambled
    // 4. Solve cube
    // 5. Verify solution appears
    // 6. Capture all states
}
```

## Troubleshooting

### Tests Fail to Find Elements

**Problem**: `XCTAssertTrue(element.exists)` fails
**Solutions**:
- Verify accessibility identifier is correct
- Check element is visible on screen
- Ensure UI has finished loading
- Use `waitForExistence(timeout:)`

### Screenshots Are Empty

**Problem**: Screenshots show blank screen
**Solutions**:
- Add delay before screenshot: `Thread.sleep(forTimeInterval: 0.5)`
- Ensure element is on screen
- Check simulator display scale

### Tests Time Out

**Problem**: Tests hang or time out
**Solutions**:
- Increase timeout values
- Check for infinite animations
- Verify app isn't waiting for user input
- Disable Reduce Motion in simulator

### Tests Pass in Xcode But Fail in CI

**Solutions**:
- Ensure CI uses same iOS version
- Check simulator configuration
- Verify CI has sufficient permissions
- Add longer timeouts for CI environment

## Advanced Topics

### Testing Different Device Sizes

```swift
// Run tests on multiple devices
xcodebuild test -destination 'platform=iOS Simulator,name=iPhone SE'
xcodebuild test -destination 'platform=iOS Simulator,name=iPhone 15 Pro Max'
xcodebuild test -destination 'platform=iOS Simulator,name=iPad Pro'
```

### Testing Accessibility

```swift
func testVoiceOverLabels() throws {
    let button = app.buttons["scrambleButton"]
    XCTAssertNotNil(button.label)
    XCTAssertTrue(button.isHittable)
}
```

### Testing Gestures

```swift
func testSwipeGesture() throws {
    let element = app.otherElements["swipeableElement"]
    element.swipeLeft()
    element.swipeRight()
}
```

### Performance Testing

```swift
func testPerformanceExample() throws {
    measure {
        // Code to measure performance
        app.buttons["scrambleButton"].tap()
    }
}
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: UI Tests
on: [push, pull_request]
jobs:
  ui-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run UI Tests
        run: |
          xcodebuild test \
            -project CubeSolver.xcodeproj \
            -scheme CubeSolverUITests \
            -destination 'platform=iOS Simulator,name=iPhone 15'
      - name: Upload Screenshots
        uses: actions/upload-artifact@v2
        with:
          name: ui-test-screenshots
          path: DerivedData/Logs/Test/Attachments
```

## Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [UI Testing Guide](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/)
- [WWDC Sessions on Testing](https://developer.apple.com/videos/frameworks/testing)

---

For questions or issues, please open an issue on GitHub.
