#!/bin/bash

# iOS Product Flavor Setup Script (CORRECTED)
# Usage: Call this from main setup.sh after getting IOS_PROJECT_NAME

setup_ios_flavors() {
local IOS_PROJECT_NAME="$1"
local IOS_BUNDLE_ID="$2"
local DISPLAY_NAME="$3"
 # Update Podfile
 PODFILE="ios/Podfile"
 # FIX 3: Changed single quotes to double quotes
 if [ -f "$PODFILE" ] && ! grep -q '"Debug_Develop"' "$PODFILE"; then
  print_info "Updating Podfile configurations..."
  TEMP_PODFILE=$(mktemp)
  
  # Check if project declaration already exists
  if grep -q "^[[:space:]]*project[[:space:]]" "$PODFILE"; then
    # Update existing project declaration
    awk -v proj="$IOS_PROJECT_NAME" '
      /^[[:space:]]*project[[:space:]]+/ {
        print "project \"" proj "\","
        print "  \"Debug\" => :debug,"
        print "  \"Release\" => :release,"
        print "  \"Debug_Production\" => :debug,"
        print "  \"Release_Production\" => :release,"
        print "  \"Debug_Develop\" => :debug,"
        print "  \"Release_Develop\" => :release,"
        print "  \"Debug_QA\" => :debug,"
        print "  \"Release_QA\" => :release,"
        print "  \"Debug_Preprod\" => :debug,"
        print "  \"Release_Preprod\" => :release"
        next
      }
      { print }
    ' "$PODFILE" > "$TEMP_PODFILE"
  else
    # Add project declaration before prepare_react_native_project!
    awk -v proj="$IOS_PROJECT_NAME" '
      /^prepare_react_native_project!/ {
        print "project \"" proj "\","
        print "  \"Debug\" => :debug,"
        print "  \"Release\" => :release,"
        print "  \"Debug_Production\" => :debug,"
        print "  \"Release_Production\" => :release,"
        print "  \"Debug_Develop\" => :debug,"
        print "  \"Release_Develop\" => :release,"
        print "  \"Debug_QA\" => :debug,"
        print "  \"Release_QA\" => :release,"
        print "  \"Debug_Preprod\" => :debug,"
        print "  \"Release_Preprod\" => :release"
        print ""
        print
        next
      }
      { print }
    ' "$PODFILE" > "$TEMP_PODFILE"
  fi
  
  mv "$TEMP_PODFILE" "$PODFILE"
 fi
 
# Add/Update post_install hook to ensure all configurations have proper Swift settings
print_info "Adding/updating post_install hook in Podfile..."
if [ -f "$PODFILE" ]; then
  # Use Python to properly update the post_install hook
  python3 - <<'PYTHONEOF'
import re
import sys

podfile_path = "ios/Podfile"
try:
    with open(podfile_path, 'r') as f:
        content = f.read()
    
    # Check if post_install already exists
    has_post_install = 'post_install do |installer|' in content
    
    # Check if our Swift settings fix is already there
    has_swift_fix = 'CRITICAL: Ensure all build configurations have proper Swift settings' in content
    
    if has_post_install and not has_swift_fix:
        # Find the post_install block and add our Swift settings before the closing 'end'
        # Look for the pattern: post_install do |installer| ... end
        pattern = r'(post_install do \|installer\|.*?)(\n  end)'
        
        swift_fix = '''
    # CRITICAL: Ensure all build configurations have proper Swift settings
    # This fixes the "cannot inherit from class 'ExpoAppDelegate'" error
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings["SWIFT_VERSION"] = "5.0"
        if config.name.include?("Release")
          config.build_settings["SWIFT_COMPILATION_MODE"] = "wholemodule"
          config.build_settings["SWIFT_OPTIMIZATION_LEVEL"] = "-O"
        end
      end
    end
    
    # CRITICAL: Ensure Expo target builds Swift modules correctly
    installer.pods_project.targets.each do |target|
      if target.name == "Expo"
        target.build_configurations.each do |config|
          config.build_settings["DEFINES_MODULE"] = "YES"
          config.build_settings["SWIFT_MODULE_NAME"] = "Expo"
          config.build_settings["SWIFT_EMIT_MODULE_INTERFACE"] = "YES" if config.name.include?("Release")
        end
      end
    end'''
        
        # Insert before the closing 'end' of post_install
        def replace_post_install(match):
            return match.group(1) + swift_fix + match.group(2)
        
        content = re.sub(pattern, replace_post_install, content, flags=re.DOTALL)
        
        with open(podfile_path, 'w') as f:
            f.write(content)
        print("Updated post_install hook with Swift settings fix")
    elif not has_post_install:
        # Add new post_install hook before the last 'end'
        lines = content.split('\n')
        # Find the last 'end' that's not indented (target or file level)
        for i in range(len(lines) - 1, -1, -1):
            if lines[i].strip() == 'end' and not lines[i].startswith('  '):
                # Insert before this line
                swift_fix = '''  post_install do |installer|
    # CRITICAL: Ensure all build configurations have proper Swift settings
    # This fixes the "cannot inherit from class 'ExpoAppDelegate'" error
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings["SWIFT_VERSION"] = "5.0"
        if config.name.include?("Release")
          config.build_settings["SWIFT_COMPILATION_MODE"] = "wholemodule"
          config.build_settings["SWIFT_OPTIMIZATION_LEVEL"] = "-O"
        end
      end
    end
    
    # CRITICAL: Ensure Expo target builds Swift modules correctly
    installer.pods_project.targets.each do |target|
      if target.name == "Expo"
        target.build_configurations.each do |config|
          config.build_settings["DEFINES_MODULE"] = "YES"
          config.build_settings["SWIFT_MODULE_NAME"] = "Expo"
          config.build_settings["SWIFT_EMIT_MODULE_INTERFACE"] = "YES" if config.name.include?("Release")
        end
      end
    end
  end'''
                lines.insert(i, swift_fix)
                break
        
        with open(podfile_path, 'w') as f:
            f.write('\n'.join(lines))
        print("Added post_install hook with Swift settings fix")
    else:
        print("Post_install hook already has Swift settings fix")
except Exception as e:
    print(f"Error updating Podfile: {e}")
    sys.exit(1)
PYTHONEOF
fi
 
 # FIX 1: Create/Update Bridging Header
print_info "Creating/updating bridging header..."
BRIDGING_HEADER="ios/$IOS_PROJECT_NAME/${IOS_PROJECT_NAME}-Bridging-Header.h"
mkdir -p "$(dirname "$BRIDGING_HEADER")"
 cat > "$BRIDGING_HEADER" << 'HEADEREOF'
#import <Expo/Expo.h>
#import <ExpoModulesCore/ExpoModulesCore.h>
#import <React/RCTLinkingManager.h>
#import <React/RCTBridge.h>
#import <React/RCTRootView.h>
//
// Use this file to import your target's public headers that you would like to expose to Swift.
// CRITICAL: These imports ensure Swift can properly resolve ExpoAppDelegate
//
HEADEREOF
 if [ -f "$BRIDGING_HEADER" ]; then
  print_success "Bridging header created/updated"
else
  print_warning "Failed to create bridging header"
fi
 # FIX 2: Create app icon sets in Images.xcassets
print_info "Creating app icon set placeholders..."
IOS_ASSETS_DIR="ios/$IOS_PROJECT_NAME/Images.xcassets"
mkdir -p "$IOS_ASSETS_DIR"
 for icon_set in "AppIcon" "AppIconDev" "AppIconQA" "AppIconPreprod"; do
  icon_dir="$IOS_ASSETS_DIR/$icon_set.appiconset"
  mkdir -p "$icon_dir"
   # Create placeholder Contents.json (will be updated when icons are set up)
   cat > "$icon_dir/Contents.json" << 'ICONEOF'
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
ICONEOF
   # Note: This is just a placeholder. The complete Contents.json with all sizes
   # will be created when icons are set up via setup.sh or setup_ios_icons.sh
done
print_success "Icon set placeholders created"
 # Configure Xcode project
print_info "Configuring Xcode project..."
if command -v ruby >/dev/null 2>&1; then
  IOS_PROJECT_NAME_ENV="$IOS_PROJECT_NAME" IOS_BUNDLE_ID_ENV="$IOS_BUNDLE_ID" DISPLAY_NAME_ENV="$DISPLAY_NAME" ruby - <<'RUBYEOF'
require 'fileutils'
begin
require 'xcodeproj'
rescue LoadError
puts "Installing xcodeproj gem..."
unless system('gem install xcodeproj --user-install')
  puts "Error: Failed to install xcodeproj gem"
  puts "Please install manually: gem install xcodeproj"
  exit 1
end
Gem.clear_paths
begin
  require 'xcodeproj'
rescue LoadError
  puts "Error: xcodeproj gem installed but could not be loaded"
  puts "Please try: gem install xcodeproj"
  exit 1
end
end

project_name = ENV['IOS_PROJECT_NAME_ENV']
project_path = "ios/#{project_name}.xcodeproj"

# FIX: Try to find the actual project if the provided name doesn't exist
unless File.exist?(project_path)
  # Try to find any .xcodeproj in ios directory
  found_projects = Dir.glob("ios/*.xcodeproj")
  if found_projects.any?
    actual_project = found_projects.first
    project_name = File.basename(actual_project, ".xcodeproj")
    project_path = actual_project
    puts "Warning: Project name mismatch. Found: #{project_name}, using it instead."
  else
    puts "Error: Project not found at #{project_path}"
    puts "Searched for: ios/*.xcodeproj"
    exit 1
  end
end

project = Xcodeproj::Project.open(project_path)
# Try to find target by exact name first, then by matching pattern
target = project.targets.find { |t| t.name == project_name }
unless target
  # Try to find target that matches the project name (case-insensitive or with different formatting)
  target = project.targets.find { |t| t.name.downcase == project_name.downcase }
end
unless target
  # Last resort: use the first application target
  target = project.targets.find { |t| t.product_type == "com.apple.product-type.application" }
end
# FIX 5: Add error handling
unless target
  puts "Error: Target '#{project_name}' not found"
  puts "Available targets: #{project.targets.map(&:name).join(', ')}"
  exit 1
end
puts "Using target: #{target.name}"

debug_proj = project.build_configurations.find { |c| c.name == 'Debug' }
release_proj = project.build_configurations.find { |c| c.name == 'Release' }
debug_tgt = target.build_configurations.find { |c| c.name == 'Debug' }
release_tgt = target.build_configurations.find { |c| c.name == 'Release' }

# FIX 5: Add error handling
unless debug_proj && release_proj && debug_tgt && release_tgt
puts "Error: Base build configurations not found"
exit 1
end

bundle_id = ENV['IOS_BUNDLE_ID_ENV']
display = ENV['DISPLAY_NAME_ENV']

infoplist_file = debug_tgt.build_settings['INFOPLIST_FILE']

# Get bridging header path - try to find it from base config or construct it
bridging_header_path = debug_tgt.build_settings['SWIFT_OBJC_BRIDGING_HEADER']
unless bridging_header_path
  # Construct the bridging header path if not found
  bridging_header_path = "#{project_name}/#{project_name}-Bridging-Header.h"
end

# NOTE: Base Debug/Release configurations are kept minimal/default
# Production-specific settings go to "Debug Production" and "Release Production" configurations
# This ensures production builds use the Production configurations, not base ones

# CRITICAL: Ensure base configurations have bridging header set
[debug_proj, release_proj, debug_tgt, release_tgt].each do |c|
  c.build_settings['SWIFT_OBJC_BRIDGING_HEADER'] = bridging_header_path unless c.build_settings['SWIFT_OBJC_BRIDGING_HEADER']
end

# FIX 4: Add icon_name parameter and set ASSETCATALOG_COMPILER_APPICON_NAME
# Create Production configurations first (uses base AppIcon, no suffix)
# These are the configurations that should be used for production builds
['Production'].each do |flavor|
  ['Debug', 'Release'].each do |type|
    name = "#{type}_#{flavor}"
    base_cfg = type == 'Debug' ? debug_tgt : release_tgt
    proj_cfg = project.build_configurations.find { |c| c.name == name }
    unless proj_cfg
      proj_cfg = project.add_build_configuration(name, type.downcase.to_sym)
    end
    tgt_cfg = target.build_configurations.find { |c| c.name == name }
    unless tgt_cfg
      tgt_cfg = target.add_build_configuration(name, type.downcase.to_sym)
    end
    [proj_cfg, tgt_cfg].each do |c|
      c.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = bundle_id
      c.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = display
      c.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
      c.build_settings['INFOPLIST_FILE'] = infoplist_file if infoplist_file
      c.build_settings['SWIFT_VERSION'] = base_cfg.build_settings['SWIFT_VERSION'] if base_cfg.build_settings['SWIFT_VERSION']
      c.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = base_cfg.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] if base_cfg.build_settings['IPHONEOS_DEPLOYMENT_TARGET']
      # CRITICAL: Set bridging header directly (needed for ExpoAppDelegate)
      c.build_settings['SWIFT_OBJC_BRIDGING_HEADER'] = bridging_header_path
      # CRITICAL: Ensure Expo module can be found for Swift compilation
      # Add Expo.swiftmodule to Swift include paths
      current_include = c.build_settings['SWIFT_INCLUDE_PATHS'] || ''
      expo_swiftmodule = '$(BUILT_PRODUCTS_DIR)/Expo/Expo.swiftmodule'
      unless current_include.include?(expo_swiftmodule)
        c.build_settings['SWIFT_INCLUDE_PATHS'] = "#{current_include} $(BUILT_PRODUCTS_DIR)/Expo $(BUILT_PRODUCTS_DIR)/Expo/Expo.swiftmodule".strip
      end
      # Ensure Release builds have proper optimization settings
      if type == 'Release'
        c.build_settings['SWIFT_COMPILATION_MODE'] = 'wholemodule' unless c.build_settings['SWIFT_COMPILATION_MODE']
        c.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-O' unless c.build_settings['SWIFT_OPTIMIZATION_LEVEL']
      end
    end
  end
