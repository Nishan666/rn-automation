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
 * Step 7: Copy splash screen files
 */
function registerStep7(plop) {
  plop.setActionType('copySplashFile', function (answers, config, plop) {
    const sourcePath = path.resolve(config.sourcePath);
    const destPath = path.resolve(config.destPath);
    const destDir = path.dirname(destPath);
    const fileName = path.basename(sourcePath);
    const variant = config.variant || '';
    
    try {
      // Ensure destination directory exists
      if (!fs.existsSync(destDir)) {
        fs.mkdirSync(destDir, { recursive: true });
      }
      
      // Copy file if source exists
      if (fs.existsSync(sourcePath)) {
        fs.copyFileSync(sourcePath, destPath);
        const variantTag = variant ? '[' + variant.toUpperCase() + ']' : '';
        return colors.green + '  ✓ ' + colors.reset + colors.cyan + variantTag + colors.reset + ' Copied splash ' + colors.bright + fileName + colors.reset;
      } else {
        return colors.yellow + '  ⚠️  ' + colors.reset + 'Source file not found: ' + sourcePath;
      }
    } catch (error) {
      return colors.yellow + '  ⚠️  ' + colors.reset + 'Could not copy file: ' + error.message;
    }
  });
}

module.exports = registerStep7;

