#!/bin/bash
#
# Setup script - Install packages, chezmoi, mise, and configure shell
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
DOTFILES_REPO="${DOTFILES_REPO:-danpecher/dotfiles}"

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
fi

echo ""
echo "=========================================="
echo "  Setup - Packages & Configuration"
echo "=========================================="
echo ""

# Install packages from Brewfile
info "Installing packages from Brewfile..."
if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
    brew bundle --file="$DOTFILES_DIR/Brewfile"
    success "Brewfile packages installed"
else
    warn "Brewfile not found at $DOTFILES_DIR/Brewfile"
fi

# Setup SSH key
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

        # Add to GitHub if gh is available
        if command -v gh &>/dev/null; then
            info "Adding SSH key to GitHub..."
            if ! gh auth status &>/dev/null; then
                gh auth login -p ssh -w
            fi
            gh ssh-key add ~/.ssh/id_ed25519.pub -t "$(hostname)-$(date +%Y%m%d)" 2>/dev/null || true
            success "SSH key added to GitHub"
        fi
    else
        success "SSH key already exists"
    fi
}

# Setup chezmoi
setup_chezmoi() {
    if ! command -v chezmoi &>/dev/null; then
        warn "chezmoi not found"
        return
    fi

    if [[ -d ~/.local/share/chezmoi ]]; then
        info "Updating dotfiles with chezmoi..."
        chezmoi update
    else
        info "Initializing chezmoi with dotfiles..."
        chezmoi init --apply "$DOTFILES_REPO"
    fi
    success "Dotfiles applied via chezmoi"
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

# Install Xcode via xcodes
setup_xcode() {
    if ! command -v xcodes &>/dev/null; then
        warn "xcodes not found - should have been installed via Brewfile"
        return
    fi

    if [[ -d "/Applications/Xcode.app" ]]; then
        success "Xcode already installed"
    else
        info "Installing latest Xcode via xcodes (this may take a while)..."
        info "Note: You may be prompted to sign in with your Apple ID"
        xcodes install --latest --experimental-unxip
        success "Xcode installed"
    fi

    # Set Xcode as active developer directory
    if [[ -d "/Applications/Xcode.app" ]]; then
        sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
        success "Xcode set as active developer directory"
    fi

    # Accept Xcode license
    if command -v xcodebuild &>/dev/null; then
        if ! sudo xcodebuild -license check &>/dev/null 2>&1; then
            info "Accepting Xcode license..."
            sudo xcodebuild -license accept
            success "Xcode license accepted"
        fi
    fi
}

# Run setup steps
setup_ssh
setup_chezmoi
setup_xcode
setup_mise
setup_shell
setup_fzf

echo ""
success "Setup complete! Run 03_macos-defaults.sh to apply macOS preferences."
info "Restart your terminal or run: source ~/.zshrc"
echo ""
