#!/bin/bash
#
# Setup script - Install packages, development tools, and configure shell
#
# This script is called by 01_bootstrap.sh but can also be run standalone
# after dotfiles have been applied via chezmoi.
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
PROFILE="${PROFILE:-${SETUP_PROFILE:-personal}}"

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check Homebrew
if ! command -v brew &>/dev/null; then
    error "Homebrew not found. Run 01_bootstrap.sh first."
fi

# Ensure Homebrew is in PATH
if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

echo ""
echo "=========================================="
echo "  Setup - $PROFILE Profile"
echo "=========================================="
echo ""

# Setup SSH key (needed before brew bundle for taps that use git@github.com)
setup_ssh() {
    if [[ ! -f ~/.ssh/id_ed25519 ]]; then
        info "Generating SSH key..."
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh

        read -p "Enter your email for SSH key: " email
        ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519

        # Add to keychain
        eval "$(ssh-agent -s)"
        ssh-add --apple-use-keychain ~/.ssh/id_ed25519

        success "SSH key generated"
    else
        success "SSH key already exists"
    fi
}

# Add SSH key to GitHub (requires gh CLI from Brewfile)
setup_github_ssh() {
    if [[ ! -f ~/.ssh/id_ed25519.pub ]]; then
        warn "No SSH key found, skipping GitHub setup"
        return
    fi

    if ! command -v gh &>/dev/null; then
        warn "gh CLI not found, skipping GitHub SSH setup"
        return
    fi

    # Check if already authenticated
    if ! gh auth status &>/dev/null; then
        info "Authenticating with GitHub..."
        gh auth login -p ssh -w
    fi

    # Check if key already added
    local key_fingerprint
    key_fingerprint=$(ssh-keygen -lf ~/.ssh/id_ed25519.pub 2>/dev/null | awk '{print $2}')
    if [[ -n "$key_fingerprint" ]] && ! gh ssh-key list 2>/dev/null | grep -q "$key_fingerprint"; then
        info "Adding SSH key to GitHub..."
        gh ssh-key add ~/.ssh/id_ed25519.pub -t "$(hostname)-$(date +%Y%m%d)" 2>/dev/null || true
        success "SSH key added to GitHub"
    else
        success "SSH key already on GitHub"
    fi
}

brewfile_for_profile() {
    case "$PROFILE" in
        personal|full) printf '%s/Brewfile\n' "$DOTFILES_DIR" ;;
        minimal|work) printf '%s/Brewfile.minimal\n' "$DOTFILES_DIR" ;;
        *) error "Unknown profile: $PROFILE" ;;
    esac
}

# Install packages from the selected Brewfile. This is additive; cleanup is a
# separate preview-only workflow.
install_packages() {
    local brewfile
    brewfile="$(brewfile_for_profile)"
    info "Installing packages from $(basename "$brewfile")..."
    if [[ -f "$brewfile" ]]; then
        # Homebrew 6 requires explicit trust for third-party formulae/casks.
        # Scope trust to the exact packages instead of trusting whole taps.
        if grep -q 'jetbrains/utils/kotlin-lsp' "$brewfile"; then
            brew tap jetbrains/utils
            brew trust --formula jetbrains/utils/kotlin-lsp
        fi

        if grep -q 'nikitabobko/local-tap/aerospace-dev' "$brewfile"; then
            local custom_aerospace="$HOME/Code/AeroSpace/.release/AeroSpace-v0.0.0-SNAPSHOT.zip"
            local local_cask
            local_cask="$(brew --repository nikitabobko/local-tap 2>/dev/null)/Casks/aerospace-dev.rb"
            if [[ ! -f "$custom_aerospace" || ! -f "$local_cask" ]]; then
                error "Customized AeroSpace build or local cask is missing; see Brewfile comments"
            fi
            brew trust --cask nikitabobko/local-tap/aerospace-dev
        fi

        local bundle_file="$brewfile"
        local temp_brewfile=""
        if grep -Eq '^mas ' "$brewfile" && command -v mas >/dev/null 2>&1 && ! mas account &>/dev/null; then
            temp_brewfile="$(mktemp "${TMPDIR:-/tmp}/Brewfile.XXXXXX")"
            grep -Ev '^mas ' "$brewfile" > "$temp_brewfile"
            bundle_file="$temp_brewfile"
            warn "Not signed into the App Store; skipping mas entries"
        fi

        brew bundle --file="$bundle_file"
        [[ -z "$temp_brewfile" ]] || rm -f "$temp_brewfile"
        success "Brewfile packages installed"
    else
        error "Brewfile not found: $brewfile"
    fi
}

