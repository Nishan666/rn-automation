#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# Source file browser utility
source "$SCRIPT_DIR/utils/file_browser.sh"

# Icon setup functions
setup_icons() {
  local environment="$1"
  local icon_path="$2"
  
  if [ ! -f "$icon_path" ]; then
    echo "Icon file not found: $icon_path" >&2
    return 1
  fi

  local android_flavor
  local ios_appicon_set
  
  case "$environment" in
    develop|dev)
      android_flavor="develop"
      ios_appicon_set="AppIconDev.appiconset"
      ;;
    qa)
      android_flavor="qa"
      ios_appicon_set="AppIconQA.appiconset"
      ;;
    preprod|preproduction)
      android_flavor="preprod"
      ios_appicon_set="AppIconPreprod.appiconset"
      ;;
    prod|production)
      android_flavor="production"
      ios_appicon_set="AppIcon.appiconset"
      ;;
    *)
      echo "Unknown environment '$environment'" >&2
      return 1
      ;;
  esac

  # Copy icon to Android directories
  local android_base="android/app/src"
  local android_targets=("main")
  if [ "$android_flavor" != "production" ]; then
    android_targets+=("$android_flavor")
  else
    android_targets+=("production")
  fi

  declare -a android_densities=(
    "mipmap-mdpi" "mipmap-hdpi" "mipmap-xhdpi" "mipmap-xxhdpi" "mipmap-xxxhdpi"
  )

  echo "Setting up Android icons for $android_flavor..."
  for target in "${android_targets[@]}"; do
    local target_dir="$android_base/$target"
    for density in "${android_densities[@]}"; do
      mkdir -p "$target_dir/res/$density"
      cp "$icon_path" "$target_dir/res/$density/ic_launcher.png"
      cp "$icon_path" "$target_dir/res/$density/ic_launcher_round.png"
    done
  done

  # Copy icon to iOS (macOS only)
  if [ "$(uname -s)" = "Darwin" ]; then
    local ios_project=$(ls ios/*.xcodeproj 2>/dev/null | head -1 || true)
    if [ -n "$ios_project" ]; then
      local ios_name=$(basename "$ios_project" .xcodeproj)
      local ios_assets_dir="ios/$ios_name/Images.xcassets"
      local ios_appicon_dir="$ios_assets_dir/$ios_appicon_set"

      mkdir -p "$ios_appicon_dir"
      cp "$icon_path" "$ios_appicon_dir/icon-1024.png"
      
      # FIXED: Create correct Contents.json for iOS
      # Changed from "ios-marketing" idiom to "universal" with "platform": "ios"
      cat > "$ios_appicon_dir/Contents.json" << 'EOF'
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
EOF
    fi
  fi

  echo "Icons set up for environment '$environment'."
}

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Helper functions
print_header() {
  echo -e "${CYAN}${BOLD}===================================${NC}"
  echo -e "${CYAN}${BOLD}🚀 React Native Expo Project Setup${NC}"
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

# Interactive prompts
clear
print_header

while true; do
  echo -e "${BOLD}What is your project name? (folder/package name - alphanumeric only)${NC}"
  echo -e "${PURPLE}Used for: folder name, package identifier (com.projectname)${NC}"
  echo -e "${YELLOW}Example: MyApp or myapp${NC}"
  read -p "📝 " PROJECT_NAME
  if [ -z "$PROJECT_NAME" ]; then
    print_error "Project name cannot be empty"
  elif [ ${#PROJECT_NAME} -lt 2 ]; then
    print_error "Project name must be at least 2 characters"
  elif ! [[ "$PROJECT_NAME" =~ ^[a-zA-Z0-9]+$ ]]; then
    print_error "Project name must contain only letters and numbers (no spaces, hyphens, or special characters)"
  else
    break
  fi
done

echo ""
while true; do
  echo -e "${BOLD}What is your app name? (display name - can contain spaces, -, _)${NC}"
  echo -e "${PURPLE}This will be shown to users on their devices${NC}"
  echo -e "${YELLOW}Example: My App${NC}"
  read -p "📱 " APP_NAME
  if [ -z "$APP_NAME" ]; then
    print_error "App name cannot be empty"
  elif [ ${#APP_NAME} -lt 2 ]; then
    print_error "App name must be at least 2 characters"
  else
    break
  fi
done

echo ""
echo -e "${BOLD}Where do you want to create the project?${NC}"
echo -e "  ${YELLOW}1)${NC} Current directory (${PWD})"
echo -e "  ${YELLOW}2)${NC} Choose different location"
read -p "📍 Enter choice (1-2): " LOCATION_CHOICE

PROJECT_DIR="$PWD"
case "$LOCATION_CHOICE" in
  2)
    echo ""
    echo -e "${BOLD}Select project directory:${NC}"
    echo -e "${PURPLE}Use the file browser to navigate and select your project location${NC}"
    echo ""
    
    echo -e "${BOLD}Choose directory selection method:${NC}"
    echo -e "  ${YELLOW}1)${NC} Manual input (type path)"
    echo -e "  ${YELLOW}2)${NC} Use fuzzy finder (fzf)"
    read -p "📁 Enter choice (1-2): " DIR_METHOD
    
    if [ "$DIR_METHOD" = "2" ]; then
      MANUAL_DIR=$(browse_files "$HOME" "" "directory")
      if [ $? -ne 0 ] || [ -z "$MANUAL_DIR" ]; then
        print_warning "Directory selection failed or cancelled"
        MANUAL_DIR=""
      fi
    else
      print_info "Enter directory path:"
      echo -e "${YELLOW}Common locations:${NC}"
      echo -e "  ${PURPLE}~/Desktop${NC} - Desktop"
      echo -e "  ${PURPLE}~/Documents${NC} - Documents"
      echo -e "  ${PURPLE}~/Projects${NC} - Projects folder"
      echo -e "  ${PURPLE}$PWD${NC} - Current directory"
      echo ""
      read -p "📁 Directory path (or press Enter for current): " MANUAL_DIR
    fi
    
    if [ -n "$MANUAL_DIR" ]; then
      # Expand tilde to home directory
      MANUAL_DIR="${MANUAL_DIR/#\~/$HOME}"
      
      if [ -d "$MANUAL_DIR" ] && [ -w "$MANUAL_DIR" ]; then
        PROJECT_DIR="$MANUAL_DIR"
        print_success "Project will be created in: $PROJECT_DIR"
      elif [ -d "$MANUAL_DIR" ] && [ ! -w "$MANUAL_DIR" ]; then
        print_warning "Directory exists but is not writable: $MANUAL_DIR"
        print_info "Using current directory: $PWD"
        PROJECT_DIR="$PWD"
      elif [ ! -d "$MANUAL_DIR" ]; then
        print_warning "Directory not found: $MANUAL_DIR"
        echo -e "${YELLOW}Do you want to create this directory? (y/n)${NC}"
        read -p "📁 " CREATE_DIR
        
        if [ "$CREATE_DIR" = "y" ] || [ "$CREATE_DIR" = "Y" ]; then
          if mkdir -p "$MANUAL_DIR" 2>/dev/null; then
            PROJECT_DIR="$MANUAL_DIR"
            print_success "Directory created: $PROJECT_DIR"
          else
            print_error "Failed to create directory. Using current directory: $PWD"
            PROJECT_DIR="$PWD"
          fi
        else
          print_info "Using current directory: $PWD"
          PROJECT_DIR="$PWD"
        fi
      else
        PROJECT_DIR="$MANUAL_DIR"
        print_success "Project will be created in: $PROJECT_DIR"
      fi
    else
      print_info "Using current directory: $PWD"
      PROJECT_DIR="$PWD"
    fi
    ;;
  *)
    print_info "Using current directory: $PWD"
    ;;
esac

slugify() {
  local input="$1"
  # Handle all naming patterns:
  # 1. Insert dots before uppercase letters (camelCase/PascalCase)
  # 2. Replace spaces, hyphens, underscores with dots
  # 3. Convert to lowercase
  # 4. Remove consecutive dots
  # 5. Remove leading/trailing dots
  # 6. Keep only alphanumeric and dots
  echo "$input" | \
    sed 's/\([A-Z]\)/\.\1/g' | \
    tr ' _-' '.' | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/\.\+/./g' | \
    sed 's/^\.//g' | \
    sed 's/\.$//g' | \
    tr -cd 'a-z0-9.'
}

echo ""
echo -e "${BOLD}Android application ID (package name)${NC}"
echo -e "${PURPLE}Auto-generated: com.$(slugify "$PROJECT_NAME")${NC}"
echo -e "  ${YELLOW}1)${NC} Use auto-generated"
echo -e "  ${YELLOW}2)${NC} Enter custom package name"
read -p "📱 Enter choice (1-2): " PACKAGE_CHOICE

if [ "$PACKAGE_CHOICE" = "2" ]; then
  while true; do
    echo ""
    echo -e "${BOLD}Enter custom Android package name:${NC}"
    echo -e "${YELLOW}Example: com.company.myapp${NC}"
    read -p "📦 " CUSTOM_APP_ID
    if [ -z "$CUSTOM_APP_ID" ]; then
      print_error "Package name cannot be empty"
    else
      # Convert to lowercase
      CUSTOM_APP_ID=$(echo "$CUSTOM_APP_ID" | tr '[:upper:]' '[:lower:]')
      # Validate format
      if [[ "$CUSTOM_APP_ID" =~ ^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$ ]]; then
        ANDROID_APP_ID="$CUSTOM_APP_ID"
        print_success "Package name set: $ANDROID_APP_ID"
        break
      else
        print_error "Invalid package name format. Must be like: com.company.appname"
      fi
    fi
  done
else
  GENERATED_SLUG="$(slugify "$PROJECT_NAME")"
  if [ -z "$GENERATED_SLUG" ]; then
    echo "Unable to derive Android application id from project name. Please provide it explicitly."
    exit 1
  fi
  ANDROID_APP_ID="com.${GENERATED_SLUG}"
  print_success "Using auto-generated: $ANDROID_APP_ID"
fi

DISPLAY_NAME="$APP_NAME"
DEVELOP_APP_ID="${ANDROID_APP_ID}.develop"
QA_APP_ID="${ANDROID_APP_ID}.qa"
PREPROD_APP_ID="${ANDROID_APP_ID}.preprod"

echo ""
echo -e "${CYAN}${BOLD}===================================${NC}"
echo -e "${CYAN}${BOLD}📋 Configuration Summary${NC}"
echo -e "${CYAN}${BOLD}===================================${NC}"
echo -e "${BOLD}Project Name:${NC} $PROJECT_NAME"
echo -e "${BOLD}App Name:${NC} $DISPLAY_NAME"
echo -e "${BOLD}Android ID:${NC} $ANDROID_APP_ID"
echo -e "  ${YELLOW}• Develop:${NC} $DEVELOP_APP_ID"
echo -e "  ${YELLOW}• QA:${NC} $QA_APP_ID"
echo -e "  ${YELLOW}• Preprod:${NC} $PREPROD_APP_ID"
echo -e "${CYAN}${BOLD}===================================${NC}"
echo ""
echo -e "${BOLD}📋 Setup Summary - What will happen:${NC}"
echo ""
echo -e "${CYAN}Step 1:${NC} Create Expo bare-minimum project"
echo -e "${CYAN}Step 2:${NC} Create organized project structure (src/modules, navigation, etc.)"
echo -e "${CYAN}Step 3:${NC} Install dependencies:"
echo -e "        • Navigation (@react-navigation)"
echo -e "        • State management (Zustand)"
echo -e "        • SVG support"
echo -e "        • Environment config"

echo -e "        • Utilities (Toast, AsyncStorage, DeviceInfo)"
echo -e "        • Development tools (ESLint, Prettier, TypeScript)"
echo -e "        • Testing (Jest, React Native Testing Library)"
echo -e "${CYAN}Step 4:${NC} Copy template files (configs, example modules)"
echo -e "${CYAN}Step 5:${NC} Create environment files (.env.develop, .env.qa, etc.)"
echo -e "${CYAN}Step 6:${NC} Configure Android product flavors"
echo -e "${CYAN}Step 7:${NC} Configure iOS (if selected and on macOS)"
echo -e "${CYAN}Step 8:${NC} Generate app icons (if selected)"
echo -e "${CYAN}Step 9:${NC} Update package.json with build scripts"
echo ""
echo -e "${BOLD}Example modules included:${NC}"
echo -e "        • Splash screen with session check"
echo -e "        • Login flow with Zustand store"
echo -e "        • Home screen"
echo -e "        • Navigation setup"
echo -e "        • Component testing setup with example tests"
echo ""
echo -e "${BOLD}Proceed with setup?${NC}"
read -p "✅ (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  print_warning "Setup cancelled."
  exit 0
fi

echo ""
print_step "Creating Expo project '$PROJECT_NAME'..."
cd "$PROJECT_DIR"
if npx create-expo-app@latest "$PROJECT_NAME" --template bare-minimum; then
  print_success "Expo project created"
  cd "$PROJECT_NAME"
else
  print_error "Failed to create Expo project"
  exit 1
fi

print_step "Creating project structure..."
mkdir -p src/assets/fonts src/constants src/model src/navigation src/modules/splash src/modules/login src/modules/home src/services src/store/slices src/styles src/utils src/viewmodels
print_success "Project structure created"

print_step "Installing dependencies..."
print_info "This may take a few minutes..."

# Navigation dependencies
npm install @react-navigation/native @react-navigation/native-stack react-native-gesture-handler react-native-safe-area-context react-native-screens

# SVG support
npm install react-native-svg
npm install --save-dev react-native-svg-transformer

# Environment & configuration
npm install react-native-config@latest

# State management
npm install zustand

# Utilities
npm install react-native-toast-message @react-native-async-storage/async-storage react-native-device-info

# Development tools
npm install --save-dev --legacy-peer-deps eslint @eslint/js typescript-eslint @typescript-eslint/eslint-plugin @typescript-eslint/parser eslint-config-prettier eslint-plugin-react prettier babel-preset-expo babel-plugin-module-resolver

# Testing dependencies
npm install --save-dev jest @testing-library/react-native@^12.4.0 @testing-library/jest-native react-test-renderer@19.1.0

# TypeScript types
npx expo install @types/react

print_success "Dependencies installed"

echo "Copying template files..."
cp "$TEMPLATES_DIR/.gitignore" .
cp "$TEMPLATES_DIR/babel.config.js" .
cp "$TEMPLATES_DIR/eslint.config.mjs" .
cp "$TEMPLATES_DIR/.eslintignore" .
cp "$TEMPLATES_DIR/.prettierrc" .
cp "$TEMPLATES_DIR/.prettierignore" .
cp "$TEMPLATES_DIR/custom.d.ts" .
cp "$TEMPLATES_DIR/jest.config.js" .
cp "$TEMPLATES_DIR/jest.setup.js" .
cp "$TEMPLATES_DIR/App.tsx" .
cp -r "$TEMPLATES_DIR/src/"* src/

echo "Creating environment files..."
cat > .env << 'EOF'
# Default environment variables
# Example:
# API_URL=https://api.example.com
EOF

cat > .env.develop << 'EOF'
# Develop environment variables
# API_URL=https://develop-api.example.com
EOF

cat > .env.qa << 'EOF'
# QA environment variables
# API_URL=https://qa-api.example.com
EOF

cat > .env.preprod << 'EOF'
# Preproduction environment variables
# API_URL=https://preprod-api.example.com
EOF

echo "Configuring Android..."
GRADLE_FILE="android/app/build.gradle"

# Add environment config
if ! grep -q "project.ext.envConfigFiles" "$GRADLE_FILE"; then
  TEMP_ENV_FILE=$(mktemp)
  echo "" > "$TEMP_ENV_FILE"
  cat "$TEMPLATES_DIR/android/env-config.gradle" >> "$TEMP_ENV_FILE"
  echo "" >> "$TEMP_ENV_FILE"
  
  awk '/apply plugin: "com.facebook.react"/ {print; system("cat '"$TEMP_ENV_FILE"'"); next}1' "$GRADLE_FILE" > "${GRADLE_FILE}.tmp"
  mv "${GRADLE_FILE}.tmp" "$GRADLE_FILE"
  rm -f "$TEMP_ENV_FILE"
fi

# Add product flavors
if ! grep -q "flavorDimensions" "$GRADLE_FILE"; then
  TEMP_FLAVORS_FILE=$(mktemp)
  echo "" > "$TEMP_FLAVORS_FILE"
  cat "$TEMPLATES_DIR/android/product-flavors.gradle" >> "$TEMP_FLAVORS_FILE"
  echo "" >> "$TEMP_FLAVORS_FILE"
  
  if grep -q "namespace" "$GRADLE_FILE"; then
    awk '/namespace[[:space:]]+".*"/ {print; system("cat '"$TEMP_FLAVORS_FILE"'"); next}1' "$GRADLE_FILE" > "${GRADLE_FILE}.tmp"
  else
    awk '/android[[:space:]]*{/ {print; system("cat '"$TEMP_FLAVORS_FILE"'"); next}1' "$GRADLE_FILE" > "${GRADLE_FILE}.tmp"
  fi
  mv "${GRADLE_FILE}.tmp" "$GRADLE_FILE"
  rm -f "$TEMP_FLAVORS_FILE"
fi

# Update namespace to match applicationId
if grep -q "namespace" "$GRADLE_FILE"; then
  sed -i.bak "s|namespace[[:space:]]*\"[^\"]*\"|namespace \"$ANDROID_APP_ID\"|" "$GRADLE_FILE"
  rm -f "${GRADLE_FILE}.bak"
fi

# Update applicationId
if grep -q "applicationId" "$GRADLE_FILE"; then
  sed -i.bak "s|applicationId[[:space:]]*\"[^\"]*\"|applicationId \"$ANDROID_APP_ID\"|" "$GRADLE_FILE"
  rm -f "${GRADLE_FILE}.bak"
else
  sed -i.bak "/defaultConfig[[:space:]]*{/a\\
        applicationId \"$ANDROID_APP_ID\"" "$GRADLE_FILE"
  rm -f "${GRADLE_FILE}.bak"
fi

# Add resValue
if ! grep -q "build_config_package" "$GRADLE_FILE"; then
  sed -i.bak "/applicationId[[:space:]]*\"$ANDROID_APP_ID\"/a\\
        resValue \"string\", \"build_config_package\", \"$ANDROID_APP_ID\"" "$GRADLE_FILE"
  rm -f "${GRADLE_FILE}.bak"
fi

# Update strings.xml
STRINGS_FILE="android/app/src/main/res/values/strings.xml"
if [ -f "$STRINGS_FILE" ]; then
  sed -i.bak "s|<string name=\"app_name\">.*</string>|<string name=\"app_name\">$DISPLAY_NAME</string>|" "$STRINGS_FILE"
  rm -f "${STRINGS_FILE}.bak"
fi

# Create flavor strings
create_flavor_strings() {
  local flavor="$1"
  local label="$2"
  mkdir -p "android/app/src/${flavor}/res/values"
  cat > "android/app/src/${flavor}/res/values/strings.xml" << EOF
<resources>
    <string name="app_name">${label}</string>
</resources>
EOF
}

create_flavor_strings develop "${DISPLAY_NAME} Develop"
create_flavor_strings qa "${DISPLAY_NAME} QA"
create_flavor_strings preprod "${DISPLAY_NAME} Preprod"

# Fix package structure to match applicationId
print_info "Fixing package structure..."
# Expo creates package path with lowercase project name
EXPO_PACKAGE_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')
OLD_PACKAGE_PATH="android/app/src/main/java/com/${EXPO_PACKAGE_NAME}"
NEW_PACKAGE_PATH="android/app/src/main/java/$(echo $ANDROID_APP_ID | tr '.' '/')"

if [ -d "$OLD_PACKAGE_PATH" ] && [ "$OLD_PACKAGE_PATH" != "$NEW_PACKAGE_PATH" ]; then
  mkdir -p "$(dirname "$NEW_PACKAGE_PATH")"
  mv "$OLD_PACKAGE_PATH" "$NEW_PACKAGE_PATH" 2>/dev/null || true
  
  # Update package declarations in Kotlin files (Expo uses lowercase package name)
  find "$NEW_PACKAGE_PATH" -name "*.kt" -type f -exec sed -i.bak "s|package com\.${EXPO_PACKAGE_NAME}|package ${ANDROID_APP_ID}|g" {} \;
  find "$NEW_PACKAGE_PATH" -name "*.kt.bak" -delete
  
  # Clean up empty directories
  find android/app/src/main/java/com -type d -empty -delete 2>/dev/null || true
fi

# Disable new architecture
GRADLE_PROPS="android/gradle.properties"
if [ -f "$GRADLE_PROPS" ]; then
  if grep -q "newArchEnabled" "$GRADLE_PROPS"; then
    sed -i.bak 's/newArchEnabled[[:space:]]*=[[:space:]]*[a-z]*/newArchEnabled=false/' "$GRADLE_PROPS"
    rm -f "${GRADLE_PROPS}.bak"
  else
    echo "newArchEnabled=false" >> "$GRADLE_PROPS"
  fi
fi

echo "Updating package.json scripts..."
PACKAGE_JSON="package.json"
TEMP_JSON="${PACKAGE_JSON}.tmp"

cat "$PACKAGE_JSON" | jq \
  --arg dev "expo run:android --variant=developDebug --app-id $DEVELOP_APP_ID" \
  --arg dev_rel "expo run:android --variant=developRelease --app-id $DEVELOP_APP_ID" \
  --arg qa "expo run:android --variant=qaDebug --app-id $QA_APP_ID" \
  --arg qa_rel "expo run:android --variant=qaRelease --app-id $QA_APP_ID" \
  --arg preprod "expo run:android --variant=preprodDebug --app-id $PREPROD_APP_ID" \
  --arg preprod_rel "expo run:android --variant=preprodRelease --app-id $PREPROD_APP_ID" \
  --arg prod "expo run:android --variant=productionDebug --app-id $ANDROID_APP_ID" \
  --arg prod_rel "expo run:android --variant=productionRelease --app-id $ANDROID_APP_ID" \
  '.scripts["android:dev"] = $dev |
   .scripts["android:dev-release"] = $dev_rel |
   .scripts["android:qa"] = $qa |
   .scripts["android:qa-release"] = $qa_rel |
   .scripts["android:preprod"] = $preprod |
   .scripts["android:preprod-release"] = $preprod_rel |
   .scripts["android:prod"] = $prod |
   .scripts["android:prod-release"] = $prod_rel |
   .scripts["lint"] = "eslint . --ext .ts,.tsx,.js,.jsx" |
   .scripts["lint:fix"] = "eslint . --ext .ts,.tsx,.js,.jsx --fix" |
   .scripts["format"] = "prettier --write \"src/**/*.{ts,tsx,js,jsx,json,css,md}\"" |
   .scripts["format:check"] = "prettier --check \"src/**/*.{ts,tsx,js,jsx,json,css,md}\"" |
   .scripts["test"] = "jest" |
   .scripts["test:watch"] = "jest --watch" |
   .scripts["test:coverage"] = "jest --coverage"' \
  > "$TEMP_JSON"

mv "$TEMP_JSON" "$PACKAGE_JSON"

# Remove default App.js if it exists
[ -f "App.js" ] && rm -f App.js

# iOS Setup
echo ""
echo -e "${BOLD}Configure iOS support?${NC}"
if [ "$(uname -s)" = "Darwin" ]; then
  echo -e "${GREEN}macOS detected - iOS support available${NC}"
else
  echo -e "${YELLOW}Non-macOS system - iOS support limited${NC}"
fi
read -p "🍎 (y/n): " SETUP_IOS
if [ "$SETUP_IOS" = "y" ] || [ "$SETUP_IOS" = "Y" ]; then
  if [ "$(uname -s)" != "Darwin" ]; then
    print_warning "iOS configuration requires macOS. Skipping iOS setup."
  else
    print_step "Configuring iOS..."
    
    # Get iOS project name from Podfile
    IOS_PROJECT_NAME=$(grep -m 1 "project '" ios/Podfile 2>/dev/null | sed "s/.*project '\([^']*\)'.*/\1/" || echo "$PROJECT_NAME")
  
  
  # Source iOS flavor setup script
  source "$SCRIPT_DIR/ios_flavor_setup.sh"
  
  # Setup iOS product flavors
  setup_ios_flavors "$IOS_PROJECT_NAME" "$ANDROID_APP_ID" "$DISPLAY_NAME"
  
  # Fix iOS icon configuration and display names for each environment
  print_info "Configuring iOS icon settings and display names for each environment..."
  
  # Update Info.plist with display name variable
  INFO_PLIST="ios/$IOS_PROJECT_NAME/Info.plist"
  if [ -f "$INFO_PLIST" ]; then
    if ! grep -q "CFBundleDisplayName" "$INFO_PLIST"; then
      # Add CFBundleDisplayName if it doesn't exist
      /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string '\$(INFOPLIST_KEY_CFBundleDisplayName)'" "$INFO_PLIST" 2>/dev/null || \
      /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName '\$(INFOPLIST_KEY_CFBundleDisplayName)'" "$INFO_PLIST" 2>/dev/null
    else
      # Update existing CFBundleDisplayName
      /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName '\$(INFOPLIST_KEY_CFBundleDisplayName)'" "$INFO_PLIST" 2>/dev/null
    fi
  fi
  
  if command -v ruby >/dev/null 2>&1; then
    IOS_PROJECT_NAME_ENV="$IOS_PROJECT_NAME" DISPLAY_NAME_ENV="$DISPLAY_NAME" ruby - <<'RUBYEOF'
require 'fileutils'
begin
  require 'xcodeproj'
rescue LoadError
  system('gem install xcodeproj --user-install')
  Gem.clear_paths
  require 'xcodeproj'
end

project_name = ENV['IOS_PROJECT_NAME_ENV']
display_name = ENV['DISPLAY_NAME_ENV'] || project_name
project_path = "ios/#{project_name}.xcodeproj"
exit 0 unless File.exist?(project_path)

project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == project_name }
exit 0 unless target

