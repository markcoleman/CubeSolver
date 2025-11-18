# CubeSolver Screenshots

This directory contains screenshots for documentation, GitHub Pages, and App Store submissions.

## Directory Structure

### `screenshots/`
Auto-generated screenshots from UI tests via GitHub Actions. These capture:
- Main interface
- Scrambled cube states
- Solution displays
- Manual input interface
- Accessibility features

**Source**: CubeSolverUITests → GitHub Actions workflow
**Format**: PNG files with descriptive names

### `appstore/`
Fastlane-generated screenshots for App Store Connect submission (light mode).
Organized by:
- Language (e.g., en-US, es-ES)
- Device type (iPhone 15 Pro Max, iPad Pro, etc.)

**Source**: `fastlane ios screenshots` or `fastlane ios screenshots_all`
**Format**: PNG files, organized by fastlane structure

### `appstore_dark/`
Fastlane-generated screenshots for App Store Connect submission (dark mode).
Same organization as `appstore/`.

**Source**: `fastlane ios screenshots_dark` or `fastlane ios screenshots_all`
**Format**: PNG files, organized by fastlane structure

### `macos/`
Screenshots for macOS App Store submission.

**Source**: `fastlane mac screenshots` or manual capture
**Format**: PNG files

## Features to Showcase

When capturing screenshots, ensure they demonstrate:

1. **Universal App**: Running on iPhone, iPad, macOS
2. **Glassmorphic Design**: Beautiful UI with glass effects
3. **Cube Solving**: Scramble, solve, and solution steps
4. **Manual Input**: User-friendly cube configuration
5. **AR Features**: (Future) AR solving assistant
6. **Accessibility**: VoiceOver and Dynamic Type support

## Generating Screenshots

### Automated (Recommended)

**Via GitHub Actions:**
1. Push to main branch or trigger "Capture Screenshots" workflow
2. Screenshots automatically generated and committed to `screenshots/`

**Via Fastlane:**
```bash
# iOS screenshots (all devices, light and dark)
fastlane ios screenshots_all

# macOS screenshots
fastlane mac screenshots_all
```

**Via UI Tests:**
```bash
# Run tests and extract screenshots
xcodebuild test -scheme CubeSolver -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -resultBundlePath .build/TestResults.xcresult
./scripts/extract_screenshots.sh
```

### Manual Capture

**iOS/iPadOS:**
1. Run app in Simulator or on device
2. Cmd+S (Simulator) or Power+Volume Up (device)
3. Save to appropriate directory

**macOS:**
1. Run app on macOS
2. Cmd+Shift+4 or use screencapture tool
3. Save to `macos/` directory

## Usage in Documentation

Reference screenshots in markdown:
```markdown
![Main Interface](docs/images/screenshots/MainInterface.png)
```

Or in HTML:
```html
<img src="images/screenshots/MainInterface.png" alt="Main Interface" width="300">
```

## Best Practices

1. **Keep Current**: Regenerate screenshots with UI changes
2. **Optimize Size**: Compress images before committing large files
3. **Descriptive Names**: Use clear, searchable filenames
4. **Alt Text**: Always provide accessibility descriptions
5. **Consistent Style**: Maintain uniform status bar and content

## Related Documentation

See [SCREENSHOT_AUTOMATION.md](../SCREENSHOT_AUTOMATION.md) for complete automation guide.
