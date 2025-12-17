#!/bin/bash

# Script to setup iOS app icons for all app icon sets
# Usage: ./setup_ios_app_icons.sh <path_to_1024x1024_icon.png> <ios_project_path>
# Example: ./setup_ios_app_icons.sh ./icon-1024.png ./ios/exampleThree

set -e

SOURCE_ICON="$1"
IOS_PROJECT_PATH="$2"
ASSETS_PATH="${IOS_PROJECT_PATH}/Images.xcassets"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if source icon is provided
if [ -z "$SOURCE_ICON" ] || [ ! -f "$SOURCE_ICON" ]; then
    echo -e "${RED}Error: Source icon file not found or not provided${NC}"
    echo "Usage: $0 <path_to_1024x1024_icon.png> <ios_project_path>"
    exit 1
fi

# Check if iOS project path is provided
if [ -z "$IOS_PROJECT_PATH" ] || [ ! -d "$ASSETS_PATH" ]; then
    echo -e "${RED}Error: iOS project path not found or Images.xcassets doesn't exist${NC}"
    echo "Usage: $0 <path_to_1024x1024_icon.png> <ios_project_path>"
    exit 1
fi

# Check if sips is available (macOS only)
if ! command -v sips &> /dev/null; then
    echo -e "${RED}Error: sips command not found. This script requires macOS.${NC}"
    exit 1
fi

