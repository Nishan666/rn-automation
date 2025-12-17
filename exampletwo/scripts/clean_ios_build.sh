#!/bin/bash

# Clean iOS Build Script
# Cleans Xcode build folders and derived data from command line
# Usage: ./clean_ios_build.sh [project_directory]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

print_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

# Get project directory
PROJECT_DIR="${1:-.}"
if [ ! -d "$PROJECT_DIR" ]; then
  echo -e "${RED}Error: Directory not found: $PROJECT_DIR${NC}" >&2
  exit 1
fi

cd "$PROJECT_DIR"

# Find iOS project
IOS_PROJECT=$(ls ios/*.xcodeproj 2>/dev/null | head -1 || true)
if [ -z "$IOS_PROJECT" ]; then
  echo -e "${RED}Error: No iOS project found.${NC}" >&2
  exit 1
fi

IOS_PROJECT_NAME=$(basename "$IOS_PROJECT" .xcodeproj)

print_info "Cleaning iOS build for: $IOS_PROJECT_NAME"
echo ""

# Method 1: Use xcodebuild clean (if available)
if command -v xcodebuild >/dev/null 2>&1; then
  print_info "Cleaning with xcodebuild..."
  
  # Clean all build configurations
  for config in "Debug" "Release" "Debug Develop" "Release Develop" "Debug QA" "Release QA" "Debug Preprod" "Release Preprod"; do
    if xcodebuild -project "$IOS_PROJECT" -scheme "$IOS_PROJECT_NAME" -configuration "$config" clean >/dev/null 2>&1; then
      print_success "Cleaned $config configuration"
    fi
  done
else
  print_warning "xcodebuild not found, using manual cleanup..."
fi

# Method 2: Remove build directories
print_info "Removing build directories..."

# Remove project build directory
if [ -d "ios/build" ]; then
  rm -rf "ios/build"
  print_success "Removed ios/build"
fi

# Remove Xcode build directory in project
if [ -d "$IOS_PROJECT/build" ]; then
  rm -rf "$IOS_PROJECT/build"
  print_success "Removed $IOS_PROJECT/build"
fi

# Remove workspace build directory
IOS_WORKSPACE=$(ls ios/*.xcworkspace 2>/dev/null | head -1 || true)
if [ -n "$IOS_WORKSPACE" ] && [ -d "$IOS_WORKSPACE/build" ]; then
  rm -rf "$IOS_WORKSPACE/build"
  print_success "Removed workspace build directory"
fi

# Remove DerivedData (optional, more aggressive)
print_info "Cleaning DerivedData..."
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
if [ -d "$DERIVED_DATA" ]; then
  # Find and remove project-specific derived data
  PROJECT_DERIVED=$(find "$DERIVED_DATA" -maxdepth 1 -type d -name "*$IOS_PROJECT_NAME*" 2>/dev/null || true)
  if [ -n "$PROJECT_DERIVED" ]; then
    rm -rf $PROJECT_DERIVED
    print_success "Removed project DerivedData"
  else
    print_info "No project-specific DerivedData found"
  fi
fi

# Clean CocoaPods build
if [ -d "ios/Pods" ]; then
  print_info "Cleaning CocoaPods..."
  cd ios
  if command -v pod >/dev/null 2>&1; then
    pod cache clean --all >/dev/null 2>&1 || true
  fi
  cd ..
fi

echo ""
print_success "iOS build cleaned successfully!"
print_info "You can now rebuild your app with: npm run ios:dev (or your preferred environment)"

