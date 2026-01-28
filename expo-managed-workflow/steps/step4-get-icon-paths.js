/**
 * Step 4: Get icon paths for each selected build variant
 * This step asks for icon file paths for each variant
 */
function registerStep4(plop) {
  // Add prompts for icon paths dynamically based on selected variants
  plop.setActionType('get-icon-paths', function (answers, config, plop) {
        // Quiet mode - no console logs
    
    return `Icon paths configured for variants: ${answers.buildVariants?.join(', ') || 'none'}`;
  });
}

// Helper function to generate icon path prompts based on selected variants
function generateIconPrompts(answers) {
  const buildVariants = answers.buildVariants || [];
  const prompts = [];
  
  buildVariants.forEach(variant => {
    prompts.push({
      type: 'input',
      name: `${variant}IconPath`,
      message: `Path to ${variant} icon file (1024x1024 PNG):`,
      when: () => true, // Always ask if variant is selected
      validate: (value) => {
        if (!value || value.trim() === '') {
          return `${variant} icon path is required`;
        }
        return true;
      },
    });
  });
  
  return prompts;
}

module.exports = { registerStep4, generateIconPrompts };

