# Screenshot Automation Guide

This guide explains how to use the automated screenshot capture system for CubeSolver, which supports App Store distribution, GitHub Pages, and documentation.

## Overview

CubeSolver includes three methods for screenshot automation:

1. **Fastlane** - For App Store Connect submissions
2. **UI Tests** - Automated screenshot capture during testing
3. **CI/CD Integration** - GitHub Actions workflows for automated capture

## 📱 Fastlane Screenshot Automation

### Prerequisites

Install fastlane:
```bash
# Using Homebrew
brew install fastlane

# Or using RubyGems
sudo gem install fastlane
```

### Configuration Files

The fastlane configuration is located in the `fastlane/` directory:

- **Fastfile** - Main configuration with screenshot lanes
- **Snapfile** - Screenshot specifications (devices, languages)
- **Appfile** - App identifier and Apple ID (optional)

### Running Screenshot Capture

#### iOS Screenshots

Capture screenshots for iOS devices:

```bash
# Light mode screenshots
fastlane ios screenshots

# Dark mode screenshots
fastlane ios screenshots_dark

# Both light and dark mode
fastlane ios screenshots_all
```

#### macOS Screenshots

Capture screenshots for macOS:

```bash
fastlane mac screenshots

# All macOS screenshots
fastlane mac screenshots_all
```

### Supported Devices

