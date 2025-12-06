# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Removed

- **Scan Cube (ScannerCameraView)**: Removed from home screen; replaced by Cube Cam and Photo Capture modes
- **AR Coach Mode**: Removed AR-guided solving assistant (ARCoachView, ARCoachViewModel, ARCoachModels)
- **Quick Solve (SolveView)**: Removed from home screen
- **Practice Mode (PracticeView)**: Removed from home screen
- **VisionCubeDetectionService**: Removed AR-specific cube detection service
- **BasicCubeSolver**: Removed AR-specific solver implementation

### Added

#### CubeCam Scanning UX Improvements (10 Major Enhancements)

**Frame Stability Detection (PROMPT 1)**
- 400ms debounce delay before accepting scans
- Requires 8 consecutive stable frames for reliability
- Lighting change detection to reject unstable frames
- Real-time scanning progress overlay with visual feedback

**Duplicate Face Prevention (PROMPT 2)**
- Pattern matching algorithm to detect already-scanned faces
- Configurable tolerance threshold for minor color differences
- Warning overlay displayed when duplicate face detected
- Prevents accidental re-scanning of the same face

**Auto Face Detection (PROMPT 3)**
- Intelligent center tile analysis to determine current face
- Maps center color to expected face (standard Rubik's cube color scheme)
- Displays helpful guidance when wrong face is shown
- Reduces user error in face identification

**3D Cube Mini-Diagram (PROMPT 4)**
- Real-time isometric 3D visualization showing all 6 faces
- Color-coded status: green (captured), blue (next), gray (pending)
- Pulsing animation highlights next face to scan
- Clear text labels for each side (Front, Back, Left, Right, Top, Bottom)

**Guided Step-by-Step Flow (PROMPT 5)**
- Step 1/2/3... instructions for each face with clear progression
- Haptic feedback on successful face captures
- Human-readable face names instead of technical terms
- Progress indicator showing completion percentage

**Improved Color Detection (PROMPT 6)**
- 9-point sampling per sticker (81 samples per face) for accuracy
- Median filtering to reduce lighting noise
- Enhanced white balance normalization algorithm
- Advanced lighting compensation for varied conditions

**Live 3D Preview (PROMPT 7)**
- Real-time scan progress visualization as you scan
- Updates immediately as each face is captured
- Integrated seamlessly into 3D cube mini-diagram
- Helps verify correct face orientation

**Robust Error Handling (PROMPT 8)**
- Validates lighting conditions (detects too dark/too bright)
- Checks color readability and contrast
- Detects physically impossible color patterns
- Provides actionable recovery suggestions

**Manual/Auto Capture Modes (PROMPT 9)**
- Toggle between automatic scanning and manual capture
- Alignment guides with corner markers for precise positioning
- 3-2-1 countdown for manual captures with visual feedback
- Haptic feedback confirms successful capture

**Debug Mode (PROMPT 10)**
- Triple-tap gesture to toggle debug overlay
- Shows stability metrics, frame count, brightness levels
- Displays detected face and recognized colors
- JSON export capability for advanced debugging

#### Core Features#### Core Features

- Initial iOS 17+ universal app implementation with multi-platform support
- SwiftUI-based modern user interface with declarative syntax
- Glassmorphism design system with Mac-style aesthetics and glass effects
- Complete Rubik's Cube 3x3x3 model implementation with all rotations
- Sophisticated cube solving algorithm with step-by-step solution generation
- Random scramble generation with configurable move count
- Interactive 3D cube visualization with color-coded faces
- Cross-platform support: iOS 17.0+, iPadOS 17.0+, and macOS 14.0+
- Comprehensive unit test suite with 13 initial tests (now 58+)

#### Manual Input System

- **Face-by-face color entry interface** for real-world cube input
- Interactive 3×3 grid for each of the 6 cube faces
- Color picker with all six official Rubik's cube colors
- Reset face functionality to correct mistakes
- Visual feedback for selected face and color
- Validation to ensure correct cube configuration

#### Accessibility Features

- **VoiceOver labels** for all interactive UI elements
- **Accessibility hints** for complex interactions and workflows
- **Accessibility identifiers** for comprehensive UI testing
- **Dynamic Type support** for text scaling across the app
- Proper **accessibility traits** (header, button, selected state)
- Decorative elements properly hidden from accessibility tree
- Keyboard navigation support for macOS users

#### Testing Infrastructure

- **UI test suite** with automated test execution
- Main interface validation tests for all screens
- User workflow tests (scramble, solve, reset operations)
- Manual input interface comprehensive tests
- Accessibility compliance validation tests
- Screenshot capture system for all test scenarios
- Screenshot gallery generation for documentation

#### Code Quality

- SwiftLint configuration for enforcing code standards
- Comprehensive documentation comments using `///` style
- MARK comments for logical code organization
- Consistent naming conventions and style

#### Documentation

- [Manual Input Guide](docs/MANUAL_INPUT_GUIDE.md) - Complete user guide
- [Accessibility Guide](docs/ACCESSIBILITY.md) - Accessibility features
- [UI Testing Guide](docs/UI_TESTING_GUIDE.md) - Testing documentation
- Updated README with all new features and capabilities
- API documentation with code examples

#### Infrastructure

- GitHub Actions CI/CD workflows for automation
- GitHub Copilot instructions and specialized agents
- GitHub Pages documentation site with comprehensive guides
- Swift Package Manager support for modular architecture
- Xcode project configuration optimized for all platforms

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