# Update icon configuration and display name for each build configuration
target.build_configurations.each do |config|
  case config.name
  when /Debug Develop|Release Develop/
    config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIconDev'
    config.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = "#{display_name} Develop"
  when /Debug QA|Release QA/
    config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIconQA'
    config.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = "#{display_name} QA"
  when /Debug Preprod|Release Preprod/
    config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIconPreprod'
    config.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = "#{display_name} Preprod"
  when /Debug|Release/
    # Production configurations keep AppIcon (default) and base display name
    config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon' unless config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME']
    config.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = display_name unless config.build_settings['INFOPLIST_KEY_CFBundleDisplayName']
  end
end

# Also update project-level configurations
project.build_configurations.each do |config|
  case config.name
  when /Debug Develop|Release Develop/
    config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIconDev'
    config.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = "#{display_name} Develop"
  when /Debug QA|Release QA/
    config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIconQA'
    config.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = "#{display_name} QA"
  when /Debug Preprod|Release Preprod/
    config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIconPreprod'
    config.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = "#{display_name} Preprod"
  when /Debug|Release/
    config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon' unless config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME']
    config.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = display_name unless config.build_settings['INFOPLIST_KEY_CFBundleDisplayName']
  end
end

project.save
puts "Updated icon and display name configurations for #{target.build_configurations.count} build configurations"
RUBYEOF
    if [ $? -eq 0 ]; then
      print_success "iOS icon configurations updated"
    else
      print_warning "Failed to update iOS icon configurations automatically"
    fi
  else
    print_warning "Ruby not found. Skipping automatic icon configuration. You'll need to set ASSETCATALOG_COMPILER_APPICON_NAME manually in Xcode."
  fi
  
  # Install Expo modules
  print_info "Installing Expo modules..."
  if npx install-expo-modules@latest --non-interactive 2>/dev/null; then
    print_success "Expo modules installed"
    
    # Pod install
    print_info "Installing CocoaPods dependencies..."
    if npx pod-install --non-interactive 2>/dev/null; then
      print_success "iOS configured"
    else
      print_warning "Pod install failed. Trying manual approach..."
      if cd ios && pod install --repo-update 2>/dev/null && cd ..; then
        print_success "iOS configured with manual pod install"
      else
        print_warning "iOS setup incomplete. Manual steps required:"
        print_info "  1. cd $PROJECT_DIR/$PROJECT_NAME"
        print_info "  2. npx install-expo-modules@latest"
        print_info "  3. cd ios && pod install"
      fi
    fi
  else
    print_warning "Expo modules installation failed."
    print_info "iOS setup skipped. To set up iOS manually:"
    print_info "  1. cd $PROJECT_DIR/$PROJECT_NAME"
    print_info "  3. cd ios && pod install"
    print_info "  2. npx install-expo-modules@latest"
    fi
  fi
