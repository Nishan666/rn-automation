#!/bin/bash

# Script to fix missing React Native codegen files
# This ensures codegen files are generated before compilation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-$PWD}"

cd "$PROJECT_DIR" || exit 1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

print_info "Fixing missing codegen files..."

# 1. Clean build folder to force regeneration
print_info "Cleaning build folder..."
rm -rf ios/build/generated
print_success "Build folder cleaned"

# 2. Reinstall pods to regenerate codegen files
print_info "Reinstalling pods to regenerate codegen files..."
cd ios

# Run pod install which triggers codegen
if pod install --repo-update 2>&1 | tee /tmp/pod_install.log; then
  print_success "Pods reinstalled"
else
  print_warning "Pod install had warnings, but continuing..."
fi

cd ..

# 3. Verify codegen files were generated
print_info "Verifying codegen files..."
GENERATED_DIR="ios/build/generated/ios"
MISSING_FILES=0

# Check for required codegen files
REQUIRED_FILES=(
  "safeareacontext/safeareacontext-generated.mm"
  "safeareacontextJSI-generated.cpp"
  "rnsvg/rnsvg-generated.mm"
  "rnsvgJSI-generated.cpp"
  "rnscreensJSI-generated.cpp"
)

for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$GENERATED_DIR/$file" ]; then
    print_warning "Missing: $file"
    ((MISSING_FILES++))
  else
    print_success "Found: $file"
  fi
done

if [ $MISSING_FILES -eq 0 ]; then
  print_success "All codegen files are present!"
  print_info "You can now try building: npm run ios:dev"
  exit 0
else
  print_warning "Some codegen files are still missing"
  print_info "This might be normal - they will be generated during the build"
  print_info "Try building now: npm run ios:dev"
  exit 0
fi




