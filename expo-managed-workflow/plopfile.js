const fs = require('fs');
const path = require('path');
const UIManager = require('./utils/ui-manager');
const registerStep1 = require('./steps/step1-create-expo-project');
const registerStep2 = require('./steps/step2-get-project-name');
const registerStep3 = require('./steps/step3-get-build-variants');
const { registerStep4, generateIconPrompts } = require('./steps/step4-get-icon-paths');
const registerStep5 = require('./steps/step5-copy-icons');
const registerStep6 = require('./steps/step6-generate-adaptive-icons');
const registerStep7 = require('./steps/step7-copy-splash');
const registerStep8 = require('./steps/step8-generate-app-config');
const registerStep9 = require('./steps/step9-install-packages');
const registerStep10 = require('./steps/step10-cleanup-default-assets');
const registerStep11 = require('./steps/step11-setup-src-folder');
const { browseFiles, getFilePath, getDirectoryPath } = require('./utils/file-browser');

module.exports = function (plop) {
  
  // Terminal colors for better output
  const colors = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
    green: '\x1b[32m',
    cyan: '\x1b[36m',
    yellow: '\x1b[33m',
  };
  
  // Store original console methods
  const originalConsoleLog = console.log;
  const originalConsoleInfo = console.info;
  
  // Intercept console methods to filter Plop's default output
  console.log = function(...args) {
    const message = args.join(' ');
    // Allow our UI output (starts with spaces and "Step" or contains header)
    if (message.match(/^\s+[○✓✗]\s+Step/) || 
        message.includes('╔') || message.includes('║') || message.includes('╚') ||
        message.match(/All steps completed/)) {
      return originalConsoleLog.apply(console, args);
    }
    // Suppress Plop's default action output
    if (message.match(/[✔✖]/) || message.match(/[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏]/)) {
      return; // Suppress
    }
    return originalConsoleLog.apply(console, args);
  };
  
  console.info = function(...args) {
    const message = args.join(' ');
    // Suppress Plop's info messages
    if (message.match(/[✔✖]/) || message.match(/[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏]/)) {
      return; // Suppress
    }
    return originalConsoleInfo.apply(console, args);
  };

  // Custom action type for creating directories safely
  plop.setActionType('ensureDir', function (answers, config, plop) {
    const dirPath = path.resolve(config.path);
    const gitkeepPath = path.join(dirPath, '.gitkeep');
    const content = config.content || '';
    
    try {
      // Create directory if it doesn't exist
      if (!fs.existsSync(dirPath)) {
        fs.mkdirSync(dirPath, { recursive: true });
      }
      
      // Create .gitkeep only if it doesn't exist
      if (!fs.existsSync(gitkeepPath) && content !== null) {
        fs.writeFileSync(gitkeepPath, content);
        return ''; // Suppress output - UI will show status
      }
      
      return ''; // Suppress output - UI will show status
    } catch (error) {
      return ''; // Suppress output - UI will show status
    }
  });

  // Custom action type for copying files (generic)
  plop.setActionType('copyFile', function (answers, config, plop) {
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
        return ''; // Suppress output - UI will show status
      } else {
        return ''; // Suppress output - UI will show status
      }
    } catch (error) {
      return ''; // Suppress output - UI will show status
    }
  });

  // Custom action to show a UI step (for built-in actions)
  plop.setActionType('ui-step-start', function (answers, config, plop) {
    const ui = global._plopUI;
    const stepName = config.stepName;
    
    if (ui && stepName) {
      ui.showStep(stepName, 'running');
    }
    
    return '';
  });

  // Custom action to finish UI and show completion message
  plop.setActionType('ui-finish', function (answers, config, plop) {
    const ui = global._plopUI;
    if (ui) {
      setTimeout(() => {
        const basePath = answers.projectPath || './';
        const projectSlug = answers.projectSlug || answers.projectName
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, '-')
          .replace(/^-+|-+$/g, '');
        const projectPath = path.join(basePath, projectSlug);
        
        const summary = {
          projectName: answers.projectName,
          projectPath: projectPath,
          projectSlug: projectSlug,
          buildVariants: answers.buildVariants || [],
          iconCount: answers.iconPaths ? Object.keys(answers.iconPaths).length : 0
        };
        
        ui.finish(summary);
      }, 500);
    }
    return '';
  });

  // Custom action to show a UI step (for built-in actions)
  plop.setActionType('ui-step-start', function (answers, config, plop) {
    const ui = global._plopUI;
    const stepName = config.stepName;
    
    if (ui && stepName) {
      ui.showStep(stepName, 'running');
    }
    
    return '';
  });

  // Custom action to mark a UI step as complete (for built-in actions)
  plop.setActionType('ui-step-complete', function (answers, config, plop) {
    const ui = global._plopUI;
    const stepName = config.stepName;
    
    if (ui && stepName) {
      ui.completeStep(stepName);
    }
    
    return '';
  });

  // Custom action wrapper for UI management
  plop.setActionType('ui-wrapped-action', function (answers, config, plop) {
    const ui = global._plopUI;
    const stepName = config.stepName;
    const actionType = config.actionType;
    const actionConfig = config.actionConfig || {};
    
    if (ui && stepName) {
      ui.showStep(stepName, 'running');
    }
    
    try {
      // Get the actual action handler
      const actionHandler = plop.getActionType(actionType);
      if (!actionHandler) {
        throw new Error(`Unknown action type: ${actionType}`);
      }
      
      // Merge actionConfig into config for the actual action
      const mergedConfig = { ...config, ...actionConfig };
      delete mergedConfig.stepName;
      delete mergedConfig.actionType;
      delete mergedConfig.actionConfig;
      
      // Call the actual action handler
      const result = actionHandler(answers, mergedConfig, plop);
      
      // Handle async results (promises)
      if (result && typeof result.then === 'function') {
        return result.then((res) => {
          if (ui && stepName) {
            ui.completeStep(stepName);
          }
          return ''; // Suppress return value
        }).catch((error) => {
          if (ui && stepName) {
            ui.failStep(stepName, error.message);
          }
          throw error;
        });
      } else {
        // Synchronous result
        if (ui && stepName) {
          ui.completeStep(stepName);
        }
        return ''; // Suppress return value
      }
    } catch (error) {
      if (ui && stepName) {
        ui.failStep(stepName, error.message);
      }
      throw error;
    }
  });

  // Register all steps
  registerStep1(plop);
  registerStep2(plop);
  registerStep3(plop);
  registerStep4(plop);
  registerStep5(plop);
  registerStep6(plop);
  registerStep7(plop);
  registerStep8(plop);
  registerStep9(plop);
  registerStep10(plop);
  registerStep11(plop);

      // Generator configuration
      plop.setGenerator('expo-app', {
        description: 'Create a new Expo app with React Navigation and TypeScript',
    prompts: async (inquirer) => {
      const prompts = [];
      
      // Step 1: Project path (using file browser)
      const projectPath = await getDirectoryPath(inquirer, 'Where should the project be created?');
      const initialAnswers = {
        projectPath: projectPath.replace(/\/+$/, '') || '.'
      };
      
      // Continue with other prompts
      const additionalAnswers = await inquirer.prompt([
        // Step 2: Project name
        {
          type: 'input',
          name: 'projectName',
          message: 'What is your project name?',
          default: 'Test Expo App',
        },
        // Step 2.5: Bundle ID
        {
          type: 'input',
          name: 'bundleId',
          message: 'What is your bundle identifier? (e.g., com.company.app)',
          default: (answers) => {
            // Generate default from project name, but user can override
            const slug = answers.projectName
              .toLowerCase()
              .replace(/[^a-z0-9]+/g, '')
              .replace(/^[0-9]/, '');
            return `com.${slug}.app`;
          },
          validate: (value) => {
            if (!value || value.trim() === '') {
              return 'Bundle identifier is required';
            }
            // Bundle IDs should be in reverse domain notation: com.company.app
            if (!/^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$/.test(value)) {
              return 'Bundle identifier must be in reverse domain notation (e.g., com.company.app). No hyphens allowed.';
            }
            // Check for hyphens
            if (value.includes('-')) {
              return 'Bundle identifier cannot contain hyphens. Use dots (.) instead.';
            }
            
            // Reserved Java keywords that cannot be used in Android package names
            const reservedKeywords = new Set([
              'abstract', 'assert', 'boolean', 'break', 'byte', 'case', 'catch', 'char',
              'class', 'const', 'continue', 'default', 'do', 'double', 'else', 'enum',
              'extends', 'final', 'finally', 'float', 'for', 'goto', 'if', 'implements',
              'import', 'instanceof', 'int', 'interface', 'long', 'native', 'new', 'package',
              'private', 'protected', 'public', 'return', 'short', 'static', 'strictfp',
              'super', 'switch', 'synchronized', 'this', 'throw', 'throws', 'transient',
              'try', 'void', 'volatile', 'while'
            ]);
            
            // Check each segment for reserved keywords
            const segments = value.split('.');
            for (const segment of segments) {
              if (reservedKeywords.has(segment.toLowerCase())) {
                return `Bundle identifier cannot contain reserved Java keywords. "${segment}" is a reserved keyword. Please use a different name.`;
              }
            }
            
            return true;
          },
        },
        // Step 3: Build variants
        {
          type: 'checkbox',
          name: 'buildVariants',
          message: 'Which build variants do you need?',
          choices: [
            { name: 'develop', value: 'develop', checked: true },
            { name: 'qa', value: 'qa', checked: false },
            { name: 'preprod', value: 'preprod', checked: false },
            { name: 'prod', value: 'prod', checked: true },
          ],
          validate: (answer) => {
            if (answer.length === 0) {
              return 'You must select at least one build variant';
            }
            return true;
          },
        },
      ]);

      // Merge additional answers into initialAnswers
      Object.assign(initialAnswers, additionalAnswers);

      // Step 4: Icon paths (dynamically generated based on selected variants)
      // Validate icons must be 1024x1024 before accepting
      // Same icon will be used for both app icon and splash screen
      initialAnswers.iconPaths = {};
      for (const variant of initialAnswers.buildVariants) {
        const iconPath = await getFilePath(
          inquirer, 
          'Select icon image (1024x1024 PNG) - will be used for app icon and splash screen', 
          variant,
          { width: 1024, height: 1024 } // Require 1024x1024 dimensions
        );
        initialAnswers.iconPaths[variant] = iconPath;
      }

      // Use the same icon paths for splash screens
      initialAnswers.splashPaths = { ...initialAnswers.iconPaths };

      // Initialize UI
      const ui = new UIManager();
      global._plopUI = ui;
      
      // Show header
      const originalLog = ui.originalLog || console.log;
      originalLog('\n\x1b[1m\x1b[36m╔═══════════════════════════════════════════════════════════╗\x1b[0m');
      originalLog('\x1b[1m\x1b[36m║\x1b[0m  \x1b[1m\x1b[37mExpo Project Generator\x1b[0m                              \x1b[1m\x1b[36m║\x1b[0m');
      originalLog('\x1b[1m\x1b[36m╚═══════════════════════════════════════════════════════════╝\x1b[0m\n');
      
      // Don't show Project Configuration as a step - it's just prompts

      return initialAnswers;
    },
    actions: function (data) {
      const actions = [];
      const basePath = data.projectPath || './';
      const projectSlug = data.projectSlug || data.projectName
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-+|-+$/g, '');
      const projectDir = path.join(basePath, projectSlug);
      
      // Step actions (these are just logging, already done in prompts)
      // No need to wrap them - they don't need UI updates
      actions.push({
        type: 'create-expo-project',
        _stepName: 'Creating Expo Project'
      });
      
      // Clean up default asset files created by blank template
      actions.push({
        type: 'cleanup-default-assets',
        projectDir: projectDir,
        _stepName: 'Cleaning Default Files'
      });
      
      // Setup src folder structure
      actions.push({
        type: 'setup-src-folder',
        projectDir: projectDir,
        _stepName: 'Setting Up Project Structure'
      });
      
      // Start "Setting Up Project Structure" step for file generation
      actions.push({
        type: 'ui-step-start',
        stepName: 'Setting Up Project Structure'
      });
      
      // Generate all src files from templates
      const srcFiles = [
        // App.tsx
        { path: 'src/App.tsx', template: 'src/App.tsx.hbs' },
        // Navigation
        { path: 'src/navigation/AppNavigator.tsx', template: 'src/navigation/AppNavigator.tsx.hbs' },
        { path: 'src/navigation/AuthNavigator.tsx', template: 'src/navigation/AuthNavigator.tsx.hbs' },
        { path: 'src/navigation/TabNavigator.tsx', template: 'src/navigation/TabNavigator.tsx.hbs' },
        // Screens
        { path: 'src/screens/HomeScreen.tsx', template: 'src/screens/HomeScreen.tsx.hbs' },
        // Components
        { path: 'src/components/Button.tsx', template: 'src/components/Button.tsx.hbs' },
        { path: 'src/components/Input.tsx', template: 'src/components/Input.tsx.hbs' },
        { path: 'src/components/Header.tsx', template: 'src/components/Header.tsx.hbs' },
        // Features - User
        { path: 'src/features/user/user.service.ts', template: 'src/features/user/user.service.ts.hbs' },
        { path: 'src/features/user/user.slice.ts', template: 'src/features/user/user.slice.ts.hbs' },
        { path: 'src/features/user/user.types.ts', template: 'src/features/user/user.types.ts.hbs' },
        // Services
        { path: 'src/services/api.ts', template: 'src/services/api.ts.hbs' },
        // Store
        { path: 'src/store/index.ts', template: 'src/store/index.ts.hbs' },
        { path: 'src/store/rootReducer.ts', template: 'src/store/rootReducer.ts.hbs' },
        // Hooks
        { path: 'src/hooks/useAuth.ts', template: 'src/hooks/useAuth.ts.hbs' },
        { path: 'src/hooks/useTheme.ts', template: 'src/hooks/useTheme.ts.hbs' },
        // Constants
        { path: 'src/constants/colors.ts', template: 'src/constants/colors.ts.hbs' },
        { path: 'src/constants/fonts.ts', template: 'src/constants/fonts.ts.hbs' },
        { path: 'src/constants/strings.ts', template: 'src/constants/strings.ts.hbs' },
        // Types
        { path: 'src/types/index.ts', template: 'src/types/index.ts.hbs' },
        // Theme
        { path: 'src/theme/index.ts', template: 'src/theme/index.ts.hbs' },
      ];
      
      srcFiles.forEach(file => {
        actions.push({
          type: 'add',
          path: projectDir + '/' + file.path,
          templateFile: 'templates/' + file.template,
          data: {
            projectName: data.projectName,
            projectSlug: projectSlug,
            bundleId: data.bundleId,
          },
        });
      });
      
      // Mark "Setting Up Project Structure" as complete after all src files are added
      actions.push({
        type: 'ui-step-complete',
        stepName: 'Setting Up Project Structure'
      });
      
      // Start "Generating App Config" step
      actions.push({
        type: 'ui-step-start',
        stepName: 'Generating App Config'
      });
      
          // Generate app.config.ts after project is created
          actions.push({
            type: 'add',
            path: projectDir + '/app.config.ts',
            templateFile: 'templates/app.config.ts.hbs',
            data: {
              projectName: data.projectName,
              projectSlug: projectSlug,
              bundleId: data.bundleId,
            },
            force: true
          });
          
          // Generate eslint.config.js
          actions.push({
            type: 'add',
            path: projectDir + '/eslint.config.js',
            templateFile: 'templates/eslint.config.js.hbs',
            force: true
          });
          
          // Generate .env file with default variant
          actions.push({
            type: 'add',
            path: projectDir + '/.env',
            template: 'EXPO_PUBLIC_APP_VARIANT=develop\n',
            force: true
          });
      
      // Mark "Generating App Config" as complete
      actions.push({
        type: 'ui-step-complete',
        stepName: 'Generating App Config'
      });
      
      // Create src/assets/icons directory if icons were provided
      if (data.iconPaths) {
        actions.push({
          type: 'ensureDir',
          path: projectDir + '/src/assets/icons',
          content: ''
        });
        
        // Copy and validate icon files (must be 1024x1024)
        Object.keys(data.iconPaths).forEach(variant => {
          const iconPath = data.iconPaths[variant];
          if (iconPath && iconPath.trim() !== '') {
            const iconSourcePath = path.resolve(iconPath);
            const iconDestPath = path.join(projectDir, 'src', 'assets', 'icons', `icon-${variant}.png`);
            actions.push({
              type: 'copyIconFile',
              sourcePath: iconSourcePath,
              destPath: iconDestPath,
              variant: variant,
              _stepName: 'Copying Icons'
            });
            
            // Generate adaptive icon from the validated icon
            const adaptiveIconDestPath = path.join(projectDir, 'src', 'assets', 'icons', `adaptive-icon-${variant}.png`);
            actions.push({
              type: 'generateAdaptiveIcon',
              sourceIconPath: iconDestPath,
              destPath: adaptiveIconDestPath,
              variant: variant,
              _stepName: 'Generating Adaptive Icons'
            });
          }
        });
      }
      
      // Splash screens will use icons directly from assets/icons folder
      // No need to copy or create separate splash directory
      
      // Install required packages with latest versions (at the end)
      actions.push({
        type: 'install-packages',
        projectDir: projectDir,
        _stepName: 'Installing Packages'
      });
      
      // UI is already initialized in prompts function
      // Just get reference to existing UI
      const ui = global._plopUI;
      
      // Wrap actions to add UI management
      // Only wrap custom actions, not built-in Plop actions (add, modify, etc.)
      const builtInActions = ['add', 'modify', 'append', 'prepend'];
      const wrappedActions = actions.map((action) => {
        const stepName = action._stepName;
        
        // Don't wrap built-in actions - Plop handles them internally
        if (builtInActions.includes(action.type)) {
          return action;
        }
        
        // Only wrap if stepName is provided
        if (!stepName) return action;
        
        // Wrap custom actions with ui-wrapped-action
        return {
          type: 'ui-wrapped-action',
          stepName: stepName,
          actionType: action.type,
          actionConfig: Object.keys(action).reduce((acc, key) => {
            if (key !== 'type' && key !== '_stepName') {
              acc[key] = action[key];
            }
            return acc;
          }, {})
        };
      });
      
      // Add final cleanup action
      wrappedActions.push({
        type: 'ui-finish'
      });
      
      return wrappedActions;
    },
  });
};
