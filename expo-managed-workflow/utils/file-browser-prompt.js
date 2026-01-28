const fs = require('fs');
const path = require('path');
const BaseModule = require('inquirer/lib/prompts/base');
const ChoicesModule = require('inquirer/lib/objects/choices');
const SeparatorModule = require('inquirer/lib/objects/separator');
const observeModule = require('inquirer/lib/utils/events');
const { takeUntil, take } = require('rxjs/operators');

// Handle ES module default exports in CommonJS
const Base = BaseModule.default || BaseModule;
const Choices = ChoicesModule.default || ChoicesModule;
const Separator = SeparatorModule.default || SeparatorModule;
const observe = observeModule.default || observeModule;

/**
 * Custom file browser prompt that lets users navigate directories
 * and select PNG files visually - works like a file explorer
 * Based on the browseFiles implementation from expo-automate
 */
class FileBrowserPrompt extends Base {
  constructor(question, rl, answers) {
    super(question, rl, answers);
    this.currentPath = this.opt.root || process.cwd();
    this.selectedFile = null;
    this.selected = 0;
    this.firstRender = true;
  }

  _run(cb) {
    this.done = cb;
    
    // Set up keyboard event handlers using inquirer's observe utility
    const events = observe(this.rl);
    
    // Handle up/down keys - these should work until a line is submitted
    events.normalizedUpKey.pipe(takeUntil(events.line)).forEach(this.onUpKey.bind(this));
    events.normalizedDownKey.pipe(takeUntil(events.line)).forEach(this.onDownKey.bind(this));
    
    // Handle Enter key - process the selection
    // Use take(1) to only process the first line event, then re-subscribe if navigating
    this.setupLineHandler(events);
    
    this.navigateDirectory(this.currentPath);
    return this;
  }
  
  setupLineHandler(events) {
    // Subscribe to line events, but only take one at a time
    events.line
      .pipe(take(1))
      .forEach(() => {
        if (this.choices && this.choices.realLength > 0 && this.status !== 'answered') {
          this.handleAnswer(events);
        }
      });
  }
  
  onUpKey() {
    if (this.choices && this.choices.realLength > 0) {
      this.selected = this.selected > 0 ? this.selected - 1 : this.choices.realLength - 1;
      this.render();
    }
  }
  
  onDownKey() {
    if (this.choices && this.choices.realLength > 0) {
      this.selected = this.selected < this.choices.realLength - 1 ? this.selected + 1 : 0;
      this.render();
    }
  }

  navigateDirectory(dir) {
    try {
      const items = fs.readdirSync(dir, { withFileTypes: true });
      const choices = [];
      
      // Add parent directory option (if not at root)
      if (dir !== '/' && dir !== path.parse(dir).root) {
        choices.push({
          name: '📁 .. (Parent Directory)',
          value: { type: 'parent', path: path.dirname(dir) }
        });
      }

      // Add directories first
      items
        .filter(item => item.isDirectory() && !item.name.startsWith('.') && item.name !== 'node_modules')
        .sort((a, b) => a.name.localeCompare(b.name))
        .forEach(item => {
          choices.push({
            name: '📁 ' + item.name + '/',
            value: { type: 'dir', path: path.join(dir, item.name) }
          });
        });
      
      // Add PNG files
      items
        .filter(item => {
          if (!item.isFile()) return false;
          const ext = path.extname(item.name).toLowerCase();
          return ext === '.png';
        })
        .sort((a, b) => a.name.localeCompare(b.name))
        .forEach(item => {
          choices.push({
            name: '🖼️  ' + item.name,
            value: { type: 'file', path: path.join(dir, item.name) }
          });
        });

      if (choices.length === 0) {
        this.rl.write('\nNo PNG files found in this directory.\n');
        this.done('');
        return;
      }

      // Create choices object
      this.choices = new Choices(choices);
      this.selected = 0;
      this.render();
    } catch (error) {
      console.error('Error reading directory:', error.message);
      this.done('');
    }
  }

  render(error) {
    let message = this.getQuestion();
    let bottomContent = '';

    if (this.firstRender) {
      message += ' (Use arrow keys)';
      this.firstRender = false;
    }

    if (this.status === 'answered') {
      message += '\n' + this.answer;
    } else if (this.choices) {
      const choicesStr = this.choices.render(this.selected);
      message += '\n' + choicesStr;
    }

    if (error) {
      bottomContent = '\n' + (error.message || error);
    }

    this.screen.render(message, bottomContent);
  }

  handleAnswer(events) {
    if (!this.choices || this.choices.realLength === 0 || this.status === 'answered') {
      return;
    }
    
    const choice = this.choices.getChoice(this.selected);
    if (!choice) {
      return;
    }
    
    const selected = choice.value;
    
    // Handle different selection types
    if (selected.type === 'file') {
      // File selected - validate it's a PNG and close the prompt
      const ext = path.extname(selected.path).toLowerCase();
      if (ext === '.png') {
        this.answer = selected.path;
        this.status = 'answered';
        this.render();
        this.screen.done();
        this.done(selected.path);
      } else {
        // Not a PNG file, stay in current directory
        this.navigateDirectory(this.currentPath);
        this.setupLineHandler(events);
      }
    } else if (selected.type === 'dir' || selected.type === 'parent') {
      // Navigate into directory - re-setup line handler for next navigation
      this.currentPath = selected.path;
      this.selected = 0;
      this.navigateDirectory(this.currentPath);
      // Re-setup line handler for next Enter press
      this.setupLineHandler(events);
    } else {
      // Unknown type, stay in current directory
      this.navigateDirectory(this.currentPath);
      this.setupLineHandler(events);
    }
  }
}

module.exports = FileBrowserPrompt;
