# Branch Protection Configuration Guide

This document provides recommended branch protection rules for the CubeSolver repository.

## Recommended Branch Protection Rules

### Main Branch Protection

Configure these settings for the `main` branch via GitHub Settings → Branches → Branch protection rules:

#### Required Status Checks

**Require status checks to pass before merging**
- ✅ Require branches to be up to date before merging
- Required checks:
  - `build-and-test (15.2)` - Primary Xcode version tests
  - `lint` - SwiftLint code quality
  - `analyze` - CodeQL security scan
  - `dependency-review` - Dependency vulnerability check

#### Pull Request Requirements

**Require pull request reviews before merging**
- ✅ Required number of approvals: 1
- ✅ Dismiss stale pull request approvals when new commits are pushed
- ✅ Require review from Code Owners
- ❌ Restrict who can dismiss pull request reviews (only for larger teams)

#### Additional Protections

**Other protections**
- ✅ Require conversation resolution before merging
- ✅ Require signed commits (recommended but optional)
- ✅ Require linear history (recommended)
- ❌ Include administrators (allows emergency fixes)
- ✅ Restrict who can push to matching branches (optional)
- ✅ Allow force pushes: Nobody
- ✅ Allow deletions: No

### Develop Branch Protection

For the `develop` branch, use slightly relaxed rules:

#### Required Status Checks

**Require status checks to pass before merging**
- ✅ Require branches to be up to date before merging
- Required checks:
  - `build-and-test (15.2)` - Primary Xcode version tests
  - `lint` - SwiftLint code quality

#### Pull Request Requirements

**Require pull request reviews before merging**
- ✅ Required number of approvals: 1
- ❌ Dismiss stale pull request approvals (allow faster iteration)
- ✅ Require review from Code Owners

#### Additional Protections

**Other protections**
- ✅ Require conversation resolution before merging
- ❌ Require linear history (allow merge commits)
- ❌ Include administrators
- ✅ Allow force pushes: Nobody
- ✅ Allow deletions: No

## Setting Up Branch Protection via GitHub UI

1. Navigate to your repository on GitHub
2. Go to **Settings** → **Branches**
3. Click **Add rule** or edit existing rule
4. Enter branch name pattern (e.g., `main`)
5. Configure the settings as shown above
6. Click **Create** or **Save changes**

## Setting Up Branch Protection via GitHub CLI

```bash
# Install GitHub CLI if not already installed
# macOS: brew install gh
# Other platforms: https://cli.github.com/

# Authenticate
gh auth login

# Create branch protection for main
gh api repos/markcoleman/CubeSolver/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["build-and-test (15.2)","lint","analyze","dependency-review"]}' \
  --field enforce_admins=false \
  --field required_pull_request_reviews='{"dismiss_stale_reviews":true,"require_code_owner_reviews":true,"required_approving_review_count":1}' \
  --field restrictions=null \
  --field required_linear_history=true \
  --field allow_force_pushes=false \
  --field allow_deletions=false \
  --field required_conversation_resolution=true
```

## Repository Security Settings

### General Security Settings

Navigate to **Settings** → **Security** → **Code security and analysis**:

#### Dependency Graph
- ✅ Enable Dependency graph

#### Dependabot
- ✅ Enable Dependabot alerts
- ✅ Enable Dependabot security updates
- ✅ Enable Dependabot version updates (configured in `.github/dependabot.yml`)

#### Code Scanning
- ✅ Enable CodeQL analysis (configured in `.github/workflows/codeql.yml`)
- ✅ Enable secret scanning
- ✅ Enable push protection for secrets (prevents committing secrets)

#### Private Vulnerability Reporting
- ✅ Enable private vulnerability reporting

### Actions Settings

Navigate to **Settings** → **Actions** → **General**:

#### Actions Permissions
- ✅ Allow all actions and reusable workflows
- ✅ Allow actions created by GitHub
- ✅ Allow Marketplace verified creator actions

#### Workflow Permissions
- Default: Read repository contents and package permissions
- ✅ Allow GitHub Actions to create and approve pull requests (for automation)

#### Fork Pull Request Workflows
- ❌ Run workflows from fork pull requests (security risk)
- Require approval for first-time contributors

## Environment Protection Rules

For production deployments, create an environment named `github-pages`:

1. Go to **Settings** → **Environments**
2. Click **New environment**
3. Name it `github-pages`
4. Configure protection rules:
   - ✅ Required reviewers: Add `@markcoleman`
   - ✅ Wait timer: 0 minutes (or add delay for safety)
   - ✅ Deployment branches: Selected branches only (main)

## Secrets Management

### Required Secrets

Configure these secrets in **Settings** → **Secrets and variables** → **Actions**:

| Secret Name | Purpose | Required |
|-------------|---------|----------|
| `CODECOV_TOKEN` | Code coverage reporting | Optional (public repos) |

### Best Practices for Secrets

1. **Never commit secrets** to the repository
2. **Use environment secrets** for production
3. **Rotate secrets regularly** (at least annually)
4. **Limit secret scope** to specific environments
5. **Audit secret usage** via Actions logs

## CODEOWNERS Configuration

The `.github/CODEOWNERS` file is already configured. To modify:

```bash
# Edit CODEOWNERS file
nano .github/CODEOWNERS

# Test CODEOWNERS locally (requires GitHub CLI)
gh api repos/markcoleman/CubeSolver/codeowners/errors
```

## Rulesets (Advanced)

GitHub Rulesets provide more granular control than branch protection. To configure:

1. Go to **Settings** → **Rules** → **Rulesets**
2. Click **New ruleset** → **New branch ruleset**
3. Configure rules similar to branch protection
4. Enable bypass for specific users/teams if needed

### Recommended Ruleset for Main

- **Target branches**: `main`
- **Bypass list**: Repository administrators (emergency only)
- **Rules**:
  - Require pull request before merging
  - Require status checks to pass
  - Block force pushes
  - Require signed commits
  - Require linear history

## Monitoring & Alerts

### Email Notifications

Configure in **Settings** → **Notifications**:
- ✅ Enable email notifications for security alerts
- ✅ Enable email notifications for failed Actions
- ✅ Enable email notifications for dependabot

### Security Advisories

Monitor at: `https://github.com/markcoleman/CubeSolver/security/advisories`

### Actions Dashboard

Monitor at: `https://github.com/markcoleman/CubeSolver/actions`

## Audit Log

For organization-owned repositories, review the audit log:
- Navigate to organization **Settings** → **Audit log**
- Review branch protection changes
- Review secret access
- Review Actions workflow runs

## Testing Protection Rules

After configuring protection rules:

1. **Create a test PR** without passing CI
2. **Verify** merge is blocked
3. **Fix issues** and ensure CI passes
4. **Verify** merge is now allowed
5. **Test** required reviews workflow

## Maintenance Schedule

Regular maintenance tasks:

- **Weekly**: Review and merge Dependabot PRs
- **Weekly**: Review CodeQL security alerts
- **Monthly**: Review branch protection rules
- **Quarterly**: Audit access and permissions
- **Annually**: Rotate secrets and review security settings

## Resources

- [GitHub Branch Protection Documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [GitHub Security Features](https://docs.github.com/en/code-security)
- [GitHub Actions Security](https://docs.github.com/en/actions/security-guides)
- [CODEOWNERS Documentation](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)

## Questions?

For questions about branch protection or security settings:
- Open a [GitHub Discussion](https://github.com/markcoleman/CubeSolver/discussions)
- Contact repository maintainers
- Review [SECURITY.md](../SECURITY.md)

---

Last Updated: 2025-11-16
