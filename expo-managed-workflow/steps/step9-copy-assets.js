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
 * Step 9: Copy assets (icons and splash screens)
 * This step handles the actual copying of icon and splash files
 */
function registerStep9(plop) {
  plop.setActionType('copy-assets', function (answers, config, plop) {
    console.log('\n📦 Step 9: Copying assets...');
    const data = answers;
    const basePath = data.projectPath || './';
    const projectSlug = data.projectSlug || data.projectName
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');
    const projectDir = path.join(basePath, projectSlug);
    
    // This action just logs - actual copying is done by copyIconFile, copySplashFile actions
    if (data.iconPaths) {
      const iconCount = Object.keys(data.iconPaths).filter(v => data.iconPaths[v]).length;
      console.log(`  Icons to copy: ${iconCount}`);
    }
    if (data.splashPaths) {
      const splashCount = Object.keys(data.splashPaths).filter(v => data.splashPaths[v]).length;
      console.log(`  Splash screens to copy: ${splashCount}`);
    }
    
    return 'Assets copying initiated';
  });
}

module.exports = registerStep9;

