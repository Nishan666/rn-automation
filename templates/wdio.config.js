exports.config = {
runner: 'local',
   port: 4723,
   path: '/wd/hub',
   specs: ['./features/**/*.feature'], // path of feature files
   exclude: [],
   maxInstances: 1,
   capabilities: [{
       platformName: 'Android',
       'appium:deviceName': 'Pixel_6_Pro_API_35', // emulator name
       'appium:automationName': 'UiAutomator2', // installed UI Automator
       'appium:app': 'android/app/build/outputs/apk/release/app-release.apk', // Relative path of the application
       'appium:appWaitActivity': 'com.halspan.app.develop.MainActivity', // First screen of application
       'appium:androidInstallTimeout': 60000,
       'appium:newCommandTimeout': 2000,
       'appium:autoGrantPermissions': true, // Automatically grants permissions
       'appium:autoDismissAlerts': true, // Automatically dismisses any alert dialogs
       'appium:skipUnlock': true, // Skip unlocking device screen
   }],
   before: async function () {
       // Add a 10-second delay after the app launches
       console.log('Waiting for 10 seconds to ensure the app is ready...');
       await browser.pause(10000);
   },
   logLevel: 'debug',
   framework: 'cucumber',
   cucumberOpts: {
       require: ['./features/step_definations/**.js'], //path of step definitions
       ignoreUndefinedDefinitions: false,
       backtrace: false,
       requireModule: [],
       dryRun: false,
       strict: false,
       timeout: 60000,
   },
 
  // reporters: ['spec', ['allure', { outputDir: 'reports/allure-results', disableWebdriverStepsReporting: true }]],   services: ['appium'],
   appium: {
       command: 'appium',
       args: {
           logLevel: 'error',
       },
   },
};
