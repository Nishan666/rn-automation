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
 * Step 10: Clean up default asset files created by blank template
 */
function registerStep10(plop) {
  plop.setActionType('cleanup-default-assets', function (answers, config, plop) {
    const projectDir = path.resolve(config.projectDir);
    const assetsDir = path.join(projectDir, 'assets');
    
    const filesToRemove = [];
    
    // Remove default asset files
    if (fs.existsSync(assetsDir)) {
      filesToRemove.push(
        path.join(assetsDir, 'adaptive-icon.png'),
        path.join(assetsDir, 'favicon.png'),
        path.join(assetsDir, 'icon.png'),
        path.join(assetsDir, 'splash-icon.png')
      );
    }
    
    // Remove app.json (we use app.config.ts instead)
    filesToRemove.push(path.join(projectDir, 'app.json'));
    
    // Remove root App.tsx (we use src/App.tsx instead)
    filesToRemove.push(path.join(projectDir, 'App.tsx'));
    
    let removedCount = 0;
    let skippedCount = 0;
    
    filesToRemove.forEach(filePath => {
      try {
        if (fs.existsSync(filePath)) {
          fs.unlinkSync(filePath);
          removedCount++;
        } else {
          skippedCount++;
        }
      } catch (error) {
        // File might not exist or already removed
        skippedCount++;
      }
    });
    
    // Remove root assets folder if it's empty (since we use src/assets instead)
    try {
      if (fs.existsSync(assetsDir)) {
        const remainingFiles = fs.readdirSync(assetsDir);
        if (remainingFiles.length === 0) {
          fs.rmdirSync(assetsDir);
          removedCount++;
        }
      }
    } catch (error) {
      // Folder might not be empty or already removed
    }
    
    if (removedCount > 0) {
      return colors.green + '  ✓ ' + colors.reset + `Removed ${removedCount} default file(s) and empty assets folder`;
    } else {
      return colors.yellow + '  ⊘ ' + colors.reset + 'No default files found to remove';
    }
  });
}

module.exports = registerStep10;

