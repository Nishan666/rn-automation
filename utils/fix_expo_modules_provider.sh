#!/bin/bash

# Script to fix ExpoModulesProvider.swift when modules cannot be found
# This fixes "cannot find 'AssetModule' in scope" and similar errors

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-$PWD}"

cd "$PROJECT_DIR" || exit 1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
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

print_info "Fixing ExpoModulesProvider.swift module resolution issues..."

# Find iOS project
IOS_PROJECT=$(find ios -maxdepth 1 -name "*.xcodeproj" -type d 2>/dev/null | head -1)

if [ -z "$IOS_PROJECT" ]; then
  print_error "No iOS project found in ios/ directory"
  exit 1
fi

IOS_PROJECT_NAME=$(basename "$IOS_PROJECT" .xcodeproj)
print_info "Found iOS project: $IOS_PROJECT_NAME"

# Step 1: Regenerate ExpoModulesProvider.swift by reinstalling pods
print_info "Step 1: Regenerating ExpoModulesProvider.swift..."
cd ios

# Remove the old provider file to force regeneration
PROVIDER_FILE="Pods/Target Support Files/Pods-${IOS_PROJECT_NAME}/ExpoModulesProvider.swift"
if [ -f "$PROVIDER_FILE" ]; then
  print_info "Removing old ExpoModulesProvider.swift to force regeneration..."
  rm -f "$PROVIDER_FILE"
fi

# Run pod install to regenerate the file
print_info "Running pod install to regenerate ExpoModulesProvider.swift..."
if pod install 2>&1 | tee /tmp/pod_install_expo_modules.log; then
  print_success "Pods reinstalled"
else
  print_warning "Pod install had warnings, but continuing..."
fi

cd ..

# Step 2: Fix Xcode project to ensure proper module linking
print_info "Step 2: Fixing Xcode project module linking..."
if command -v ruby >/dev/null 2>&1; then
  IOS_PROJECT_NAME_ENV="$IOS_PROJECT_NAME" ruby - <<'RUBYEOF'
require 'fileutils'
begin
  require 'xcodeproj'
rescue LoadError
  puts "Installing xcodeproj gem..."
  system('gem install xcodeproj --user-install')
  Gem.clear_paths
  require 'xcodeproj'
end

project_name = ENV['IOS_PROJECT_NAME_ENV']
project_path = "ios/#{project_name}.xcodeproj"

unless File.exist?(project_path)
  puts "Error: Project not found at #{project_path}"
  exit 1
end

project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == project_name }

unless target
  target = project.targets.find { |t| t.name.downcase == project_name.downcase }
end

unless target
  target = project.targets.find { |t| t.product_type == "com.apple.product-type.application" }
end

unless target
  puts "Error: Target not found"
  exit 1
end

puts "Found target: #{target.name}"

