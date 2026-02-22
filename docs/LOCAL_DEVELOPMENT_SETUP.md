# Local Development Environment Setup

This guide keeps local development aligned with CI.

## Source of Truth

- Required Xcode version: `.xcode-version`
- Required Swift tools version: first line of `Package.swift`
- CI workflows: `.github/workflows/`
- Local CI parity script: `scripts/pre-commit-check.sh`

## Quick Start

1. Install the Xcode version from `.xcode-version`.
2. Install SwiftLint:
   ```bash
   brew install swiftlint
   ```
3. Resolve packages and run local CI parity checks:
   ```bash
   swift package resolve
   ./scripts/pre-commit-check.sh
   ```

## Verify Environment

```bash
xcodebuild -version
swift --version
cat .xcode-version
sed -n '1p' Package.swift
```

Your installed Xcode should match `.xcode-version`, and your Swift major version should be compatible with `swift-tools-version` in `Package.swift`.

## Daily Workflow

```bash
swift package resolve
swift build
swift test --enable-code-coverage --parallel
swiftlint --strict
```

## Troubleshooting

- Toolchain mismatch:
  - Re-select Xcode with `xcode-select` and verify again.
- Build/test drift from CI:
  - Re-run `./scripts/pre-commit-check.sh` and fix the first failing check.
- Dependency issues:
  - Run `swift package reset && swift package resolve`.

## Why This Replaced the Previous Version

The previous version contained stale platform/toolchain references and duplicated CI logic. This version intentionally defers to source-of-truth files so it stays accurate as CI evolves.