else
  print_info "Skipping iOS configuration."
fi

# Add iOS scripts to package.json if iOS was configured
if [ "$SETUP_IOS" = "y" ] || [ "$SETUP_IOS" = "Y" ]; then
  if [ "$(uname -s)" = "Darwin" ]; then
    IOS_PROJECT_NAME_FOR_SCRIPTS=$(grep -m 1 "project '" ios/Podfile 2>/dev/null | sed "s/.*project '\([^']*\)'.*/\1/" || echo "$PROJECT_NAME")
    
    TEMP_JSON2="${PACKAGE_JSON}.tmp2"
    cat "$PACKAGE_JSON" | jq \
      --arg ios_dev "expo run:ios --scheme '${IOS_PROJECT_NAME_FOR_SCRIPTS} Develop' --configuration 'Debug Develop'" \
      --arg ios_qa "expo run:ios --scheme '${IOS_PROJECT_NAME_FOR_SCRIPTS} QA' --configuration 'Debug QA'" \
      --arg ios_preprod "expo run:ios --scheme '${IOS_PROJECT_NAME_FOR_SCRIPTS} Preprod' --configuration 'Debug Preprod'" \
      --arg ios_prod "expo run:ios --scheme '${IOS_PROJECT_NAME_FOR_SCRIPTS}' --configuration 'Debug'" \
      '.scripts["ios:dev"] = $ios_dev |
       .scripts["ios:qa"] = $ios_qa |
       .scripts["ios:preprod"] = $ios_preprod |
       .scripts["ios:prod"] = $ios_prod' \
      > "$TEMP_JSON2"
    
    mv "$TEMP_JSON2" "$PACKAGE_JSON"
  fi
