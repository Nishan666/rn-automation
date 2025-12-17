# iOS App Icon Setup - Troubleshooting Guide

## Problem
iOS app icons are not appearing after building the app.

## Root Causes
1. **Missing Icon Files**: The `Contents.json` files reference `icon-1024.png`, but the actual image files are missing from the appiconset directories.
2. **Incorrect Contents.json Format**: The format was using `"idiom": "universal"` instead of `"idiom": "ios-marketing"` for iOS 11+.

## Solution

### Option 1: Use the Icon Setup Script (Recommended)
Run the dedicated icon setup script:

```bash
./setup_ios_icons.sh [project_directory]
```

This script will:
- Guide you through selecting icon files for each environment
- Copy the icons to the correct locations
- Create properly formatted `Contents.json` files
- Set up icons for all 4 environments (production, develop, qa, preprod)

### Option 2: Manual Setup
1. **Prepare your icon files**: You need 1024x1024 PNG files for each environment
2. **Copy icons to the correct directories**:
   ```bash
   # For production
   cp your-icon.png ios/[PROJECT_NAME]/Images.xcassets/AppIcon.appiconset/icon-1024.png
   
   # For develop
   cp your-dev-icon.png ios/[PROJECT_NAME]/Images.xcassets/AppIconDev.appiconset/icon-1024.png
   
   # For QA
   cp your-qa-icon.png ios/[PROJECT_NAME]/Images.xcassets/AppIconQA.appiconset/icon-1024.png
   
   # For preprod
   cp your-preprod-icon.png ios/[PROJECT_NAME]/Images.xcassets/AppIconPreprod.appiconset/icon-1024.png
   ```

3. **Verify Contents.json format**: Each appiconset directory should have a `Contents.json` with:
   ```json
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
   ```

### After Setting Up Icons

1. **Clean the build folder in Xcode**:
   - Open your project in Xcode
   - Press `Cmd + Shift + K` (or Product > Clean Build Folder)
   - This is crucial - iOS caches app icons, so a clean build is necessary

2. **Rebuild your app**:
   ```bash
   npm run ios:dev    # or ios:qa, ios:preprod, ios:prod
   ```

3. **Verify in Xcode**:
   - Open `ios/[PROJECT_NAME].xcodeproj` in Xcode
   - Select your target
   - Go to Build Settings
   - Search for `ASSETCATALOG_COMPILER_APPICON_NAME`
   - Verify each build configuration points to the correct icon set:
     - Debug/Release → `AppIcon`
     - Debug Develop/Release Develop → `AppIconDev`
     - Debug QA/Release QA → `AppIconQA`
     - Debug Preprod/Release Preprod → `AppIconPreprod`

## Icon Requirements
- **Format**: PNG
- **Size**: 1024x1024 pixels
- **No transparency**: iOS app icons should not have transparent backgrounds
- **Square**: The icon should be square (1024x1024)

## Verification Checklist
- [ ] Icon files exist in all appiconset directories (`icon-1024.png`)
- [ ] `Contents.json` files use `"idiom": "ios-marketing"`
- [ ] `ASSETCATALOG_COMPILER_APPICON_NAME` is set correctly for each build configuration
- [ ] Build folder has been cleaned in Xcode
- [ ] App has been rebuilt after icon setup

## Common Issues

### Icons still not appearing after setup
1. **Clean build folder** - This is the most common fix
2. **Restart Xcode** - Sometimes Xcode needs a restart
3. **Delete derived data**:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
4. **Check target membership**: In Xcode, select `Images.xcassets` and verify your target is checked

### Icon appears in Xcode but not on device/simulator
- This is usually a caching issue. Try:
  1. Delete the app from the simulator/device
  2. Clean build folder
  3. Rebuild and reinstall

### Wrong icon appearing for an environment
- Check that `ASSETCATALOG_COMPILER_APPICON_NAME` is set correctly for the build configuration you're using
- Verify the scheme is using the correct build configuration


