#!/bin/bash

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Auto-install fzf based on OS and package manager
install_fzf() {
  echo -e "${YELLOW}Installing fzf...${NC}"
  
  if command -v brew >/dev/null 2>&1; then
    # macOS Homebrew
    if brew install fzf; then
      echo -e "${GREEN}fzf installed successfully${NC}"
      return 0
    fi
  elif command -v apt >/dev/null 2>&1; then
    # Debian/Ubuntu
    if sudo apt update && sudo apt install -y fzf; then
      echo -e "${GREEN}fzf installed successfully${NC}"
      return 0
    fi
  elif command -v pacman >/dev/null 2>&1; then
    # Arch Linux
    if sudo pacman -S --noconfirm fzf; then
      echo -e "${GREEN}fzf installed successfully${NC}"
      return 0
    fi
  elif command -v dnf >/dev/null 2>&1; then
    # Fedora
    if sudo dnf install -y fzf; then
      echo -e "${GREEN}fzf installed successfully${NC}"
      return 0
    fi
  elif command -v yum >/dev/null 2>&1; then
    # CentOS/RHEL
    if sudo yum install -y fzf; then
      echo -e "${GREEN}fzf installed successfully${NC}"
      return 0
    fi
  elif command -v zypper >/dev/null 2>&1; then
    # openSUSE
    if sudo zypper install -y fzf; then
      echo -e "${GREEN}fzf installed successfully${NC}"
      return 0
    fi
  elif command -v apk >/dev/null 2>&1; then
    # Alpine Linux
    if sudo apk add fzf; then
      echo -e "${GREEN}fzf installed successfully${NC}"
      return 0
    fi
  else
    echo -e "${RED}Unsupported package manager. Please install fzf manually:${NC}"
    echo -e "${CYAN}Visit: https://github.com/junegunn/fzf#installation${NC}"
  fi
  
  echo -e "${RED}Failed to install fzf${NC}"
  return 1
}

# Fuzzy finder browser function using fzf
# Usage: browse_files [starting_directory] [file_extensions] [mode]
# Returns: selected file path or directory path
browse_files() {
  local start_dir="${1:-$HOME}"
  local file_extensions="${2:-png|PNG}"
  local mode="${3:-file}" # 'file' or 'directory'
  
  # Check if fzf is available, install if not
  if ! command -v fzf >/dev/null 2>&1; then
    echo -e "${YELLOW}fzf not found. Attempting to install...${NC}"
    if install_fzf; then
      if ! command -v fzf >/dev/null 2>&1; then
        echo -e "${RED}fzf installation failed${NC}"
        return 1
      fi
    else
      return 1
    fi
  fi
  
  echo -e "${CYAN}Opening fuzzy finder...${NC}" >&2
  echo -e "${YELLOW}Use arrow keys to navigate, type to search, Enter to select${NC}" >&2
  sleep 1
  
  local selected=""
  
  if [ "$mode" = "directory" ]; then
    # Directory selection - show user directories only, exclude node_modules and hidden folders
    selected=$(find "$start_dir" -type d -not -path '*/node_modules*' -not -path '*/.*' 2>/dev/null | fzf --height=25 --border --prompt="Select directory: " --preview="ls -la {}" --preview-window=right:50%:wrap)
  else
    # File selection with extension filter
    if [ "$file_extensions" = "png|PNG" ]; then
      selected=$(find "$start_dir" -type f \( -name "*.png" -o -name "*.PNG" -o -name "*.jpg" -o -name "*.JPG" -o -name "*.jpeg" -o -name "*.JPEG" -o -name "*.svg" -o -name "*.SVG" \) 2>/dev/null | fzf --height=20 --border --prompt="Select image file: " --preview="file {}" --preview-window=right:50%:wrap)
    else
      # Generic file selection
      selected=$(find "$start_dir" -type f 2>/dev/null | fzf --height=20 --border --prompt="Select file: " --preview="file {}" --preview-window=right:50%:wrap)
    fi
  fi
  
  if [ -n "$selected" ]; then
    echo "$selected"
    return 0
  else
    return 1
  fi
}