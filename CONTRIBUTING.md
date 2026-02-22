# Contributing to CubeSolver

First off, thank you for considering contributing to CubeSolver! It's people like you that make CubeSolver such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code. We are committed to providing a welcoming and inclusive environment for all contributors.

**Key Principles:**
- Be respectful and inclusive
- Provide constructive feedback
- Focus on what's best for the community
- Show empathy towards others

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* **Use a clear and descriptive title** for the issue to identify the problem.
* **Describe the exact steps which reproduce the problem** in as many details as possible.
* **Provide specific examples to demonstrate the steps**.
* **Describe the behavior you observed after following the steps** and point out what exactly is the problem with that behavior.
* **Explain which behavior you expected to see instead and why.**
* **Include screenshots and animated GIFs** if possible.

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* **Use a clear and descriptive title** for the issue to identify the suggestion.
* **Provide a step-by-step description of the suggested enhancement** in as many details as possible.
* **Provide specific examples to demonstrate the steps**.
* **Describe the current behavior** and **explain which behavior you expected to see instead** and why.
* **Explain why this enhancement would be useful** to most CubeSolver users.

### Pull Requests

* Fill in the required template
* Do not include issue numbers in the PR title
* Follow the Swift style guide
* Include thoughtfully-worded, well-structured tests
* Document new code
* End all files with a newline
* Follow the glassmorphism design guidelines

## Development Process

### Setting Up Your Environment

**📖 First-time setup:** Please read the [Local Development Environment Setup Guide](docs/LOCAL_DEVELOPMENT_SETUP.md) to ensure your local environment matches the CI pipeline.

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/CubeSolver.git`
3. Add the upstream remote: `git remote add upstream https://github.com/markcoleman/CubeSolver.git`
4. Create a new branch: `git checkout -b feature/my-new-feature`
5. **Verify your environment:** Run `./scripts/pre-commit-check.sh` to ensure everything matches CI

### Environment Requirements

**Essential:**
- **Xcode**: 26.0 or later (must match CI environment)
- **macOS**: 26.0 or later
- **Swift**: 6.2 or later (included with Xcode)
- **SwiftLint**: For code quality (`brew install swiftlint`)

**Optional but Recommended:**
- **fastlane**: For automated tasks (`brew install fastlane`)
- **xcbeautify**: For pretty build output (`brew install xcbeautify`)
- **git-lfs**: If working with large files (`brew install git-lfs`)

### Using GitHub Copilot Agents

This repository includes specialized GitHub Copilot agents to assist with development. When working on contributions, consider using these agents for expert guidance:

* **SwiftUI Expert** (`swiftui-ios-expert`) - For UI components, glassmorphic design, platform-specific features
* **Algorithm Expert** (`algorithm-expert`) - For cube solving algorithms, data structures, performance optimization
* **Accessibility Expert** (`accessibility-expert`) - For VoiceOver, Dynamic Type, WCAG compliance
* **Testing Specialist** (`test-specialist`) - For writing tests, improving coverage, test quality
* **Documentation Expert** (`documentation-expert`) - For API docs, README updates, technical writing
* **DevOps Expert** (`devops-expert`) - For CI/CD workflows, GitHub Actions, deployment

See [.github/agents/README.md](.github/agents/README.md) for detailed information on each agent and when to use them.

### Making Changes

1. **Create a feature branch** from `main`:
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make your changes** following the style guidelines below

3. **Add tests** for your changes:
   - Unit tests for business logic
   - UI tests if changing user interface
   - Integration tests if appropriate

4. **Run the test suite** (must match CI):
   ```bash
   swift test --enable-code-coverage --parallel
   ```

5. **Ensure all tests pass** with no failures

6. **Build the project** without warnings:
   ```bash
   swift build
   ```

7. **Run SwiftLint** to check code quality:
   ```bash
   swiftlint
   ```

8. **Run pre-commit validation** (recommended):
   ```bash
   ./scripts/pre-commit-check.sh
   ```

9. **Commit your changes** with a descriptive message (see guidelines below)

### Commit Message Guidelines (Recommended)

We recommend following the [Conventional Commits](https://www.conventionalcommits.org/) specification for consistency:

* `feat:` A new feature
* `fix:` A bug fix
* `docs:` Documentation only changes
* `style:` Changes that do not affect the meaning of the code
* `refactor:` A code change that neither fixes a bug nor adds a feature
* `perf:` A code change that improves performance
* `test:` Adding missing tests or correcting existing tests
* `chore:` Changes to the build process or auxiliary tools

Example:
```
feat: Add Kociemba algorithm for faster solving
```

### Swift Style Guide

* Follow [Apple's Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
* Use meaningful, descriptive names for variables, functions, and types
* Prefer value types (struct) over reference types (class) unless reference semantics are required
* Use SwiftUI best practices
* Add documentation comments for public APIs
* Keep functions small and focused on a single task

### Testing Guidelines

* Write unit tests for all business logic
* Test edge cases and error conditions
* Use descriptive test names: `test[Method][Scenario][ExpectedResult]`
* Aim for high test coverage
* Mock dependencies where appropriate

### UI/UX Guidelines

* Follow the glassmorphism design principles
* Use `.ultraThinMaterial` for glass effects
* Maintain consistency across all UI components
* Test on multiple device sizes
* Ensure accessibility support

### Submitting Your Changes

1. Push to your fork: `git push origin feature/my-new-feature`
2. Open a Pull Request against the `main` branch
3. Wait for review and address any feedback
4. Once approved, your PR will be merged

## Code Review Process

The maintainers look at Pull Requests on a regular basis. After feedback has been given, we expect responses within two weeks. After two weeks, we may close the PR if it isn't showing any activity.

## Community

* Star the project on GitHub
* Share your experience using CubeSolver
* Help answer questions in issues
* Suggest new features

Thank you for your contribution! 🎉
