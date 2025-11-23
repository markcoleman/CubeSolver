# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **CubeCam Scanning UX Improvements (10 Major Enhancements)**
  - **PROMPT 1: Frame Stability Detection**
    - 400ms debounce delay before accepting scans
    - Requires 8 consecutive stable frames
    - Lighting change detection to reject unstable frames
    - Real-time scanning progress overlay
  - **PROMPT 2: Duplicate Face Prevention**
    - Pattern matching to detect already-scanned faces
    - Tolerance threshold for minor color differences
    - Warning overlay when duplicate detected
  - **PROMPT 3: Auto Face Detection**
    - Analyzes center tile color to determine face
    - Maps center color to expected face (standard Rubik's cube)
    - Displays guidance when wrong face is shown
  - **PROMPT 4: 3D Cube Mini-Diagram**
    - Isometric 3D visualization showing all 6 faces
    - Color-coded: green (captured), blue (next), gray (pending)
    - Pulsing animation for next face to scan
    - Clear text labels for each side
  - **PROMPT 5: Guided Step-by-Step Flow**
    - Step 1/2/3... instructions for each face
    - Haptic feedback on successful captures
    - Human-readable face names (Top, Bottom, etc.)
  - **PROMPT 6: Improved Color Detection**
    - 9-point sampling per sticker (81 samples per face)
    - Median filtering to reduce noise
    - Enhanced white balance normalization
    - Lighting compensation for better accuracy
  - **PROMPT 7: Live 3D Preview**
    - Real-time scan progress visualization
    - Updates as each face is captured
    - Integrated into 3D cube mini-diagram
  - **PROMPT 8: Robust Error Handling**
    - Validates lighting conditions (too dark/bright)
    - Checks color readability
    - Detects impossible patterns
    - Provides recovery suggestions
  - **PROMPT 9: Manual/Auto Capture Modes**
    - Toggle between auto-scan and manual capture
    - Alignment guides with corner markers
    - 3-2-1 countdown for manual captures
    - Haptic feedback on capture
  - **PROMPT 10: Debug Mode**
    - Triple-tap to toggle debug overlay
    - Shows stability, frames, brightness metrics
    - Displays detected face and colors
    - JSON export for debugging

- Initial iOS 26 universal app implementation
- SwiftUI-based user interface
- Glassmorphism design with Mac-style aesthetics
- Rubik's Cube 3x3x3 model implementation
- Cube solving algorithm with step-by-step solutions
- Random scramble generation
- Interactive cube visualization
- Support for iOS 17.0+, iPadOS 17.0+, and macOS 14.0+
- Comprehensive unit test suite (13 tests)
- **Manual cube input interface for real-life cubes**
  - Face-by-face color entry
  - Interactive 3×3 grid for each face
  - Color picker with all six cube colors
  - Reset face functionality
- **Full accessibility support**
  - VoiceOver labels for all interactive elements
  - Accessibility hints for complex interactions
  - Accessibility identifiers for UI testing
  - Dynamic Type support
  - Proper accessibility traits (header, button, selected)
  - Hidden decorative elements from accessibility tree
- **Comprehensive UI test suite**
  - Main interface validation tests
  - User workflow tests (scramble, solve, reset)
  - Manual input interface tests
  - Accessibility compliance tests
  - Screenshot capture for all tests
  - Screenshot gallery test for documentation
- **Code quality improvements**
  - SwiftLint configuration for code standards
  - Comprehensive documentation comments (/// style)
  - MARK comments for code organization
- **Enhanced documentation**
  - Manual Input Guide
  - Accessibility Guide
  - UI Testing Guide
  - Updated README with new features
- GitHub Actions CI/CD workflows
- GitHub Copilot instructions and optimizations
- GitHub Pages documentation site
- Swift Package Manager support
- Xcode project configuration

### Features
- 🎯 Universal app support (iPhone, iPad, Mac)
- 🎨 Beautiful glassmorphic UI components
- 🧩 Step-by-step cube solving
- 🔀 Random cube scrambling
- ⌨️ Manual cube input from real-life cubes
- ♿ Full accessibility with VoiceOver support
- 🧪 UI tests with screenshot capture
- 📏 SwiftLint code quality enforcement
- ⚡ High performance with native Swift
- ✅ Full test coverage
- 📚 Comprehensive documentation

## [1.0.0] - TBD

### Planned
- Advanced solving algorithms (Kociemba, CFOP)
- 3D cube visualization with SceneKit/RealityKit
- Solution animation playback
- Camera-based cube scanning (AR)
- Statistics and solve time tracking
- Custom cube patterns and persistence
- Multi-language support
- Dark mode optimization
- Performance optimizations
- Cube validation for manual input

---

## Version History Format

Each version should:
- List all **Added** features
- Document all **Changed** functionality
- Note any **Deprecated** features
- List all **Removed** features
- Document all **Fixed** bugs
- Note any **Security** updates