Screenshots are captured for:
- iPhone 15 Pro Max (6.7")
- iPhone 15 Pro (6.1")
- iPhone 15 (6.1")
- iPhone SE 3rd gen (4.7")
- iPad Pro 12.9" (6th gen)
- iPad Pro 11" (4th gen)

### Supported Languages

Currently configured for:
- English (en-US)

To add more languages, edit `fastlane/Snapfile`:

```ruby
languages([
  "en-US",
  "es-ES",  # Spanish
  "fr-FR",  # French
  "de-DE",  # German
  "ja-JP",  # Japanese
  "zh-Hans" # Chinese Simplified
])
```

### Output Directories

Screenshots are saved to:
- `fastlane/screenshots/` - Light mode iOS screenshots
- `fastlane/screenshots_dark/` - Dark mode iOS screenshots
- `fastlane/screenshots_mac/` - macOS screenshots
- `docs/images/appstore/` - Copied for documentation (light mode)
- `docs/images/appstore_dark/` - Copied for documentation (dark mode)

## 🧪 UI Test Screenshot Capture

### Manual Execution

Run UI tests with screenshot capture:

```bash
# Run UI tests
xcodebuild test \
  -scheme CubeSolver \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -resultBundlePath .build/TestResults.xcresult

# Extract screenshots
./scripts/extract_screenshots.sh
```

### Screenshot Test Methods

The `CubeSolverUITests` class includes several test methods that capture screenshots:

- `testMainInterfaceElements()` - Main app interface
- `testScrambleFlow()` - Scrambled cube state
- `testSolveFlow()` - Solution display
- `testResetFlow()` - Reset functionality
- `testManualInputInterface()` - Manual input UI
- `testScreenshotGallery()` - Comprehensive gallery

### Adding Custom Screenshots

To capture custom screenshots in UI tests:

```swift
func testMyFeature() throws {
    // Your test code here
    
    // Capture screenshot
    let screenshot = app.screenshot()
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = "MyFeatureName"
    attachment.lifetime = .keepAlways  // Important!
    add(attachment)
}
```

### Extracting Screenshots

Use the provided script to extract screenshots from test results:

```bash
# Default: Extract from .build/TestResults.xcresult to docs/images/screenshots
./scripts/extract_screenshots.sh

# Custom paths
./scripts/extract_screenshots.sh <xcresult-path> <output-dir>
```

## 🤖 GitHub Actions Automation

### Workflows

#### Screenshot Capture Workflow

The `capture-screenshots.yml` workflow runs automatically on:
- Push to `main` branch
- Pull requests to `main`
- Manual trigger via workflow_dispatch

**What it does:**
1. Builds the app for iOS
2. Runs UI tests with screenshot capture
3. Extracts screenshots from test results
4. Uploads screenshots as artifacts
5. Commits screenshots to `docs/images/screenshots/` (on main branch only)

#### Manual Trigger

Trigger screenshot capture manually:

1. Go to Actions tab in GitHub
2. Select "Capture Screenshots" workflow
3. Click "Run workflow"
4. Choose branch and options
5. Click "Run workflow"

### Viewing Generated Screenshots

After the workflow completes:

1. **As Artifacts**: Download from workflow run
   - Go to Actions → Workflow run → Artifacts
   - Download `ios-screenshots` artifact

2. **In Repository**: Check `docs/images/screenshots/`
   - Automatically committed on main branch
   - Available at `https://markcoleman.github.io/CubeSolver/images/screenshots/`

### Integration with Release Workflow

Screenshots can be automatically included in releases:

```yaml
# In .github/workflows/release.yml
- name: Generate screenshots
  run: |
    fastlane ios screenshots_all
    
- name: Upload to release
  uses: softprops/action-gh-release@v2
  with:
    files: |
      fastlane/screenshots/**/*.png
```

## 📸 Screenshot Organization

### Directory Structure

```
docs/images/
├── screenshots/          # UI test screenshots (auto-generated)
│   ├── MainInterface.png
│   ├── ScrambledCube.png
│   ├── SolutionSteps.png
│   └── ...
├── appstore/            # Fastlane iOS screenshots (light mode)
│   ├── en-US/
│   │   ├── iPhone15ProMax/
│   │   ├── iPhone15Pro/
│   │   └── ...
├── appstore_dark/       # Fastlane iOS screenshots (dark mode)
│   └── en-US/
│       └── ...
└── macos/              # macOS screenshots
    └── ...
```

### Naming Conventions

**UI Test Screenshots:**
- Use descriptive names: `MainInterface.png`, `ScrambledCube.png`
- Set via `attachment.name` in test code

**Fastlane Screenshots:**
- Organized by device and language
- Numbered by capture order: `1_MainScreen.png`, `2_SolveScreen.png`

## 📚 Using Screenshots in Documentation

### In README

Reference screenshots using relative paths:

```markdown
![Main Interface](docs/images/screenshots/MainInterface.png)
```

### In GitHub Pages

The documentation site at `https://markcoleman.github.io/CubeSolver` can include screenshots:

```html
<img src="images/screenshots/MainInterface.png" alt="Main Interface" />
```

### Screenshot Gallery

Create a gallery page:

```markdown
## Screenshots

### Main Interface
![Main Interface](images/screenshots/01_InitialState.png)

### Scrambled Cube
![Scrambled](images/screenshots/02_Scrambled.png)

### Solution Display
![Solution](images/screenshots/03_SolutionShown.png)
```

## 🔧 Troubleshooting

### Fastlane Issues

**Problem**: Fastlane not found
```bash
# Install fastlane
brew install fastlane
# or
sudo gem install fastlane
```

**Problem**: Simulator not found
```bash
# List available simulators
xcrun simctl list devices

# Create a simulator if needed
xcrun simctl create "iPhone 15 Pro" "iPhone 15 Pro" "iOS-17-2"
```

### UI Test Issues

**Problem**: No screenshots captured
- Ensure `attachment.lifetime = .keepAlways` is set
- Verify UI tests are running successfully
- Check that test bundle path is correct

**Problem**: Screenshots not extracted
- Verify xcresult bundle exists
- Check script has execute permissions: `chmod +x scripts/extract_screenshots.sh`
- Run script with verbose output

### GitHub Actions Issues

**Problem**: Workflow fails on screenshot capture
- Check macOS runner availability
- Verify Xcode version compatibility
- Review workflow logs for specific errors

**Problem**: Screenshots not committed
- Ensure workflow has write permissions
- Check that screenshots directory is not in .gitignore
- Verify git configuration in workflow

## 🚀 Best Practices

### For App Store Submissions

1. **Capture in Multiple Languages**: Update `Snapfile` with target languages
2. **Use All Device Sizes**: Cover all required device types
3. **Include Dark Mode**: Users appreciate seeing both themes
4. **Show Key Features**: Focus on unique selling points
5. **Keep Updated**: Regenerate screenshots with each major release

### For Documentation

1. **Consistent Naming**: Use clear, descriptive names
2. **Optimize Size**: Compress images before committing
3. **Update Regularly**: Keep screenshots current with UI changes
4. **Accessibility**: Provide alt text for all images
5. **Organization**: Group related screenshots

### For CI/CD

1. **Run on Main Only**: Avoid unnecessary screenshot generation on feature branches
2. **Use Artifacts**: Store screenshots as artifacts for review
3. **Conditional Commits**: Only commit if screenshots change
4. **Cache Dependencies**: Speed up workflow with caching
5. **Monitor Costs**: Be aware of CI/CD minutes usage

## 📝 Examples

### Complete Screenshot Capture Pipeline

```bash
# 1. Run UI tests with screenshot capture
xcodebuild test \
  -scheme CubeSolver \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -resultBundlePath .build/TestResults.xcresult

# 2. Extract screenshots from tests
./scripts/extract_screenshots.sh

# 3. Generate App Store screenshots with fastlane
fastlane ios screenshots_all

# 4. Commit to repository
git add docs/images/
git commit -m "Update screenshots"
git push
```

### Adding Screenshots to Release Notes

In release workflow or manually:

```markdown
## 📸 Screenshots

### Main Features

![Feature 1](https://markcoleman.github.io/CubeSolver/images/screenshots/MainInterface.png)
![Feature 2](https://markcoleman.github.io/CubeSolver/images/screenshots/SolutionSteps.png)
```

## 🔗 Related Documentation

- [UI Testing Guide](UI_TESTING_GUIDE.md)
- [DevOps Summary](DEVOPS_SUMMARY.md)
- [Contributing Guidelines](../CONTRIBUTING.md)
- [Fastlane Documentation](https://docs.fastlane.tools/getting-started/ios/screenshots/)

## ❓ Need Help?

- Check [GitHub Discussions](https://github.com/markcoleman/CubeSolver/discussions)
- Open an [Issue](https://github.com/markcoleman/CubeSolver/issues)
- Review [Contributing Guidelines](../CONTRIBUTING.md)
