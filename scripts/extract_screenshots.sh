#!/bin/bash
# Script to extract screenshots from Xcode test results
# Usage: ./extract_screenshots.sh <path-to-xcresult> <output-directory>

set -e

XCRESULT_PATH=${1:-.build/TestResults.xcresult}
OUTPUT_DIR=${2:-docs/images/screenshots}

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}📸 CubeSolver Screenshot Extractor${NC}"
echo ""

# Check if xcresult bundle exists
if [ ! -d "$XCRESULT_PATH" ]; then
    echo -e "${YELLOW}⚠️  Warning: xcresult bundle not found at $XCRESULT_PATH${NC}"
    echo "Please run UI tests first to generate screenshots:"
    echo "  xcodebuild test -scheme CubeSolver -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -resultBundlePath $XCRESULT_PATH"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}Extracting screenshots from: ${NC}$XCRESULT_PATH"
echo -e "${BLUE}Output directory: ${NC}$OUTPUT_DIR"
echo ""

# Export attachments to temporary directory
TEMP_DIR=$(mktemp -d)
echo -e "${BLUE}Exporting attachments to temporary directory...${NC}"

xcrun xcresulttool export \
    --type directory \
    --path "$XCRESULT_PATH" \
    --output-path "$TEMP_DIR" 2>/dev/null || true

# Find and copy all screenshots
SCREENSHOT_COUNT=0

if [ -d "$TEMP_DIR" ]; then
    echo -e "${BLUE}Searching for screenshots...${NC}"
    
    # Find all PNG and JPEG files (screenshots)
    while IFS= read -r -d '' file; do
        filename=$(basename "$file")
        
        # Copy to output directory
        cp "$file" "$OUTPUT_DIR/$filename"
        echo -e "${GREEN}✓${NC} Extracted: $filename"
        ((SCREENSHOT_COUNT++))
    done < <(find "$TEMP_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) -print0)
    
    # Clean up temp directory
    rm -rf "$TEMP_DIR"
fi

# Also check DerivedData for screenshots (fallback)
if [ $SCREENSHOT_COUNT -eq 0 ] && [ -d ".build/DerivedData" ]; then
    echo -e "${BLUE}Searching DerivedData for screenshots...${NC}"
    
    while IFS= read -r -d '' file; do
        filename=$(basename "$file")
        
        # Avoid duplicates
        if [ ! -f "$OUTPUT_DIR/$filename" ]; then
            cp "$file" "$OUTPUT_DIR/$filename"
            echo -e "${GREEN}✓${NC} Extracted: $filename"
            ((SCREENSHOT_COUNT++))
        fi
    done < <(find .build/DerivedData -type f -name "*.png" -print0)
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ $SCREENSHOT_COUNT -gt 0 ]; then
    echo -e "${GREEN}✓ Successfully extracted $SCREENSHOT_COUNT screenshot(s)${NC}"
    echo ""
    echo "Screenshots saved to: $OUTPUT_DIR"
    echo ""
    ls -lh "$OUTPUT_DIR"
else
    echo -e "${YELLOW}⚠️  No screenshots found${NC}"
    echo ""
    echo "Make sure your UI tests are configured to capture screenshots:"
    echo "  let screenshot = app.screenshot()"
    echo "  let attachment = XCTAttachment(screenshot: screenshot)"
    echo "  attachment.lifetime = .keepAlways"
    echo "  add(attachment)"
fi

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
