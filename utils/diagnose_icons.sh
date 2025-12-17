#!/bin/bash

# iOS Icon Diagnostic Script
# Helps diagnose why icons aren't appearing

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

echo -e "${BOLD}🔍 iOS Icon Diagnostic${NC}"
echo "================================"
echo ""

# Find iOS project - use find to get .xcodeproj directory, not files or other directories
IOS_PROJECT=$(find ios -maxdepth 1 -name "*.xcodeproj" -type d 2>/dev/null | head -1 || true)
if [ -z "$IOS_PROJECT" ]; then
  echo -e "${RED}❌ No iOS project found${NC}"
  exit 1
fi

IOS_PROJECT_NAME=$(basename "$IOS_PROJECT" .xcodeproj)
IOS_ASSETS_DIR="ios/$IOS_PROJECT_NAME/Images.xcassets"

echo -e "${BLUE}Project:${NC} $IOS_PROJECT_NAME"
echo ""

# Check 1: Icon files exist
echo -e "${BOLD}1. Checking icon files...${NC}"
MISSING_FILES=0
for icon_set in "AppIcon" "AppIconDev" "AppIconQA" "AppIconPreprod"; do
  icon_file="$IOS_ASSETS_DIR/$icon_set.appiconset/icon-1024.png"
  if [ -f "$icon_file" ]; then
    SIZE=$(stat -f%z "$icon_file" 2>/dev/null || stat -c%s "$icon_file" 2>/dev/null || echo "unknown")
    echo -e "  ${GREEN}✅${NC} $icon_set.appiconset/icon-1024.png exists (size: $SIZE bytes)"
  else
    echo -e "  ${RED}❌${NC} $icon_set.appiconset/icon-1024.png MISSING"
    MISSING_FILES=$((MISSING_FILES + 1))
  fi
done
echo ""

# Check 2: Contents.json format
echo -e "${BOLD}2. Checking Contents.json format...${NC}"
for icon_set in "AppIcon" "AppIconDev" "AppIconQA" "AppIconPreprod"; do
  contents_file="$IOS_ASSETS_DIR/$icon_set.appiconset/Contents.json"
  if [ -f "$contents_file" ]; then
    if grep -q '"idiom": "ios-marketing"' "$contents_file"; then
      echo -e "  ${GREEN}✅${NC} $icon_set.appiconset/Contents.json has correct format"
    else
      echo -e "  ${YELLOW}⚠️${NC}  $icon_set.appiconset/Contents.json may have incorrect format"
      echo -e "     Current idiom: $(grep -o '"idiom": "[^"]*"' "$contents_file" || echo 'not found')"
    fi
  else
    echo -e "  ${RED}❌${NC} $icon_set.appiconset/Contents.json MISSING"
  fi
done
echo ""

# Check 3: Build settings
echo -e "${BOLD}3. Checking build settings...${NC}"
if command -v xcodebuild >/dev/null 2>&1; then
  for config in "Debug" "Debug Develop" "Debug QA" "Debug Preprod"; do
    ICON_NAME=$(xcodebuild -project "$IOS_PROJECT" -scheme "$IOS_PROJECT_NAME" -configuration "$config" -showBuildSettings 2>/dev/null | grep "ASSETCATALOG_COMPILER_APPICON_NAME" | head -1 | awk -F'=' '{print $2}' | xargs)
    if [ -n "$ICON_NAME" ]; then
      echo -e "  ${GREEN}✅${NC} $config → $ICON_NAME"
    else
      echo -e "  ${YELLOW}⚠️${NC}  $config → Not set"
    fi
  done
else
  echo -e "  ${YELLOW}⚠️${NC}  xcodebuild not available, skipping build settings check"
fi
echo ""

# Check 4: Asset catalog in project
echo -e "${BOLD}4. Checking asset catalog in Xcode project...${NC}"
if grep -q "Images.xcassets" "$IOS_PROJECT/project.pbxproj"; then
  echo -e "  ${GREEN}✅${NC} Images.xcassets referenced in project"
else
  echo -e "  ${RED}❌${NC} Images.xcassets NOT found in project.pbxproj"
fi
echo ""

# Summary
echo -e "${BOLD}Summary:${NC}"
if [ $MISSING_FILES -eq 0 ]; then
  echo -e "  ${GREEN}✅ All icon files exist${NC}"
else
  echo -e "  ${RED}❌ $MISSING_FILES icon file(s) missing${NC}"
  echo ""
  echo -e "${YELLOW}Solution:${NC}"
  echo "  1. Run: ./setup_ios_icons.sh (or ../setup_ios_icons.sh from project root)"
  echo "  2. Or manually copy icon files to:"
  echo "     - $IOS_ASSETS_DIR/AppIcon.appiconset/icon-1024.png"
  echo "     - $IOS_ASSETS_DIR/AppIconDev.appiconset/icon-1024.png"
  echo "     - $IOS_ASSETS_DIR/AppIconQA.appiconset/icon-1024.png"
  echo "     - $IOS_ASSETS_DIR/AppIconPreprod.appiconset/icon-1024.png"
fi
echo ""
echo -e "${BOLD}Next steps if icons are missing:${NC}"
echo "  1. Set up icons: ./setup_ios_icons.sh"
echo "  2. Clean build: npm run ios:clean"
echo "  3. Rebuild: npm run ios:dev"