# Fix all build configurations to ensure Expo modules are found
target.build_configurations.each do |config|
  # Ensure SWIFT_INCLUDE_PATHS includes all Expo module paths
  current_include = config.build_settings['SWIFT_INCLUDE_PATHS'] || '$(inherited)'
  
  # Add paths for Expo modules
  expo_paths = [
    '$(BUILT_PRODUCTS_DIR)/Expo',
    '$(BUILT_PRODUCTS_DIR)/Expo/Expo.swiftmodule',
    '$(BUILT_PRODUCTS_DIR)/ExpoAsset',
    '$(BUILT_PRODUCTS_DIR)/EXConstants',
    '$(BUILT_PRODUCTS_DIR)/ExpoFileSystem',
    '$(BUILT_PRODUCTS_DIR)/ExpoFont',
    '$(BUILT_PRODUCTS_DIR)/ExpoKeepAwake',
    '$(BUILT_PRODUCTS_DIR)/ExpoModulesCore'
  ]
  
  expo_paths.each do |path|
    unless current_include.include?(path)
      base_include = current_include.include?('$(inherited)') ? current_include : "$(inherited) #{current_include}"
      config.build_settings['SWIFT_INCLUDE_PATHS'] = "#{base_include} #{path}".strip
      current_include = config.build_settings['SWIFT_INCLUDE_PATHS']
    end
  end
  
  # Ensure FRAMEWORK_SEARCH_PATHS includes Expo modules
  current_framework = config.build_settings['FRAMEWORK_SEARCH_PATHS'] || '$(inherited)'
  expo_frameworks = [
    '$(BUILT_PRODUCTS_DIR)/Expo',
    '$(BUILT_PRODUCTS_DIR)/ExpoAsset',
    '$(BUILT_PRODUCTS_DIR)/EXConstants',
    '$(BUILT_PRODUCTS_DIR)/ExpoFileSystem',
    '$(BUILT_PRODUCTS_DIR)/ExpoFont',
    '$(BUILT_PRODUCTS_DIR)/ExpoKeepAwake',
    '$(BUILT_PRODUCTS_DIR)/ExpoModulesCore'
  ]
  
  expo_frameworks.each do |framework|
    unless current_framework.include?(framework)
      base_framework = current_framework.include?('$(inherited)') ? current_framework : "$(inherited) #{current_framework}"
      config.build_settings['FRAMEWORK_SEARCH_PATHS'] = "#{base_framework} #{framework}".strip
      current_framework = config.build_settings['FRAMEWORK_SEARCH_PATHS']
    end
  end
  
  # Ensure ALWAYS_SEARCH_USER_PATHS is YES
  config.build_settings['ALWAYS_SEARCH_USER_PATHS'] = 'YES'
  
  # Ensure Swift can find modules from Pods
  config.build_settings['SWIFT_INCLUDE_PATHS'] ||= '$(inherited)'
  unless config.build_settings['SWIFT_INCLUDE_PATHS'].include?('$(PODS_ROOT)')
    config.build_settings['SWIFT_INCLUDE_PATHS'] = "#{config.build_settings['SWIFT_INCLUDE_PATHS']} $(PODS_ROOT)".strip
  end
end

# Ensure ExpoModulesProvider.swift is in the build
provider_file = project.files.find { |f| f.path && f.path.include?('ExpoModulesProvider.swift') }
if provider_file
  # Check if it's already in the target
  unless target.source_build_phase.files.find { |f| f.file_ref == provider_file }
    target.add_file_references([provider_file])
    puts "Added ExpoModulesProvider.swift to target"
  end
end

if project.save
  puts "Success: Fixed Xcode project module linking"
  exit 0
else
  puts "Error: Failed to save project"
  exit 1
end
RUBYEOF

  if [ $? -eq 0 ]; then
    print_success "Xcode project module linking fixed"
  else
    print_warning "Failed to fix Xcode project (may need manual configuration)"
  fi
else
  print_warning "Ruby not found. Skipping Xcode project fixes."
fi

# Step 3: Verify ExpoModulesProvider.swift exists and is valid
print_info "Step 3: Verifying ExpoModulesProvider.swift..."
PROVIDER_FILE="ios/Pods/Target Support Files/Pods-${IOS_PROJECT_NAME}/ExpoModulesProvider.swift"
if [ -f "$PROVIDER_FILE" ]; then
  print_success "ExpoModulesProvider.swift found"
  
  # Check if it has the expected imports
  if grep -q "import ExpoAsset" "$PROVIDER_FILE" && grep -q "import EXConstants" "$PROVIDER_FILE"; then
    print_success "ExpoModulesProvider.swift has expected imports"
  else
    print_warning "ExpoModulesProvider.swift may be missing some imports"
  fi
else
  print_error "ExpoModulesProvider.swift not found after pod install"
  print_info "This file should be generated automatically by expo-modules-autolinking"
  print_info "Try running: cd ios && pod install && cd .."
fi

print_success "Fix completed!"
print_info ""
print_info "Next steps:"
print_info "  1. Clean build folder: npm run ios:clean (or rm -rf ios/build)"
print_info "  2. Try building again: npm run ios:dev"
print_info ""
print_warning "Note: If issues persist, the Expo modules may need to be built first."
print_warning "      The build order script should handle this automatically."

