#!/bin/bash
#
# Bootstrap script for nix-darwin
# Run this on a fresh macOS installation
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           macOS Fresh Install Setup (nix-darwin)             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# =============================================================================
# Step 1: Xcode Command Line Tools
# =============================================================================
info "Checking Xcode Command Line Tools..."

if ! xcode-select -p &>/dev/null; then
    info "Installing Xcode Command Line Tools..."
    xcode-select --install

    echo ""
    warn "Xcode CLI installation started."
    warn "Please complete the installation in the popup window."
    read -p "Press Enter after installation completes..."

    if ! xcode-select -p &>/dev/null; then
        error "Xcode CLI tools installation failed. Please install manually."
    fi
fi

success "Xcode Command Line Tools installed"

# =============================================================================
# Step 2: Install Nix
# =============================================================================
info "Checking Nix installation..."

if ! command -v nix &>/dev/null; then
    info "Installing Nix using Determinate Systems installer..."

    curl --proto '=https' --tlsv1.2 -sSf -L \
        https://install.determinate.systems/nix | sh -s -- install

    # Source nix for current session
    if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi

    success "Nix installed"
else
    success "Nix already installed"
fi

# =============================================================================
# Step 3: Bootstrap nix-darwin
# =============================================================================
info "Bootstrapping nix-darwin..."

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

# First time setup - use nix run to bootstrap
if ! command -v darwin-rebuild &>/dev/null; then
    info "Running initial nix-darwin build..."
    nix run nix-darwin -- switch --flake .#default
else
    info "Running darwin-rebuild..."
    darwin-rebuild switch --flake .#default
fi

success "nix-darwin configured!"

# =============================================================================
# Done
# =============================================================================
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                     Setup Complete!                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Your system has been configured with nix-darwin."
echo ""
echo "Common commands:"
echo "  darwin-rebuild switch --flake ~/code/dotfiles    # Apply changes"
echo "  darwin-rebuild switch --rollback                 # Rollback"
echo "  nix flake update                                 # Update inputs"
echo ""
echo "Next steps:"
echo "  1. Update git config in home/git.nix with your email"
echo "  2. Sign into Mac App Store for MAS apps"
echo "  3. Restart your terminal to apply shell changes"
echo "  4. Some macOS settings may require logout/restart"
echo ""
