#!/bin/bash

# macOS System Preferences via CLI
# Run once on a fresh Mac, then reboot.
#
# Usage: ./defaults.sh

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  macOS Defaults${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Close System Preferences to prevent overriding changes
osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

# ── Keyboard ────────────────────────────────────────────────────────────────

echo -e "${YELLOW}Keyboard${NC}"

# Fast key repeat (lowest via UI is 2, this goes lower)
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable auto-correct, auto-capitalize, smart quotes/dashes
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

echo -e "${GREEN}✓${NC} Key repeat fast, auto-correct off"

# ── Dock ────────────────────────────────────────────────────────────────────

echo -e "${YELLOW}Dock${NC}"

# Auto-hide dock
defaults write com.apple.dock autohide -bool true

# Remove auto-hide delay
defaults write com.apple.dock autohide-delay -float 0

# Faster show/hide animation
defaults write com.apple.dock autohide-time-modifier -float 0.3

# Icon size
defaults write com.apple.dock tilesize -int 48

# Don't show recent apps in Dock
defaults write com.apple.dock show-recents -bool false

# Minimize windows into app icon
defaults write com.apple.dock minimize-to-application -bool true

echo -e "${GREEN}✓${NC} Auto-hide, no recents, 48px icons"

# ── Finder ──────────────────────────────────────────────────────────────────

echo -e "${YELLOW}Finder${NC}"

# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show path bar at bottom
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Default to list view
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Search current folder by default (not entire Mac)
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable warning when changing file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Keep folders on top when sorting
defaults write com.apple.finder _FXSortFoldersFirst -bool true

echo -e "${GREEN}✓${NC} Show extensions, hidden files, list view, path bar"

# ── Screenshots ─────────────────────────────────────────────────────────────

echo -e "${YELLOW}Screenshots${NC}"

# Save to ~/Screenshots instead of Desktop
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"

# PNG format (default, but explicit)
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

echo -e "${GREEN}✓${NC} Save to ~/Screenshots, PNG, no shadow"

# ── Trackpad ────────────────────────────────────────────────────────────────

echo -e "${YELLOW}Trackpad${NC}"

# Tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Three finger drag
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true

echo -e "${GREEN}✓${NC} Tap to click, three-finger drag"

# ── Global ──────────────────────────────────────────────────────────────────

echo -e "${YELLOW}Global${NC}"

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Disable "Are you sure you want to open this application?"
defaults write com.apple.LaunchServices LSQuarantine -bool false

echo -e "${GREEN}✓${NC} Expanded save/print panels, no quarantine warning"

# ── Safari (if used) ────────────────────────────────────────────────────────

echo -e "${YELLOW}Safari${NC}"

# Show full URL in address bar
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

# Enable developer menu
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true

echo -e "${GREEN}✓${NC} Full URL, developer menu enabled"

# ── Apply Changes ───────────────────────────────────────────────────────────

echo ""
echo -e "${YELLOW}Restarting affected apps...${NC}"
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

echo ""
echo -e "${GREEN}Done! Some changes require a logout/reboot to take effect.${NC}"
