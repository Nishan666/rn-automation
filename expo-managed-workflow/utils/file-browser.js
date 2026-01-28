const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

/**
 * Helper function to validate image dimensions
 */
async function validateImageDimensions(imagePath, expectedWidth, expectedHeight) {
  try {
    const metadata = await sharp(imagePath).metadata();
    return {
      isValid: metadata.width === expectedWidth && metadata.height === expectedHeight,
      width: metadata.width,
      height: metadata.height
    };
  } catch (error) {
    return { isValid: false, width: 0, height: 0, error: error.message };
  }
}

/**
 * Helper function to browse directories (for selecting folder paths)
 */
async function browseDirectories(inquirer, currentDir) {
  try {
    const items = fs.readdirSync(currentDir, { withFileTypes: true });

    const choices = [];

    // Add parent directory option
    if (currentDir !== path.parse(currentDir).root) {
      choices.push({
        name: '📁 .. (Parent Directory)',
        value: { type: 'parent', path: path.dirname(currentDir) }
      });
    }

    // Add current directory as selectable option
    choices.push({
      name: '✓ Select this directory',
      value: { type: 'select', path: currentDir }
    });

    // Add directories
    items
      .filter(item => item.isDirectory() && !item.name.startsWith('.') && item.name !== 'node_modules')
      .sort((a, b) => a.name.localeCompare(b.name))
      .forEach(item => {
        choices.push({
          name: '📁 ' + item.name + '/',
          value: { type: 'dir', path: path.join(currentDir, item.name) }
        });
      });

    const answer = await inquirer.prompt([{
      type: 'list',
      name: 'selection',
      message: '📁 Browse: ' + currentDir,
      choices: choices,
      pageSize: 15,
      loop: false
    }]);

    const selection = answer.selection;

    // Handle different selection types
    if (selection.type === 'select') {
      return selection.path;
    } else if (selection.type === 'dir') {
      // Navigate into directory
      return await browseDirectories(inquirer, selection.path);
    } else if (selection.type === 'parent') {
      // Go to parent directory
      return await browseDirectories(inquirer, selection.path);
    } else {
      // Unknown type or cancel
      return '';
    }
  } catch (error) {
    console.error('Error reading directory: ' + error.message);
    return '';
  }
}

/**
 * Helper function to browse files in a directory (from expo-automate reference)
 */
async function browseFiles(inquirer, currentDir, fileExtensions, requireDimensions = null) {
  try {
    const items = fs.readdirSync(currentDir, { withFileTypes: true });
    
    const choices = [];
    
    // Add parent directory option
    if (currentDir !== path.parse(currentDir).root) {
      choices.push({
        name: '📁 .. (Parent Directory)',
        value: { type: 'parent', path: path.dirname(currentDir) }
      });
    }
    
    // Add directories
    items
      .filter(item => item.isDirectory() && !item.name.startsWith('.') && item.name !== 'node_modules')
      .sort((a, b) => a.name.localeCompare(b.name))
      .forEach(item => {
        choices.push({
          name: '📁 ' + item.name + '/',
          value: { type: 'dir', path: path.join(currentDir, item.name) }
        });
      });
    
    // Add files matching extensions
    items
      .filter(item => {
        if (!item.isFile()) return false;
        const ext = path.extname(item.name).toLowerCase();
        return fileExtensions.includes(ext);
      })
      .sort((a, b) => a.name.localeCompare(b.name))
      .forEach(item => {
        choices.push({
          name: '🖼️  ' + item.name,
          value: { type: 'file', path: path.join(currentDir, item.name) }
        });
      });
    
    if (choices.filter(c => c.value.type === 'file').length === 0 && choices.length > 0) {
      choices.push({
        name: '⚠️  No PNG files found in this directory',
        value: { type: 'info' },
        disabled: true
      });
    }
    
    const answer = await inquirer.prompt([{
      type: 'list',
      name: 'selection',
      message: '📁 Browse: ' + currentDir,
      choices: choices,
      pageSize: 15,
      loop: false
    }]);
    
    const selection = answer.selection;
    
    // Handle different selection types
    if (selection.type === 'file') {
      // Validate that it's actually a PNG file
      const ext = path.extname(selection.path).toLowerCase();
      if (fileExtensions.includes(ext)) {
        // Validate dimensions if required
        if (requireDimensions) {
          const validation = await validateImageDimensions(selection.path, requireDimensions.width, requireDimensions.height);
          if (!validation.isValid) {
            console.log(`\n⚠️  Image dimensions are ${validation.width}x${validation.height}, but ${requireDimensions.width}x${requireDimensions.height} is required.`);
            console.log('Please select a different file.\n');
            // Recursively browse again until valid file is selected
            return await browseFiles(inquirer, currentDir, fileExtensions, requireDimensions);
          }
        }
        return selection.path;
      } else {
        // Not a valid file, stay in current directory
        return await browseFiles(inquirer, currentDir, fileExtensions, requireDimensions);
      }
    } else if (selection.type === 'dir') {
      // Navigate into directory
      return await browseFiles(inquirer, selection.path, fileExtensions, requireDimensions);
    } else if (selection.type === 'parent') {
      // Go to parent directory
      return await browseFiles(inquirer, selection.path, fileExtensions, requireDimensions);
    } else if (selection.type === 'info') {
      // Info message, stay in current directory
      return await browseFiles(inquirer, currentDir, fileExtensions, requireDimensions);
    } else {
      // Unknown type or cancel
      return '';
    }
  } catch (error) {
    console.error('Error reading directory: ' + error.message);
    return '';
  }
}

