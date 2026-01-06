#!/bin/bash
#
# Bootstrap script - Install Xcode CLI tools and Homebrew
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
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check macOS
if [[ "$(uname)" != "Darwin" ]]; then
    error "This script is only for macOS"
fi

echo ""
echo "=========================================="
echo "  Bootstrap - Xcode & Homebrew"
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

    # Add to PATH for Apple Silicon
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    success "Homebrew installed"
fi

# Update Homebrew
info "Updating Homebrew..."
brew update
success "Homebrew updated"

echo ""
success "Bootstrap complete! Run 02_setup.sh next."
echo ""
