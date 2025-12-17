#!/bin/bash

# Fix Icon Location Script
# Moves icons from wrong location (ios/project.pbxproj/Images.xcassets/) 
# to correct location (ios/[PROJECT_NAME]/Images.xcassets/)

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

echo -e "${BOLD}${CYAN}🔧 Fixing Icon Locations${NC}"
echo "=========================="
echo ""

# Find iOS project
IOS_PROJECT=$(find ios -maxdepth 1 -name "*.xcodeproj" -type d 2>/dev/null | head -1 || true)
if [ -z "$IOS_PROJECT" ]; then
  echo -e "${RED}❌ No iOS project found in: $PROJECT_DIR${NC}"
  echo ""
  echo "Usage: ./utils/fix_icon_location.sh [project_directory]"
  exit 1
fi

IOS_PROJECT_NAME=$(basename "$IOS_PROJECT" .xcodeproj)
CORRECT_LOCATION="ios/$IOS_PROJECT_NAME/Images.xcassets"
WRONG_LOCATION="ios/project.pbxproj/Images.xcassets"

echo -e "${BLUE}Project:${NC} $IOS_PROJECT_NAME"
echo ""

# Check if icons are in wrong location
if [ ! -d "$WRONG_LOCATION" ]; then
  echo -e "${GREEN}✅ Icons are not in the wrong location${NC}"
  echo ""
  echo "Checking if icons are in correct location..."
  MISSING_COUNT=0
  for icon_set in "AppIcon" "AppIconDev" "AppIconQA" "AppIconPreprod"; do
    icon_file="$CORRECT_LOCATION/$icon_set.appiconset/icon-1024.png"
    if [ ! -f "$icon_file" ]; then
      echo -e "  ${RED}❌${NC} $icon_set.appiconset/icon-1024.png MISSING"
      MISSING_COUNT=$((MISSING_COUNT + 1))
    else
      echo -e "  ${GREEN}✅${NC} $icon_set.appiconset/icon-1024.png exists"
    fi
  done
  
  if [ $MISSING_COUNT -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ All icons are in the correct location!${NC}"
    exit 0
  else
    echo ""
    echo -e "${YELLOW}⚠️  $MISSING_COUNT icon(s) missing. Run setup_ios_icons.sh to add them.${NC}"
    exit 1
  fi
fi

# Icons found in wrong location - fix them
echo -e "${YELLOW}⚠️  Found icons in wrong location: $WRONG_LOCATION${NC}"
echo -e "${BLUE}Moving icons to correct location: $CORRECT_LOCATION${NC}"
echo ""

FIXED=0
for icon_set in "AppIcon" "AppIconDev" "AppIconQA" "AppIconPreprod"; do
  wrong_icon="$WRONG_LOCATION/$icon_set.appiconset/icon-1024.png"
  correct_dir="$CORRECT_LOCATION/$icon_set.appiconset"
  
  if [ -f "$wrong_icon" ]; then
    # Ensure correct directory exists
    mkdir -p "$correct_dir"
    
    # Copy icon
    cp "$wrong_icon" "$correct_dir/icon-1024.png"
    echo -e "  ${GREEN}✅${NC} Moved $icon_set.appiconset/icon-1024.png"
    FIXED=$((FIXED + 1))
    
    # Generate all required icon sizes if sips is available
    if command -v sips >/dev/null 2>&1; then
      echo -e "    ${BLUE}Generating all icon sizes...${NC}"
      source_icon="$correct_dir/icon-1024.png"
      
      sips -z 40 40 "$source_icon" --out "$correct_dir/icon-20x20@2x.png" >/dev/null 2>&1 || true
      sips -z 60 60 "$source_icon" --out "$correct_dir/icon-20x20@3x.png" >/dev/null 2>&1 || true
      sips -z 58 58 "$source_icon" --out "$correct_dir/icon-29x29@2x.png" >/dev/null 2>&1 || true
      sips -z 87 87 "$source_icon" --out "$correct_dir/icon-29x29@3x.png" >/dev/null 2>&1 || true
      sips -z 80 80 "$source_icon" --out "$correct_dir/icon-40x40@2x.png" >/dev/null 2>&1 || true
      sips -z 120 120 "$source_icon" --out "$correct_dir/icon-40x40@3x.png" >/dev/null 2>&1 || true
      sips -z 120 120 "$source_icon" --out "$correct_dir/icon-60x60@2x.png" >/dev/null 2>&1 || true
      sips -z 180 180 "$source_icon" --out "$correct_dir/icon-60x60@3x.png" >/dev/null 2>&1 || true
      sips -z 20 20 "$source_icon" --out "$correct_dir/icon-20x20~ipad.png" >/dev/null 2>&1 || true
      sips -z 40 40 "$source_icon" --out "$correct_dir/icon-20x20~ipad@2x.png" >/dev/null 2>&1 || true
      sips -z 29 29 "$source_icon" --out "$correct_dir/icon-29x29~ipad.png" >/dev/null 2>&1 || true
      sips -z 58 58 "$source_icon" --out "$correct_dir/icon-29x29~ipad@2x.png" >/dev/null 2>&1 || true
      sips -z 40 40 "$source_icon" --out "$correct_dir/icon-40x40~ipad.png" >/dev/null 2>&1 || true
      sips -z 80 80 "$source_icon" --out "$correct_dir/icon-40x40~ipad@2x.png" >/dev/null 2>&1 || true
      sips -z 76 76 "$source_icon" --out "$correct_dir/icon-76x76~ipad.png" >/dev/null 2>&1 || true
      sips -z 152 152 "$source_icon" --out "$correct_dir/icon-76x76~ipad@2x.png" >/dev/null 2>&1 || true
      sips -z 167 167 "$source_icon" --out "$correct_dir/icon-83.5x83.5~ipad@2x.png" >/dev/null 2>&1 || true
      echo -e "    ${GREEN}✅ Generated all 18 icon sizes${NC}"
    fi
  else
    echo -e "  ${YELLOW}⚠️${NC}  $icon_set.appiconset/icon-1024.png not found in wrong location"
  fi
done

echo ""
if [ $FIXED -gt 0 ]; then
  echo -e "${GREEN}✅ Fixed $FIXED icon set(s)!${NC}"
  echo ""
  echo -e "${BOLD}Next steps:${NC}"
  echo "  1. Clean build: ${CYAN}npm run ios:clean${NC} (or ${CYAN}../utils/clean_ios_build.sh${NC})"
  echo "  2. Delete app from simulator/device"
  echo "  3. Rebuild: ${CYAN}npm run ios:dev${NC}"
else
  echo -e "${YELLOW}⚠️  No icons found to fix${NC}"
fi
echo ""


