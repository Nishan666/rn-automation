#!/bin/bash

# Script to fix duplicate script phases in Xcode projects
# This fixes the "Unexpected duplicate tasks" error

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-$PWD}"

cd "$PROJECT_DIR" || exit 1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
  echo -e "${RED}❌ $1${NC}"
}

# Find iOS project
IOS_PROJECT=$(find ios -maxdepth 1 -name "*.xcodeproj" -type d 2>/dev/null | head -1)

if [ -z "$IOS_PROJECT" ]; then
  print_error "No iOS project found in ios/ directory"
  exit 1
fi

IOS_PROJECT_NAME=$(basename "$IOS_PROJECT" .xcodeproj)
print_info "Found iOS project: $IOS_PROJECT_NAME"

# Use Ruby to fix duplicate script phases
if command -v ruby >/dev/null 2>&1; then
  IOS_PROJECT_NAME_ENV="$IOS_PROJECT_NAME" ruby - <<'RUBYEOF'
require 'fileutils'
begin
  require 'xcodeproj'
rescue LoadError
  puts "Installing xcodeproj gem..."
  system('gem install xcodeproj --user-install')
  Gem.clear_paths
  require 'xcodeproj'
end

project_name = ENV['IOS_PROJECT_NAME_ENV']
project_path = "ios/#{project_name}.xcodeproj"

unless File.exist?(project_path)
  puts "Error: Project not found at #{project_path}"
  exit 1
end

project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == project_name }

unless target
  # Try case-insensitive
  target = project.targets.find { |t| t.name.downcase == project_name.downcase }
end

unless target
  # Use first application target
  target = project.targets.find { |t| t.product_type == "com.apple.product-type.application" }
end

unless target
  puts "Error: Target not found"
  exit 1
end

puts "Found target: #{target.name}"

# CRITICAL: First, remove any duplicate UUIDs from build_phases array
# This fixes "Unexpected duplicate tasks" error when same phase appears multiple times
seen_uuids = {}
duplicates_to_remove = []

target.build_phases.each_with_index do |phase, index|
  uuid = phase.uuid
  if seen_uuids[uuid]
    puts "Warning: Found duplicate build phase UUID #{uuid} at index #{index}. Will remove duplicate..."
    duplicates_to_remove << index
  else
    seen_uuids[uuid] = true
  end
end

# Remove duplicates in reverse order to preserve indices
duplicates_to_remove.reverse.each do |index|
  target.build_phases.delete_at(index)
end

if duplicates_to_remove.length > 0
  puts "Removed #{duplicates_to_remove.length} duplicate build phase reference(s)"
end

# Find all script phases
script_phases = target.build_phases.select { |p| p.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) }

# Group by name to find duplicates
script_groups = script_phases.group_by(&:name)

duplicates_found = duplicates_to_remove.length > 0
script_groups.each do |name, phases|
  next if name.nil? || phases.length <= 1
  
  puts "Found #{phases.length} duplicate script phases with name: '#{name}'"
  duplicates_found = true
  
  # Keep the first one, remove the rest
  phases[1..-1].each do |dup|
    puts "  Removing duplicate: #{dup.uuid}"
    target.build_phases.delete(dup)
  end
  
  # Update the remaining one to have correct settings
  remaining = phases.first
  remaining.always_out_of_date = '0' if remaining.respond_to?(:always_out_of_date=)
  puts "  Kept and updated: #{remaining.uuid}"
end

if duplicates_found
  if project.save
    puts "Success: Removed duplicate script phases"
    exit 0
  else
    puts "Error: Failed to save project"
    exit 1
  end
else
  puts "No duplicate script phases found"
  exit 0
end
RUBYEOF

  if [ $? -eq 0 ]; then
    print_success "Fixed duplicate script phases"
    print_info "You can now try building again: npm run ios:dev"
  else
    print_error "Failed to fix duplicate script phases"
    exit 1
  fi
else
  print_error "Ruby not found. Please install Ruby to use this script."
  exit 1
fi


