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
 * Step 11: Setup complete src folder structure using templates
 */
function registerStep11(plop) {
  plop.setActionType('setup-src-folder', function (answers, config, plop) {
    const projectDir = path.resolve(config.projectDir);
    const srcDir = path.join(projectDir, 'src');
    const indexPath = path.join(projectDir, 'index.ts');
    
    try {
      // Create src directory structure
      const folders = [
        'src/navigation',
        'src/screens',
        'src/components',
        'src/features/user',
        'src/services',
        'src/store',
        'src/hooks',
        'src/constants',
        'src/assets/images',
        'src/assets/fonts',
        'src/types',
        'src/theme'
      ];
      
      folders.forEach(folder => {
        const folderPath = path.join(projectDir, folder);
        if (!fs.existsSync(folderPath)) {
          fs.mkdirSync(folderPath, { recursive: true });
        }
      });
      
      // Update index.ts to import from src
      const newIndexContent = `import { registerRootComponent } from 'expo';

// Import the main app component from src
import App from './src/App';

// Register the main component
registerRootComponent(App);
`;
      fs.writeFileSync(indexPath, newIndexContent);
      
      return colors.green + '  ✓ ' + colors.reset + 'Created src folder structure';
    } catch (error) {
      return colors.yellow + '  ⚠️  ' + colors.reset + 'Could not setup src folder: ' + error.message;
    }
  });
}

module.exports = registerStep11;
