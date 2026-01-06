#!/bin/bash
#
# Bootstrap script - Complete macOS setup from scratch
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/danpecher/dotfiles/main/scripts/01_bootstrap.sh | bash
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

# Initialize chezmoi with dotfiles
if [[ -d "$DOTFILES_DIR" ]]; then
    info "Updating dotfiles..."
    chezmoi update
else
    info "Initializing dotfiles from $DOTFILES_REPO..."
    chezmoi init "$DOTFILES_REPO"
fi

# Apply dotfiles
info "Applying dotfiles..."
chezmoi apply

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
