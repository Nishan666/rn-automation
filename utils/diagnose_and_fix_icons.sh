#!/bin/bash

# Comprehensive Icon Diagnostic and Fix Script
# Diagnoses and fixes all icon-related issues

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

echo -e "${BOLD}${CYAN}🔍 iOS Icon Diagnostic & Fix${NC}"
echo "=================================="
echo ""

# Find iOS project
IOS_PROJECT=$(find ios -maxdepth 1 -name "*.xcodeproj" -type d 2>/dev/null | head -1 || true)
if [ -z "$IOS_PROJECT" ]; then
  echo -e "${RED}❌ No iOS project found in: $PROJECT_DIR${NC}"
  echo ""
  echo "Usage: ./utils/diagnose_and_fix_icons.sh [project_directory]"
  echo "Example: ./utils/diagnose_and_fix_icons.sh exampleProject"
  exit 1
fi

IOS_PROJECT_NAME=$(basename "$IOS_PROJECT" .xcodeproj)
IOS_ASSETS_DIR="ios/$IOS_PROJECT_NAME/Images.xcassets"

echo -e "${BLUE}Project:${NC} $IOS_PROJECT_NAME"
echo -e "${BLUE}Location:${NC} $PROJECT_DIR"
echo ""

# Track issues
ISSUES_FOUND=0
FIXES_APPLIED=0

# Check 1: Icon files exist
echo -e "${BOLD}1. Checking icon files...${NC}"
MISSING_ICONS=()
for icon_set in "AppIcon" "AppIconDev" "AppIconQA" "AppIconPreprod"; do
  icon_file="$IOS_ASSETS_DIR/$icon_set.appiconset/icon-1024.png"
  if [ -f "$icon_file" ]; then
    SIZE=$(stat -f%z "$icon_file" 2>/dev/null || stat -c%s "$icon_file" 2>/dev/null || echo "unknown")
    if [ "$SIZE" = "0" ] || [ "$SIZE" = "unknown" ]; then
      echo -e "  ${RED}❌${NC} $icon_set.appiconset/icon-1024.png exists but is empty/corrupted"
      MISSING_ICONS+=("$icon_set")
      ISSUES_FOUND=$((ISSUES_FOUND + 1))
    else
      echo -e "  ${GREEN}✅${NC} $icon_set.appiconset/icon-1024.png exists (size: $SIZE bytes)"
    fi
  else
    echo -e "  ${RED}❌${NC} $icon_set.appiconset/icon-1024.png MISSING"
    MISSING_ICONS+=("$icon_set")
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
  fi
done
echo ""

