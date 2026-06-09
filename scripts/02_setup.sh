#!/bin/bash
#
# Setup script - install packages and configure shell
#
# Profiles:
#   minimal (default): work VM essentials only
#   full: full workstation setup
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
SETUP_PROFILE="${SETUP_PROFILE:-minimal}"

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

if ! command -v brew &>/dev/null; then
    error "Homebrew not found. Run 01_bootstrap.sh first."
fi

if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

echo ""
echo "=========================================="
echo "  Setup - $SETUP_PROFILE Profile"
echo "=========================================="
echo ""

brewfile_for_profile() {
    case "$SETUP_PROFILE" in
        minimal)
            echo "$DOTFILES_DIR/Brewfile.minimal"
            ;;
        full)
            echo "$DOTFILES_DIR/Brewfile"
            ;;
        *)
            error "Unknown SETUP_PROFILE: $SETUP_PROFILE"
            ;;
    esac
}

install_packages() {
    local brewfile
    brewfile="$(brewfile_for_profile)"
    local bundle_args=("--file=$brewfile")
    local temp_brewfile=""

    if [[ ! -f "$brewfile" ]]; then
        error "Brewfile not found: $brewfile"
    fi

    if grep -Eq '^mas ' "$brewfile" && ! mas account &>/dev/null; then
        temp_brewfile="$(mktemp "${TMPDIR:-/tmp}/Brewfile.XXXXXX")"
        grep -Ev '^mas ' "$brewfile" > "$temp_brewfile"
        bundle_args=("--file=$temp_brewfile")
        warn "Not signed into the App Store; skipping mas dependencies for this run"
    fi

    info "Installing packages from $(basename "$brewfile")..."
    brew bundle "${bundle_args[@]}"

    if [[ -n "$temp_brewfile" && -f "$temp_brewfile" ]]; then
        rm -f "$temp_brewfile"
    fi

    success "Packages installed"
}

setup_mise() {
    if ! command -v mise &>/dev/null; then
        warn "mise not found"
        return
    fi

    info "Installing development tools via mise..."
    eval "$(mise activate bash)"
    mise install
    success "mise tools installed"
}

setup_shell() {
    if [[ "$SHELL" != *"zsh"* ]]; then
        info "Changing default shell to zsh..."
        chsh -s "$(which zsh)"
        success "Default shell changed to zsh"
    else
        success "zsh is already the default shell"
    fi
}

setup_fzf() {
    if ! command -v fzf &>/dev/null; then
        return
    fi

    info "Setting up fzf key bindings..."
    "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish \
        2>/dev/null || true
    success "fzf configured"
}

print_manual_steps() {
    echo ""
    info "Manual follow-up:"
    echo "  - Open a new shell so Homebrew, zsh plugins, and prompt changes load."
    echo "  - If GitHub auth needs to be refreshed later, run: gh auth login"
    echo "  - If App Store apps were skipped, sign into the App Store and rerun the setup profile later."

    if [[ "$SETUP_PROFILE" == "full" ]]; then
        echo "  - Full profile keeps the larger workstation package set and mise toolchain install."
    fi
}

install_packages
setup_mise
setup_shell
setup_fzf
print_manual_steps

echo ""
success "Setup complete!"
echo ""