fi

# Fix build.gradle after install-expo-modules
print_info "Cleaning up build configuration..."
if [ -f "$GRADLE_FILE" ]; then
  # Remove duplicate autolinking entries added by install-expo-modules
  if grep -q "Added by install-expo-modules" "$GRADLE_FILE"; then
    awk '/\/\/ Added by install-expo-modules/,/bundleCommand = "export:embed"/{next}1' "$GRADLE_FILE" > "${GRADLE_FILE}.tmp"
    mv "${GRADLE_FILE}.tmp" "$GRADLE_FILE"
  fi
  
  # Also remove any duplicate entryFile/cliFile/bundleCommand after autolinkLibrariesWithApp
  awk '/autolinkLibrariesWithApp\(\)/{print; getline; while(/^[[:space:]]*(entryFile|cliFile|bundleCommand)/) getline; print; next}1' "$GRADLE_FILE" > "${GRADLE_FILE}.tmp"
  mv "${GRADLE_FILE}.tmp" "$GRADLE_FILE"
fi

# Optional icon setup
echo ""
echo -e "${BOLD}Set up app icons for environments?${NC}"
if [ "$SETUP_IOS" = "y" ] || [ "$SETUP_IOS" = "Y" ]; then
  if [ "$(uname -s)" = "Darwin" ]; then
    echo -e "${GREEN}✅ iOS icon configurations are already set up for each environment${NC}"
    echo -e "${PURPLE}   Each environment will use its own icon automatically${NC}"
  fi
