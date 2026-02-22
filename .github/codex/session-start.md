# Codex Session Start Template

Use this as a quick planning scaffold at the top of a coding session.

## Goal

- What should be improved/fixed?

## Constraints

- API/behavior compatibility constraints
- Performance constraints
- Platform/toolchain constraints

## Scope

- In scope:
- Out of scope:

## Plan

1. Inspect relevant modules/workflows.
2. Implement minimal changes with clear intent.
3. Run targeted verification.
4. Summarize impacts and remaining risks.

## Verification Commands

```bash
swift build
swift test --enable-code-coverage --parallel
swiftlint --strict
```

## Delivery Checklist

- [ ] Behavior change documented (if any)
- [ ] Tests added/updated (if needed)
- [ ] CI/workflow impact considered
- [ ] No generated artifacts committed
