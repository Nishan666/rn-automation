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
 * Step 6: Generate adaptive icons from validated icons
 */
function registerStep6(plop) {
  plop.setActionType('generateAdaptiveIcon', async function (answers, config, plop) {
    const sourceIconPath = path.resolve(config.sourceIconPath);
    const destPath = path.resolve(config.destPath);
    const destDir = path.dirname(destPath);
    const variant = config.variant || '';
    
    try {
      // Skip if icon copy failed for this variant (check answers first)
      if (answers.iconCopyFailures && answers.iconCopyFailures[variant]) {
        return colors.yellow + '  ⊘ ' + colors.reset + 'Skipped adaptive icon generation (icon copy failed for ' + variant + ')';
      }
      
      // Ensure destination directory exists
      if (!fs.existsSync(destDir)) {
        fs.mkdirSync(destDir, { recursive: true });
      }
      
      // Check if source icon file exists (if copy failed, it won't exist)
      if (!fs.existsSync(sourceIconPath)) {
        // Mark as failure for future reference
        if (!answers.iconCopyFailures) {
          answers.iconCopyFailures = {};
        }
        answers.iconCopyFailures[variant] = true;
        return colors.yellow + '  ⊘ ' + colors.reset + 'Skipped adaptive icon (source icon not found - copy may have failed)';
      }
      
      // Generate adaptive icon: 1024x1024 with safe area (centered content)
      // Android adaptive icons need a safe area - we'll create a 1024x1024 icon
      // with the original icon centered and padded with transparent background
      await sharp(sourceIconPath)
        .resize(768, 768, {
          fit: 'contain',
          background: { r: 0, g: 0, b: 0, alpha: 0 }
        })
        .extend({
          top: 128,
          bottom: 128,
          left: 128,
          right: 128,
          background: { r: 0, g: 0, b: 0, alpha: 0 }
        })
        .resize(1024, 1024)
        .png({ 
          quality: 100,
          compressionLevel: 9,
          adaptiveFiltering: true,
          force: true
        })
        .toFile(destPath);
      
      const variantTag = variant ? '[' + variant.toUpperCase() + ']' : '';
      return colors.green + '  ✓ ' + colors.reset + colors.cyan + variantTag + colors.reset + ' Generated adaptive icon';
    } catch (error) {
      return colors.yellow + '  ⚠️  ' + colors.reset + 'Could not generate adaptive icon: ' + error.message;
    }
  });
}

module.exports = registerStep6;

