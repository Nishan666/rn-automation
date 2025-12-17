#!/bin/bash

# Fix iOS Icon Contents.json Format
# Updates all Contents.json files to use correct "ios-marketing" idiom

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

echo -e "${BOLD}🔧 Fixing iOS Icon Contents.json Files${NC}"
echo "=========================================="
echo ""

# Find iOS project - use find to get .xcodeproj directory, not files or other directories
IOS_PROJECT=$(find ios -maxdepth 1 -name "*.xcodeproj" -type d 2>/dev/null | head -1 || true)
if [ -z "$IOS_PROJECT" ]; then
  echo -e "${RED}❌ No iOS project found${NC}"
  exit 1
fi

IOS_PROJECT_NAME=$(basename "$IOS_PROJECT" .xcodeproj)
IOS_ASSETS_DIR="ios/$IOS_PROJECT_NAME/Images.xcassets"

FIXED=0
for icon_set in "AppIcon" "AppIconDev" "AppIconQA" "AppIconPreprod"; do
  contents_file="$IOS_ASSETS_DIR/$icon_set.appiconset/Contents.json"
  
  if [ -f "$contents_file" ]; then
    # Check if it needs fixing
    if grep -q '"idiom": "universal"' "$contents_file"; then
      echo -e "${YELLOW}⚠️${NC}  Fixing $icon_set.appiconset/Contents.json"
      
      # Check if we have a source icon to generate sizes from
      SOURCE_ICON="$IOS_ASSETS_DIR/$icon_set.appiconset/icon-1024-source.png"
      if [ ! -f "$SOURCE_ICON" ]; then
        SOURCE_ICON="$IOS_ASSETS_DIR/$icon_set.appiconset/icon-1024.png"
      fi
      
      # If we have a source icon, generate all sizes
      if [ -f "$SOURCE_ICON" ] && command -v sips >/dev/null 2>&1; then
        print_info "Generating all icon sizes for $icon_set..."
        icon_dir="$IOS_ASSETS_DIR/$icon_set.appiconset"
        
        # Generate all required sizes
        sips -z 40 40 "$SOURCE_ICON" --out "$icon_dir/icon-20x20@2x.png" >/dev/null 2>&1
        sips -z 60 60 "$SOURCE_ICON" --out "$icon_dir/icon-20x20@3x.png" >/dev/null 2>&1
        sips -z 58 58 "$SOURCE_ICON" --out "$icon_dir/icon-29x29@2x.png" >/dev/null 2>&1
        sips -z 87 87 "$SOURCE_ICON" --out "$icon_dir/icon-29x29@3x.png" >/dev/null 2>&1
        sips -z 80 80 "$SOURCE_ICON" --out "$icon_dir/icon-40x40@2x.png" >/dev/null 2>&1
        sips -z 120 120 "$SOURCE_ICON" --out "$icon_dir/icon-40x40@3x.png" >/dev/null 2>&1
        sips -z 120 120 "$SOURCE_ICON" --out "$icon_dir/icon-60x60@2x.png" >/dev/null 2>&1
        sips -z 180 180 "$SOURCE_ICON" --out "$icon_dir/icon-60x60@3x.png" >/dev/null 2>&1
        sips -z 20 20 "$SOURCE_ICON" --out "$icon_dir/icon-20x20~ipad.png" >/dev/null 2>&1
        sips -z 40 40 "$SOURCE_ICON" --out "$icon_dir/icon-20x20~ipad@2x.png" >/dev/null 2>&1
        sips -z 29 29 "$SOURCE_ICON" --out "$icon_dir/icon-29x29~ipad.png" >/dev/null 2>&1
        sips -z 58 58 "$SOURCE_ICON" --out "$icon_dir/icon-29x29~ipad@2x.png" >/dev/null 2>&1
        sips -z 40 40 "$SOURCE_ICON" --out "$icon_dir/icon-40x40~ipad.png" >/dev/null 2>&1
        sips -z 80 80 "$SOURCE_ICON" --out "$icon_dir/icon-40x40~ipad@2x.png" >/dev/null 2>&1
        sips -z 76 76 "$SOURCE_ICON" --out "$icon_dir/icon-76x76~ipad.png" >/dev/null 2>&1
        sips -z 152 152 "$SOURCE_ICON" --out "$icon_dir/icon-76x76~ipad@2x.png" >/dev/null 2>&1
        sips -z 167 167 "$SOURCE_ICON" --out "$icon_dir/icon-83.5x83.5~ipad@2x.png" >/dev/null 2>&1
        cp "$SOURCE_ICON" "$icon_dir/icon-1024.png"
      fi
      
      # Create complete Contents.json
      cat > "$contents_file" << EOF
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
      echo -e "  ${GREEN}✅ Fixed${NC}"
      FIXED=$((FIXED + 1))
    else
      echo -e "${GREEN}✅${NC} $icon_set.appiconset/Contents.json already correct"
    fi
  else
    echo -e "${YELLOW}⚠️${NC}  $icon_set.appiconset/Contents.json not found, creating..."
    mkdir -p "$IOS_ASSETS_DIR/$icon_set.appiconset"
    cat > "$contents_file" << EOF
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
    echo -e "  ${GREEN}✅ Created${NC}"
    FIXED=$((FIXED + 1))
  fi
done

echo ""
if [ $FIXED -gt 0 ]; then
  echo -e "${GREEN}✅ Fixed $FIXED Contents.json file(s)${NC}"
  echo ""
  echo -e "${BOLD}Next steps:${NC}"
  echo "  1. Clean build: ${GREEN}npm run ios:clean${NC}"
  echo "  2. Rebuild: ${GREEN}npm run ios:dev${NC}"
else
  echo -e "${GREEN}✅ All Contents.json files are already correct${NC}"
fi

