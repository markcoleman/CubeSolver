# GitHub Actions Workflows

This file is the operational reference for CI/CD behavior.

## Workflow Inventory

- `ios-ci.yml`
  - Runs lint, build, tests, and coverage upload.
  - Triggered for `main`/`develop` plus relevant source/config path changes.
  - Publishes performance data in job summaries (not PR comments).

- `codeql.yml`
  - Runs CodeQL security analysis for Swift.
  - Triggered by relevant code/config path changes plus weekly schedule.

- `dependency-review.yml`
  - Runs only when dependency manifests change (`Package.swift`, `Package.resolved`).
  - Blocks on high/critical findings.

- `auto-label.yml`
  - Applies labels based on changed files via `.github/labeler.yml`.

- `pr-size-check.yml`
  - Applies `size/*` labels and comments only for large PRs.

- `capture-screenshots.yml`
  - Expensive/manual workflow.
  - Runs on `workflow_dispatch` or PRs labeled `screenshots`.
  - Uploads artifacts only (no automatic commits to the repo).

- `deploy-docs.yml`
  - Publishes `docs/` to GitHub Pages on push to `main`.

- `release.yml`
  - Validates and creates releases for `v*.*.*` tags.

- `stale.yml`
  - Scheduled maintenance for inactive issues/PRs.

## CI Design Rules

- Use workflow-level concurrency:
  - `group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}`
  - `cancel-in-progress: true`
- Prefer path filters to avoid unnecessary runs.
- Put developer-facing metrics in `GITHUB_STEP_SUMMARY`, not PR comment spam.
- Keep permissions minimal per workflow.
- Keep heavy jobs opt-in when possible.

## Local Parity

Run this before opening PRs:

```bash
./scripts/pre-commit-check.sh
```

## When Editing Workflows

1. Update only affected workflows.
2. Keep this document synchronized with trigger and behavior changes.
3. Prefer small, measurable CI changes over broad rewrites.
