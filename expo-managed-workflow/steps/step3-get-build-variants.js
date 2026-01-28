/**
 * Step 3: Get build variants
 * This step validates/stores the selected build variants
 */
function registerStep3(plop) {
  plop.setActionType('get-build-variants', function (answers, config, plop) {
    const buildVariants = answers.buildVariants || [];
    
        // Quiet mode - no console logs
    
    if (buildVariants.length === 0) {
      throw new Error('At least one build variant must be selected');
    }
    
    return `Build variants configured: ${buildVariants.join(', ')}`;
  });
}

module.exports = registerStep3;

