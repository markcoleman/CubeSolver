#!/bin/bash

# Pre-commit validation script that matches CI checks
# This helps ensure "works locally" means "works in CI"

set -e  # Exit on first error

echo "🔍 Running pre-commit validation (matching CI pipeline)..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track failures
FAILED=0

# Helper function to run commands silently
run_silently() {
    "$@" >/dev/null 2>&1
}

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        FAILED=1
    fi
}

# 1. Check Xcode version
echo "📱 Checking Xcode version..."
REQUIRED_XCODE_VERSION=$(cat .xcode-version 2>/dev/null || echo "unknown")
if command -v xcodebuild >/dev/null 2>&1; then
    XCODE_VERSION=$(xcodebuild -version 2>/dev/null | head -n 1 | awk '{print $2}' || echo "unknown")
    if [[ "$XCODE_VERSION" == "$REQUIRED_XCODE_VERSION" ]]; then
        print_status 0 "Xcode version $XCODE_VERSION matches CI"
    else
        echo -e "${YELLOW}⚠️  Xcode version $XCODE_VERSION differs from CI ($REQUIRED_XCODE_VERSION)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  xcodebuild not found - unable to verify Xcode version${NC}"
fi
echo ""

# 2. Check Swift version
echo "🔨 Checking Swift version..."
REQUIRED_SWIFT_TOOLS=$(sed -n '1s|// swift-tools-version: ||p' Package.swift | tr -d '[:space:]')
REQUIRED_SWIFT_MAJOR=$(echo "$REQUIRED_SWIFT_TOOLS" | cut -d. -f1)
if command -v swift >/dev/null 2>&1; then
    SWIFT_VERSION=$(swift --version 2>/dev/null | head -n 1 || echo "unknown")
    INSTALLED_SWIFT_MAJOR=$(echo "$SWIFT_VERSION" | sed -E 's/.*Swift version ([0-9]+)\..*/\1/' || echo "0")
    if [[ "$INSTALLED_SWIFT_MAJOR" =~ ^[0-9]+$ ]] && [ "$INSTALLED_SWIFT_MAJOR" -ge "$REQUIRED_SWIFT_MAJOR" ]; then
        print_status 0 "Swift version matches required major version ($REQUIRED_SWIFT_TOOLS)"
    else
        print_status 1 "Swift version incompatible - requires Swift $REQUIRED_SWIFT_TOOLS+"
        echo "Current: $SWIFT_VERSION"
    fi
else
    print_status 1 "Swift not found - please install Xcode"
fi
echo ""

# 3. SwiftLint (matches CI: --strict mode)
echo "📝 Running SwiftLint (strict mode)..."
if command -v swiftlint >/dev/null 2>&1; then
    if swiftlint lint --strict --quiet; then
        print_status 0 "SwiftLint passed (strict mode)"
    else
        print_status 1 "SwiftLint failed - fix issues before committing"
    fi
else
    echo -e "${YELLOW}⚠️  SwiftLint not installed - install with: brew install swiftlint${NC}"
    FAILED=1
fi
echo ""

# 4. Swift Package Resolution (matches CI)
echo "📦 Resolving Swift Package dependencies..."
if run_silently swift package resolve; then
    print_status 0 "Package dependencies resolved"
else
    print_status 1 "Package resolution failed"
fi
echo ""

# 5. Build (matches CI)
echo "🏗️  Building with Swift Package Manager..."
if run_silently swift build; then
    print_status 0 "Build succeeded"
else
    print_status 1 "Build failed"
    echo "Run 'swift build' to see detailed errors"
fi
echo ""

# 6. Run tests (matches CI: with code coverage and parallel)
echo "🧪 Running tests (parallel + code coverage)..."
if run_silently swift test --enable-code-coverage --parallel; then
    print_status 0 "All tests passed"
else
    print_status 1 "Tests failed"
    echo "Run 'swift test --parallel' to see detailed errors"
fi
echo ""

# Final status
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All validation checks passed!${NC}"
    echo "Your environment matches CI. Safe to commit and push."
    exit 0
else
    echo -e "${RED}❌ Validation failed!${NC}"
    echo "Please fix the issues above before committing."
    echo ""
    echo "Quick fixes:"
    echo "  - SwiftLint issues: swiftlint --fix"
    echo "  - Build issues: swift build (for detailed errors)"
    echo "  - Test failures: swift test --parallel"
    echo "  - Clean build: swift package clean && swift build"
    exit 1
fi
