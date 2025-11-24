# Security Policy

## Supported Versions

We release patches for security vulnerabilities in the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of CubeSolver seriously. If you discover a security vulnerability, please follow these steps to report it responsibly:

### 1. Do Not Disclose Publicly

**Important**: Please do not open a public GitHub issue for security vulnerabilities, as this could put users at risk before a fix is available.

### 2. Report Privately

Report security vulnerabilities through one of the following secure methods:

- **GitHub Security Advisories** (Preferred): Use the [Security tab](https://github.com/markcoleman/CubeSolver/security/advisories/new) to privately report a vulnerability
- **Email**: Contact the repository maintainers directly (see repository for contact details)

### 3. What to Include

To help us understand and address the vulnerability quickly, please include:

**Required Information:**
- **Type of vulnerability** (e.g., injection, authentication bypass, data exposure)
- **Full paths of source file(s)** related to the vulnerability
- **Location of affected code** (tag/branch/commit or direct URL)
- **Step-by-step instructions** to reproduce the issue
- **Impact assessment**: How an attacker might exploit this vulnerability
- **Affected versions**: Which versions of CubeSolver are impacted

**Optional but Helpful:**
- Proof-of-concept or exploit code (if available)
- Suggested fix or mitigation
- References to similar vulnerabilities or CVEs

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

CubeSolver is built with security and privacy as core principles:

### Privacy Protection
- **Privacy-First Design**: All analytics are strictly opt-in only (disabled by default)
- **Local Storage**: User data stored locally using iOS secure storage APIs (UserDefaults, Keychain)
- **No Network Calls**: Core functionality works entirely offline
- **GDPR Compliance**: Users can delete all their data at any time
- **No Third-Party Tracking**: No analytics or tracking libraries by default

### Code Security
- **Code Signing**: All releases are properly signed with valid developer certificates
- **App Sandbox**: Running in iOS/macOS sandbox with minimal permissions
- **Secure Coding**: Following OWASP Mobile Security guidelines
- **Input Validation**: All user inputs validated and sanitized
- **No Eval/Dynamic Code**: No dynamic code execution or eval functions

### Dependency Management
- **Regular Updates**: Dependencies updated weekly via Dependabot
- **Automated Scanning**: CodeQL security scanning on every commit and PR
- **Dependency Review**: GitHub Dependency Review checks all dependency changes
- **Minimal Dependencies**: Using native Apple frameworks where possible

### Development Practices
- **Code Review Required**: All code changes require review before merging
- **Static Analysis**: SwiftLint enforces secure coding practices
- **Automated Testing**: Comprehensive test coverage including security scenarios
- **Principle of Least Privilege**: Request only necessary system permissions
- **Secure Defaults**: Security features enabled by default

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
