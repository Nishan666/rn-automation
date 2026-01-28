const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

// Terminal colors for better output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  cyan: '\x1b[36m',
  yellow: '\x1b[33m',
};

/**
 * Step 5: Copy and validate icon files (must be 1024x1024)
 */
function registerStep5(plop) {
  // Helper function to validate image dimensions
  async function validateImageDimensions(imagePath, expectedWidth, expectedHeight) {
    try {
      const metadata = await sharp(imagePath).metadata();
      return metadata.width === expectedWidth && metadata.height === expectedHeight;
    } catch (error) {
      return false;
    }
  }

  plop.setActionType('copyIconFile', async function (answers, config, plop) {
    const sourcePath = path.resolve(config.sourcePath);
    const destPath = path.resolve(config.destPath);
    const destDir = path.dirname(destPath);
    const fileName = path.basename(sourcePath);
    const variant = config.variant || '';
    
    try {
      // Validate image dimensions (must be 1024x1024)
      const isValid = await validateImageDimensions(sourcePath, 1024, 1024);
      if (!isValid) {
        // Store failure in answers so adaptive icon generation can skip
        if (!answers.iconCopyFailures) {
          answers.iconCopyFailures = {};
        }
        answers.iconCopyFailures[variant] = true;
        return colors.yellow + '  ⚠️  ' + colors.reset + 'Icon must be 1024x1024 pixels: ' + fileName + ' (skipped)';
      }
      
      // Ensure destination directory exists
      if (!fs.existsSync(destDir)) {
        fs.mkdirSync(destDir, { recursive: true });
      }
      
      // Copy file if source exists
      if (fs.existsSync(sourcePath)) {
        fs.copyFileSync(sourcePath, destPath);
        // Mark success so adaptive icon can be generated
        if (!answers.iconCopySuccess) {
          answers.iconCopySuccess = {};
        }
        answers.iconCopySuccess[variant] = destPath;
        const variantTag = variant ? '[' + variant.toUpperCase() + ']' : '';
        return colors.green + '  ✓ ' + colors.reset + colors.cyan + variantTag + colors.reset + ' Copied icon ' + colors.bright + fileName + colors.reset + ' (1024x1024)';
      } else {
        if (!answers.iconCopyFailures) {
          answers.iconCopyFailures = {};
        }
        answers.iconCopyFailures[variant] = true;
        return colors.yellow + '  ⚠️  ' + colors.reset + 'Source file not found: ' + sourcePath;
      }
    } catch (error) {
      if (!answers.iconCopyFailures) {
        answers.iconCopyFailures = {};
      }
      answers.iconCopyFailures[variant] = true;
      return colors.yellow + '  ⚠️  ' + colors.reset + 'Could not copy file: ' + error.message;
    }
  });
}

module.exports = registerStep5;

