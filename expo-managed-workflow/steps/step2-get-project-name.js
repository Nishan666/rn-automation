/**
 * Step 2: Get project name
 * This step just validates/stores the project name
 */
function registerStep2(plop) {
  plop.setActionType('get-project-name', function (answers, config, plop) {
    const projectName = answers.projectName;
    const projectSlug = projectName
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');
    
        // Quiet mode - no console logs
    
    // Store slug in answers for later steps
    answers.projectSlug = projectSlug;
    
    return `Project name "${projectName}" configured (slug: ${projectSlug})`;
  });
}

module.exports = registerStep2;

