# Local Development Environment Setup

This guide helps you set up your local development environment to match the CI/CD pipeline configuration, ensuring "it works on my machine" actually means "it works everywhere."

## 🎯 Quick Start Checklist

Before you start development, ensure your environment matches CI:

- [ ] Xcode 15.2 or 15.3 installed (CI uses both)
- [ ] macOS 14.0+ (Sonoma)
- [ ] Swift 5.9+ toolchain
- [ ] SwiftLint installed
- [ ] Git configured with your credentials
- [ ] Xcode Command Line Tools installed

## 📋 Environment Requirements

### Xcode Version

**CI Configuration:** macOS 14 runners with Xcode 15.2 and 15.3 (matrix build)

**Local Requirement:** Install Xcode 15.2 or 15.3

```bash
# Check your current Xcode version
xcodebuild -version

# Expected output:
# Xcode 15.2 (or 15.3)
# Build version 15C500b (or similar)
```

**To install a specific Xcode version:**
1. Download from [Apple Developer Downloads](https://developer.apple.com/download/all/)
2. Install and set as active:
```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

**For managing multiple Xcode versions:**
```bash
# Use xcodes (recommended): https://github.com/RobotsAndPencils/xcodes
brew install xcodes
xcodes install 15.2
xcodes select 15.2
```

### macOS Version

**CI Configuration:** `runs-on: macos-14`

**Local Requirement:** macOS 14.0+ (Sonoma)

```bash
# Check your macOS version
sw_vers

# ProductVersion should be 14.0 or higher
```

### Swift Version

**Package Requirement:** Swift 5.9+ (declared in Package.swift)

**Xcode Project Setting:** Currently set to 5.0 (⚠️ **mismatch - see Fix below**)

```bash
# Check Swift version
swift --version

# Expected: Swift version 5.9.x or higher
```

### Platform SDK Versions

**From Package.swift:**
- iOS 17.0+
- macOS 14.0+
- watchOS 10.0+

**From Xcode Project:**
- IPHONEOS_DEPLOYMENT_TARGET = 17.0
- MACOSX_DEPLOYMENT_TARGET = 14.0

## 🔧 Initial Setup

### 1. Clone the Repository

```bash
git clone https://github.com/markcoleman/CubeSolver.git
cd CubeSolver
```

### 2. Install Dependencies

#### SwiftLint

SwiftLint is required and runs with `--strict` mode in CI.

```bash
# Using Homebrew (recommended)
brew install swiftlint

# Verify installation
swiftlint version

# Expected: 0.50.0 or higher
```

#### Swift Package Dependencies

```bash
# Resolve Swift Package Manager dependencies (CI does this)
swift package resolve

# This creates/updates Package.resolved and downloads dependencies
```

### 3. Verify Build Settings Match CI

The CI pipeline uses **Swift Package Manager** commands, not `xcodebuild` with the Xcode project:

```bash
# CI runs these commands:
swift package resolve
swift build
swift test --enable-code-coverage --parallel
```

## 🏗️ Building Locally

### Option 1: Swift Package Manager (Matches CI Exactly)

This is what the CI pipeline uses, so it's the most reliable way to ensure parity:

```bash
# Clean build
swift package clean

# Build for debugging
swift build

# Build for release
swift build -c release

# Run tests with code coverage (matches CI)
swift test --enable-code-coverage --parallel

# Build specific target
swift build --target CubeCore
```

**Success Criteria:** All commands should complete without errors, matching CI behavior.

### Option 2: Xcode IDE

Opening the Xcode project allows for IDE features but may have different build settings:

```bash
# Open in Xcode
open CubeSolver.xcodeproj
```

**Important Xcode Settings to Verify:**

1. **Active Scheme:** Select "CubeSolver" scheme
2. **Build Configuration:** Debug (for development) or Release (for testing production builds)
3. **Destination:** 
   - "My Mac" for macOS
   - "iPhone 15 Pro" simulator (or any iOS 17+ device) for iOS
   - "Any iOS Device" for generic iOS build

**Build in Xcode:**
- `Cmd + B` to build
- `Cmd + U` to run tests
- `Cmd + R` to run the app

## ⚠️ Known Discrepancies and Fixes

### Swift Version Mismatch

**Issue:** The Xcode project has `SWIFT_VERSION = 5.0` but `Package.swift` requires Swift 5.9.

**Impact:** This can cause build failures when using modern Swift 5.9+ features.

**Fix:** Update Xcode project build settings:

1. **Via Xcode UI:**
   - Open `CubeSolver.xcodeproj` in Xcode
   - Select the project in the navigator
   - Select the "CubeSolver" target
   - Go to "Build Settings" tab
   - Search for "Swift Language Version"
   - Change from "Swift 5" to "Swift 5.9" (or later)
   - Repeat for all configurations (Debug, Release)

2. **Via Command Line (after making changes):**
   ```bash
   # Verify the change
   grep "SWIFT_VERSION" CubeSolver.xcodeproj/project.pbxproj
   # Should show: SWIFT_VERSION = 5.9;
   ```

**Validation:**
```bash
# After the fix, both should succeed:
swift build        # Uses Package.swift (Swift 5.9)
xcodebuild build   # Uses project settings (should now also be 5.9)
```

### SPM Package Resolution

**Issue:** Local package cache might differ from CI.

**Fix:**
```bash
# Clear and re-resolve packages to match CI
rm -rf .build
rm -rf ~/Library/Caches/org.swift.swiftpm
swift package reset
swift package resolve
swift build
```

### SwiftLint Strict Mode

**Issue:** CI runs SwiftLint with `--strict` flag, which treats warnings as errors.

**Fix:** Always run linting locally before pushing:

```bash
# Run SwiftLint the same way CI does
swiftlint lint --strict

# Fix auto-fixable issues
swiftlint --fix

# Run from specific directory
cd CubeSolver
swiftlint lint --strict
```

## 🧪 Testing Locally

### Unit Tests

Match the CI test command exactly:

```bash
# Run all tests with code coverage and parallel execution (CI mode)
swift test --enable-code-coverage --parallel

# Run tests for a specific module
swift test --filter CubeCoreTests

# Run a specific test
swift test --filter CubeCoreTests.testCubeStateInitialization
```

### Code Coverage

Generate coverage reports like CI:

```bash
# Run tests with coverage
swift test --enable-code-coverage

# Generate LCOV format (like CI does)
xcrun llvm-cov export \
  .build/debug/CubeSolverPackageTests.xctest/Contents/MacOS/CubeSolverPackageTests \
  -instr-profile .build/debug/codecov/default.profdata \
  -format="lcov" > coverage.lcov

# View coverage summary
xcrun llvm-cov report \
  .build/debug/CubeSolverPackageTests.xctest/Contents/MacOS/CubeSolverPackageTests \
  -instr-profile .build/debug/codecov/default.profdata
```

### UI Tests

UI tests use the Xcode project:

```bash
# Via command line
xcodebuild test \
  -project CubeSolver.xcodeproj \
  -scheme CubeSolver \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Or in Xcode: Cmd+U with CubeSolverUITests scheme selected
```

## 🔍 Pre-Commit Validation

Before committing, run these checks to match CI validation:

```bash
#!/bin/bash
# Save as scripts/pre-commit-check.sh

echo "🔍 Running pre-commit validation..."

# 1. SwiftLint (matches CI)
echo "📝 Running SwiftLint..."
swiftlint lint --strict
if [ $? -ne 0 ]; then
  echo "❌ SwiftLint failed"
  exit 1
fi

# 2. Build (matches CI)
echo "🏗️  Building with Swift PM..."
swift build
if [ $? -ne 0 ]; then
  echo "❌ Build failed"
  exit 1
fi

# 3. Run tests (matches CI)
echo "🧪 Running tests..."
swift test --enable-code-coverage --parallel
if [ $? -ne 0 ]; then
  echo "❌ Tests failed"
  exit 1
fi

echo "✅ All checks passed!"
```

Make it executable:
```bash
chmod +x scripts/pre-commit-check.sh
./scripts/pre-commit-check.sh
```

## 🐛 Troubleshooting Common Issues

### Issue: "Build succeeds in CI but fails locally"

**Possible Causes:**
1. **Different Xcode version** - Verify with `xcodebuild -version`
2. **Different Swift version** - Check `swift --version`
3. **Stale package cache** - Run `swift package clean`
4. **SwiftLint issues** - Run `swiftlint lint --strict`
5. **Swift version mismatch** - Update SWIFT_VERSION in project.pbxproj to 5.9

**Solution Steps:**
```bash
# 1. Clean everything
rm -rf .build
rm -rf ~/Library/Caches/org.swift.swiftpm
swift package clean

# 2. Verify environment
xcodebuild -version  # Should be 15.2 or 15.3
swift --version      # Should be 5.9+

# 3. Re-resolve and build
swift package resolve
swift build

# 4. Run SwiftLint
swiftlint lint --strict
```

### Issue: "Module not found" errors

**Cause:** Swift Package Manager dependencies not resolved or cache corrupted.

**Solution:**
```bash
# Reset package dependencies
swift package reset
swift package resolve
swift package clean
swift build
```

### Issue: "Tests pass locally but fail in CI"

**Possible Causes:**
1. **Parallel execution differences** - CI runs tests with `--parallel`
2. **Timing-dependent tests** - Race conditions exposed in parallel execution
3. **File system differences** - Case sensitivity on CI (macOS is case-insensitive by default)

**Solution:**
```bash
# Test with parallel execution like CI
swift test --parallel

# Run specific failing test in isolation
swift test --filter TestName

# Check for race conditions by running multiple times
for i in {1..10}; do swift test --parallel || break; done
```

### Issue: "SwiftLint warnings treated as errors"

**Cause:** CI runs with `--strict` flag.

**Solution:**
```bash
# Run locally with strict mode before committing
swiftlint lint --strict

# Auto-fix issues where possible
swiftlint --fix

# Review remaining issues
swiftlint lint --strict --reporter xcode
```

### Issue: "Different build artifacts between Xcode and SPM"

**Cause:** Xcode may use different build settings than Swift PM.

**Solution:**
```bash
# Always test with Swift PM commands to match CI
swift build -c release
swift test

# If you must use xcodebuild, match the destination
xcodebuild build \
  -project CubeSolver.xcodeproj \
  -scheme CubeSolver \
  -destination 'generic/platform=iOS'
```

## 📚 Additional Resources

### CI/CD Configuration Files

- **Main CI Workflow:** `.github/workflows/ios-ci.yml`
- **SwiftLint Config:** `.swiftlint.yml`
- **Package Manifest:** `Package.swift`
- **Xcode Project:** `CubeSolver.xcodeproj/project.pbxproj`

### Useful Commands Reference

```bash
# Show all available schemes
xcodebuild -list

# Show build settings for a scheme
xcodebuild -project CubeSolver.xcodeproj \
  -scheme CubeSolver \
  -showBuildSettings

# Build for all platforms
swift build --build-tests

# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/CubeSolver-*

# Resolve packages in Xcode
xcodebuild -resolvePackageDependencies
```

### Documentation

- [Swift Package Manager Documentation](https://swift.org/package-manager/)
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)
- [SwiftLint Rules](https://realm.github.io/SwiftLint/rule-directory.html)
- [GitHub Actions - macOS Runners](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners#supported-runners-and-hardware-resources)

## 🎯 Validation Checklist

Before opening a PR, verify your environment matches CI:

- [ ] Xcode version is 15.2 or 15.3
- [ ] Swift version is 5.9+
- [ ] `swift build` succeeds
- [ ] `swift test --enable-code-coverage --parallel` succeeds
- [ ] `swiftlint lint --strict` passes with no errors
- [ ] No pending package dependency updates
- [ ] Build settings in Xcode project use Swift 5.9 (not 5.0)
- [ ] All tests pass in both sequential and parallel modes

## 🚀 Quick Command Summary

```bash
# Complete local validation (matches CI exactly)
swift package resolve && \
swift build && \
swift test --enable-code-coverage --parallel && \
swiftlint lint --strict

# If all succeed: ✅ Your environment matches CI!
```

---

**Still having issues?** Check the [CI logs](https://github.com/markcoleman/CubeSolver/actions/workflows/ios-ci.yml) to compare the exact commands and environment used in CI, or open a discussion in the repository.
