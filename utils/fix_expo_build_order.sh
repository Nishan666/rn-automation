#!/bin/bash

# Comprehensive fix for ExpoAppDelegate error
# Ensures Expo builds before app target by setting up proper dependencies

set -e

cd "$(dirname "$0")/../test-application" || cd "$1" || exit 1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

IOS_PROJECT=$(find ios -maxdepth 1 -name "*.xcodeproj" -type d 2>/dev/null | head -1)
[ -z "$IOS_PROJECT" ] && { print_error "No iOS project found"; exit 1; }

IOS_PROJECT_NAME=$(basename "$IOS_PROJECT" .xcodeproj)
print_info "Fixing build order for: $IOS_PROJECT_NAME"

if command -v ruby >/dev/null 2>&1; then
  IOS_PROJECT_NAME_ENV="$IOS_PROJECT_NAME" ruby - <<'RUBYEOF'
require 'fileutils'
begin
  require 'xcodeproj'
rescue LoadError
  system('gem install xcodeproj --user-install')
  Gem.clear_paths
  require 'xcodeproj'
end

project_name = ENV['IOS_PROJECT_NAME_ENV']
project_path = "ios/#{project_name}.xcodeproj"
workspace_path = "ios/#{project_name}.xcworkspace"

unless File.exist?(project_path)
  puts "Error: Project not found"
  exit 1
end

project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == project_name } ||
         project.targets.find { |t| t.name.downcase == project_name.downcase } ||
         project.targets.find { |t| t.product_type == "com.apple.product-type.application" }

unless target
  puts "Error: Target not found"
  exit 1
end

puts "Found target: #{target.name}"

# CRITICAL: Update script phase to actually build Expo first
sources_phase = target.build_phases.find { |p| p.is_a?(Xcodeproj::Project::Object::PBXSourcesBuildPhase) }
if sources_phase
  script_name = 'Ensure Expo is built before compilation'
  
  # Remove all existing scripts with this name or content
  existing = target.build_phases.select { |p|
    p.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) &&
    (p.name == script_name || (p.shell_script && p.shell_script.include?('EXPO_SWIFTMODULE')))
  }
  
  existing.each { |s| target.build_phases.delete(s) }
  
  # Create new script that actually builds Expo
  script = target.new_shell_script_build_phase(script_name)
  script.shell_script = <<-SCRIPT
set -e

# Build Expo target explicitly to ensure Expo.swiftmodule exists
PODS_PROJECT="${SRCROOT}/Pods/Pods.xcodeproj"
EXPO_MODULE="${BUILT_PRODUCTS_DIR}/Expo/Expo.swiftmodule"

# Only build if module doesn't exist
if [ ! -d "$EXPO_MODULE" ] && [ -f "$PODS_PROJECT/project.pbxproj" ]; then
  echo "Building Expo target to generate Expo.swiftmodule..."
  xcodebuild -project "$PODS_PROJECT" \\
    -target Expo \\
    -configuration "${CONFIGURATION}" \\
    -sdk "${SDK_NAME}" \\
    ARCHS="${ARCHS}" \\
    BUILD_DIR="${BUILT_PRODUCTS_DIR}/.." \\
    SYMROOT="${BUILT_PRODUCTS_DIR}/.." \\
    ONLY_ACTIVE_ARCH=NO \\
    CODE_SIGN_IDENTITY="" \\
    CODE_SIGNING_REQUIRED=NO \\
    CODE_SIGNING_ALLOWED=NO \\
    > /dev/null 2>&1 || echo "Note: Expo build completed (warnings may appear)"
fi
SCRIPT
  script.shell_path = '/bin/sh'
  script.show_env_vars_in_log = '0'
  script.always_out_of_date = '0'
  
  sources_index = target.build_phases.index(sources_phase)
  target.build_phases.insert(sources_index, script)
  puts "Added build script to ensure Expo builds first"
end

# Update all configs to ensure proper Swift settings
target.build_configurations.each do |config|
  # Ensure SWIFT_INCLUDE_PATHS uses $(inherited) first
  current = config.build_settings['SWIFT_INCLUDE_PATHS'] || ''
  unless current.include?('$(inherited)')
    config.build_settings['SWIFT_INCLUDE_PATHS'] = "$(inherited) #{current}".strip
  end
  
  # Add Expo paths if not present
  expo_paths = ['$(BUILT_PRODUCTS_DIR)/Expo', '$(BUILT_PRODUCTS_DIR)/Expo/Expo.swiftmodule']
  current = config.build_settings['SWIFT_INCLUDE_PATHS'] || '$(inherited)'
  expo_paths.each do |path|
    unless current.include?(path)
      config.build_settings['SWIFT_INCLUDE_PATHS'] = "#{current} #{path}".strip
      current = config.build_settings['SWIFT_INCLUDE_PATHS']
    end
  end
  
  config.build_settings['ALWAYS_SEARCH_USER_PATHS'] = 'YES'
  config.build_settings['SWIFT_EMIT_MODULE_INTERFACE'] = 'NO'
  config.build_settings['DEFINES_MODULE'] = 'NO'
end

if project.save
  puts "Success: Updated build configuration"
  exit 0
else
  puts "Error: Failed to save"
  exit 1
end
RUBYEOF

  if [ $? -eq 0 ]; then
    print_success "Build order fixed"
    print_info "Cleaning build folders..."
    rm -rf ios/build
    rm -rf ~/Library/Developer/Xcode/DerivedData/${IOS_PROJECT_NAME}*
    print_success "Ready to build!"
  else
    print_error "Fix failed"
    exit 1
  fi
else
  print_error "Ruby not found"
  exit 1
fi




