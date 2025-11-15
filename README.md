# 🎲 CubeSolver - Next-Gen

[![iOS CI](https://github.com/markcoleman/CubeSolver/workflows/iOS%20CI/badge.svg)](https://github.com/markcoleman/CubeSolver/actions)
[![Swift Version](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20iPadOS%20%7C%20macOS%20%7C%20watchOS-lightgrey.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A next-generation, modular iOS/iPadOS/macOS/watchOS application for solving Rubik's Cubes with camera scanning, AR visualization, and a stunning glassmorphic interface.

![CubeSolver](docs/images/screenshot.png)

## ✨ Features

### 🎯 Core Features
- **Universal App**: Runs seamlessly on iPhone, iPad, Mac, and Apple Watch
- **Modular Architecture**: Clean Swift Package modules (CubeCore, CubeUI, CubeScanner, CubeAR)
- **Swift 6 Ready**: Modern concurrency with async/await and Sendable conformance
- **Glassmorphism Design**: Beautiful Mac-style UI with glass effects

### 📸 Camera Scanning (Core ML + Vision)
- **Live Camera View**: Real-time cube scanning with AVFoundation
- **3×3 Grid Overlay**: Visual guide for accurate face scanning
- **Color Detection**: Vision framework-powered sticker recognition
- **Confidence Scoring**: Automatic quality assessment
- **Manual Correction**: Fix low-confidence stickers with intuitive UI
- **6-Face Scanning**: Complete cube state capture

### 🧩 Solving & Validation
- **Enhanced Solver**: Two-phase algorithm with async/await support
- **Physical Validation**: Parity and orientation checks
- **Move Optimization**: Efficient solution generation
- **Standard Notation**: R, U', F2, etc.
- **Step-by-Step Solutions**: Interactive playback with controls

### 🎬 AR Solving Assistant
- **ARKit Integration**: Virtual 3D cube overlay
- **Animated Moves**: Visual turn guidance
- **Dual Modes**: Toggle between Standard and AR views
- **Session Persistence**: Resume AR from where you left off

### 📱 Multi-Device Support
- **Modern Navigation**: SwiftUI NavigationStack
- **Home Dashboard**: Recent solves and statistics
- **Solve History**: Track all your solves with persistence
- **Privacy Controls**: Opt-in analytics (disabled by default)
- **Settings**: Comprehensive privacy and data management
- **watchOS Ready**: Architecture supports Watch companion (coming soon)

### 🔒 Privacy & Security
- **Privacy First**: All analytics opt-in only
- **Local Storage**: UserDefaults-based persistence
- **Data Control**: Clear history anytime
- **GDPR Compliant**: Respect for user privacy

### ♿ Accessibility
- **VoiceOver**: Full screen reader support
- **Accessibility Labels**: All UI elements properly labeled
- **Dynamic Type**: Text scaling support
- **High Contrast**: Glassmorphic design works in all modes

### 🧪 Testing & Quality
- **58+ Unit Tests**: 100% pass rate
- **Modular Tests**: Separate test suites for each module
- **CI/CD**: GitHub Actions integration
- **Code Quality**: SwiftLint enforcement

## 🚀 Getting Started

### Requirements

- Xcode 15.0 or later
- iOS 17.0+ / iPadOS 17.0+ / macOS 14.0+
- Swift 5.9+

### Installation

1. Clone the repository:
```bash
git clone https://github.com/markcoleman/CubeSolver.git
cd CubeSolver
```

2. Build the project:
```bash
swift build
```

3. Run tests:
```bash
swift test
```

4. Open in Xcode:
```bash
open CubeSolver.xcodeproj
```

## 🏗️ Architecture

CubeSolver follows a modular Swift Package architecture with clean separation of concerns:

### 📦 Swift Package Modules

#### CubeCore
Core business logic and models (platform-independent)
- **RubiksCube**: 3D cube representation
- **CubeState**: 54-sticker state management
- **EnhancedCubeSolver**: Two-phase async solving algorithm
- **CubeValidator**: Physical legality validation
- **Move/Turn/Amount**: Standard notation types
- **Sendable conformance**: Swift 6 concurrency support

#### CubeUI
SwiftUI views and view models
- **HomeView**: Modern navigation hub
- **CubeViewModel**: Main view model with async solving
- **ScannerCameraView**: Camera scanning interface
- **ManualInputView**: Manual cube input
- **SolutionPlaybackView**: Step-by-step playback
- **SolveHistoryManager**: Persistence layer
- **PrivacySettings**: Privacy controls
- **AnalyticsTracker**: Opt-in analytics

#### CubeScanner
Vision and Core ML integration (iOS only)
- **CubeScanner**: Camera-based cube detection
- **Sticker Detection**: Vision framework integration
- **Color Classification**: Core ML color recognition
- **Confidence Scoring**: Quality assessment

#### CubeAR
ARKit and RealityKit integration (iOS only)
- **CubeARView**: AR cube visualization
- **Virtual Cube**: 3D animated cube model
- **AR Session Management**: Scene coordination

### 🎯 Design Patterns
- **MVVM**: Clear separation of UI and logic
- **Async/Await**: Modern Swift concurrency
- **ObservableObject**: Reactive state management
- **Modular Design**: Clean dependencies
- **Protocol-Oriented**: Flexible abstractions

## 🎨 Glassmorphism Design

The app features a modern glassmorphic design inspired by macOS Big Sur and later:

- Ultra-thin material backdrops
- Subtle transparency and blur effects
- Smooth animations and transitions
- Responsive to system appearance (light/dark mode)

## 🧪 Testing

### Unit Tests

Run the test suite:

```bash
swift test
```

Or in Xcode: `Cmd + U`

The project includes comprehensive unit tests for:
- **Data Structures**: CubeState, Move notation, Face/Turn enums
- **Validation**: Basic and physical legality checks
- **Cube Model**: Face rotations and state management
- **Solver Algorithm**: Two-phase solving with move generation
- **ViewModel Logic**: State management and operations
- **Move Application**: Scramble generation and application
- **Test Coverage**: 56+ tests with 100% pass rate

### UI Tests

UI tests with screenshot capture are available for:
- Main interface validation
- Scramble, solve, and reset workflows
- Manual cube input interface
- Accessibility features
- Comprehensive screenshot gallery

Run UI tests in Xcode: `Cmd + U` (select CubeSolverUITests scheme)

### Code Quality

The project uses SwiftLint for code quality enforcement:

```bash
swiftlint
```

Configuration is in `.swiftlint.yml`

## 📦 Project Structure

```
CubeSolver/
├── CubeSolver/
│   ├── Sources/
│   │   ├── CubeSolverApp.swift              # App entry point
│   │   ├── ContentView.swift                # Main UI
│   │   ├── CubeView.swift                   # Cube visualization
│   │   ├── CubeViewModel.swift              # ViewModel
│   │   ├── ManualInputView.swift            # Original manual input
│   │   ├── ValidatedManualInputView.swift   # Enhanced input with validation
│   │   ├── SolutionPlaybackView.swift       # Solution visualization
│   │   ├── RubiksCube.swift                 # 3D cube model
│   │   ├── CubeSolver.swift                 # Original solver
│   │   ├── EnhancedCubeSolver.swift         # Two-phase solver
│   │   ├── CubeDataStructures.swift         # Core data types
│   │   └── CubeValidation.swift             # Validation logic
│   ├── Tests/
│   │   ├── CubeSolverTests.swift            # Original tests
│   │   ├── CubeDataStructuresTests.swift    # Data structure tests
│   │   ├── CubeValidationTests.swift        # Validation tests
│   │   └── EnhancedCubeSolverTests.swift    # Solver tests
│   └── UITests/
│       └── CubeSolverUITests.swift          # UI tests
├── docs/                                     # Documentation
├── .github/
│   ├── workflows/                            # CI/CD
│   └── copilot-instructions.md              # Copilot config
├── .swiftlint.yml                           # Linting config
└── Package.swift                             # SPM manifest
```

## 🔧 Technologies

- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **Package Manager**: Swift Package Manager
- **Testing**: XCTest
- **CI/CD**: GitHub Actions
- **Documentation**: GitHub Pages

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📖 Documentation

Full documentation is available at [https://markcoleman.github.io/CubeSolver](https://markcoleman.github.io/CubeSolver)

## 🎯 Roadmap

- [x] Manual cube input for real-life cubes
- [x] Validated manual input with real-time feedback
- [x] Comprehensive accessibility support
- [x] UI testing with screenshot capture
- [x] SwiftLint code quality enforcement
- [x] Two-phase solving algorithm
- [x] Solution playback with interactive controls
- [x] Cube validation with physical legality checks
- [x] Standard move notation (R, U', F2, etc.)
- [x] 56+ comprehensive unit tests
- [ ] Advanced solving algorithms (Kociemba's full implementation, CFOP)
- [ ] Enhanced 3D cube visualization with SceneKit/RealityKit
- [ ] Smooth solution animation playback
- [ ] Statistics and solve time tracking
- [ ] Camera-based cube scanning with Vision/CoreML (AR)
- [ ] Multi-language support
- [ ] Optimal move count optimization

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by the Rubik's Cube solving community
- Built with ❤️ using SwiftUI
- Glassmorphism design inspired by macOS

---

Made with ❤️ by the CubeSolver team