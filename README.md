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
- 🧩 **Smart Solver**: Step-by-step solution algorithm for any cube configuration
- 🔀 **Random Scramble**: Generate random cube states for practice
- ⚡ **High Performance**: Native Swift/SwiftUI for optimal performance
- 🧪 **Well Tested**: Comprehensive unit test coverage
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

- **Models**: `RubiksCube`, `CubeFace`, `FaceColor`
- **ViewModels**: `CubeViewModel`
- **Views**: `ContentView`, `CubeView`, `GlassmorphicButton`, `GlassmorphicCard`
- **Logic**: `CubeSolver` - Solving algorithm implementation

## 🎨 Glassmorphism Design

The app features a modern glassmorphic design inspired by macOS Big Sur and later:

- Ultra-thin material backdrops
- Subtle transparency and blur effects
- Smooth animations and transitions
- Responsive to system appearance (light/dark mode)

## 🧪 Testing

Run the test suite:

```bash
swift test
```

Or in Xcode: `Cmd + U`

The project includes comprehensive unit tests for:
- Cube model and rotations
- Solving algorithm
- ViewModel logic
- Face color management

## 📦 Project Structure

```
CubeSolver/
├── CubeSolver/
│   ├── Sources/
│   │   ├── CubeSolverApp.swift      # App entry point
│   │   ├── ContentView.swift        # Main UI
│   │   ├── CubeView.swift          # Cube visualization
│   │   ├── RubiksCube.swift        # Cube model
│   │   ├── CubeSolver.swift        # Solving algorithm
│   │   └── CubeViewModel.swift     # ViewModel
│   ├── Tests/
│   │   └── CubeSolverTests.swift   # Unit tests
│   └── Resources/
├── docs/                            # GitHub Pages documentation
├── .github/
│   ├── workflows/                   # GitHub Actions CI/CD
│   └── copilot-instructions.md     # GitHub Copilot config
└── Package.swift                    # Swift Package Manager
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

- [ ] Advanced solving algorithms (Kociemba, CFOP)
- [ ] 3D cube visualization with SceneKit/RealityKit
- [ ] Custom cube patterns and configurations
- [ ] Solution animation playback
- [ ] Statistics and solve time tracking
- [ ] Camera-based cube scanning (AR)
- [ ] Multi-language support

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by the Rubik's Cube solving community
- Built with ❤️ using SwiftUI
- Glassmorphism design inspired by macOS

---

Made with ❤️ by the CubeSolver team