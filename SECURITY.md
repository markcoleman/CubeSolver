# Security Policy

## Supported Versions

We release patches for security vulnerabilities in the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of CubeSolver seriously. If you discover a security vulnerability, please follow these steps:

### 1. Do Not Disclose Publicly

Please do not open a public GitHub issue for security vulnerabilities. This could put users at risk.

### 2. Report Privately

Report security vulnerabilities through one of the following methods:

- **GitHub Security Advisories** (Preferred): Use the [Security tab](https://github.com/markcoleman/CubeSolver/security/advisories/new) to privately report a vulnerability
- **Email**: Send details to the repository maintainer at [security contact email]

### 3. What to Include

Please include the following information in your report:

- Type of vulnerability
- Full paths of source file(s) related to the vulnerability
- Location of the affected source code (tag/branch/commit or direct URL)
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

### 4. Response Timeline

- **Initial Response**: We will acknowledge your report within 48 hours
- **Status Update**: We will provide a detailed response within 7 days, including next steps
- **Fix Timeline**: We aim to release a fix within 30 days for critical vulnerabilities
- **Disclosure**: We will coordinate with you on public disclosure timing

## Security Best Practices

### For Users

1. **Keep Updated**: Always use the latest version of CubeSolver
2. **Review Permissions**: Only grant necessary permissions to the app
3. **Privacy Settings**: Configure privacy settings according to your needs
4. **Trusted Sources**: Download only from official sources

### For Developers

1. **Code Review**: All code changes require review before merging
2. **Dependency Scanning**: Automated scanning with Dependabot and CodeQL
3. **Static Analysis**: SwiftLint enforces secure coding practices
4. **Testing**: Comprehensive test coverage including security scenarios
5. **Principle of Least Privilege**: Request only necessary permissions
6. **Data Encryption**: Sensitive data is encrypted at rest and in transit
7. **Input Validation**: All user inputs are validated and sanitized

## Security Features

- **Privacy-First Design**: All analytics are opt-in only
- **Local Storage**: Data stored locally using iOS secure storage APIs
- **No Network Calls**: Core functionality works offline
- **Code Signing**: All releases are properly signed
- **Regular Updates**: Dependencies updated weekly via Dependabot
- **Automated Scanning**: CodeQL security scanning on every commit
- **GDPR Compliance**: User data can be deleted at any time

## Security Updates

Security updates will be released as patch versions (e.g., 1.0.1) and will be clearly marked in the release notes with a 🔒 security badge.

## Bug Bounty Program

We currently do not have a bug bounty program, but we greatly appreciate responsible disclosure of security vulnerabilities.

## Acknowledgments

We would like to thank the security researchers who have responsibly disclosed vulnerabilities to us (list will be maintained here).

## Contact

For general security questions or concerns, please contact:
- GitHub Issues: https://github.com/markcoleman/CubeSolver/issues (for non-sensitive topics)
- Security Advisories: https://github.com/markcoleman/CubeSolver/security/advisories

---

Last Updated: 2025-11-16
