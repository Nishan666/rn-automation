# Script Workflow and Verification

## ✅ Complete Setup Flow

### 1. **Initial Project Setup** (`setup.sh`)
   - Creates Expo bare-minimum project
   - Sets up project structure
   - Installs dependencies
   - Configures Android product flavors
   - **Calls `ios_flavor_setup.sh`** to configure iOS

### 2. **iOS Flavor Setup** (`ios_flavor_setup.sh`)
   - Creates build configurations for all 4 environments
   - Creates app icon set placeholders with **correct Contents.json format**:
     - `AppIcon.appiconset` (production)
     - `AppIconDev.appiconset` (develop)
     - `AppIconQA.appiconset` (qa)
     - `AppIconPreprod.appiconset` (preprod)
   - Sets `ASSETCATALOG_COMPILER_APPICON_NAME` for each build configuration
   - Creates Xcode schemes

### 3. **Icon Setup** (Optional during setup, or later)
   - **During setup.sh**: User can choose to set up icons
   - **After setup**: Use `setup_ios_icons.sh` script
   - The `setup_icons()` function:
     - Copies icon files to Android directories (all densities)
     - Copies icon files to iOS appiconset directories
     - Creates/updates Contents.json with correct format

## ✅ What's Fixed

1. **Contents.json Format**: Changed from `"idiom": "universal"` to `"idiom": "ios-marketing"` (correct for iOS 11+)
2. **Icon File Copying**: Verified the `setup_icons()` function correctly copies icons
3. **Build Configuration**: Verified `ASSETCATALOG_COMPILER_APPICON_NAME` is set correctly
4. **Placeholder Creation**: Fixed in `ios_flavor_setup.sh` to use correct format

## ✅ Verification Checklist

### During Project Setup:
- [x] `setup.sh` creates project correctly
- [x] `ios_flavor_setup.sh` creates icon placeholders with correct Contents.json
- [x] Build configurations are created for all environments
- [x] `ASSETCATALOG_COMPILER_APPICON_NAME` is set correctly
- [x] Icon setup function uses correct Contents.json format

### After Icon Setup:
- [ ] Icon files exist in all appiconset directories (`icon-1024.png`)
- [ ] Contents.json files use `"idiom": "ios-marketing"`
- [ ] Clean build folder in Xcode (Cmd+Shift+K)
- [ ] Rebuild app

## 🎯 Usage Scenarios

### Scenario 1: New Project Setup
```bash
./setup.sh
# Follow prompts:
# - Enter project name
# - Choose location
# - Configure iOS? (y)
# - Set up icons? (y) → Select icons for each environment
```

**Result**: Complete project with icons set up for all environments

### Scenario 2: Project Already Created, Need Icons
```bash
cd your-project-directory
../setup_ios_icons.sh
# Follow prompts to select icons for each environment
```

**Result**: Icons added to existing project

### Scenario 3: Icons Set Up, But Not Appearing
1. Open project in Xcode
2. Clean build folder (Cmd+Shift+K)
3. Rebuild app
4. If still not working, delete derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

## 🔧 Technical Details

### Icon File Structure
```
ios/[PROJECT_NAME]/Images.xcassets/
├── AppIcon.appiconset/
│   ├── Contents.json (✅ Fixed format)
│   └── icon-1024.png (needs to be added)
├── AppIconDev.appiconset/
│   ├── Contents.json (✅ Fixed format)
│   └── icon-1024.png (needs to be added)
├── AppIconQA.appiconset/
│   ├── Contents.json (✅ Fixed format)
│   └── icon-1024.png (needs to be added)
└── AppIconPreprod.appiconset/
    ├── Contents.json (✅ Fixed format)
    └── icon-1024.png (needs to be added)
```

### Contents.json Format (Fixed)
```json
{
  "images": [
    {
      "filename": "icon-1024.png",
      "idiom": "ios-marketing",  // ✅ Fixed: was "universal"
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

### Build Configuration Mapping
- **Debug/Release** → `AppIcon`
- **Debug Develop/Release Develop** → `AppIconDev`
- **Debug QA/Release QA** → `AppIconQA`
- **Debug Preprod/Release Preprod** → `AppIconPreprod`

## ✅ Everything Should Work Now!

The scripts are properly integrated and use the correct formats. The main thing users need to do is:
1. Run the setup script
2. Add icon files (either during setup or later)
3. Clean build folder in Xcode
4. Rebuild

All the technical issues have been fixed! 🎉


