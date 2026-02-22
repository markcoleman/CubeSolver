# Codex Workflow Guide

This guide helps future Codex sessions be consistent and efficient.

## Preferred Order of Operations

1. Read relevant files only.
2. Confirm source-of-truth versions (`.xcode-version`, `Package.swift`).
3. Make the smallest safe change.
4. Run targeted checks first, then full parity checks.
5. Report risks and follow-up steps.

## Typical Commands

```bash
rg --files
swift build
swift test --enable-code-coverage --parallel
./scripts/pre-commit-check.sh
```

## Common Pitfalls to Avoid

- Hardcoding toolchain versions in multiple places.
- Adding PR comment noise from CI when summaries are sufficient.
- Running expensive workflows on every PR when labels/manual dispatch are better.
