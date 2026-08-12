#!/bin/bash
#
# macOS System Preferences & Defaults
# Based on nix-darwin system.nix configuration
#

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/macos-defaults-lib.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Close System Settings to prevent it from overriding our settings
osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

# Ask for admin password upfront
sudo -v

# Keep-alive: update sudo timestamp
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &

echo ""
echo "=========================================="
echo "  macOS System Preferences"
echo "=========================================="
echo ""

info "Applying audited macOS defaults policy..."
apply_managed_defaults
success "Audited macOS defaults applied"

###############################################################################
# General UI/UX (from NSGlobalDomain)
###############################################################################
info "Configuring General UI/UX..."

# Disable beep sound on volume change
defaults write NSGlobalDomain "com.apple.sound.beep.feedback" -int 0

# Full keyboard access for all controls
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Expand save/print panels by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Add web inspector context menu
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

success "General UI/UX configured"

###############################################################################
# Menu Bar Clock
###############################################################################
info "Configuring Menu Bar Clock..."

defaults write com.apple.menuextra.clock Show24Hour -bool true
defaults write com.apple.menuextra.clock ShowDate -int 1
defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true
defaults write com.apple.menuextra.clock ShowSeconds -bool false

success "Menu Bar Clock configured"

###############################################################################
# Dock
###############################################################################
info "Configuring Dock..."

defaults write com.apple.dock show-process-indicators -bool true
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write com.apple.dock autohide-time-modifier -float 0.3
defaults write com.apple.dock tilesize -int 48

# Set Dock apps (persistent-apps)
info "Setting Dock apps..."

DOCK_PLIST="$HOME/Library/Preferences/com.apple.dock.plist"
APP_INDEX=0
FOLDER_INDEX=0

# Helper function to add an app to the Dock
add_dock_app() {
  local app_path="$1"
  if [[ -d "$app_path" ]]; then
    /usr/libexec/PlistBuddy \
      -c "Add :persistent-apps:$APP_INDEX dict" \
      -c "Add :persistent-apps:$APP_INDEX:tile-data dict" \
      -c "Add :persistent-apps:$APP_INDEX:tile-data:file-data dict" \
      -c "Add :persistent-apps:$APP_INDEX:tile-data:file-data:_CFURLString string $app_path" \
      -c "Add :persistent-apps:$APP_INDEX:tile-data:file-data:_CFURLStringType integer 0" \
      "$DOCK_PLIST"
    APP_INDEX=$((APP_INDEX + 1))
  fi
}

# Helper function to add a folder to the Dock
add_dock_folder() {
  local folder_path="$1"
  local arrangement="${2:-1}" # 1=name, 2=date added, 3=date modified, 4=date created, 5=kind
  local displayas="${3:-0}"   # 0=stack, 1=folder
  local showas="${4:-2}"      # 0=auto, 1=fan, 2=grid, 3=list
  if [[ -d "$folder_path" ]]; then
    /usr/libexec/PlistBuddy \
      -c "Add :persistent-others:$FOLDER_INDEX dict" \
      -c "Add :persistent-others:$FOLDER_INDEX:tile-data dict" \
      -c "Add :persistent-others:$FOLDER_INDEX:tile-data:arrangement integer $arrangement" \
      -c "Add :persistent-others:$FOLDER_INDEX:tile-data:displayas integer $displayas" \
      -c "Add :persistent-others:$FOLDER_INDEX:tile-data:showas integer $showas" \
      -c "Add :persistent-others:$FOLDER_INDEX:tile-data:file-data dict" \
      -c "Add :persistent-others:$FOLDER_INDEX:tile-data:file-data:_CFURLString string file://$folder_path/" \
      -c "Add :persistent-others:$FOLDER_INDEX:tile-data:file-data:_CFURLStringType integer 15" \
      -c "Add :persistent-others:$FOLDER_INDEX:tile-type string directory-tile" \
      "$DOCK_PLIST"
    FOLDER_INDEX=$((FOLDER_INDEX + 1))
  fi
}

# Clear existing persistent-apps and persistent-others
/usr/libexec/PlistBuddy -c "Delete :persistent-apps" "$DOCK_PLIST"
/usr/libexec/PlistBuddy -c "Delete :persistent-others" "$DOCK_PLIST"
/usr/libexec/PlistBuddy -c "Add :persistent-apps array" "$DOCK_PLIST"
/usr/libexec/PlistBuddy -c "Add :persistent-others array" "$DOCK_PLIST"

# Add apps to Dock
add_dock_app "/Applications/Ghostty.app"
add_dock_app "/Applications/Notion.app"
add_dock_app "/System/Cryptexes/App/System/Applications/Safari.app"
add_dock_app "/Applications/Visual Studio Code.app"

# Add folders to Dock (right side)
add_dock_folder "$HOME/Downloads" 2 0 2 # Sort by date added, stack, grid
add_dock_folder "$HOME/Desktop" 1 0 2   # Sort by name, stack, grid

success "Dock configured"

###############################################################################
# Finder
###############################################################################
info "Configuring Finder..."

defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder QuitMenuItem -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# Show drives on desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Show ~/Library folder
chflags nohidden ~/Library 2>/dev/null || true

