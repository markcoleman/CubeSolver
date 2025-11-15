# GitHub Copilot Instructions for CubeSolver

## Project Overview
CubeSolver is a universal iOS/iPadOS/macOS application built with SwiftUI that provides Rubik's Cube solving capabilities with a modern glassmorphic UI design.

## Code Style and Conventions

### Swift Style
- Use Swift 5.9+ features
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

## Testing Guidelines
- Write unit tests for all business logic
- Test ViewModels thoroughly
- Mock dependencies where appropriate
- Aim for high test coverage
- Use descriptive test names following the pattern: `test[Method][Scenario][ExpectedResult]`

## Performance Optimizations
- Minimize view updates by using appropriate property wrappers
- Avoid expensive computations in view body
- Use `Equatable` conformance to optimize view updates
- Lazy load resources when possible

## Platform Support
- Support iOS 17.0+
- Support macOS 14.0+
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

## Code Review Checklist
- [ ] Code follows Swift style guidelines
- [ ] All tests pass
- [ ] New features have unit tests
- [ ] UI is responsive on all supported platforms
- [ ] Glassmorphic design is consistent
- [ ] Documentation is updated
- [ ] No compiler warnings
- [ ] Performance is acceptable
