# DevOps & CI/CD Guide

This document provides an overview of the DevOps practices, CI/CD pipelines, and automation configured for CubeSolver.

## 🚀 Continuous Integration & Deployment

### Workflows Overview

| Workflow | Trigger | Purpose | Status |
|----------|---------|---------|--------|
| iOS CI | Push, PR | Build, test, and code coverage | [![iOS CI](https://github.com/markcoleman/CubeSolver/workflows/iOS%20CI/badge.svg)](https://github.com/markcoleman/CubeSolver/actions) |
| CodeQL | Push, PR, Schedule | Security vulnerability scanning | [![CodeQL](https://github.com/markcoleman/CubeSolver/workflows/CodeQL%20Security%20Scan/badge.svg)](https://github.com/markcoleman/CubeSolver/actions) |
| Dependency Review | PR | Check dependencies for vulnerabilities | - |
| Deploy Docs | Push to main | Deploy documentation to GitHub Pages | [![Deploy Docs](https://github.com/markcoleman/CubeSolver/workflows/Deploy%20Documentation/badge.svg)](https://github.com/markcoleman/CubeSolver/actions) |
| Release | Tag push | Automated release creation | - |
| Auto Label | PR | Automatic PR labeling | - |
| PR Size Check | PR | Check PR size and add labels | - |
| Stale | Schedule | Clean up stale issues/PRs | - |
| Build Performance | PR (manual) | Measure build performance | - |

### CI Pipeline Details

#### iOS CI Pipeline

The main CI pipeline runs on every push and pull request to `main` and `develop` branches.

**Steps:**
1. **Lint** - SwiftLint code quality check
2. **Build** - Swift package build with caching
3. **Test** - Run all unit tests in parallel
4. **Coverage** - Generate and upload code coverage reports

**Matrix Strategy:**
- Xcode 15.2 (primary)
- Xcode 15.3 (compatibility check)

**Optimizations:**
- Swift Package Manager caching
- Parallel test execution
- Concurrent build jobs
- Workflow concurrency control

#### Security Scanning

**CodeQL Analysis:**
- Runs on every push and PR
- Weekly scheduled scans (Monday 2 AM UTC)
- Uses `security-extended` and `security-and-quality` query suites
- Automatically creates security advisories for findings

**Dependency Review:**
- Runs on all PRs
- Fails on high or critical vulnerabilities
- Blocks problematic licenses (LGPL variants)
- Posts summary in PR comments

**Dependabot:**
- Weekly updates for Swift packages (Monday 9 AM)
- Weekly updates for GitHub Actions (Monday 9 AM)
- Auto-labels with `dependencies` tag
- Requests review from `@markcoleman`

## 🔒 Security Practices

### Vulnerability Reporting

Please see [SECURITY.md](../SECURITY.md) for our security policy and how to report vulnerabilities.

### Security Features

- ✅ Automated security scanning with CodeQL
- ✅ Dependency vulnerability checking
- ✅ Weekly dependency updates via Dependabot
- ✅ Private security advisory reporting
- ✅ Principle of least privilege in permissions
- ✅ Secret scanning (GitHub native)

## 📦 Release Process

### Automated Releases

Releases are automated through GitHub Actions:

1. **Tag Creation**: Create a tag following semantic versioning (e.g., `v1.0.0`)
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

2. **Validation**: The release workflow automatically:
   - Builds the project in release mode
   - Runs all tests
   - Runs SwiftLint

3. **Release Creation**: If validation passes:
   - Creates a GitHub release
   - Generates changelog from commit history
   - Marks pre-releases (alpha, beta, rc) appropriately
   - Adds installation instructions

### Semantic Versioning

We follow [Semantic Versioning 2.0.0](https://semver.org/):

- **MAJOR** (v1.0.0): Breaking changes
- **MINOR** (v1.1.0): New features, backward compatible
- **PATCH** (v1.0.1): Bug fixes, backward compatible

### Pre-releases

- **Alpha** (v1.0.0-alpha.1): Early testing
- **Beta** (v1.0.0-beta.1): Feature complete, testing
- **RC** (v1.0.0-rc.1): Release candidate

## 🏷️ Labeling & Organization

### Automatic Labeling

PRs are automatically labeled based on:
- Files changed (core, ui, scanner, ar, tests, docs, ci)
- PR size (small, medium, large, extra-large)
- Commit message conventions (feat, fix, docs, etc.)

### Manual Labels

| Label | Purpose |
|-------|---------|
| `bug` | Bug reports |
| `enhancement` / `feature` | New features |
| `documentation` | Documentation changes |
| `security` | Security-related issues |
| `performance` | Performance improvements |
| `dependencies` | Dependency updates |
| `good first issue` | Good for newcomers |
| `help wanted` | Community help needed |

## 📝 Commit Message Convention (Recommended)

We recommend using [Conventional Commits](https://www.conventionalcommits.org/) for consistency:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Test changes
- `build`: Build system changes
- `ci`: CI/CD changes
- `chore`: Other changes

**Examples:**
```bash
feat(core): add enhanced cube solver algorithm
fix(ui): correct glassmorphic button styling
docs(readme): update installation instructions
ci(actions): add code coverage reporting
```

## 🧪 Testing Strategy

### Test Coverage Goals

- **Overall**: 80% minimum
- **Core Module**: 90% minimum
- **UI Module**: 70% minimum
- **Critical Paths**: 100%

### Test Execution

```bash
# Run all tests
swift test

# Run tests with coverage
swift test --enable-code-coverage

# Run specific test suite
swift test --filter CubeCoreTests
```

## 🔧 Local Development

### Prerequisites

- Xcode 15.0+
- Swift 5.9+
- SwiftLint (optional but recommended)

### Setup

```bash
# Clone repository
git clone https://github.com/markcoleman/CubeSolver.git
cd CubeSolver

# Install dependencies
swift package resolve

# Build project
swift build

# Run tests
swift test
```

### Running SwiftLint

```bash
# Install SwiftLint (if not installed)
brew install swiftlint

# Run linter
swiftlint

# Auto-fix issues
swiftlint --fix
```

## 📊 Code Coverage

Coverage reports are automatically generated and uploaded to [Codecov](https://codecov.io/gh/markcoleman/CubeSolver).

### View Coverage

- **Online**: Visit [codecov.io/gh/markcoleman/CubeSolver](https://codecov.io/gh/markcoleman/CubeSolver)
- **PR Comments**: Coverage diff posted automatically on PRs
- **Local**: Generate coverage locally with `swift test --enable-code-coverage`

### Coverage Configuration

See [.codecov.yml](../.codecov.yml) for coverage thresholds and settings.

## 🤝 Contributing

### PR Checklist

Before submitting a PR:

- [ ] Code follows Swift style guidelines
- [ ] All tests pass locally
- [ ] New code has tests
- [ ] SwiftLint passes without errors
- [ ] Commit messages follow conventional commits
- [ ] PR description is clear and complete
- [ ] Documentation updated if needed
- [ ] No security vulnerabilities introduced

### Review Process

1. **Automated Checks**: All CI workflows must pass
2. **Code Owner Review**: `@markcoleman` reviews all PRs
3. **Security Review**: Security-related changes get extra scrutiny
4. **Merge**: Squash and merge to main

## 📈 Metrics & Monitoring

### Build Performance

- **Build Time**: ~30-60 seconds (cached)
- **Test Time**: ~5-10 seconds
- **Total CI Time**: ~2-3 minutes

### Success Rates

- **CI Success Rate Target**: > 95%
- **Test Pass Rate Target**: 100%
- **Security Scan Target**: 0 high/critical vulnerabilities

## 🎯 Best Practices

### For Contributors

1. **Small PRs**: Keep PRs focused and under 500 lines
2. **Write Tests**: Add tests for all new features
3. **Document**: Update docs for user-facing changes
4. **Security**: Never commit secrets or sensitive data
5. **Review**: Respond to review comments promptly

### For Maintainers

1. **Review Speed**: Aim to review PRs within 48 hours
2. **Release Cadence**: Regular releases (at least monthly)
3. **Dependency Updates**: Review and merge Dependabot PRs weekly
4. **Security**: Triage security alerts within 24 hours
5. **Community**: Respond to issues and discussions promptly

## 🔗 Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Swift Package Manager](https://swift.org/package-manager/)
- [SwiftLint](https://github.com/realm/SwiftLint)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
- [CodeQL](https://codeql.github.com/)

## 📞 Support

For questions about DevOps setup:
- Open a [GitHub Discussion](https://github.com/markcoleman/CubeSolver/discussions)
- Review [CONTRIBUTING.md](../CONTRIBUTING.md)
- Contact maintainers via issues

---

Last Updated: 2025-11-16
