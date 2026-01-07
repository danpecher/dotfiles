#!/bin/bash
#
# Bootstrap script - Complete macOS setup from scratch
#
# Usage (run in a new shell to preserve TTY for sudo prompts):
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/danpecher/dotfiles/main/scripts/01_bootstrap.sh)"
#
# Or clone and run:
#   git clone https://github.com/danpecher/dotfiles.git
#   cd dotfiles && ./scripts/01_bootstrap.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_REPO="danpecher/dotfiles"
DOTFILES_DIR="$HOME/.local/share/chezmoi"

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check macOS
if [[ "$(uname)" != "Darwin" ]]; then
    error "This script is only for macOS"
fi

echo ""
echo "=========================================="
echo "  macOS Bootstrap"
echo "=========================================="
echo ""

# Check if running non-interactively (piped input)
if [[ ! -t 0 ]]; then
    error "This script requires interactive input for sudo prompts.\nPlease run with: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/danpecher/dotfiles/main/scripts/01_bootstrap.sh)\""
fi

# Setup SSH key early (needed because git config rewrites HTTPS to SSH)
if [[ ! -f ~/.ssh/id_ed25519 ]]; then
    info "Generating SSH key (needed for GitHub access)..."
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh

    read -p "Enter your email for SSH key: " ssh_email
    ssh-keygen -t ed25519 -C "$ssh_email" -f ~/.ssh/id_ed25519

    # Add to keychain
    eval "$(ssh-agent -s)"
    ssh-add --apple-use-keychain ~/.ssh/id_ed25519

    success "SSH key generated"
    echo ""
    warn "Add this SSH key to GitHub before continuing:"
    echo ""
    cat ~/.ssh/id_ed25519.pub
    echo ""
    info "Go to: https://github.com/settings/keys"
    echo ""
    read -p "Press Enter after adding the key to GitHub..."
else
    success "SSH key already exists"
    # Ensure key is in agent
    eval "$(ssh-agent -s)" &>/dev/null
    ssh-add --apple-use-keychain ~/.ssh/id_ed25519 &>/dev/null || true
fi

# Install Xcode Command Line Tools
if xcode-select -p &>/dev/null; then
    success "Xcode Command Line Tools already installed"
else
    info "Installing Xcode Command Line Tools..."
    xcode-select --install
    # Wait for installation
    until xcode-select -p &>/dev/null; do
        sleep 5
    done
    success "Xcode Command Line Tools installed"
fi

# Install Homebrew
if command -v brew &>/dev/null; then
    success "Homebrew already installed"
else
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    success "Homebrew installed"
fi

# Add Homebrew to PATH
if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Update Homebrew
info "Updating Homebrew..."
brew update

# Install essential tools
info "Installing chezmoi and git..."
brew install chezmoi git

# Initialize and apply dotfiles with chezmoi
if [[ -d "$DOTFILES_DIR" ]]; then
    info "Updating dotfiles..."
    chezmoi update
else
    info "Initializing dotfiles from $DOTFILES_REPO..."
    info "You will be prompted for your name, email, and GitHub username."
    chezmoi init --apply "$DOTFILES_REPO"
fi

# Run the main setup script
SETUP_SCRIPT="$DOTFILES_DIR/scripts/02_setup.sh"
if [[ -f "$SETUP_SCRIPT" ]]; then
    info "Running setup script..."
    chmod +x "$SETUP_SCRIPT"
    "$SETUP_SCRIPT"
else
    warn "Setup script not found at $SETUP_SCRIPT"
fi

# Run macOS defaults script
DEFAULTS_SCRIPT="$DOTFILES_DIR/scripts/03_macos-defaults.sh"
if [[ -f "$DEFAULTS_SCRIPT" ]]; then
    echo ""
    read -p "Apply macOS system preferences? [y/N] " apply_defaults
    if [[ "$apply_defaults" =~ ^[Yy]$ ]]; then
        chmod +x "$DEFAULTS_SCRIPT"
        "$DEFAULTS_SCRIPT"
    else
        info "Skipping macOS defaults. Run later with: $DEFAULTS_SCRIPT"
    fi
fi

echo ""
echo "=========================================="
success "Setup complete!"
echo "=========================================="
echo ""
info "Restart your terminal or run: source ~/.zshrc"
info "Some macOS preferences may require a logout/restart."
echo ""