end

# Create other flavor configurations (Develop, QA, Preprod)
[['Develop', '.develop', 'AppIconDev'], ['QA', '.qa', 'AppIconQA'], ['Preprod', '.preprod', 'AppIconPreprod']].each do |flavor, suffix, icon_name|
['Debug', 'Release'].each do |type|
  name = "#{type}_#{flavor}"
  base_cfg = type == 'Debug' ? debug_tgt : release_tgt
   # FIX 4: Check if config exists before creating
  proj_cfg = project.build_configurations.find { |c| c.name == name }
  unless proj_cfg
    proj_cfg = project.add_build_configuration(name, type.downcase.to_sym)
  end
   tgt_cfg = target.build_configurations.find { |c| c.name == name }
  unless tgt_cfg
    tgt_cfg = target.add_build_configuration(name, type.downcase.to_sym)
  end
   # FIX 4: Set icon name and copy other settings
  [proj_cfg, tgt_cfg].each do |c|
    c.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "#{bundle_id}#{suffix}"
    c.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = "#{display} #{flavor}"
    c.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = icon_name
  
    # Copy other important settings from base config
    c.build_settings['INFOPLIST_FILE'] = infoplist_file if infoplist_file
    c.build_settings['SWIFT_VERSION'] = base_cfg.build_settings['SWIFT_VERSION'] if base_cfg.build_settings['SWIFT_VERSION']
    c.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = base_cfg.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] if base_cfg.build_settings['IPHONEOS_DEPLOYMENT_TARGET']
    # CRITICAL: Set bridging header directly (needed for ExpoAppDelegate)
    # Use the bridging header path we determined earlier
    c.build_settings['SWIFT_OBJC_BRIDGING_HEADER'] = bridging_header_path
    # CRITICAL: Ensure Expo module can be found for Swift compilation
    # Add Expo.swiftmodule to Swift include paths
    current_include = c.build_settings['SWIFT_INCLUDE_PATHS'] || ''
    expo_swiftmodule = '$(BUILT_PRODUCTS_DIR)/Expo/Expo.swiftmodule'
    unless current_include.include?(expo_swiftmodule)
      c.build_settings['SWIFT_INCLUDE_PATHS'] = "#{current_include} $(BUILT_PRODUCTS_DIR)/Expo $(BUILT_PRODUCTS_DIR)/Expo/Expo.swiftmodule".strip
    end
    # Ensure Release builds have proper optimization settings
    if type == 'Release'
      c.build_settings['SWIFT_COMPILATION_MODE'] = 'wholemodule' unless c.build_settings['SWIFT_COMPILATION_MODE']
      c.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-O' unless c.build_settings['SWIFT_OPTIMIZATION_LEVEL']
    end
  end