# Check 2: Contents.json format
echo -e "${BOLD}2. Checking Contents.json format...${NC}"
FIXED_JSON=0
for icon_set in "AppIcon" "AppIconDev" "AppIconQA" "AppIconPreprod"; do
  contents_file="$IOS_ASSETS_DIR/$icon_set.appiconset/Contents.json"
  icon_dir="$IOS_ASSETS_DIR/$icon_set.appiconset"
  
  if [ ! -f "$contents_file" ]; then
    echo -e "  ${RED}❌${NC} $icon_set.appiconset/Contents.json MISSING"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
    
    # Create directory if needed
    mkdir -p "$icon_dir"
    
    # Create Contents.json with correct format
    cat > "$contents_file" << 'EOF'
{
  "images": [
    {
      "filename": "icon-1024.png",
      "idiom": "ios-marketing",
      "platform": "ios",
      "size": "1024x1024"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
EOF
    echo -e "  ${GREEN}✅${NC} Created Contents.json"
    FIXED_JSON=$((FIXED_JSON + 1))
    FIXES_APPLIED=$((FIXES_APPLIED + 1))
  elif ! grep -q '"idiom": "ios-marketing"' "$contents_file"; then
    echo -e "  ${YELLOW}⚠️${NC}  $icon_set.appiconset/Contents.json has incorrect format"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
    
    # Check if we have a source icon to generate sizes from
    SOURCE_ICON="$icon_dir/icon-1024-source.png"
    if [ ! -f "$SOURCE_ICON" ]; then
      SOURCE_ICON="$icon_dir/icon-1024.png"
    fi
    
    # If we have a source icon, generate all sizes
    if [ -f "$SOURCE_ICON" ] && command -v sips >/dev/null 2>&1; then
      echo -e "  ${BLUE}   Generating all icon sizes...${NC}"
      
      # Generate all required sizes
      sips -z 40 40 "$SOURCE_ICON" --out "$icon_dir/icon-20x20@2x.png" >/dev/null 2>&1 || true
      sips -z 60 60 "$SOURCE_ICON" --out "$icon_dir/icon-20x20@3x.png" >/dev/null 2>&1 || true
      sips -z 58 58 "$SOURCE_ICON" --out "$icon_dir/icon-29x29@2x.png" >/dev/null 2>&1 || true
      sips -z 87 87 "$SOURCE_ICON" --out "$icon_dir/icon-29x29@3x.png" >/dev/null 2>&1 || true
      sips -z 80 80 "$SOURCE_ICON" --out "$icon_dir/icon-40x40@2x.png" >/dev/null 2>&1 || true
      sips -z 120 120 "$SOURCE_ICON" --out "$icon_dir/icon-40x40@3x.png" >/dev/null 2>&1 || true
      sips -z 120 120 "$SOURCE_ICON" --out "$icon_dir/icon-60x60@2x.png" >/dev/null 2>&1 || true
      sips -z 180 180 "$SOURCE_ICON" --out "$icon_dir/icon-60x60@3x.png" >/dev/null 2>&1 || true
      sips -z 20 20 "$SOURCE_ICON" --out "$icon_dir/icon-20x20~ipad.png" >/dev/null 2>&1 || true
      sips -z 40 40 "$SOURCE_ICON" --out "$icon_dir/icon-20x20~ipad@2x.png" >/dev/null 2>&1 || true
      sips -z 29 29 "$SOURCE_ICON" --out "$icon_dir/icon-29x29~ipad.png" >/dev/null 2>&1 || true
      sips -z 58 58 "$SOURCE_ICON" --out "$icon_dir/icon-29x29~ipad@2x.png" >/dev/null 2>&1 || true
      sips -z 40 40 "$SOURCE_ICON" --out "$icon_dir/icon-40x40~ipad.png" >/dev/null 2>&1 || true
      sips -z 80 80 "$SOURCE_ICON" --out "$icon_dir/icon-40x40~ipad@2x.png" >/dev/null 2>&1 || true
      sips -z 76 76 "$SOURCE_ICON" --out "$icon_dir/icon-76x76~ipad.png" >/dev/null 2>&1 || true
      sips -z 152 152 "$SOURCE_ICON" --out "$icon_dir/icon-76x76~ipad@2x.png" >/dev/null 2>&1 || true
      sips -z 167 167 "$SOURCE_ICON" --out "$icon_dir/icon-83.5x83.5~ipad@2x.png" >/dev/null 2>&1 || true
      cp "$SOURCE_ICON" "$icon_dir/icon-1024.png" 2>/dev/null || true
    fi
    
    # Create complete Contents.json with correct format
    cat > "$contents_file" << 'EOF'
{
  "images": [
    {
      "filename": "icon-20x20@2x.png",
      "idiom": "iphone",
      "scale": "2x",
      "size": "20x20"
    },
    {
      "filename": "icon-20x20@3x.png",
      "idiom": "iphone",
      "scale": "3x",
      "size": "20x20"
    },
    {
      "filename": "icon-29x29@2x.png",
      "idiom": "iphone",
      "scale": "2x",
      "size": "29x29"
    },
    {
      "filename": "icon-29x29@3x.png",
      "idiom": "iphone",
      "scale": "3x",
      "size": "29x29"
    },
    {
      "filename": "icon-40x40@2x.png",
      "idiom": "iphone",
      "scale": "2x",
      "size": "40x40"
    },
    {
      "filename": "icon-40x40@3x.png",
      "idiom": "iphone",
      "scale": "3x",
      "size": "40x40"
    },
    {
      "filename": "icon-60x60@2x.png",
      "idiom": "iphone",
      "scale": "2x",
      "size": "60x60"
    },
    {
      "filename": "icon-60x60@3x.png",
      "idiom": "iphone",
      "scale": "3x",
      "size": "60x60"
    },
    {
      "filename": "icon-20x20~ipad.png",
      "idiom": "ipad",
      "scale": "1x",
      "size": "20x20"
    },
    {
      "filename": "icon-20x20~ipad@2x.png",
      "idiom": "ipad",
      "scale": "2x",
      "size": "20x20"
    },
    {
      "filename": "icon-29x29~ipad.png",
      "idiom": "ipad",
      "scale": "1x",
      "size": "29x29"
    },
    {
      "filename": "icon-29x29~ipad@2x.png",
      "idiom": "ipad",
      "scale": "2x",
      "size": "29x29"
    },
    {
      "filename": "icon-40x40~ipad.png",
      "idiom": "ipad",
      "scale": "1x",
      "size": "40x40"
    },
    {
      "filename": "icon-40x40~ipad@2x.png",
      "idiom": "ipad",
      "scale": "2x",
      "size": "40x40"
    },
    {
      "filename": "icon-76x76~ipad.png",
      "idiom": "ipad",
      "scale": "1x",
      "size": "76x76"
    },
    {
      "filename": "icon-76x76~ipad@2x.png",
      "idiom": "ipad",
      "scale": "2x",
      "size": "76x76"
    },
    {
      "filename": "icon-83.5x83.5~ipad@2x.png",
      "idiom": "ipad",
      "scale": "2x",
      "size": "83.5x83.5"
    },
    {
      "filename": "icon-1024.png",
      "idiom": "ios-marketing",
      "platform": "ios",
      "size": "1024x1024"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
EOF
    echo -e "  ${GREEN}✅${NC} Fixed Contents.json"
    FIXED_JSON=$((FIXED_JSON + 1))
    FIXES_APPLIED=$((FIXES_APPLIED + 1))
  else
    echo -e "  ${GREEN}✅${NC} $icon_set.appiconset/Contents.json has correct format"
  fi
done
echo ""

# Check 3: Build settings
echo -e "${BOLD}3. Checking build settings...${NC}"
if command -v xcodebuild >/dev/null 2>&1; then
  BUILD_SETTINGS_OK=true
  for config in "Debug" "Debug Develop" "Debug QA" "Debug Preprod"; do
    ICON_NAME=$(xcodebuild -project "$IOS_PROJECT" -scheme "$IOS_PROJECT_NAME" -configuration "$config" -showBuildSettings 2>/dev/null | grep "ASSETCATALOG_COMPILER_APPICON_NAME" | head -1 | awk -F'=' '{print $2}' | xargs || echo "")
    if [ -n "$ICON_NAME" ]; then
      echo -e "  ${GREEN}✅${NC} $config → $ICON_NAME"
    else
      echo -e "  ${YELLOW}⚠️${NC}  $config → Not set (may need to rebuild project)"
      BUILD_SETTINGS_OK=false
    fi
  done
else
  echo -e "  ${YELLOW}⚠️${NC}  xcodebuild not available, skipping build settings check"
fi
echo ""

# Check 4: Asset catalog in project
echo -e "${BOLD}4. Checking asset catalog in Xcode project...${NC}"
if [ -f "$IOS_PROJECT/project.pbxproj" ] && grep -q "Images.xcassets" "$IOS_PROJECT/project.pbxproj"; then
  echo -e "  ${GREEN}✅${NC} Images.xcassets referenced in project"
else
  if [ -d "$IOS_ASSETS_DIR" ]; then
    echo -e "  ${YELLOW}⚠️${NC}  Images.xcassets exists but may not be properly linked in Xcode project"
    echo -e "  ${BLUE}   This is usually fine - Xcode will link it during build${NC}"
  else
    echo -e "  ${RED}❌${NC} Images.xcassets directory not found"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
  fi
fi
echo ""

# Summary
echo -e "${BOLD}${CYAN}Summary:${NC}"
echo "=================================="

if [ ${#MISSING_ICONS[@]} -gt 0 ]; then
  echo -e "${RED}❌ Missing Icons:${NC}"
  for icon_set in "${MISSING_ICONS[@]}"; do
    echo -e "  - $icon_set.appiconset/icon-1024.png"
  done
  echo ""
  echo -e "${YELLOW}💡 Solution:${NC}"
  echo "  Run the icon setup script to add icons:"
  echo -e "  ${CYAN}./setup_ios_icons.sh${NC} (or ${CYAN}../setup_ios_icons.sh${NC} from project root)"
  echo ""
fi

if [ $FIXES_APPLIED -gt 0 ]; then
  echo -e "${GREEN}✅ Fixed $FIXES_APPLIED issue(s)${NC}"
  echo ""
fi

if [ $ISSUES_FOUND -eq 0 ] && [ ${#MISSING_ICONS[@]} -eq 0 ]; then
  echo -e "${GREEN}✅ All icon files and configurations look correct!${NC}"
  echo ""
  echo -e "${YELLOW}💡 If icons still don't appear, try:${NC}"
  echo "  1. Delete the app from simulator/device"
  echo "  2. Clean DerivedData: ${CYAN}rm -rf ~/Library/Developer/Xcode/DerivedData/*${NC}"
  echo "  3. Clean build: ${CYAN}npm run ios:clean${NC}"
  echo "  4. Rebuild: ${CYAN}npm run ios:dev${NC}"
else
  echo -e "${YELLOW}⚠️  $ISSUES_FOUND issue(s) found${NC}"
  echo ""
  echo -e "${BOLD}Next steps:${NC}"
  if [ ${#MISSING_ICONS[@]} -gt 0 ]; then
    echo "  1. Set up icons: ${CYAN}./setup_ios_icons.sh${NC}"
  fi
  echo "  2. Clean build: ${CYAN}npm run ios:clean${NC} (or ${CYAN}./utils/clean_ios_build.sh${NC})"
  echo "  3. Delete app from simulator/device"
  echo "  4. Rebuild: ${CYAN}npm run ios:dev${NC}"
fi
echo ""