fi
read -p "🎨 (y/n): " SETUP_ICONS
if [ "$SETUP_ICONS" = "y" ] || [ "$SETUP_ICONS" = "Y" ]; then
  # Remove default webp icons to avoid conflicts with PNG icons
  print_info "Removing default webp icons..."
  find android/app/src/main/res -name "*.webp" -delete 2>/dev/null || true
  
  echo ""
  echo -e "${BOLD}Select icon files for each environment:${NC}"
  echo -e "${PURPLE}Please provide PNG files (recommended: 1024x1024)${NC}"
  echo ""
  
  for env in "develop" "qa" "preprod" "production"; do
    echo -e "${BOLD}Select icon for ${env} environment:${NC}"
    ICON_PATH=$(browse_files "$HOME" "png|PNG" "file")
    
    if [ $? -eq 0 ] && [ -n "$ICON_PATH" ] && [ -f "$ICON_PATH" ]; then
      print_step "Setting up $env icons..."
      if setup_icons "$env" "$ICON_PATH"; then
        print_success "Icons set up for $env environment"
      else
        print_warning "Icon setup failed for $env"
      fi
    else
      print_warning "No icon selected for $env environment. Skipping."
    fi
    echo ""
  done
  
  if [ "$SETUP_IOS" = "y" ] || [ "$SETUP_IOS" = "Y" ]; then
    if [ "$(uname -s)" = "Darwin" ]; then
      print_success "Icon setup complete! Each iOS environment is configured to use its own icon."
    fi
  fi
