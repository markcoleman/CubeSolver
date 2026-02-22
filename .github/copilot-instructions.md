# GitHub Copilot Instructions for CubeSolver

> **Note**: This file contains instructions for GitHub Copilot to understand the CubeSolver project structure, coding standards, and best practices.

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Code Style and Conventions](#code-style-and-conventions)
- [Design System](#design-system)
- [Testing Guidelines](#testing-guidelines)
- [Platform Support](#platform-support)
- [Documentation Standards](#documentation-standards)
- [Accessibility Requirements](#accessibility-requirements)
- [Security Practices](#security-practices)
- [Specialized Agents](#specialized-agents)
- [Code Review Checklist](#code-review-checklist)

## Project Overview

CubeSolver is a next-generation, universal iOS/iPadOS/macOS/watchOS application built with SwiftUI that provides Rubik's Cube solving capabilities with a modern glassmorphic UI design.

### Key Technologies
- **Language**: Swift 6.2+ (Swift 6 ready)
- **UI Framework**: SwiftUI with declarative syntax
- **Architecture**: MVVM (Model-View-ViewModel)
- **Package Manager**: Swift Package Manager (SPM)
- **Testing**: XCTest framework
- **CI/CD**: GitHub Actions
- **Documentation**: GitHub Pages + Markdown

### Project Goals
1. Provide an intuitive, beautiful interface for solving Rubik's Cubes
2. Support multiple input methods (manual, camera scanning, AR)
3. Deliver exceptional accessibility across all features
4. Maintain high code quality with comprehensive testing
5. Create modular, reusable components

## Architecture

CubeSolver follows a modular Swift Package architecture with clear separation of concerns:

### Module Structure

```
CubeSolver/
├── CubeCore/          # Platform-independent business logic
├── CubeUI/            # SwiftUI views and ViewModels
├── CubeScanner/       # Vision/CoreML camera scanning (iOS-only)
└── CubeAR/            # ARKit/RealityKit integration (iOS-only)
```

### CubeCore Module
**Platform-independent core business logic**

- `RubiksCube`: 3D cube representation and state management
- `CubeState`: 54-sticker state tracking
- `EnhancedCubeSolver`: Two-phase async solving algorithm
- `CubeValidator`: Physical legality validation (parity, orientation)
- `Move/Turn/Amount`: Standard notation types (R, U', F2, etc.)
- **Sendable conformance**: Full Swift 6 concurrency support

### CubeUI Module
**SwiftUI views and reactive ViewModels**

- `HomeView`: Modern navigation hub with dashboard
- `CubeViewModel`: Main ViewModel with async/await solving
- `ScannerCameraView`: Camera scanning interface with live preview
- `ManualInputView`: Manual cube configuration interface
- `SolutionPlaybackView`: Interactive step-by-step solution playback
- `SolveHistoryManager`: UserDefaults-based persistence layer
- `PrivacySettings`: Privacy controls and opt-in analytics
- `AnalyticsTracker`: Privacy-first analytics tracking

### CubeScanner Module
**Vision and Core ML integration (iOS-only)**

- `CubeScanner`: Camera-based cube detection and color recognition
- `Sticker Detection`: Vision framework integration for face scanning
- `Color Classification`: Core ML color recognition with confidence scoring
- `Confidence Scoring`: Quality assessment for scanned colors

### CubeAR Module
**ARKit and RealityKit integration (iOS-only)**

- `CubeARView`: AR cube visualization with virtual overlay
- `Virtual Cube`: Animated 3D cube model with move visualization
- `AR Session Management`: ARKit scene coordination and persistence



## Code Style and Conventions

### Swift Style
- Use Swift 6.2+ features
- Follow Apple's Swift API Design Guidelines
- Prefer value types (struct) over reference types (class) unless reference semantics are required
- Use meaningful, descriptive variable and function names
- Add documentation comments for public APIs

### SwiftUI Best Practices
- Use `@State` for view-local state
- Use `@StateObject` for observable objects owned by the view
- Use `@ObservedObject` for observable objects passed into the view
- Prefer composition over inheritance
- Extract reusable components into separate views

### Architecture
- Follow MVVM (Model-View-ViewModel) pattern
- Keep business logic in ViewModels
- Keep views focused on presentation
- Use Combine for reactive programming

## Glassmorphism Design
- Use `.ultraThinMaterial` backdrop for glassmorphic effects
- Apply subtle transparency (0.1-0.2 opacity) with white overlays
- Add subtle borders with white.opacity(0.2)
- Include shadow effects for depth
- Maintain consistency across all UI components

## Design System

CubeSolver features a distinctive glassmorphism design system inspired by macOS Big Sur and later versions.

### Glassmorphism Principles

**Visual Effects**
- Use `.ultraThinMaterial` backdrop for primary glassmorphic effects
- Apply subtle transparency (0.1-0.2 opacity) with white overlays for depth
- Add subtle borders using `Color.white.opacity(0.2)` for definition
- Include shadow effects for depth and hierarchy
- Maintain consistency across all UI components

**Color Usage**
- Respect system appearance (light/dark mode)
- Use semantic colors that adapt to appearance
- Ensure sufficient contrast for accessibility (WCAG AA)
- Use color sparingly for emphasis

**Animation**
- Smooth, natural animations using SwiftUI's built-in transitions
- Respect "Reduce Motion" accessibility setting
- Use spring animations for interactive elements
- Keep animations brief (0.2-0.4 seconds typical)

### Component Library

All UI components should follow the glassmorphic design:
- `GlassmorphicButton`: Buttons with glass effect
- `GlassmorphicCard`: Container with glass background
- `GlassmorphicOverlay`: Overlay with backdrop blur

### Layout Guidelines

- Use consistent spacing (8pt grid system)
- Maintain clear visual hierarchy
- Optimize for different screen sizes
- Test on all supported platforms

## Testing Guidelines

### Test Coverage Requirements

- **Minimum Coverage**: Aim for 80%+ code coverage
- **Business Logic**: 100% coverage required
- **UI Logic**: Test all user interactions
- **Edge Cases**: Test boundary conditions
- **Error Handling**: Test failure scenarios

### Test Organization

```swift
// Follow this naming pattern:
func test[Method][Scenario][ExpectedResult]() {
    // Arrange
    // Act
    // Assert
}
```

**Example:**
```swift
func testSolveWithScrambledCubeReturnsValidSolution() {
    // Arrange: Create a scrambled cube
    var cube = RubiksCube()
    CubeSolver.applyScramble(cube: &cube, scramble: ["F", "R", "U"])
    
    // Act: Solve the cube
    let solution = CubeSolver.solve(cube: &cube)
    
    // Assert: Verify cube is solved
    XCTAssertTrue(cube.isSolved)
    XCTAssertFalse(solution.isEmpty)
}
```

### Testing Best Practices

- Write tests before or alongside code (TDD approach preferred)
- Test ViewModels thoroughly with mock dependencies
- Use XCTest for unit and integration tests
- Use XCUITest for UI automation
- Mock external dependencies (network, file system)
- Keep tests fast and deterministic
- Avoid testing implementation details
- Test behavior, not internal state

### UI Testing

- Test complete user workflows
- Capture screenshots for visual verification
- Test accessibility features with VoiceOver
- Test on multiple device sizes
- Verify proper error messaging

## Performance Optimizations
- Minimize view updates by using appropriate property wrappers
- Avoid expensive computations in view body
- Use `Equatable` conformance to optimize view updates
- Lazy load resources when possible

## Platform Support
- Support iOS 26.0+
- Support macOS 26.0+
- Test on both iPhone and iPad layouts
- Ensure proper scaling for different screen sizes
- Use platform-specific modifiers when needed (#if os(macOS))

## Cube Solving Algorithm
- The current implementation uses a simplified demonstration algorithm
- For production, consider implementing:
  - Kociemba's algorithm (two-phase algorithm)
  - CFOP method (Fridrich method)
  - Roux method
- Optimize for minimal move count
- Provide step-by-step solution visualization

## Documentation
- Document complex algorithms
- Provide inline comments for non-obvious code
- Update README with new features
- Include screenshots in documentation
- Maintain changelog for version updates

## Accessibility
- Provide VoiceOver labels for all interactive elements
- Support Dynamic Type
- Ensure sufficient color contrast
- Test with accessibility features enabled

## Security
- Never commit sensitive data
- Validate all user inputs
- Follow secure coding practices
- Use App Transport Security (ATS)

## Specialized Agents

This repository includes specialized GitHub Copilot agents for specific development tasks:

- **SwiftUI Expert** - UI components, platform-specific features, glassmorphic design
- **Algorithm Expert** - Cube solving algorithms, data structures, performance
- **Accessibility Expert** - VoiceOver, Dynamic Type, WCAG compliance
- **Testing Specialist** - XCTest, code coverage, test quality
- **Documentation Expert** - API docs, guides, technical writing
- **DevOps Expert** - CI/CD, GitHub Actions, deployment

See `.github/agents/README.md` for details on when to use each agent.

## Code Review Checklist
- [ ] Code follows Swift style guidelines
- [ ] All tests pass
- [ ] New features have unit tests
- [ ] UI is responsive on all supported platforms
- [ ] Glassmorphic design is consistent
- [ ] Documentation is updated
- [ ] No compiler warnings
- [ ] Performance is acceptable
