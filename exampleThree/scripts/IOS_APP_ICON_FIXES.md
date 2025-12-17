# iOS App Icon Setup - Fixes Summary

## Problem Identified

The iOS app icon was not appearing because:

1. **Missing Icon Files**: The `AppIconDev.appiconset` directory (used by the "Develop" scheme) only contained `Contents.json` but no actual PNG icon files.

2. **Incomplete Contents.json**: The `Contents.json` file only defined the 1024x1024 marketing icon, but iOS requires multiple icon sizes for different devices and contexts.

3. **Wrong Icon Location**: The source icon file was in an incorrect location (`ios/project.pbxproj/Images.xcassets/` instead of `ios/exampleThree/Images.xcassets/`).

4. **Multiple App Icon Sets**: The project uses different app icon sets for different build schemes:
   - `AppIcon` - Production builds
   - `AppIconDev` - Develop builds (this was the broken one)
   - `AppIconQA` - QA builds
   - `AppIconPreprod` - Preprod builds

## Fixes Applied

### 1. Icon File Setup
- Copied the 1024x1024 source icon to the correct location: `ios/exampleThree/Images.xcassets/AppIconDev.appiconset/icon-1024.png`

### 2. Generated All Required Icon Sizes
Generated all required iOS icon sizes from the 1024x1024 source using `sips` (macOS built-in tool):

**iPhone Icons:**
- 20x20 @2x (40x40 pixels) - Notification icon
- 20x20 @3x (60x60 pixels) - Notification icon
- 29x29 @2x (58x58 pixels) - Settings icon
- 29x29 @3x (87x87 pixels) - Settings icon
- 40x40 @2x (80x80 pixels) - Spotlight icon
- 40x40 @3x (120x120 pixels) - Spotlight icon
- 60x60 @2x (120x120 pixels) - App icon
- 60x60 @3x (180x180 pixels) - App icon

**iPad Icons:**
- 20x20 @1x (20x20 pixels) - Notification icon
- 20x20 @2x (40x40 pixels) - Notification icon
- 29x29 @1x (29x29 pixels) - Settings icon
- 29x29 @2x (58x58 pixels) - Settings icon
- 40x40 @1x (40x40 pixels) - Spotlight icon
- 40x40 @2x (80x80 pixels) - Spotlight icon
- 76x76 @1x (76x76 pixels) - App icon
- 76x76 @2x (152x152 pixels) - App icon
- 83.5x83.5 @2x (167x167 pixels) - iPad Pro app icon

**App Store:**
- 1024x1024 - Marketing icon for App Store

### 3. Updated Contents.json
Created a complete `Contents.json` file that references all generated icon files with correct size and scale specifications.

## Implementation in Setup Script

### Required Steps:

1. **Ensure source icon exists**: The script should have access to a 1024x1024 PNG icon file.

2. **For each app icon set** (AppIcon, AppIconDev, AppIconQA, AppIconPreprod):
   - Copy the 1024x1024 source icon to the appiconset directory
   - Generate all required icon sizes using `sips` command
   - Create/update `Contents.json` with all icon references

3. **Verify asset catalog structure**: Ensure `Images.xcassets` is properly referenced in the Xcode project.

### Script Usage

```bash
# Make script executable
chmod +x scripts/setup_ios_app_icons.sh

# Run the script
./scripts/setup_ios_app_icons.sh <path_to_1024x1024_icon.png> <ios_project_path>

# Example:
./scripts/setup_ios_app_icons.sh ./assets/icon-1024.png ./ios/exampleThree
```

### Key Commands Used

```bash
# Generate iPhone icons
sips -z 40 40 icon-1024.png --out icon-20@2x.png
sips -z 60 60 icon-1024.png --out icon-20@3x.png
sips -z 58 58 icon-1024.png --out icon-29@2x.png
sips -z 87 87 icon-1024.png --out icon-29@3x.png
sips -z 80 80 icon-1024.png --out icon-40@2x.png
sips -z 120 120 icon-1024.png --out icon-40@3x.png
sips -z 120 120 icon-1024.png --out icon-60@2x.png
sips -z 180 180 icon-1024.png --out icon-60@3x.png

# Generate iPad icons
sips -z 20 20 icon-1024.png --out icon-20-ipad.png
sips -z 40 40 icon-1024.png --out icon-20-ipad@2x.png
sips -z 29 29 icon-1024.png --out icon-29-ipad.png
sips -z 58 58 icon-1024.png --out icon-29-ipad@2x.png
sips -z 40 40 icon-1024.png --out icon-40-ipad.png
sips -z 80 80 icon-1024.png --out icon-40-ipad@2x.png
sips -z 76 76 icon-1024.png --out icon-76-ipad.png
sips -z 152 152 icon-1024.png --out icon-76-ipad@2x.png
sips -z 167 167 icon-1024.png --out icon-83.5-ipad@2x.png
```

## Verification

After running the script, verify:

1. All icon files exist in each appiconset directory
2. `Contents.json` is valid JSON and references all icon files
3. Build settings in Xcode project reference the correct app icon set:
   - `ASSETCATALOG_COMPILER_APPICON_NAME = AppIconDev` (for Develop scheme)
   - `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` (for Production scheme)
   - etc.

## Notes

- The `sips` command is macOS-only. For cross-platform scripts, consider using ImageMagick or another image processing tool.
- Each build scheme may use a different app icon set, so all sets need to be configured.
- After setting up icons, clean the Xcode build folder and rebuild the app.
- The simulator may cache old icons - delete the app from simulator and reinstall if needed.