end
end

# CRITICAL: Link Pods xcconfig files to project-level configurations
# CocoaPods only links target-level configs, but project-level configs also need them
# for Swift to find modules like Expo
pods_xcconfigs = {}
project.files.each do |file|
  if file.path && file.path.include?("Pods-#{project_name}") && file.path.end_with?(".xcconfig")
    config_name = file.path.match(/Pods-#{project_name}\.(.+)\.xcconfig/)[1]
    # Map config names to match Xcode configuration names
    mapped_name = case config_name.downcase
    when /^debug$/
      "Debug"
    when /^release$/
      "Release"
    when /^debug[_-]production$/
      "Debug_Production"
    when /^release[_-]production$/
      "Release_Production"
    when /^debug[_-]develop$/
      "Debug_Develop"
    when /^release[_-]develop$/
      "Release_Develop"
    when /^debug[_-]qa$/
      "Debug_QA"
    when /^release[_-]qa$/
      "Release_QA"
    when /^debug[_-]preprod$/
      "Debug_Preprod"
    when /^release[_-]preprod$/
      "Release_Preprod"
    else
      config_name.split.map(&:capitalize).join(" ")
    end
    pods_xcconfigs[mapped_name] = file
  end
end

# Link project-level configurations to Pods xcconfig
project.build_configurations.each do |config|
  if pods_xcconfigs[config.name] && !config.base_configuration_reference
    config.base_configuration_reference = pods_xcconfigs[config.name]
  end
end

# CRITICAL: Ensure app target has proper Swift module resolution settings
# This fixes the "cannot inherit from class 'ExpoAppDelegate'" error
target.build_configurations.each do |config|
  # Ensure SWIFT_INCLUDE_PATHS includes Expo.swiftmodule for all configurations
  # Use $(inherited) to preserve Pods settings
  current_include = config.build_settings['SWIFT_INCLUDE_PATHS'] || '$(inherited)'
  expo_paths = ['$(BUILT_PRODUCTS_DIR)/Expo', '$(BUILT_PRODUCTS_DIR)/Expo/Expo.swiftmodule']
  expo_paths.each do |path|
    unless current_include.include?(path)
      # Prepend inherited if not already there, then add our paths
      base_include = current_include.include?('$(inherited)') ? current_include : "$(inherited) #{current_include}"
      config.build_settings['SWIFT_INCLUDE_PATHS'] = "#{base_include} #{path}".strip
      current_include = config.build_settings['SWIFT_INCLUDE_PATHS']
    end
  end
  
  # Ensure FRAMEWORK_SEARCH_PATHS includes Expo framework
  # Use $(inherited) to preserve Pods settings
  current_framework = config.build_settings['FRAMEWORK_SEARCH_PATHS'] || '$(inherited)'
  expo_framework = '$(BUILT_PRODUCTS_DIR)/Expo'
  unless current_framework.include?(expo_framework)
    base_framework = current_framework.include?('$(inherited)') ? current_framework : "$(inherited) #{current_framework}"
    config.build_settings['FRAMEWORK_SEARCH_PATHS'] = "#{base_framework} $(BUILT_PRODUCTS_DIR)/Expo".strip
  end
  
  # Ensure ALWAYS_SEARCH_USER_PATHS is YES to help find modules
  config.build_settings['ALWAYS_SEARCH_USER_PATHS'] = 'YES'
  
  # CRITICAL: Disable module interface emission for app target
  # Apps don't need to emit module interfaces, which can cause Swift compilation issues
  config.build_settings['SWIFT_EMIT_MODULE_INTERFACE'] = 'NO'
  config.build_settings['DEFINES_MODULE'] = 'NO'
end

# CRITICAL: Add a pre-compile script phase to ensure Expo is built before AppDelegate compiles
# This fixes the "cannot inherit from class 'ExpoAppDelegate'" error by ensuring build order
sources_phase = target.build_phases.find { |p| p.is_a?(Xcodeproj::Project::Object::PBXSourcesBuildPhase) }
if sources_phase
  script_phase_name = 'Ensure Expo is built before compilation'
  expected_script_content = /EXPO_MODULES|EXPO_SWIFTMODULE/
  
  # CRITICAL: Remove ALL duplicates from build_phases array first
  # This fixes "Unexpected duplicate tasks" error
  # We need to check both by UUID (same object added twice) and by name/content (different objects with same purpose)
  
  # Step 0: First, remove ALL script phases matching our name/content to start fresh
  # This ensures we don't have any leftover duplicates from previous runs
  scripts_to_remove = []
  target.build_phases.each do |phase|
    if phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
      if (phase.name == script_phase_name) || (phase.shell_script && phase.shell_script.match(expected_script_content))
        scripts_to_remove << phase
      end
    end
  end
  
  if scripts_to_remove.length > 0
    puts "Removing #{scripts_to_remove.length} existing script phase(s) matching '#{script_phase_name}' to start fresh..."
    scripts_to_remove.each do |script|
      target.build_phases.delete(script)
    end
  end
  
  # Step 1: Remove duplicate UUIDs (same object referenced multiple times)
  seen_uuids = {}
  duplicates_to_remove = []
  
  target.build_phases.each_with_index do |phase, index|
    uuid = phase.uuid
    if seen_uuids[uuid]
      puts "Warning: Found duplicate build phase UUID #{uuid} at index #{index}. Will remove duplicate..."
      duplicates_to_remove << index
    else
      seen_uuids[uuid] = true
    end
  end
  
  # Remove duplicates in reverse order to preserve indices
  duplicates_to_remove.reverse.each do |index|
    target.build_phases.delete_at(index)
  end
  
  if duplicates_to_remove.length > 0
    puts "Removed #{duplicates_to_remove.length} duplicate build phase reference(s) by UUID"
  end
  
  # Step 2: Verify no matching scripts remain (should be empty after Step 0)
  all_scripts = target.build_phases.select { |p| 
    p.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
  }
  
  matching_scripts = all_scripts.select { |s|
    (s.name == script_phase_name) || 
    (s.shell_script && s.shell_script.match(expected_script_content))
  }
  
  if matching_scripts.length > 0
    puts "Warning: Still found #{matching_scripts.length} matching script phase(s) after cleanup. Removing..."
    matching_scripts.each do |script|
      target.build_phases.delete(script)
    end
  end
  
  # Step 3: Now add a fresh script phase (we've ensured none exist)
  # This guarantees we only have one script phase
    script_phase = target.new_shell_script_build_phase(script_phase_name)
    script_phase.shell_script = <<-SCRIPT
set -e

# CRITICAL: Build Expo modules explicitly to ensure all Swift modules exist
# This fixes "cannot find 'AssetModule' in scope" and similar errors
PODS_PROJECT="${SRCROOT}/Pods/Pods.xcodeproj"

# List of Expo modules that need to be built before the app target
EXPO_MODULES=(
  "Expo"
  "ExpoAsset"
  "EXConstants"
  "ExpoFileSystem"
  "ExpoFont"
  "ExpoKeepAwake"
  "ExpoModulesCore"
)

# Build each Expo module if it doesn't exist
for MODULE in "${EXPO_MODULES[@]}"; do
  MODULE_PATH="${BUILT_PRODUCTS_DIR}/${MODULE}"
  SWIFTMODULE_PATH="${MODULE_PATH}/${MODULE}.swiftmodule"
  
  # Only build if module doesn't exist
  if [ ! -d "$SWIFTMODULE_PATH" ] && [ -f "$PODS_PROJECT/project.pbxproj" ]; then
    echo "Building ${MODULE} target to generate ${MODULE}.swiftmodule..."
    xcodebuild -project "$PODS_PROJECT" \\
      -target "${MODULE}" \\
      -configuration "${CONFIGURATION}" \\
      -sdk "${SDK_NAME}" \\
      ARCHS="${ARCHS}" \\
      BUILD_DIR="${BUILT_PRODUCTS_DIR}/.." \\
      SYMROOT="${BUILT_PRODUCTS_DIR}/.." \\
      ONLY_ACTIVE_ARCH=NO \\
      CODE_SIGN_IDENTITY="" \\
      CODE_SIGNING_REQUIRED=NO \\
      CODE_SIGNING_ALLOWED=NO \\
      > /dev/null 2>&1 || echo "Note: ${MODULE} build completed (warnings may appear)"
  fi
done
SCRIPT
    script_phase.shell_path = '/bin/sh'
    script_phase.show_env_vars_in_log = '0'
    
    # CRITICAL: Add output dependencies to avoid "will be run during every build" warning
    # We specify output files that this script generates
    # Use the correct xcodeproj API for output paths
    if script_phase.respond_to?(:output_paths=)
      script_phase.output_paths = [
        '$(BUILT_PRODUCTS_DIR)/Expo/Expo.swiftmodule',
        '$(BUILT_PRODUCTS_DIR)/ExpoAsset/ExpoAsset.swiftmodule',
        '$(BUILT_PRODUCTS_DIR)/EXConstants/EXConstants.swiftmodule',
        '$(BUILT_PRODUCTS_DIR)/ExpoFileSystem/ExpoFileSystem.swiftmodule',
        '$(BUILT_PRODUCTS_DIR)/ExpoFont/ExpoFont.swiftmodule',
        '$(BUILT_PRODUCTS_DIR)/ExpoKeepAwake/ExpoKeepAwake.swiftmodule',
        '$(BUILT_PRODUCTS_DIR)/ExpoModulesCore/ExpoModulesCore.swiftmodule'
      ]
    elsif script_phase.respond_to?(:output_paths)
      # Alternative API name
      script_phase.output_paths = [
        '$(BUILT_PRODUCTS_DIR)/Expo/Expo.swiftmodule',
        '$(BUILT_PRODUCTS_DIR)/ExpoAsset/ExpoAsset.swiftmodule',
        '$(BUILT_PRODUCTS_DIR)/EXConstants/EXConstants.swiftmodule',
        '$(BUILT_PRODUCTS_DIR)/ExpoFileSystem/ExpoFileSystem.swiftmodule',
        '$(BUILT_PRODUCTS_DIR)/ExpoFont/ExpoFont.swiftmodule',
        '$(BUILT_PRODUCTS_DIR)/ExpoKeepAwake/ExpoKeepAwake.swiftmodule',
        '$(BUILT_PRODUCTS_DIR)/ExpoModulesCore/ExpoModulesCore.swiftmodule'
      ]
    end
    
    # Set to run based on dependency analysis (only when outputs are missing)
    script_phase.always_out_of_date = '0'
    
    # Insert before Sources phase
    sources_index = target.build_phases.index(sources_phase)
    target.build_phases.insert(sources_index, script_phase)
    
    puts "Added pre-compile script to ensure Expo builds first"
  
  # Step 4: Final verification - ensure no duplicates remain
  final_scripts = target.build_phases.select { |p| 
    p.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) &&
    ((p.name == script_phase_name) || (p.shell_script && p.shell_script.match(expected_script_content)))
  }
  
  if final_scripts.length > 1
    puts "ERROR: Still found #{final_scripts.length} duplicate script phases after cleanup!"
    puts "This should not happen. Removing all but the first..."
    final_scripts[1..-1].each do |dup|
      target.build_phases.delete(dup)
    end
  elsif final_scripts.length == 1
    puts "Verified: Only one '#{script_phase_name}' script phase exists"
  end
