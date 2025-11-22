# GitHub Actions Workflows

This document describes the CI/CD workflows configured for the CubeSolver project and recent optimizations to prevent duplicate work and comments on pull requests.

## Workflows Overview

### Core CI/CD Workflows

#### 1. iOS CI (`ios-ci.yml`)
**Triggers:** Push to main/develop, Pull requests to main/develop, Manual dispatch

**What it does:**
- Runs SwiftLint for code quality checks
- Builds and tests on multiple Xcode versions (15.2, 15.3)
- Generates code coverage reports
- Uploads coverage to Codecov

**Optimizations:**
- Uses concurrency control to cancel outdated runs
- Caches Swift Package Manager dependencies
- Only generates coverage for one Xcode version

---

#### 2. CodeQL Security Scan (`codeql.yml`)
**Triggers:** Push to main/develop, Pull requests, Weekly schedule (Monday 2 AM UTC), Manual dispatch

**What it does:**
- Performs static security analysis on Swift code
- Detects security vulnerabilities and code quality issues

**Optimizations:**
- Concurrency control to prevent duplicate scans
- Only runs on code changes or scheduled intervals

---

### PR Quality Workflows

#### 3. PR Size Check (`pr-size-check.yml`)
**Triggers:** PR opened, synchronized, or reopened

**What it does:**
- Automatically labels PRs based on size (small, medium, large, extra-large)
- Posts/updates a comment for large PRs with tips

**Optimizations:**
- ✅ **Updates existing comments** instead of creating duplicates
- ✅ Removes old size labels before adding new ones
- ✅ Deletes comments when PR becomes smaller
- ✅ Concurrency control prevents duplicate runs

**Size Thresholds:**
- Small: < 200 lines or < 5 files
- Medium: 200-500 lines or 5-10 files
- Large: 500-1000 lines or 10-20 files
- Extra-large: > 1000 lines or > 20 files

---

#### 4. Build Performance (`build-performance.yml`)
**Triggers:** Pull requests to main/develop, Manual dispatch

**What it does:**
- Measures clean build and test times
- Posts/updates performance metrics on PRs

**Optimizations:**
- ✅ **Updates existing performance comments** instead of creating duplicates
- ✅ Concurrency control prevents overlapping runs
- Only runs on manual trigger or PR events

---

#### 5. Auto Label (`auto-label.yml`)
**Triggers:** PR opened or synchronized

**What it does:**
- Automatically labels PRs based on changed files
- Uses `.github/labeler.yml` configuration

**Optimizations:**
- ✅ Removed unnecessary `edited` trigger
- ✅ Only runs when files actually change
- ✅ Concurrency control

---

#### 6. Dependency Review (`dependency-review.yml`)
**Triggers:** Pull requests to main/develop

**What it does:**
- Reviews dependency changes for security vulnerabilities
- Checks for license compliance

**Optimizations:**
- ✅ **Only comments on PRs when vulnerabilities are found** (not always)
- ✅ Concurrency control
- Fails CI on high/critical vulnerabilities

---

### Utility Workflows

#### 7. Capture Screenshots (`capture-screenshots.yml`)
**Triggers:** 
- Push to main
- Manual dispatch
- Pull requests with `screenshots` label

**What it does:**
- Runs UI tests and captures screenshots
- Uploads screenshot artifacts
- Commits screenshots to repo (main branch only)

**Optimizations:**
- ✅ **Only runs on PRs when explicitly requested** (add `screenshots` label)
- ✅ Prevents automatic execution on every PR
- ✅ Significant reduction in macOS runner usage

**How to trigger on PRs:**
Add the `screenshots` label to your PR to capture screenshots.

---

#### 8. Stale Issues/PRs (`stale.yml`)
**Triggers:** Daily schedule

**What it does:**
- Marks inactive issues/PRs as stale
- Closes stale items after warning period

---

## Workflow Optimization Summary

### Problems Solved
1. **Duplicate PR Comments** - Multiple workflows creating new comments on every run
2. **Redundant Workflow Runs** - Same workflow running multiple times concurrently
3. **Unnecessary Builds** - Screenshot workflow running on every PR
4. **Excessive Notifications** - Too many bot comments cluttering PRs

### Solutions Implemented

#### Comment Deduplication
All workflows that post PR comments now:
- Check for existing bot comments first
- Update existing comments instead of creating new ones
- Delete comments when no longer needed (e.g., PR size changes)

#### Concurrency Control
All workflows now use concurrency groups:
```yaml
concurrency:
  group: workflow-name-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true
```

Benefits:
- Cancels outdated runs when new commits are pushed
- Prevents queue buildup
- Reduces CI/CD minutes consumption

#### Conditional Execution
- Screenshot workflow only runs when explicitly needed
- Dependency review only comments on failures
- Workflows skip unnecessary steps based on context

### Expected Impact
- **50-70% reduction** in GitHub Actions minutes for PRs
- **Cleaner PR threads** - no more duplicate comments
- **Faster feedback** - cancelled obsolete runs don't delay new ones
- **Better resource utilization** - macOS runners used only when needed

---

## Best Practices for Contributors

### Working with PRs
1. **Keep PRs small** - Aim for < 200 lines when possible
2. **Check workflow status** - Ensure all checks pass before requesting review
3. **Request screenshots** - Add `screenshots` label if you need UI verification
4. **Monitor performance** - Build time comments help track performance impact

### Triggering Workflows Manually
Some workflows support manual triggering via `workflow_dispatch`:
- iOS CI
- Build Performance
- Screenshot Capture
- CodeQL Scan

To trigger manually:
1. Go to Actions tab
2. Select the workflow
3. Click "Run workflow"
4. Choose branch and options

### Understanding Workflow Results

#### Check Annotations
Workflows can add annotations to your code:
- **SwiftLint** - Code style issues
- **CodeQL** - Security vulnerabilities
- **Build errors** - Compilation failures

#### Artifacts
Some workflows upload artifacts:
- **ios-screenshots** - UI test screenshots (30 days)
- **macos-build** - macOS build products (7 days)
- **Test results** - XCTest bundles

---

## Troubleshooting

### Workflow not running?
- Check if concurrency cancellation occurred
- Verify trigger conditions match your event
- Look for conditional steps that may be skipped

### Comment not updating?
- Ensure bot comment exists (look for GitHub Actions bot)
- Check PR comment permissions
- Verify workflow has `pull-requests: write` permission

### Screenshot workflow not running on PR?
- Add the `screenshots` label to your PR
- Or trigger manually via workflow_dispatch
- Or wait for merge to main (auto-runs)

---

## Future Improvements

Potential optimizations being considered:
- Reusable workflows for common build steps
- Shared build artifacts between workflows
- Matrix strategy for parallel screenshot capture
- Smart test selection based on changed files
- Build cache optimization across workflows

---

## Related Files
- `.github/workflows/` - All workflow definitions
- `.github/labeler.yml` - Auto-label configuration
- `.github/dependabot.yml` - Dependency update configuration

## Support
For workflow issues or questions, please:
1. Check this documentation
2. Review workflow runs in the Actions tab
3. Open an issue with the `ci/cd` label
