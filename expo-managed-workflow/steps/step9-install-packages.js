const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Terminal colors for better output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  cyan: '\x1b[36m',
  yellow: '\x1b[33m',
};

/**
 * Step 9: Install required packages with latest versions
 */
function registerStep9(plop) {
  plop.setActionType('install-packages', function (answers, config, plop) {
    const projectDir = path.resolve(config.projectDir);
    
    if (!fs.existsSync(projectDir)) {
      return colors.yellow + '  ⚠️  ' + colors.reset + 'Project directory not found: ' + projectDir;
    }
    
    const packageJsonPath = path.join(projectDir, 'package.json');
    if (!fs.existsSync(packageJsonPath)) {
      return colors.yellow + '  ⚠️  ' + colors.reset + 'package.json not found';
    }
    
    try {
      // Read current package.json
      const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
      
      // Build scripts object with base scripts
      // Variant is handled via .env file (APP_VARIANT)
      const scripts = {
        "start": "expo start --clear",
        "prebuild": "DOTENV_CONFIG_DEBUG=false expo prebuild --npm",
        "prebuild:clean": "DOTENV_CONFIG_DEBUG=false expo prebuild --clean --npm",
        "web": "expo start --web",
        "lint": "expo lint",
        "build": "npm run prebuild && expo run:android",
        "build:ios": "npm run prebuild && expo run:ios"
      };
      
      packageJson.scripts = scripts;
      
      // Update dependencies (using latest versions)
      packageJson.dependencies = {
        "@react-navigation/drawer": "^7.0.0",
        "@react-navigation/native": "^7.0.0",
        "dotenv": "^16.4.5",
        "expo": "^54.0.0",
        "expo-font": "~14.0.10",
        "expo-linking": "^8.0.11",
        "expo-notifications": "~0.32.15",
        "expo-status-bar": "~3.0.9",
        "react": "^19.1.0",
        "react-native": "^0.81.5",
        "react-native-gesture-handler": "~2.28.0",
        "react-native-reanimated": "~4.1.1",
        "react-native-safe-area-context": "~5.6.0",
        "react-native-screens": "~4.16.0"
      };
      
      // Update devDependencies (using latest versions)
      packageJson.devDependencies = {
        "@types/react": "~19.1.10",
        "eslint-config-expo": "~10.0.0",
        "eslint-config-prettier": "^10.1.8",
        "eslint-plugin-prettier": "^5.5.4",
        "eslint-plugin-react-compiler": "^19.1.0-rc.2",
        "prettier": "^3.7.4",
        "typescript": "^5.9.2"
      };
      
      // Write updated package.json
      fs.writeFileSync(packageJsonPath, JSON.stringify(packageJson, null, 2) + '\n');
      
      // Build install command with latest versions
      const allDeps = { ...packageJson.dependencies, ...packageJson.devDependencies };
      const packages = Object.keys(allDeps).map(pkg => `${pkg}@latest`).join(' ');
      
      // Install packages with latest versions (suppress output for cleaner UI)
      execSync(
        `npm install ${packages}`,
        {
          stdio: 'pipe',
          cwd: projectDir,
          encoding: 'utf8',
          shell: '/bin/bash'
        }
      );
      
      // Run expo install --fix to ensure all Expo packages are compatible
      // Catch errors and continue since packages are already installed
      try {
        execSync(
          `npx expo install --fix`,
          {
            stdio: 'pipe',
            cwd: projectDir,
            encoding: 'utf8',
            shell: '/bin/bash'
          }
        );
      } catch (fixError) {
        // expo install --fix may fail due to version conflicts or internal errors
        // but pa      console.error('\n❌ Failed to install packages:', error.message);
        console.error('there is an error with the packages');
        // The user can manually run 'npx expo install --fix' later if needed
      }
      
      return colors.green + '  ✓ ' + colors.reset + 'Packages installed successfully';
    } catch (error) {
      console.error('\n❌ Failed to install packages:', error.message);
      return colors.yellow + '  ⚠️  ' + colors.reset + 'Could not install packages: ' + error.message;
    }
  });
}

module.exports = registerStep9;

