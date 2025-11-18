# Screenshot Automation Quick Reference

Quick reference for CubeSolver screenshot automation.

## 🚀 Quick Commands

### Fastlane (Local)

```bash
# iOS screenshots (light mode)
fastlane ios screenshots

# iOS screenshots (dark mode)
fastlane ios screenshots_dark

# All iOS screenshots (light + dark)
fastlane ios screenshots_all

# macOS screenshots
fastlane mac screenshots_all
```

### UI Tests (Local)

```bash
# Run UI tests and extract screenshots
xcodebuild test \
  -scheme CubeSolver \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -resultBundlePath .build/TestResults.xcresult

# Extract screenshots
./scripts/extract_screenshots.sh
```

### GitHub Actions

```bash
# Trigger screenshot capture workflow manually
gh workflow run capture-screenshots.yml

# Or via GitHub UI:
# Actions → Capture Screenshots → Run workflow
```

## 📁 Output Directories

| Directory | Purpose | Source |
|-----------|---------|--------|
| `docs/images/screenshots/` | UI test screenshots | GitHub Actions or manual |
| `fastlane/screenshots/` | iOS light mode (temp) | Fastlane |
| `fastlane/screenshots_dark/` | iOS dark mode (temp) | Fastlane |
| `docs/images/appstore/` | iOS light mode (docs) | Copied from fastlane |
| `docs/images/appstore_dark/` | iOS dark mode (docs) | Copied from fastlane |
| `docs/images/macos/` | macOS screenshots | Fastlane or manual |

## 📱 Supported Devices

- iPhone 15 Pro Max (6.7")
- iPhone 15 Pro (6.1")
- iPhone 15 (6.1")
- iPhone SE 3rd gen (4.7")
- iPad Pro 12.9" (6th gen)
- iPad Pro 11" (4th gen)

## 🌍 Supported Languages

Currently: `en-US`

To add more, edit `fastlane/Snapfile`:
```ruby
languages([
  "en-US",
  "es-ES",
  "fr-FR"
])
```

## 🔧 Common Tasks

### Add Custom Screenshot to UI Tests

```swift
func testMyFeature() throws {
    // Your test code
    
    let screenshot = app.screenshot()
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = "MyFeatureName"
    attachment.lifetime = .keepAlways  // Important!
    add(attachment)
}
```

### Extract Specific xcresult

```bash
./scripts/extract_screenshots.sh \
  path/to/custom.xcresult \
  output/directory
```

### Commit Screenshots

```bash
git add docs/images/
git commit -m "Update screenshots"
git push
```

## ⚙️ Workflow Triggers

| Event | Branch | Action |
|-------|--------|--------|
| Push | `main` | Auto-capture & commit |
| PR | → `main` | Capture & upload artifacts |
| Manual | Any | Capture via workflow_dispatch |

## 📚 Documentation

- Full Guide: [SCREENSHOT_AUTOMATION.md](SCREENSHOT_AUTOMATION.md)
- Directory Info: [images/README.md](images/README.md)
- UI Testing: [UI_TESTING_GUIDE.md](UI_TESTING_GUIDE.md)

## 🐛 Troubleshooting

**No screenshots captured?**
```bash
# Verify tests ran
ls -la .build/TestResults.xcresult

# Check test logs
xcrun xcresulttool get --path .build/TestResults.xcresult
```

**Fastlane fails?**
```bash
# Check simulator availability
xcrun simctl list devices

# Install fastlane
brew install fastlane
```

**Workflow doesn't commit?**
- Check workflow permissions (needs `contents: write`)
- Verify not in a fork (can't push to main)
- Ensure screenshots actually changed

## 📞 Support

- [GitHub Issues](https://github.com/markcoleman/CubeSolver/issues)
- [Discussions](https://github.com/markcoleman/CubeSolver/discussions)
- [Contributing Guide](../CONTRIBUTING.md)