# Setup mise
setup_mise() {
    if ! command -v mise &>/dev/null; then
        warn "mise not found"
        return
    fi

    info "Activating mise..."
    eval "$(mise activate bash)"

    if [[ -f ~/.config/mise/config.toml ]]; then
        info "Installing development tools via mise..."
        mise install
        success "mise tools installed"
    else
        warn "mise config not found - should have been applied by chezmoi"
    fi
}

# Setup shell
setup_shell() {
    if [[ "$SHELL" != *"zsh"* ]]; then
        info "Changing default shell to zsh..."
        chsh -s "$(which zsh)"
        success "Default shell changed to zsh"
    else
        success "zsh is already the default shell"
    fi
}

# Setup fzf
setup_fzf() {
    if command -v fzf &>/dev/null; then
        info "Setting up fzf key bindings..."
        "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish 2>/dev/null || true
        success "fzf configured"
    fi
}

# AeroSpace refreshes this widget on focus/workspace changes. Pin the clean
# upstream checkout so a fresh setup gets the same bar implementation.
setup_ubersicht() {
    [[ "$PROFILE" == personal || "$PROFILE" == full ]] || return

    local widget_dir="$HOME/Library/Application Support/Übersicht/widgets/simple-bar"
    local widget_commit="fb5cada548a05bd01f727772c0a18fd8c7f65b42"

    if [[ ! -d "$widget_dir/.git" ]]; then
        info "Installing pinned simple-bar widget..."
        mkdir -p "$(dirname "$widget_dir")"
        git clone https://github.com/Jean-Tinland/simple-bar.git "$widget_dir"
    elif [[ -n "$(git -C "$widget_dir" status --porcelain)" ]]; then
        warn "simple-bar has local changes; leaving it untouched"
        return
    fi

    if [[ "$(git -C "$widget_dir" rev-parse HEAD)" != "$widget_commit" ]]; then
        git -C "$widget_dir" fetch origin "$widget_commit"
        git -C "$widget_dir" checkout --detach "$widget_commit"
    fi
    success "simple-bar is pinned at ${widget_commit:0:8}"
}

# Configure an existing Xcode installation. A bootstrap should not silently
# download a multi-gigabyte application; install Xcode explicitly when needed.
setup_xcode() {
    if ! command -v xcodes &>/dev/null; then
        warn "xcodes not found - should have been installed via Brewfile"
        return
    fi

    # Find any Xcode installation (xcodes uses versioned names like Xcode-16.2.0.app)
    local xcode_app
    xcode_app=$(find /Applications -maxdepth 1 -name "Xcode*.app" -type d 2>/dev/null | head -1)

    if [[ -z "$xcode_app" ]]; then
        warn "Xcode is not installed; install it explicitly with: xcodes install --latest"
        return
    fi

    success "Xcode already installed: $(basename "$xcode_app")"

    # Set Xcode as active developer directory (must happen before xcodebuild commands)
    if [[ -n "$xcode_app" && -d "$xcode_app/Contents/Developer" ]]; then
        info "Setting Xcode as active developer directory..."
        sudo xcode-select -s "$xcode_app/Contents/Developer"
        success "Xcode set as active developer directory"

        # Accept Xcode license
        if ! sudo xcodebuild -license check &>/dev/null 2>&1; then
            info "Accepting Xcode license..."
            sudo xcodebuild -license accept
            success "Xcode license accepted"
        else
            success "Xcode license already accepted"
        fi
    else
        warn "Xcode Developer directory not found - Xcode may need to be reinstalled"
        warn "Try: xcodes install --latest"
    fi
}

# Run setup steps
setup_ssh          # Generate SSH keys first (needed for GitHub taps)
install_packages   # Install Brewfile packages
setup_ubersicht    # Install the workspace bar used by AeroSpace
setup_github_ssh   # Add SSH key to GitHub (now that gh is installed)
if [[ "$PROFILE" == personal || "$PROFILE" == full ]]; then
    setup_xcode    # Configure Xcode when it is already installed
fi
setup_mise         # Install dev tools via mise
setup_shell        # Set zsh as default shell
setup_fzf          # Configure fzf keybindings

echo ""
success "Setup complete!"
echo ""
