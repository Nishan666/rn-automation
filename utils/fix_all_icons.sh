#!/bin/bash

# Complete Icon Fix Script
# Fixes Contents.json and ensures icons are properly set up

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

PROJECT_DIR="${1:-.}"
if [ ! -d "$PROJECT_DIR" ]; then
  echo -e "${RED}Error: Directory not found: $PROJECT_DIR${NC}" >&2
  exit 1
fi
cd "$PROJECT_DIR"

echo -e "${BOLD}🔧 Complete Icon Fix${NC}"
echo "======================"
echo ""

# Step 1: Fix Contents.json
echo -e "${BLUE}Step 1: Fixing Contents.json files...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/fix_icon_contents.sh" "$PROJECT_DIR"
echo ""

# Step 2: Clean build
echo -e "${BLUE}Step 2: Cleaning build folders...${NC}"
if [ -f "package.json" ] && grep -q '"ios:clean"' package.json; then
  npm run ios:clean
else
  bash "$SCRIPT_DIR/clean_ios_build.sh" "$PROJECT_DIR"
fi
echo ""

echo -e "${GREEN}✅ Icon fix complete!${NC}"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo "  1. Rebuild your app: ${GREEN}npm run ios:dev${NC}"
echo "  2. If icons still don't appear, try:"
echo "     - Delete app from simulator/device"
echo "     - Run: ${GREEN}rm -rf ~/Library/Developer/Xcode/DerivedData/*${NC}"
echo "     - Rebuild again"


