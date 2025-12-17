# VSCode-Only Workflow Guide

This guide shows you how to work entirely from VSCode/terminal without opening Xcode.

## ✅ Complete Setup (No Xcode Required)

### 1. Initial Project Setup
```bash
./setup.sh
# Follow prompts - everything works from terminal!
```

### 2. Set Up Icons (Optional)
```bash
# During setup, or later:
./setup_ios_icons.sh
# Or from project directory:
cd your-project
../setup_ios_icons.sh
```

## 🧹 Cleaning Builds (Command Line)

### Clean iOS Build
```bash
# From project root:
npm run ios:clean

# Or directly:
./utils/clean_ios_build.sh

# Or from project directory:
../utils/clean_ios_build.sh
```

This script:
- Cleans all build configurations
- Removes build directories
- Cleans DerivedData (project-specific)
- Cleans CocoaPods cache

### Clean Android Build
```bash
cd android
./gradlew clean
cd ..
```

## 🚀 Building and Running

### iOS Builds
```bash
# Clean first (especially after icon changes)
npm run ios:clean

# Then build and run
npm run ios:dev      # Development
npm run ios:qa       # QA
npm run ios:preprod  # Pre-production
npm run ios:prod     # Production
```

### Android Builds
```bash
npm run android:dev      # Development
npm run android:qa       # QA
npm run android:preprod  # Pre-production
npm run android:prod     # Production
```

## 🔍 Verifying Icon Setup (Command Line)

### Check Icon Files Exist
```bash
# List all icon files
ls -la ios/[PROJECT_NAME]/Images.xcassets/*/icon-1024.png

# Should show:
# - AppIcon.appiconset/icon-1024.png
# - AppIconDev.appiconset/icon-1024.png
# - AppIconQA.appiconset/icon-1024.png
# - AppIconPreprod.appiconset/icon-1024.png
```

### Verify Contents.json Format
```bash
# Check a specific icon set
cat ios/[PROJECT_NAME]/Images.xcassets/AppIcon.appiconset/Contents.json

# Should show:
# {
#   "images": [
#     {
#       "filename": "icon-1024.png",
#       "idiom": "ios-marketing",
#       "platform": "ios",
#       "size": "1024x1024"
#     }
#   ],
#   ...
# }
```

### Check Build Settings (if xcodebuild available)
```bash
# Check icon name for a specific configuration
xcodebuild -project ios/[PROJECT_NAME].xcodeproj \
  -scheme "[PROJECT_NAME]" \
  -configuration "Debug Develop" \
  -showBuildSettings | grep ASSETCATALOG_COMPILER_APPICON_NAME

# Should show: ASSETCATALOG_COMPILER_APPICON_NAME = AppIconDev
```

## 📝 Common Workflows

### After Setting Up Icons
```bash
# 1. Clean build
npm run ios:clean

# 2. Rebuild
npm run ios:dev
```

### After Changing Icons
```bash
# 1. Update icon files (replace icon-1024.png in appiconset directories)
# 2. Clean build
npm run ios:clean

# 3. Rebuild
npm run ios:dev
```

### Troubleshooting Missing Icons
```bash
# 1. Verify icons exist
ls -la ios/[PROJECT_NAME]/Images.xcassets/*/icon-1024.png

# 2. Clean everything
npm run ios:clean
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 3. Rebuild
npm run ios:dev
```

## 🛠️ Available NPM Scripts

After setup, your `package.json` includes:

### iOS Scripts
- `npm run ios:clean` - Clean iOS build folder
- `npm run ios:dev` - Development build
- `npm run ios:qa` - QA build
- `npm run ios:preprod` - Pre-production build
- `npm run ios:prod` - Production build

### Android Scripts
- `npm run android:dev` - Development build
- `npm run android:qa` - QA build
- `npm run android:preprod` - Pre-production build
- `npm run android:prod` - Production build

### Code Quality
- `npm run lint` - Check code quality
- `npm run lint:fix` - Auto-fix linting issues
- `npm run format` - Format code

## 💡 Tips

1. **Always clean after icon changes**: Run `npm run ios:clean` before rebuilding
2. **Use VSCode terminal**: All commands work in VSCode's integrated terminal
3. **Check logs**: If icons don't appear, check build logs for asset catalog errors
4. **Verify file paths**: Make sure icon files are in the correct appiconset directories

## ❌ No Xcode Required!

Everything can be done from:
- ✅ VSCode terminal
- ✅ Command line
- ✅ Terminal app
- ✅ VSCode integrated terminal

You only need Xcode installed (for the build tools), but you never need to open it! 🎉


