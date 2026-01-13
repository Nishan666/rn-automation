#!/bin/bash

# Script to fix ExpoAppDelegate inheritance error
# This ensures Expo builds before the app target and Swift can find the module

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

# Find iOS project
IOS_PROJECT=$(find ios -maxdepth 1 -name "*.xcodeproj" -type d 2>/dev/null | head -1)

if [ -z "$IOS_PROJECT" ]; then
  print_error "No iOS project found in ios/ directory"
  exit 1
fi

IOS_PROJECT_NAME=$(basename "$IOS_PROJECT" .xcodeproj)
print_info "Found iOS project: $IOS_PROJECT_NAME"

# Use Ruby to fix the build dependencies and settings
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

# CRITICAL: Update all build configurations to ensure Expo module is found
target.build_configurations.each do |config|
  # Ensure SWIFT_INCLUDE_PATHS includes Expo.swiftmodule
  current_include = config.build_settings['SWIFT_INCLUDE_PATHS'] || '$(inherited)'
  expo_paths = [
    '$(BUILT_PRODUCTS_DIR)/Expo',
    '$(BUILT_PRODUCTS_DIR)/Expo/Expo.swiftmodule'
  ]
  
  expo_paths.each do |path|
    unless current_include.include?(path)
      base_include = current_include.include?('$(inherited)') ? current_include : "$(inherited) #{current_include}"
      config.build_settings['SWIFT_INCLUDE_PATHS'] = "#{base_include} #{path}".strip
      current_include = config.build_settings['SWIFT_INCLUDE_PATHS']
    end
  end
  
  # Ensure FRAMEWORK_SEARCH_PATHS includes Expo
  current_framework = config.build_settings['FRAMEWORK_SEARCH_PATHS'] || '$(inherited)'
  unless current_framework.include?('$(BUILT_PRODUCTS_DIR)/Expo')
    base_framework = current_framework.include?('$(inherited)') ? current_framework : "$(inherited) #{current_framework}"
    config.build_settings['FRAMEWORK_SEARCH_PATHS'] = "#{base_framework} $(BUILT_PRODUCTS_DIR)/Expo".strip
  end
  
  # CRITICAL: Set ALWAYS_SEARCH_USER_PATHS to help Swift find modules
  config.build_settings['ALWAYS_SEARCH_USER_PATHS'] = 'YES'
  
  # Disable module interface emission for app target
  config.build_settings['SWIFT_EMIT_MODULE_INTERFACE'] = 'NO'
  config.build_settings['DEFINES_MODULE'] = 'NO'
end

# Update or create script phase that ensures Expo builds first
sources_phase = target.build_phases.find { |p| p.is_a?(Xcodeproj::Project::Object::PBXSourcesBuildPhase) }
if sources_phase
  script_phase_name = 'Ensure Expo is built before compilation'
  
  # Find existing script
  existing_script = target.build_phases.find { |p|
    p.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) &&
    (p.name == script_phase_name || (p.shell_script && p.shell_script.include?('EXPO_SWIFTMODULE')))
  }
  
  # Remove duplicates
  matching_scripts = target.build_phases.select { |p|
    p.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) &&
    (p.name == script_phase_name || (p.shell_script && p.shell_script.include?('EXPO_SWIFTMODULE')))
  }
  
  if matching_scripts.length > 1
    matching_scripts[1..-1].each { |dup| target.build_phases.delete(dup) }
    existing_script = matching_scripts.first
  end
  
  unless existing_script
    script_phase = target.new_shell_script_build_phase(script_phase_name)
    script_phase.shell_script = <<-SCRIPT
# CRITICAL: Build Expo target first to ensure Expo.swiftmodule exists
# This fixes the "cannot inherit from class 'ExpoAppDelegate'" error

# Try to build Expo target explicitly
if command -v xcodebuild >/dev/null 2>&1; then
  # Build Expo target in Pods project
  EXPO_BUILD_DIR="${BUILT_PRODUCTS_DIR}/../.."
  xcodebuild -project "${EXPO_BUILD_DIR}/Pods/Pods.xcodeproj" \\
    -target Expo \\
    -configuration "${CONFIGURATION}" \\
    -sdk "${SDK_NAME}" \\
    BUILD_DIR="${BUILT_PRODUCTS_DIR}/.." \\
    SYMROOT="${BUILT_PRODUCTS_DIR}/.." \\
    ONLY_ACTIVE_ARCH=NO \\
    CODE_SIGN_IDENTITY="" \\
    CODE_SIGNING_REQUIRED=NO \\
    CODE_SIGNING_ALLOWED=NO \\
    > /dev/null 2>&1 || true
fi

# Verify Expo.swiftmodule exists
EXPO_MODULE_DIR="${BUILT_PRODUCTS_DIR}/Expo"
EXPO_SWIFTMODULE="${EXPO_MODULE_DIR}/Expo.swiftmodule"

if [ ! -d "$EXPO_SWIFTMODULE" ]; then
  echo "Warning: Expo.swiftmodule not found at $EXPO_SWIFTMODULE"
  echo "Expo target may need to build first. This is normal on first build."
fi
SCRIPT
    script_phase.shell_path = '/bin/sh'
    script_phase.show_env_vars_in_log = '0'
    script_phase.always_out_of_date = '0'
    
    sources_index = target.build_phases.index(sources_phase)
    target.build_phases.insert(sources_index, script_phase)
    puts "Added script phase to ensure Expo builds first"
  else
    existing_script.always_out_of_date = '0'
    puts "Updated existing script phase"
  end
end

if project.save
  puts "Success: Fixed ExpoAppDelegate build configuration"
  exit 0
else
  puts "Error: Failed to save project"
  exit 1
end
RUBYEOF

  EXIT_CODE=$?
  
  if [ $EXIT_CODE -eq 0 ]; then
    print_success "Fixed ExpoAppDelegate configuration"
    print_info "Reinstalling pods to apply changes..."
    
    cd ios
    pod install
    cd ..
    
    print_success "Done! Try building again: npm run ios:dev"
  else
    print_error "Failed to fix configuration"
    exit 1
  fi
else
  print_error "Ruby not found. Please install Ruby."
  exit 1
fi