# Show /Volumes folder
sudo chflags nohidden /Volumes 2>/dev/null || true

success "Finder configured"

###############################################################################
# Trackpad
###############################################################################
info "Configuring Trackpad..."

defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Light haptic feedback
defaults write com.apple.AppleMultitouchTrackpad ActuationStrength -int 0
defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 0

success "Trackpad configured"

###############################################################################
# Window Manager
###############################################################################
info "Configuring Window Manager..."

defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -int 1
defaults write com.apple.WindowManager StandardHideDesktopIcons -int 0
defaults write com.apple.WindowManager HideDesktop -int 0
defaults write com.apple.WindowManager StageManagerHideWidgets -int 0
defaults write com.apple.WindowManager StandardHideWidgets -int 0

success "Window Manager configured"

###############################################################################
# Privacy
###############################################################################
info "Configuring Privacy..."

# Prevent Photos from opening when devices are plugged in
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

success "Privacy configured"

###############################################################################
# Safari (may fail on newer macOS due to sandboxing - configure manually)
###############################################################################
info "Configuring Safari (some settings may require manual configuration)..."

# These settings may fail due to Safari sandboxing in newer macOS versions
# If they fail, configure Safari preferences manually in Safari > Settings
{
  defaults write com.apple.Safari AlwaysRestoreSessionAtLaunch -bool true
  defaults write com.apple.Safari ExcludePrivateWindowWhenRestoringSessionAtLaunch -bool true
  defaults write com.apple.Safari ShowOverlayStatusBar -bool true
  defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
  defaults write com.apple.Safari IncludeDevelopMenu -bool true
  defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
  defaults write com.apple.Safari WebAutomaticSpellingCorrectionEnabled -bool false
  defaults write com.apple.Safari WebContinuousSpellCheckingEnabled -bool true
  defaults write com.apple.Safari AutoFillFromAddressBook -bool false
  defaults write com.apple.Safari AutoFillCreditCardData -bool false
  defaults write com.apple.Safari AutoFillMiscellaneousForms -bool false
  defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true
  defaults write com.apple.Safari WebKitJavaEnabled -bool false
  defaults write com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically -bool false
  defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true
} 2>/dev/null || true

success "Safari configured (some settings may need manual setup)"

###############################################################################
# Control Center
###############################################################################
info "Configuring Control Center..."

defaults write com.apple.controlcenter "NSStatusItem Visible Battery" -bool true
# Note: Bluetooth visibility is not scriptable in macOS 15+ (set manually in System Settings → Control Center)
defaults write com.apple.controlcenter "NSStatusItem Visible Sound" -bool true
defaults write com.apple.controlcenter "NSStatusItem Visible WiFi" -bool true
defaults write com.apple.controlcenter "NSStatusItem Visible AirDrop" -bool false
defaults write com.apple.controlcenter "NSStatusItem Visible Display" -bool false
defaults write com.apple.controlcenter "NSStatusItem Visible FocusModes" -bool false
defaults write com.apple.controlcenter "NSStatusItem Visible NowPlaying" -bool false

# Show battery percentage
defaults write com.apple.menuextra.battery ShowPercent -string "YES"

success "Control Center configured"

###############################################################################
# Spotlight (disable for Raycast)
###############################################################################
info "Configuring Spotlight..."

# Disable Spotlight keyboard shortcut (Cmd+Space) - will use Raycast
# NOTE: This doesn't work reliably in macOS 15+. Must disable manually:
#   System Settings → Keyboard → Keyboard Shortcuts → Spotlight → uncheck "Show Spotlight search"
warn "Spotlight shortcut must be disabled manually: System Settings → Keyboard → Keyboard Shortcuts → Spotlight"

###############################################################################
# Activity Monitor
###############################################################################
info "Configuring Activity Monitor..."

defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
defaults write com.apple.ActivityMonitor IconType -int 5
defaults write com.apple.ActivityMonitor ShowCategory -int 0
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

success "Activity Monitor configured"

###############################################################################
# TextEdit
###############################################################################
info "Configuring TextEdit..."

defaults write com.apple.TextEdit RichText -int 0
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

success "TextEdit configured"

###############################################################################
# Time Machine
###############################################################################
info "Configuring Time Machine..."

defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

success "Time Machine configured"

###############################################################################
# Login Items
###############################################################################
info "Configuring Login Items..."

add_login_item() {
  local app_path="$1"
  if [[ -d "$app_path" ]]; then
    osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$app_path\", hidden:false}" 2>/dev/null || true
  fi
}

add_login_item "/Applications/Raycast.app"
# AeroSpace is intentionally disabled; do not add it as a login item.
# add_login_item "/Applications/AeroSpace.app"
add_login_item "/Applications/MonitorControl.app"

success "Login Items configured"

###############################################################################
# Restart affected applications
###############################################################################
info "Restarting affected applications..."

for app in "Activity Monitor" \
  "Dock" \
  "Finder" \
  "Safari" \
  "SystemUIServer"; do
  killall "${app}" &>/dev/null || true
done

echo ""
success "macOS preferences applied!"
warn "Some changes require a logout/restart to take effect."
echo ""
