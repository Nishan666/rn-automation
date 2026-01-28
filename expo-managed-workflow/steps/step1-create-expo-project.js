const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

/**
 * Step 1: Create blank Expo project with TypeScript
 * This step creates the Expo project using create-expo-app
 */
function registerStep1(plop) {
  plop.setActionType('create-expo-project', function (answers, config, plop) {
    const basePath = path.resolve(answers.projectPath || './');
    // Use projectSlug from step2 if available, otherwise generate it
    const projectSlug = answers.projectSlug || answers.projectName
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');
    const projectDir = path.join(basePath, projectSlug);
    
    // Ensure base path exists
    if (!fs.existsSync(basePath)) {
      fs.mkdirSync(basePath, { recursive: true });
    }
    
    try {
      // Create blank Expo project with TypeScript template
      execSync(
        `npx create-expo-app@latest ${projectSlug} --template blank-typescript --yes --no-install`,
        { 
          stdio: 'pipe', // Suppress output for cleaner UI
          cwd: basePath,
          encoding: 'utf8',
          shell: '/bin/bash'
        }
      );
      
      return `Expo project "${projectSlug}" created successfully`;
    } catch (error) {
      console.error('\n❌ Step 1 failed:', error.message);
      throw new Error(`Failed to create Expo project - ${error.message}`);
    }
  });
}

module.exports = registerStep1;

