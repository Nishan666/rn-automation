#!/bin/bash

# iOS App Icon Setup Script
# This script helps you set up app icons for all iOS environments
# Usage: ./setup_ios_icons.sh [project_directory]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

print_header() {
  echo -e "${CYAN}${BOLD}===================================${NC}"
  echo -e "${CYAN}${BOLD}🎨 iOS App Icon Setup${NC}"
  echo -e "${CYAN}${BOLD}===================================${NC}"
  echo ""
}

print_step() {
  echo -e "${BLUE}▶ $1${NC}"
}

print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
  echo -e "${RED}❌ $1${NC}"
}

print_info() {
  echo -e "${PURPLE}ℹ️  $1${NC}"
}

# Get project directory
PROJECT_DIR="${1:-.}"
if [ ! -d "$PROJECT_DIR" ]; then
  print_error "Directory not found: $PROJECT_DIR"
  exit 1
fi

cd "$PROJECT_DIR"

# Find iOS project - use find to get .xcodeproj directory, not files or other directories
IOS_PROJECT=$(find ios -maxdepth 1 -name "*.xcodeproj" -type d 2>/dev/null | head -1 || true)
if [ -z "$IOS_PROJECT" ]; then
  print_error "No iOS project found. Make sure you're in a React Native project directory."
  exit 1
fi

IOS_PROJECT_NAME=$(basename "$IOS_PROJECT" .xcodeproj)
IOS_ASSETS_DIR="ios/$IOS_PROJECT_NAME/Images.xcassets"

if [ ! -d "$IOS_ASSETS_DIR" ]; then
  print_error "Images.xcassets directory not found: $IOS_ASSETS_DIR"
  exit 1
fi

clear
print_header

print_info "Found iOS project: $IOS_PROJECT_NAME"
echo ""

# Source file browser utility if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/utils/file_browser.sh" ]; then
  source "$SCRIPT_DIR/utils/file_browser.sh"
  USE_BROWSER=true
else
  USE_BROWSER=false
  print_warning "File browser utility not found. Using manual input."
fi