/**
 * Helper function to get file path (browse or type) with validation
 */
async function getFilePath(inquirer, message, variant, requireDimensions = null) {
  const methodAnswer = await inquirer.prompt([{
    type: 'list',
    name: 'method',
    message: message + ' for ' + variant.toUpperCase() + ':',
    choices: [
      { name: 'Browse files', value: 'browse' },
      { name: 'Type path manually', value: 'type' },
      { name: 'Skip (add later)', value: 'skip' }
    ]
  }]);

  if (methodAnswer.method === 'skip') {
    return '';
  } else if (methodAnswer.method === 'browse') {
    // Start from current working directory
    const startDir = process.cwd();
    const filePath = await browseFiles(inquirer, startDir, ['.png'], requireDimensions);
    return filePath;
  } else {
    let filePath = '';
    let isValid = false;
    
    while (!isValid) {
      const pathAnswer = await inquirer.prompt([{
        type: 'input',
        name: 'filePath',
        message: 'Enter file path (absolute or relative):',
        default: filePath || '',
        validate: async (input) => {
          if (!input || input.trim() === '') {
            return 'Path cannot be empty (or press Ctrl+C to cancel)';
          }
          if (!fs.existsSync(input)) {
            return 'File does not exist';
          }
          
          // Validate dimensions if required
          if (requireDimensions) {
            const validation = await validateImageDimensions(input, requireDimensions.width, requireDimensions.height);
            if (!validation.isValid) {
              return `Image dimensions are ${validation.width}x${validation.height}, but ${requireDimensions.width}x${requireDimensions.height} is required`;
            }
          }
          
          return true;
        }
      }]);
      
      filePath = pathAnswer.filePath;
      
      // Double-check dimensions after input
      if (requireDimensions && filePath) {
        const validation = await validateImageDimensions(filePath, requireDimensions.width, requireDimensions.height);
        if (validation.isValid) {
          isValid = true;
        } else {
          console.log(`\n⚠️  Image dimensions are ${validation.width}x${validation.height}, but ${requireDimensions.width}x${requireDimensions.height} is required.`);
          console.log('Please enter a different file path.\n');
        }
      } else {
        isValid = true;
      }
    }
    
    return filePath;
  }
}

/**
 * Helper function to get directory path (browse or type)
 */
async function getDirectoryPath(inquirer, message) {
  const methodAnswer = await inquirer.prompt([{
    type: 'list',
    name: 'method',
    message: message,
    choices: [
      { name: 'Browse directories', value: 'browse' },
      { name: 'Type path manually', value: 'type' }
    ]
  }]);

  if (methodAnswer.method === 'browse') {
    // Start from current working directory
    const startDir = process.cwd();
    const dirPath = await browseDirectories(inquirer, startDir);
    return dirPath || './';
  } else {
    const pathAnswer = await inquirer.prompt([{
      type: 'input',
      name: 'dirPath',
      message: 'Enter directory path (absolute or relative):',
      default: './',
      validate: (input) => {
        if (!input || input.trim() === '') {
          return 'Path cannot be empty';
        }
        return true;
      }
    }]);
    return pathAnswer.dirPath || './';
  }
}

module.exports = { browseFiles, getFilePath, browseDirectories, getDirectoryPath };
