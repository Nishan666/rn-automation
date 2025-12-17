# Complete Setup Flow - What Happens When You Run ./setup.sh

## ✅ Yes! All scripts are executed automatically

When you run `./setup.sh` from the script root directory, here's what happens:

## 📋 Complete Execution Flow

### 1. **Initial Setup**
   - Script sources `utils/file_browser.sh` (for icon file selection)
   - Prompts for project name, location, Android app ID
   - Creates Expo bare-minimum project

### 2. **Project Structure**
   - Creates all necessary directories
   - Installs all dependencies
   - Copies template files

### 3. **Android Configuration**
   - Configures product flavors (develop, qa, preprod, production)
   - Sets up build.gradle with flavors
   - Creates environment-specific resources

### 4. **iOS Configuration** (if you choose "y")
   - **Automatically sources `ios_flavor_setup.sh`**
   - **Calls `setup_ios_flavors()` function** which:
     - Creates all 4 build configurations
     - Creates icon set placeholders (AppIcon, AppIconDev, AppIconQA, AppIconPreprod)
     - Sets `ASSETCATALOG_COMPILER_APPICON_NAME` for each configuration
     - Creates Xcode schemes
     - Configures bundle IDs and display names
   - Updates Info.plist
   - Installs Expo modules
   - Runs pod install

### 5. **Icon Setup** (if you choose "y")
   - Uses `setup_icons()` function (defined in setup.sh)
   - For each environment (develop, qa, preprod, production):
     - Prompts you to select an icon file
     - **Generates all 18 required iOS icon sizes** using `sips`
     - Creates complete `Contents.json` with all sizes
     - Copies icons to Android directories
   - Verifies all icons were created
   - **Optionally calls clean script** if you choose "y"

### 6. **Final Steps**
   - Updates package.json with all build scripts
   - Copies clean script to project (if iOS was set up)
   - Shows summary and next steps

## 🔄 Scripts Called Automatically

1. **`utils/file_browser.sh`** - Sourced at the start (for file selection)
2. **`ios_flavor_setup.sh`** - Sourced when iOS setup is selected
3. **`setup_ios_flavors()`** - Called from ios_flavor_setup.sh
4. **`setup_icons()`** - Function in setup.sh (not a separate script)
5. **`scripts/clean_ios_build.sh`** - Called if you choose to clean (after icon setup)

## ✅ What You Need to Do

Just run:
```bash
./setup.sh
```

Then answer the prompts:
1. Project name? → Enter name
2. Location? → Choose 1 or 2
3. Android app ID? → Enter or press Enter for auto
4. Configure iOS? → **y** (if you want iOS)
5. Set up icons? → **y** (if you want icons)
   - Select icon for each environment
6. Clean build now? → **y** (recommended)

That's it! Everything else is automatic.

## 🎯 No Manual Steps Required

- ✅ iOS flavors are set up automatically
- ✅ Icon sizes are generated automatically
- ✅ Contents.json is created automatically
- ✅ Build configurations are set up automatically
- ✅ Xcode schemes are created automatically
- ✅ Package.json scripts are added automatically

## 📝 Standalone Scripts (Optional)

These are available if you need them later, but NOT required during setup:

- `setup_ios_icons.sh` - If you skipped icon setup and want to add icons later
- `utils/diagnose_icons.sh` - To check if icons are set up correctly
- `utils/fix_icon_contents.sh` - To fix incomplete icon setups
- `utils/fix_all_icons.sh` - Complete icon fix (fix + clean)

## 🚀 Summary

**Yes, `./setup.sh` executes everything automatically!**

You don't need to run any other scripts manually. Just:
1. Run `./setup.sh`
2. Answer the prompts
3. Done! 🎉