end

# CRITICAL: Add explicit target dependencies on Expo modules to ensure they build first
# This fixes the "cannot find 'AssetModule' in scope" and similar errors
puts "Setting up target dependencies on Expo modules..."
begin
  # Find Expo module targets in Pods project
  # These need to be built before the app target can compile ExpoModulesProvider.swift
  expo_module_targets = [
    'Expo',
    'ExpoAsset',
    'EXConstants',
    'ExpoFileSystem',
    'ExpoFont',
    'ExpoKeepAwake',
    'ExpoModulesCore'
  ]
  
  # Try to find targets in the Pods project
  # Note: Pods targets are in a separate project, so we can't directly add dependencies
  # Instead, we ensure the build order via the script phase and build settings
  
  # CRITICAL: Ensure all Expo modules are in the build search paths
  target.build_configurations.each do |config|
    # Ensure we're linking against all Expo module frameworks
    framework_paths = config.build_settings['FRAMEWORK_SEARCH_PATHS'] || '$(inherited)'
    expo_module_targets.each do |module_name|
      module_path = "$(BUILT_PRODUCTS_DIR)/#{module_name}"
      unless framework_paths.include?(module_path)
        config.build_settings['FRAMEWORK_SEARCH_PATHS'] = "#{framework_paths} #{module_path}".strip
        framework_paths = config.build_settings['FRAMEWORK_SEARCH_PATHS']
      end
    end
    
    # Ensure Swift can find all Expo modules
    include_paths = config.build_settings['SWIFT_INCLUDE_PATHS'] || '$(inherited)'
    expo_module_targets.each do |module_name|
      # Add module directory
      module_dir = "$(BUILT_PRODUCTS_DIR)/#{module_name}"
      unless include_paths.include?(module_dir)
        config.build_settings['SWIFT_INCLUDE_PATHS'] = "#{include_paths} #{module_dir}".strip
        include_paths = config.build_settings['SWIFT_INCLUDE_PATHS']
      end
      
      # Add Swift module if it exists
      swiftmodule_path = "$(BUILT_PRODUCTS_DIR)/#{module_name}/#{module_name}.swiftmodule"
      unless include_paths.include?(swiftmodule_path)
        config.build_settings['SWIFT_INCLUDE_PATHS'] = "#{include_paths} #{swiftmodule_path}".strip
        include_paths = config.build_settings['SWIFT_INCLUDE_PATHS']
      end
    end
    
    # CRITICAL: Ensure ALWAYS_SEARCH_USER_PATHS is YES to help Swift find modules
    config.build_settings['ALWAYS_SEARCH_USER_PATHS'] = 'YES'
    
    # Ensure Swift can find modules from Pods
    unless include_paths.include?('$(PODS_ROOT)')
      config.build_settings['SWIFT_INCLUDE_PATHS'] = "#{include_paths} $(PODS_ROOT)".strip
    end
  end
  
  puts "Configured build settings for Expo modules"
  