# Function to setup icon for an environment
setup_icon_for_env() {
  local env="$1"
  local icon_set_name="$2"
  local icon_dir="$IOS_ASSETS_DIR/$icon_set_name.appiconset"
  
  print_step "Setting up icon for $env environment..."
  
  # Ensure directory exists
  mkdir -p "$icon_dir"
  
  # Get icon file
  if [ "$USE_BROWSER" = true ]; then
    echo -e "${BOLD}Select icon file for $env (1024x1024 PNG recommended):${NC}"
    ICON_PATH=$(browse_files "$HOME" "png|PNG" "file")
  else
    echo -e "${BOLD}Enter path to icon file for $env (1024x1024 PNG recommended):${NC}"
    read -p "📁 " ICON_PATH
    # Expand tilde
    ICON_PATH="${ICON_PATH/#\~/$HOME}"
  fi
  
  if [ -z "$ICON_PATH" ] || [ ! -f "$ICON_PATH" ]; then
    print_warning "No valid icon file provided for $env. Skipping."
    return 1
  fi
  
  # Copy source icon
  cp "$ICON_PATH" "$icon_dir/icon-1024-source.png"
  
  # Generate all required icon sizes using sips (macOS built-in)
  print_info "Generating all required iOS icon sizes..."
  if command -v sips >/dev/null 2>&1; then
    # iPhone icons
    sips -z 40 40 "$ICON_PATH" --out "$icon_dir/icon-20x20@2x.png" >/dev/null 2>&1
    sips -z 60 60 "$ICON_PATH" --out "$icon_dir/icon-20x20@3x.png" >/dev/null 2>&1
    sips -z 58 58 "$ICON_PATH" --out "$icon_dir/icon-29x29@2x.png" >/dev/null 2>&1
    sips -z 87 87 "$ICON_PATH" --out "$icon_dir/icon-29x29@3x.png" >/dev/null 2>&1
    sips -z 80 80 "$ICON_PATH" --out "$icon_dir/icon-40x40@2x.png" >/dev/null 2>&1
    sips -z 120 120 "$ICON_PATH" --out "$icon_dir/icon-40x40@3x.png" >/dev/null 2>&1
    sips -z 120 120 "$ICON_PATH" --out "$icon_dir/icon-60x60@2x.png" >/dev/null 2>&1
    sips -z 180 180 "$ICON_PATH" --out "$icon_dir/icon-60x60@3x.png" >/dev/null 2>&1
    
    # iPad icons
    sips -z 20 20 "$ICON_PATH" --out "$icon_dir/icon-20x20~ipad.png" >/dev/null 2>&1
    sips -z 40 40 "$ICON_PATH" --out "$icon_dir/icon-20x20~ipad@2x.png" >/dev/null 2>&1
    sips -z 29 29 "$ICON_PATH" --out "$icon_dir/icon-29x29~ipad.png" >/dev/null 2>&1
    sips -z 58 58 "$ICON_PATH" --out "$icon_dir/icon-29x29~ipad@2x.png" >/dev/null 2>&1
    sips -z 40 40 "$ICON_PATH" --out "$icon_dir/icon-40x40~ipad.png" >/dev/null 2>&1
    sips -z 80 80 "$ICON_PATH" --out "$icon_dir/icon-40x40~ipad@2x.png" >/dev/null 2>&1
    sips -z 76 76 "$ICON_PATH" --out "$icon_dir/icon-76x76~ipad.png" >/dev/null 2>&1
    sips -z 152 152 "$ICON_PATH" --out "$icon_dir/icon-76x76~ipad@2x.png" >/dev/null 2>&1
    sips -z 167 167 "$ICON_PATH" --out "$icon_dir/icon-83.5x83.5~ipad@2x.png" >/dev/null 2>&1
    
    # App Store icon (1024x1024)
    cp "$ICON_PATH" "$icon_dir/icon-1024.png"
    
    print_success "Generated all 18 required icon sizes"
  else
    print_warning "sips not found, only copying 1024x1024 icon"
    cp "$ICON_PATH" "$icon_dir/icon-1024.png"
  fi
  
  # Create complete Contents.json with all required sizes
  cat > "$icon_dir/Contents.json" << EOF
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
  
  print_success "Icon set up for $env environment"
  echo ""
}

# Setup icons for each environment
for env_info in "production:AppIcon" "develop:AppIconDev" "qa:AppIconQA" "preprod:AppIconPreprod"; do
  env=$(echo "$env_info" | cut -d: -f1)
  icon_set=$(echo "$env_info" | cut -d: -f2)
  setup_icon_for_env "$env" "$icon_set"
done

print_success "All icons set up!"
echo ""
print_info "Next steps (all from terminal/VSCode):"
echo -e "  ${CYAN}1.${NC} Clean build folder: ${GREEN}npm run ios:clean${NC} (or ./utils/clean_ios_build.sh)"
echo -e "  ${CYAN}2.${NC} Rebuild your app: ${GREEN}npm run ios:dev${NC} (or your preferred environment)"
echo -e "  ${CYAN}3.${NC} Verify icons appear correctly in the app"
echo ""
print_info "To verify icon configuration (command line):"
echo -e "  ${CYAN}1.${NC} Check icon files exist:"
echo -e "     ${PURPLE}ls -la ios/$IOS_PROJECT_NAME/Images.xcassets/*/icon-1024.png${NC}"
echo -e "  ${CYAN}2.${NC} Verify Contents.json format:"
echo -e "     ${PURPLE}cat ios/$IOS_PROJECT_NAME/Images.xcassets/AppIcon.appiconset/Contents.json${NC}"
echo -e "  ${CYAN}3.${NC} Check build settings (if xcodebuild available):"
echo -e "     ${PURPLE}xcodebuild -project ios/$IOS_PROJECT_NAME.xcodeproj -showBuildSettings | grep ASSETCATALOG_COMPILER_APPICON_NAME${NC}"
echo ""

