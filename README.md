# 🎲 CubeSolver

[![iOS CI](https://github.com/markcoleman/CubeSolver/workflows/iOS%20CI/badge.svg)](https://github.com/markcoleman/CubeSolver/actions)
[![Swift Version](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20iPadOS%20%7C%20macOS-lightgrey.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A beautiful, universal iOS/iPadOS/macOS application for solving Rubik's Cubes with a stunning glassmorphic interface.

![CubeSolver](docs/images/screenshot.png)

## ✨ Features

- 🎯 **Universal App**: Runs seamlessly on iPhone, iPad, and Mac
- 🎨 **Glassmorphism Design**: Modern Mac-style UI with beautiful glass effects
- 🧩 **Enhanced Solver**: Two-phase solving algorithm with step-by-step solutions
- ✅ **Cube Validation**: Physical legality checking with detailed error messages
- 🎬 **Solution Playback**: Interactive visualization with play/pause controls
- 🔀 **Smart Scramble**: Generate random valid cube configurations
- ⌨️ **Validated Manual Input**: Input real-life cube patterns with live validation feedback
- 📊 **Move Notation**: Standard Rubik's Cube notation (R, U', F2, etc.)
- ♿ **Accessibility**: Full VoiceOver support with accessibility labels and hints
- 🧪 **UI Testing**: Comprehensive UI test suite with screenshot capture
- ⚡ **High Performance**: Native Swift/SwiftUI for optimal performance
- 🧪 **Well Tested**: 56+ comprehensive unit tests with 100% pass rate
- 📱 **iOS 17+**: Built for the latest iOS features
- 💻 **macOS 14+**: Full macOS support with optimized UI

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

CubeSolver follows the MVVM (Model-View-ViewModel) architecture pattern:

### Core Models
- **RubiksCube**: 3D cube representation with face rotations
- **CubeState**: 54-sticker representation for validation and solving
- **CubeFace**: Individual face with 3x3 color grid
- **Move**: Standard notation move (Turn + Amount)
- **FaceColor/CubeColor**: Six standard Rubik's Cube colors

### ViewModels
- **CubeViewModel**: Manages cube state and operations

### Views
- **ContentView**: Main app interface
- **CubeView**: 3D cube visualization
- **ValidatedManualInputView**: Manual input with validation
- **SolutionPlaybackView**: Step-by-step solution display
- **ManualInputView**: Original manual input interface
- **GlassmorphicButton/Card**: Reusable UI components

### Logic Modules
- **EnhancedCubeSolver**: Two-phase solving algorithm
- **CubeValidator**: Physical legality validation
- **CubeSolver**: Original solving implementation

### Data Structures
- **Face**: Enum for cube faces (U, D, L, R, F, B)
- **Turn**: Move turn type
- **Amount**: Move amount (clockwise, counter, double)
- **CubeValidationError**: Validation error types

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