# Function to generate all icon sizes for an app icon set
generate_icon_set() {
    local ICON_SET_NAME="$1"
    local ICON_SET_PATH="${ASSETS_PATH}/${ICON_SET_NAME}.appiconset"
    local SOURCE_ICON_PATH="$2"
    
    echo -e "${YELLOW}Setting up ${ICON_SET_NAME}...${NC}"
    
    # Create directory if it doesn't exist
    mkdir -p "$ICON_SET_PATH"
    
    # Copy source icon to the icon set directory
    cp "$SOURCE_ICON_PATH" "${ICON_SET_PATH}/icon-1024.png"
    
    # Generate iPhone icons
    echo "  Generating iPhone icons..."
    sips -z 40 40 "${ICON_SET_PATH}/icon-1024.png" --out "${ICON_SET_PATH}/icon-20@2x.png" > /dev/null 2>&1
    sips -z 60 60 "${ICON_SET_PATH}/icon-1024.png" --out "${ICON_SET_PATH}/icon-20@3x.png" > /dev/null 2>&1
    sips -z 58 58 "${ICON_SET_PATH}/icon-1024.png" --out "${ICON_SET_PATH}/icon-29@2x.png" > /dev/null 2>&1
    sips -z 87 87 "${ICON_SET_PATH}/icon-1024.png" --out "${ICON_SET_PATH}/icon-29@3x.png" > /dev/null 2>&1
    sips -z 80 80 "${ICON_SET_PATH}/icon-1024.png" --out "${ICON_SET_PATH}/icon-40@2x.png" > /dev/null 2>&1
    sips -z 120 120 "${ICON_SET_PATH}/icon-1024.png" --out "${ICON_SET_PATH}/icon-40@3x.png" > /dev/null 2>&1
    sips -z 120 120 "${ICON_SET_PATH}/icon-1024.png" --out "${ICON_SET_PATH}/icon-60@2x.png" > /dev/null 2>&1
    sips -z 180 180 "${ICON_SET_PATH}/icon-1024.png" --out "${ICON_SET_PATH}/icon-60@3x.png" > /dev/null 2>&1
    
    # Generate iPad icons
    echo "  Generating iPad icons..."
    sips -z 20 20 "${ICON_SET_PATH}/icon-1024.png" --out "${ICON_SET_PATH}/icon-20-ipad.png" > /dev/null 2>&1
    sips -z 40 40 "${ICON_SET_PATH}/icon-1024.png" --out "${ICON_SET_PATH}/icon-20-ipad@2x.png" > /dev/null 2>&1
    sips -z 29 29 "${ICON_SET_PATH}/icon-1024.png" --out "${ICON_SET_PATH}/icon-29-ipad.png" > /dev/null 2>&1
    sips -z 58 58 "${ICON_SET_PATH}/icon-1024.png" --out "${ICON_SET_PATH}/icon-29-ipad@2x.png" > /dev/null 2>&1
    sips -z 40 40 "${ICON_SET_PATH}/icon-1024.png" --out "${ICON_SET_PATH}/icon-40-ipad.png" > /dev/null 2>&1
    sips -z 80 80 "${ICON_SET_PATH}/icon-1024.png" --out "${ICON_SET_PATH}/icon-40-ipad@2x.png" > /dev/null 2>&1
    sips -z 76 76 "${ICON_SET_PATH}/icon-1024.png" --out "${ICON_SET_PATH}/icon-76-ipad.png" > /dev/null 2>&1
    sips -z 152 152 "${ICON_SET_PATH}/icon-1024.png" --out "${ICON_SET_PATH}/icon-76-ipad@2x.png" > /dev/null 2>&1
    sips -z 167 167 "${ICON_SET_PATH}/icon-1024.png" --out "${ICON_SET_PATH}/icon-83.5-ipad@2x.png" > /dev/null 2>&1
    
    # Create Contents.json
    echo "  Creating Contents.json..."
    cat > "${ICON_SET_PATH}/Contents.json" << 'EOF'
{
  "images": [
    {
      "filename": "icon-20@2x.png",
      "idiom": "iphone",
      "scale": "2x",
      "size": "20x20"
    },
    {
      "filename": "icon-20@3x.png",
      "idiom": "iphone",
      "scale": "3x",
      "size": "20x20"
    },
    {
      "filename": "icon-29@2x.png",
      "idiom": "iphone",
      "scale": "2x",
      "size": "29x29"
    },
    {
      "filename": "icon-29@3x.png",
      "idiom": "iphone",
      "scale": "3x",
      "size": "29x29"
    },
    {
      "filename": "icon-40@2x.png",
      "idiom": "iphone",
      "scale": "2x",
      "size": "40x40"
    },
    {
      "filename": "icon-40@3x.png",
      "idiom": "iphone",
      "scale": "3x",
      "size": "40x40"
    },
    {
      "filename": "icon-60@2x.png",
      "idiom": "iphone",
      "scale": "2x",
      "size": "60x60"
    },
    {
      "filename": "icon-60@3x.png",
      "idiom": "iphone",
      "scale": "3x",
      "size": "60x60"
    },
    {
      "filename": "icon-20-ipad.png",
      "idiom": "ipad",
      "scale": "1x",
      "size": "20x20"
    },
    {
      "filename": "icon-20-ipad@2x.png",
      "idiom": "ipad",
      "scale": "2x",
      "size": "20x20"
    },
    {
      "filename": "icon-29-ipad.png",
      "idiom": "ipad",
      "scale": "1x",
      "size": "29x29"
    },
    {
      "filename": "icon-29-ipad@2x.png",
      "idiom": "ipad",
      "scale": "2x",
      "size": "29x29"
    },
    {
      "filename": "icon-40-ipad.png",
      "idiom": "ipad",
      "scale": "1x",
      "size": "40x40"
    },
    {
      "filename": "icon-40-ipad@2x.png",
      "idiom": "ipad",
      "scale": "2x",
      "size": "40x40"
    },
    {
      "filename": "icon-76-ipad.png",
      "idiom": "ipad",
      "scale": "1x",
      "size": "76x76"
    },
    {
      "filename": "icon-76-ipad@2x.png",
      "idiom": "ipad",
      "scale": "2x",
      "size": "76x76"
    },
    {
      "filename": "icon-83.5-ipad@2x.png",
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
    
    echo -e "${GREEN}  ✓ ${ICON_SET_NAME} setup complete${NC}"
}

# Main execution
echo -e "${GREEN}Starting iOS app icon setup...${NC}"
echo "Source icon: $SOURCE_ICON"
echo "iOS project path: $IOS_PROJECT_PATH"
echo ""

# List of app icon sets to configure
# Add or remove icon sets based on your project's needs
ICON_SETS=("AppIcon" "AppIconDev" "AppIconQA" "AppIconPreprod")

# Generate icons for each app icon set
for ICON_SET in "${ICON_SETS[@]}"; do
    if [ -d "${ASSETS_PATH}/${ICON_SET}.appiconset" ]; then
        generate_icon_set "$ICON_SET" "$SOURCE_ICON"
    else
        echo -e "${YELLOW}Warning: ${ICON_SET}.appiconset not found, skipping...${NC}"
    fi
done

echo ""
echo -e "${GREEN}✓ All app icons have been set up successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Clean your Xcode build folder (Product → Clean Build Folder)"
echo "2. Rebuild your iOS app"
echo "3. The app icon should now appear correctly"


