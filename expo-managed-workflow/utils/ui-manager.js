class UIManager {
  constructor() {
    this.originalLog = console.log;
    this.originalError = console.error;
    this.stepCounter = 0;
    this.completedSteps = new Set();
    this.stepNumbers = new Map(); // Map step names to their step numbers
  }

  showStep(stepName, status = 'running') {
    // Don't show if already completed (unless it's an error)
    if (status === 'success' && this.completedSteps.has(stepName)) {
      return;
    }
    
    // Don't show running status if already completed
    if (status === 'running' && this.completedSteps.has(stepName)) {
      return;
    }
    
    const originalLog = this.originalLog || console.log;
    
    // Assign step number on first run
    if (!this.stepNumbers.has(stepName)) {
      this.stepCounter++;
      this.stepNumbers.set(stepName, this.stepCounter);
    }
    
    const stepNum = this.stepNumbers.get(stepName);
    
    if (status === 'running') {
      const icon = '○';
      const color = '\x1b[36m';
      const reset = '\x1b[0m';
      originalLog(`  ${color}${icon}${reset} Step ${stepNum}: ${stepName}`);
    } else if (status === 'success') {
      const icon = '✓';
      const color = '\x1b[32m';
      const reset = '\x1b[0m';
      originalLog(`  ${color}${icon}${reset} Step ${stepNum}: ${stepName}`);
      this.completedSteps.add(stepName);
    } else if (status === 'error') {
      const icon = '✗';
      const color = '\x1b[31m';
      const reset = '\x1b[0m';
      originalLog(`  ${color}${icon}${reset} Step ${stepNum}: ${stepName}`);
    }
  }

  completeStep(stepName) {
    this.showStep(stepName, 'success');
  }

  failStep(stepName, errorMessage) {
    const originalLog = this.originalLog || console.log;
    this.showStep(stepName, 'error');
    if (errorMessage) {
      originalLog(`    \x1b[31mFAIL: ${errorMessage}\x1b[0m`);
    }
  }

  finish(summary = {}) {
    const originalLog = this.originalLog || console.log;
    originalLog('\n\x1b[1m\x1b[32m✓ All steps completed!\x1b[0m\n');
    
    // Show summary if provided
    if (Object.keys(summary).length > 0) {
      originalLog('\x1b[1m\x1b[36m╔═══════════════════════════════════════════════════════════╗\x1b[0m');
      originalLog('\x1b[1m\x1b[36m║\x1b[0m  \x1b[1m\x1b[37mProject Summary\x1b[0m                                    \x1b[1m\x1b[36m║\x1b[0m');
      originalLog('\x1b[1m\x1b[36m╚═══════════════════════════════════════════════════════════╝\x1b[0m\n');
      
      if (summary.projectName) {
        originalLog(`  \x1b[1mProject Name:\x1b[0m ${summary.projectName}`);
      }
      if (summary.projectPath) {
        originalLog(`  \x1b[1mProject Path:\x1b[0m ${summary.projectPath}`);
      }
      if (summary.projectSlug) {
        originalLog(`  \x1b[1mProject Slug:\x1b[0m ${summary.projectSlug}`);
      }
      if (summary.buildVariants && summary.buildVariants.length > 0) {
        originalLog(`  \x1b[1mBuild Variants:\x1b[0m ${summary.buildVariants.join(', ')}`);
      }
      if (summary.iconCount) {
        originalLog(`  \x1b[1mIcons Configured:\x1b[0m ${summary.iconCount}`);
      }
      
      originalLog('\n  \x1b[1m\x1b[32mNext Steps:\x1b[0m');
      originalLog('  1. Navigate to your project: \x1b[36mcd ' + (summary.projectPath || '') + '\x1b[0m');
      originalLog('  2. Set APP_VARIANT in .env file (e.g., APP_VARIANT=develop)');
      originalLog('  3. Run prebuild: \x1b[36mnpm run prebuild\x1b[0m');
      originalLog('  4. Start the development server: \x1b[36mnpm start\x1b[0m');
      originalLog('  5. Build the app: \x1b[36mnpm run build\x1b[0m (Android) or \x1b[36mnpm run build:ios\x1b[0m (iOS)');
      originalLog('');
    }
  }

  close() {
    // Restore stdout if it was intercepted
    if (global._originalStdoutWrite) {
      process.stdout.write = global._originalStdoutWrite;
    }
  }
}

module.exports = UIManager;
