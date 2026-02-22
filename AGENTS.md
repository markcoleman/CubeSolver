# AGENTS

Operational context for AI coding agents (Codex/Copilot) working in this repository.

## Repository Snapshot

- Language: Swift
- Package manager: Swift Package Manager
- Toolchain baseline:
  - Xcode version from `.xcode-version`
  - Swift tools version from `Package.swift`
- Main modules:
  - `Sources/CubeCore`
  - `Sources/CubeUI`
  - `Sources/CubeScanner`
  - `Sources/CubeAR`
- Tests:
  - `Tests/CubeCoreTests`
  - `Tests/CubeUITests`
  - `Tests/CubeScannerTests`
  - `Tests/CubeARTests`

## Fast Paths

- Run local CI parity:
  ```bash
  ./scripts/pre-commit-check.sh
  ```
- Build + test quickly:
  ```bash
  swift build && swift test --parallel
  ```
- Full test + coverage parity with CI:
  ```bash
  swift test --enable-code-coverage --parallel
  ```
- Lint:
  ```bash
  swiftlint --strict
  ```

## CI Notes

- Workflows live in `.github/workflows/`.
- Expensive screenshot jobs are opt-in via `screenshots` PR label or manual dispatch.
- CI performance metrics are reported in workflow summaries, not PR comments.

## Change Guardrails

- Keep changes small and module-scoped.
- Prefer source-of-truth files over duplicated constants:
  - `.xcode-version`
  - `Package.swift`
  - `.github/workflows/*.yml`
- Update docs when changing workflow triggers/toolchain requirements.
- Do not commit generated artifacts from CI.

## Suggested Session Start Prompt

Use `.github/codex/session-start.md` as the default planning scaffold when starting work.
