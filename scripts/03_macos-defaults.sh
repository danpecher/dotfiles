#!/bin/bash
#
# macOS System Preferences & Defaults
# Based on nix-darwin system.nix configuration
#

set -e

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
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

echo ""
echo "=========================================="
echo "  macOS System Preferences"
echo "=========================================="
echo ""

###############################################################################
# General UI/UX (from NSGlobalDomain)
###############################################################################
info "Configuring General UI/UX..."

# Dark mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Natural scrolling
defaults write NSGlobalDomain "com.apple.swipescrolldirection" -bool true

# Disable beep sound on volume change
defaults write NSGlobalDomain "com.apple.sound.beep.feedback" -int 0

# Full keyboard access for all controls
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Enable press and hold
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool true

# Fast keyboard repeat (for vim users)
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain KeyRepeat -int 3

# Disable auto-correct features
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

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

defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock show-process-indicators -bool true
defaults write com.apple.dock launchanim -bool false
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock autohide-delay -float 0.0
defaults write com.apple.dock autohide-time-modifier -float 0.3
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock tilesize -int 48

# Set Dock apps (persistent-apps)
info "Setting Dock apps..."

# Helper function to create a Dock app entry
dock_app() {
    local app_path="$1"
    if [[ -d "$app_path" ]]; then
        echo "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$app_path</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
    fi
}

# Helper function to create a Dock folder entry
dock_folder() {
    local folder_path="$1"
    local arrangement="${2:-1}"  # 1=name, 2=date added, 3=date modified, 4=date created, 5=kind
    local displayas="${3:-0}"    # 0=stack, 1=folder
    local showas="${4:-2}"       # 0=auto, 1=fan, 2=grid, 3=list
    if [[ -d "$folder_path" ]]; then
        echo "<dict><key>tile-data</key><dict><key>arrangement</key><integer>$arrangement</integer><key>displayas</key><integer>$displayas</integer><key>file-data</key><dict><key>_CFURLString</key><string>file://$folder_path/</string><key>_CFURLStringType</key><integer>15</integer></dict><key>showas</key><integer>$showas</integer></dict><key>tile-type</key><string>directory-tile</string></dict>"
    fi
}

# Build persistent-apps array
persistent_apps=""
for app in "/Applications/Ghostty.app" \
           "/Applications/Notion.app" \
           "/System/Cryptexes/App/System/Applications/Safari.app" \
           "/Applications/Visual Studio Code.app"; do
    entry=$(dock_app "$app")
    if [[ -n "$entry" ]]; then
        persistent_apps+="$entry"
    fi
done

# Build persistent-others array (folders on the right side)
persistent_others=""
persistent_others+=$(dock_folder "$HOME/Downloads" 2 0 2)  # Sort by date added, stack, grid
persistent_others+=$(dock_folder "$HOME/Desktop" 1 0 2)   # Sort by name, stack, grid

# Apply to Dock
defaults write com.apple.dock persistent-apps -array $persistent_apps
defaults write com.apple.dock persistent-others -array $persistent_others

success "Dock configured"

###############################################################################
# Finder
###############################################################################
info "Configuring Finder..."

defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder QuitMenuItem -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

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
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Light haptic feedback
defaults write com.apple.AppleMultitouchTrackpad ActuationStrength -int 0
defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 0

success "Trackpad configured"

###############################################################################
# Desktop Services
###############################################################################
info "Configuring Desktop Services..."

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

success "Desktop Services configured"

###############################################################################
# Spaces
###############################################################################
info "Configuring Spaces..."

# Displays have separate spaces
defaults write com.apple.spaces "spans-displays" -int 0

# Auto-switch to space when switching to app
defaults write .GlobalPreferences AppleSpacesSwitchOnActivate -bool true

success "Spaces configured"

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
# Screen Saver & Security
###############################################################################
info "Configuring Screen Saver & Security..."

# Require password immediately after sleep
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

success "Screen Saver & Security configured"

###############################################################################
# Screen Capture
###############################################################################
info "Configuring Screen Capture..."

defaults write com.apple.screencapture location -string "~/Desktop"
defaults write com.apple.screencapture type -string "png"

success "Screen Capture configured"

###############################################################################
# Privacy
###############################################################################
info "Configuring Privacy..."

# Disable personalized ads
defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false

# Disable app quarantine dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

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
# Login Window
###############################################################################
info "Configuring Login Window..."

# Disable guest user
sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false

success "Login Window configured"

###############################################################################
# Control Center
###############################################################################
info "Configuring Control Center..."

defaults write com.apple.controlcenter "NSStatusItem Visible Battery" -bool true
defaults write com.apple.controlcenter "NSStatusItem Visible Bluetooth" -bool true
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
# Software Update
###############################################################################
info "Configuring Software Update..."

defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1
defaults write com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool true
defaults write com.apple.commerce AutoUpdate -bool true

success "Software Update configured"

###############################################################################
# Spotlight (disable for Raycast)
###############################################################################
info "Configuring Spotlight..."

# Disable Spotlight keyboard shortcut (Cmd+Space) - will use Raycast
/usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:64:enabled false" ~/Library/Preferences/com.apple.symbolichotkeys.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:65:enabled false" ~/Library/Preferences/com.apple.symbolichotkeys.plist 2>/dev/null || true

success "Spotlight configured"

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
add_login_item "/Applications/AeroSpace.app"
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