else
  print_info "Skipping icon setup."
fi

echo ""
echo -e "${GREEN}${BOLD}===================================${NC}"
echo -e "${GREEN}${BOLD}🎉 Setup complete!${NC}"
echo -e "${GREEN}${BOLD}===================================${NC}"
echo ""
echo ""
echo -e "${BOLD}📋 Next steps:${NC}"
echo -e "  ${CYAN}1.${NC} cd $PROJECT_DIR/$PROJECT_NAME"
echo -e "  ${CYAN}2.${NC} Update .env files with your API endpoints"
echo -e "  ${CYAN}3.${NC} Review android/app/build.gradle for any additional tweaks"
echo -e "  ${CYAN}4.${NC} Re-run setup script to generate icons for other environments"
echo ""
echo "Example modules created:"
echo "  - src/modules/splash/ (with Zustand store and API)"
echo "  - src/modules/login/ (with Zustand store and API)"
echo "  - src/modules/home/"
echo "  - src/navigation/AppNavigator.tsx"
echo ""
echo ""
echo -e "${BOLD}🚀 Available commands:${NC}"
echo ""
echo -e "${YELLOW}Android:${NC}"
echo -e "  ${GREEN}npm run android:dev${NC}          # Development build"
echo -e "  ${GREEN}npm run android:qa${NC}           # QA build"
echo -e "  ${GREEN}npm run android:preprod${NC}      # Pre-production build"
echo -e "  ${GREEN}npm run android:prod${NC}         # Production build"
echo ""
if [ "$SETUP_IOS" = "y" ] || [ "$SETUP_IOS" = "Y" ]; then
  if [ "$(uname -s)" = "Darwin" ]; then
echo -e "${YELLOW}iOS:${NC}"
echo -e "  ${GREEN}npm run ios:dev${NC}              # Development build"
echo -e "  ${GREEN}npm run ios:qa${NC}               # QA build"
echo -e "  ${GREEN}npm run ios:preprod${NC}          # Pre-production build"
echo -e "  ${GREEN}npm run ios:prod${NC}             # Production build"
echo ""
  fi
fi
echo -e "${YELLOW}Code Quality:${NC}"
echo -e "  ${GREEN}npm run lint${NC}                 # Check code quality"
echo -e "  ${GREEN}npm run lint:fix${NC}             # Auto-fix linting issues"
echo -e "  ${GREEN}npm run format${NC}               # Format code"
echo ""
echo -e "${YELLOW}Testing:${NC}"
echo -e "  ${GREEN}npm test${NC}                     # Run tests"
echo -e "  ${GREEN}npm run test:watch${NC}           # Run tests in watch mode"
echo -e "  ${GREEN}npm run test:coverage${NC}        # Run tests with coverage"
echo ""
echo "==================================="