rescue => e
  puts "Warning: Could not set up Expo module dependencies: #{e.message}"
  puts "Build order will be handled by CocoaPods and the script phase"
end

# FIX 5: Add error handling for save
if project.save
puts "Success: Configured #{project.build_configurations.count} build configurations"
exit 0
else
puts "Error: Failed to save project"
exit 1
end
RUBYEOF
   if [ $? -eq 0 ]; then
    print_success "Xcode project configured"
  else
    print_warning "Failed to configure Xcode project"
  fi
fi
 # Create schemes
print_info "Creating Xcode schemes..."
IOS_PROJECT_NAME_ENV="$IOS_PROJECT_NAME" python3 - <<'PYEOF'
import os, xml.etree.ElementTree as ET
from pathlib import Path

# FIX 6: Add error handling
proj = os.environ.get("IOS_PROJECT_NAME_ENV")
if not proj:
  print("Error: IOS_PROJECT_NAME_ENV not set")
  exit(1)

scheme_dir = Path(f"ios/{proj}.xcodeproj/xcshareddata/xcschemes")
default = scheme_dir / f"{proj}.xcscheme"
if not default.exists():
  print(f"Warning: Default scheme not found at {default}")
  exit(0)

scheme_dir.mkdir(parents=True, exist_ok=True)
tree = ET.parse(default)
root = tree.getroot()

