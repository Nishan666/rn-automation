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
if [ -f "$PODFILE" ] && ! grep -q '"Debug Develop"' "$PODFILE" ]; then
  print_info "Updating Podfile configurations..."
  TEMP_PODFILE=$(mktemp)
  awk -v proj="$IOS_PROJECT_NAME" '
    /^[[:space:]]*project[[:space:]]+/ {
      print "project \"" proj "\","
      print "  \"Debug\" => :debug,"
      print "  \"Release\" => :release,"
      print "  \"Debug Develop\" => :debug,"
      print "  \"Release Develop\" => :release,"
      print "  \"Debug QA\" => :debug,"
      print "  \"Release QA\" => :release,"
      print "  \"Debug Preprod\" => :debug,"
      print "  \"Release Preprod\" => :release"
      next
    }
    { print }
  ' "$PODFILE" > "$TEMP_PODFILE"
  mv "$TEMP_PODFILE" "$PODFILE"
fi
 # FIX 1: Create/Update Bridging Header
print_info "Creating/updating bridging header..."
BRIDGING_HEADER="ios/$IOS_PROJECT_NAME/${IOS_PROJECT_NAME}-Bridging-Header.h"
mkdir -p "$(dirname "$BRIDGING_HEADER")"
 cat > "$BRIDGING_HEADER" << 'HEADEREOF'
#import <Expo/Expo.h>
#import <React/RCTLinkingManager.h>
//
// Use this file to import your target's public headers that you would like to expose to Swift.
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
   cat > "$icon_dir/Contents.json" << 'ICONEOF'
{
"images": [
  {
    "filename": "icon-1024.png",
    "idiom": "universal",
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
# FIX 5: Add error handling
unless File.exist?(project_path)
puts "Error: Project not found at #{project_path}"
exit 1
end

project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == project_name }
# FIX 5: Add error handling
unless target
puts "Error: Target '#{project_name}' not found"
exit 1
end

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

# FIX 4: Set icon name for base configurations
[debug_proj, release_proj, debug_tgt, release_tgt].each do |c|
c.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = bundle_id
c.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = display
c.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
end

# FIX 4: Add icon_name parameter and set ASSETCATALOG_COMPILER_APPICON_NAME
[['Develop', '.develop', 'AppIconDev'], ['QA', '.qa', 'AppIconQA'], ['Preprod', '.preprod', 'AppIconPreprod']].each do |flavor, suffix, icon_name|
['Debug', 'Release'].each do |type|
  name = "#{type} #{flavor}"
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
  end
end
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
  (proj, ".env", "Debug", "Release"),
  (f"{proj} Develop", ".env.develop", "Debug Develop", "Release Develop"),
  (f"{proj} QA", ".env.qa", "Debug QA", "Release QA"),
  (f"{proj} Preprod", ".env.preprod", "Debug Preprod", "Release Preprod"),
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
import React
import ReactAppDependencyProvider

@UIApplicationMain
public class AppDelegate: ExpoAppDelegate {
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



