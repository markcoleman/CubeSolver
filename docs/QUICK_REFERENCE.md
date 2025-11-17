# DevOps Quick Reference

Quick reference for common DevOps tasks in the CubeSolver project.

## 🚀 Quick Commands

### Build & Test

```bash
# Build the project
swift build

# Build in release mode
swift build --configuration release

# Run all tests
swift test

# Run tests with coverage
swift test --enable-code-coverage

# Run tests in parallel
swift test --parallel

# Run specific test
swift test --filter CubeCoreTests

# Clean build
rm -rf .build && swift build
```

### Linting

```bash
# Run SwiftLint
swiftlint

# Auto-fix issues
swiftlint --fix

# Strict mode (fail on warnings)
swiftlint --strict

# Lint specific files
swiftlint lint --path Sources/CubeCore
```

### Git & GitHub

```bash
# Create feature branch
git checkout -b feature/my-feature

# Commit changes
git commit -m "feat(core): add new solver algorithm"

# Create tag for release
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# View workflow runs
gh run list

# View specific workflow
gh run view <run-id>

# Re-run failed workflows
gh run rerun <run-id>
```

### Local Testing of Workflows

```bash
# Install act (GitHub Actions local runner)
brew install act

# List workflows
act -l

# Run specific workflow
act -j build-and-test

# Run with secrets
act -j build-and-test -s CODECOV_TOKEN=xxx
```

## 📋 Common Tasks

### Creating a New Release

1. **Update version numbers** in code if needed
2. **Update CHANGELOG.md** with changes
3. **Commit changes**:
   ```bash
   git commit -m "chore: prepare release v1.0.0"
   ```
4. **Create and push tag**:
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```
5. **Wait for CI** to complete validation
6. **Verify release** on GitHub Releases page

### Updating Dependencies

```bash
# Update all dependencies
swift package update

# Update specific dependency
swift package update <package-name>

# Resolve dependencies
swift package resolve

# Reset dependencies
rm -rf .build
swift package reset
```

### Responding to Security Alerts

1. **Review alert** in GitHub Security tab
2. **Check Dependabot PR** if available
3. **Test the fix** locally:
   ```bash
   git checkout dependabot/swift/package-name-1.0.0
   swift build
   swift test
   ```
4. **Merge PR** if tests pass
5. **Close alert** if fixed manually

### Adding New Workflow

1. **Create workflow file**:
   ```bash
   touch .github/workflows/my-workflow.yml
   ```
2. **Add workflow content**
3. **Test locally** with `act` if possible
4. **Commit and push**
5. **Monitor** first run on GitHub

### Troubleshooting Failed CI

```bash
# View recent workflow runs
gh run list --limit 10

# View logs for failed run
gh run view <run-id> --log

# Re-run failed jobs
gh run rerun <run-id> --failed

# Download logs
gh run download <run-id>
```

## 🔍 Debugging

### Build Issues

```bash
# Verbose build output
swift build --verbose

# Show build settings
swift build --build-tests --verbose

# Clean and rebuild
swift package clean
swift build
```

### Test Issues

```bash
# Run tests with verbose output
swift test --verbose

# List all tests
swift test --list-tests

# Run single test
swift test --filter testMySpecificTest

# Debug test failures
swift test --parallel --verbose 2>&1 | tee test-output.log
```

### Coverage Issues

```bash
# Generate coverage HTML
xcrun llvm-cov show \
  .build/debug/CubeSolverPackageTests.xctest/Contents/MacOS/CubeSolverPackageTests \
  -instr-profile=.build/debug/codecov/default.profdata \
  -format=html \
  > coverage.html

# View coverage summary
xcrun llvm-cov report \
  .build/debug/CubeSolverPackageTests.xctest/Contents/MacOS/CubeSolverPackageTests \
  -instr-profile=.build/debug/codecov/default.profdata
```

## 📊 Monitoring

### Check CI Status

```bash
# View all workflows
gh workflow list

# View specific workflow runs
gh run list --workflow="iOS CI"

# Watch workflow run
gh run watch <run-id>

# View workflow status
gh run view <run-id>
```

### Check Code Coverage

```bash
# Visit Codecov dashboard
open https://codecov.io/gh/markcoleman/CubeSolver

# View coverage badge
# See README.md for badge link
```

### Check Security

```bash
# View security advisories
gh api repos/markcoleman/CubeSolver/security-advisories

# View Dependabot alerts
gh api repos/markcoleman/CubeSolver/dependabot/alerts
```

## 🛠️ Maintenance

### Weekly Tasks

```bash
# Review and merge Dependabot PRs
gh pr list --author app/dependabot

# Check for security alerts
gh api repos/markcoleman/CubeSolver/dependabot/alerts

# Review stale issues
gh issue list --label stale
```

### Monthly Tasks

```bash
# Review all open issues
gh issue list

# Review all open PRs
gh pr list

# Check CI success rate
gh run list --limit 100 --json conclusion

# Review code coverage trends
# Visit codecov.io dashboard
```

### Quarterly Tasks

- Review and update dependencies
- Review branch protection rules
- Audit repository permissions
- Review security settings
- Update documentation

## 🔐 Security

### Secret Management

```bash
# List repository secrets (requires admin)
gh secret list

# Set a secret
gh secret set CODECOV_TOKEN < token.txt

# Remove a secret
gh secret remove CODECOV_TOKEN
```

### Code Scanning

```bash
# View CodeQL alerts
gh api repos/markcoleman/CubeSolver/code-scanning/alerts

# Upload SARIF file (if running locally)
gh api repos/markcoleman/CubeSolver/code-scanning/sarifs \
  --method POST \
  --field commit_sha=<sha> \
  --field ref=refs/heads/main \
  --field sarif=@results.sarif
```

## 📱 GitHub Mobile

For on-the-go management:

1. **Install GitHub Mobile** app
2. **Enable notifications** for repository
3. **Review and merge** PRs from mobile
4. **Monitor** workflow runs
5. **Respond** to security alerts

## ⚡ Useful Aliases

Add to your `.bashrc` or `.zshrc`:

```bash
# Swift aliases
alias sb='swift build'
alias st='swift test'
alias stp='swift test --parallel'
alias stc='swift test --enable-code-coverage'
alias sclean='rm -rf .build'

# Git aliases
alias gco='git checkout'
alias gcb='git checkout -b'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'

# GitHub CLI aliases
alias ghpr='gh pr list'
alias ghrun='gh run list'
alias ghissue='gh issue list'
```

## 📚 Documentation

- [Full DevOps Guide](DEVOPS.md)
- [Branch Protection Guide](BRANCH_PROTECTION.md)
- [Security Policy](../SECURITY.md)
- [Contributing Guide](../CONTRIBUTING.md)

## 🆘 Getting Help

```bash
# GitHub CLI help
gh help

# Swift help
swift --help
swift build --help
swift test --help

# SwiftLint help
swiftlint help
```

## 🔗 Useful Links

- [GitHub Actions Workflows](https://github.com/markcoleman/CubeSolver/actions)
- [Code Coverage Dashboard](https://codecov.io/gh/markcoleman/CubeSolver)
- [Security Advisories](https://github.com/markcoleman/CubeSolver/security)
- [Releases](https://github.com/markcoleman/CubeSolver/releases)
- [Issues](https://github.com/markcoleman/CubeSolver/issues)
- [Pull Requests](https://github.com/markcoleman/CubeSolver/pulls)

---

Keep this guide updated as new tools and processes are added!