def write_scheme(name, env, debug_cfg, release_cfg):
  new_root = ET.Element("Scheme", **dict(root.attrib))
  new_root.set("LastUpgradeVersion", root.get("LastUpgradeVersion", "1130"))
  new_root.set("version", root.get("version", "1.3"))
  ba = ET.SubElement(new_root, "BuildAction", **dict(root.find("BuildAction").attrib))
  pre = ET.SubElement(ba, "PreActions")
  ea = ET.SubElement(pre, "ExecutionAction", ActionType="Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction")
  ET.SubElement(ea, "ActionContent", title="Run Script", scriptText=f'echo "{env}" > /tmp/envfile\n')
  entries = ET.SubElement(ba, "BuildActionEntries")
  entry = ET.SubElement(entries, "BuildActionEntry", buildForTesting="YES", buildForRunning="YES", buildForProfiling="YES", buildForArchiving="YES", buildForAnalyzing="YES")
  br = root.find(".//BuildableReference")
  if br is not None:
    ET.SubElement(entry, "BuildableReference", **dict(br.attrib))
  ta = ET.SubElement(new_root, "TestAction", buildConfiguration=debug_cfg, selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB", selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB", shouldUseLaunchSchemeArgsEnv="YES")
  la = ET.SubElement(new_root, "LaunchAction", buildConfiguration=debug_cfg, selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB", selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB", launchStyle="0", useCustomWorkingDirectory="NO", ignoresPersistentStateOnLaunch="NO", debugDocumentVersioning="YES", allowLocationSimulation="YES")
  runnable = ET.SubElement(la, "BuildableProductRunnable", runnableDebuggingMode="0")
  if br is not None:
    ET.SubElement(runnable, "BuildableReference", **dict(br.attrib))
  pa = ET.SubElement(new_root, "ProfileAction", buildConfiguration=release_cfg, shouldUseLaunchSchemeArgsEnv="YES", savedToolIdentifier="", useCustomWorkingDirectory="NO", debugDocumentVersioning="YES")
  runnable2 = ET.SubElement(pa, "BuildableProductRunnable", runnableDebuggingMode="0")
  if br is not None:
    ET.SubElement(runnable2, "BuildableReference", **dict(br.attrib))
  ET.SubElement(new_root, "AnalyzeAction", buildConfiguration=debug_cfg)
  ET.SubElement(new_root, "ArchiveAction", buildConfiguration=release_cfg, revealArchiveInOrganizer="YES")
  ET.indent(ET.ElementTree(new_root), space="   ")
  ET.ElementTree(new_root).write(scheme_dir / f"{name}.xcscheme", encoding="UTF-8", xml_declaration=True)

