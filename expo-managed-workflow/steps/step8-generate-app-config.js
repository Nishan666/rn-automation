/**
 * Step 8: Generate app.config.ts file
 * This step is handled in the actions array in plopfile.js
 */
function registerStep8(plop) {
  plop.setActionType('generate-app-config', function (answers, config, plop) {
    console.log('\n📄 Step 8: Generating app.config.ts');
    return 'app.config.ts generated successfully';
  });
}

module.exports = registerStep8;