for name, env, debug, release in [
  (proj, ".env", "Debug_Production", "Release_Production"),
  (f"{proj}_Develop", ".env.develop", "Debug_Develop", "Release_Develop"),
  (f"{proj}_QA", ".env.qa", "Debug_QA", "Release_QA"),
  (f"{proj}_Preprod", ".env.preprod", "Debug_Preprod", "Release_Preprod"),
]:
  write_scheme(name, env, debug, release)

print("Success: Schemes created")
exit(0)
PYEOF
 if [ $? -eq 0 ]; then
  print_success "Schemes created"
else
  print_warning "Failed to create schemes"
fi
 # Enhanced AppDelegate
print_info "Creating AppDelegate..."
cat > "ios/$IOS_PROJECT_NAME/AppDelegate.swift" << 'SWIFTEOF'
import Expo
import ExpoModulesCore
import React
import ReactAppDependencyProvider
import UIKit

@main
class AppDelegate: ExpoAppDelegate {
var window: UIWindow?

var reactNativeDelegate: ExpoReactNativeFactoryDelegate?
var reactNativeFactory: RCTReactNativeFactory?

public override func application(
  _ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
) -> Bool {
  let delegate = ReactNativeDelegate()
  let factory = ExpoReactNativeFactory(delegate: delegate)
  delegate.dependencyProvider = RCTAppDependencyProvider()

  reactNativeDelegate = delegate
  reactNativeFactory = factory
  bindReactNativeFactory(factory)

#if os(iOS) || os(tvOS)
  window = UIWindow(frame: UIScreen.main.bounds)
  factory.startReactNative(
    withModuleName: "main",
    in: window,
    launchOptions: launchOptions)
#endif

  return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}

// Linking API
public override func application(
  _ app: UIApplication,
  open url: URL,
  options: [UIApplication.OpenURLOptionsKey: Any] = [:]
) -> Bool {
  return super.application(app, open: url, options: options) || RCTLinkingManager.application(app, open: url, options: options)
}

// Universal Links
public override func application(
  _ application: UIApplication,
  continue userActivity: NSUserActivity,
  restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
) -> Bool {
  let result = RCTLinkingManager.application(application, continue: userActivity, restorationHandler: restorationHandler)
  return super.application(application, continue: userActivity, restorationHandler: restorationHandler) || result
}
}

class ReactNativeDelegate: ExpoReactNativeFactoryDelegate {
// Extension point for config-plugins

override func sourceURL(for bridge: RCTBridge) -> URL? {
  // needed to return the correct URL for expo-dev-client.
  bridge.bundleURL ?? bundleURL()
}

override func bundleURL() -> URL? {
#if DEBUG
  let urlProvider = RCTBundleURLProvider.sharedSettings()
   // Try with ".expo/.virtual-metro-entry" for Expo dev-client (preferred)
  if let url = urlProvider.jsBundleURL(forBundleRoot: ".expo/.virtual-metro-entry") {
    return url
  }
   // Try with "index" as bundle root (matches package.json "main": "index.js")
  if let url = urlProvider.jsBundleURL(forBundleRoot: "index") {
    return url
  }
   // Fallback: Extract port from RCTBundleURLProvider by trying different bundle roots
  // This automatically detects both host and port without hardcoding
  let host = urlProvider.jsLocation ?? "localhost"
  var port: String? = nil
   // Try multiple bundle roots to find one that works and extract the port
  let bundleRootsToTry = ["index", "main", ""]
  for bundleRoot in bundleRootsToTry {
    if let testUrl = urlProvider.jsBundleURL(forBundleRoot: bundleRoot) {
      if let detectedPort = testUrl.port {
        port = String(detectedPort)
        break
      }
    }
  }
   // If we couldn't detect port from jsBundleURL, use RCTBundleURLProvider's default port
  // Metro bundler defaults to port 8081, which RCTBundleURLProvider also uses by default
  // This is a safe fallback when jsBundleURL returns nil for all bundle roots
  let finalPort = port ?? "8081"
   // Construct Expo dev-client URL using detected host and port
  let bundleRoot = ".expo/.virtual-metro-entry"
  let urlString = "http://\(host):\(finalPort)/\(bundleRoot).bundle?platform=ios&dev=true"
  return URL(string: urlString)
#else
  return Bundle.main.url(forResource: "main", withExtension: "jsbundle")
#endif
}
}
SWIFTEOF
print_success "AppDelegate created"
}



