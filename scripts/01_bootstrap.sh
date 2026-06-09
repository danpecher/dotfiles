#!/bin/bash
#
# Bootstrap script - macOS setup from scratch
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
SETUP_PROFILE="${SETUP_PROFILE:-minimal}"
DOTFILES_REF="${DOTFILES_REF:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

is_local_checkout() {
    [[ -d "$REPO_ROOT/.git" ]]
}

run_chezmoi_init() {
    if is_local_checkout; then
        chezmoi init --apply --source="$REPO_ROOT"
        return
    fi

    if [[ -n "$DOTFILES_REF" ]]; then
        chezmoi init --apply --branch="$DOTFILES_REF" "$DOTFILES_REPO"
    else
        chezmoi init --apply "$DOTFILES_REPO"
    fi
}

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

# Generate SSH key early because the git config rewrites GitHub HTTPS URLs to SSH.
generate_ssh_key() {
    if [[ ! -f ~/.ssh/id_ed25519 ]]; then
        info "Generating SSH key for GitHub access..."
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh

        read -p "Enter your email for SSH key: " ssh_email
        ssh-keygen -t ed25519 -C "$ssh_email" -f ~/.ssh/id_ed25519

        eval "$(ssh-agent -s)" &>/dev/null
        ssh-add --apple-use-keychain ~/.ssh/id_ed25519

        success "SSH key generated"
    else
        success "SSH key already exists"
        eval "$(ssh-agent -s)" &>/dev/null
        ssh-add --apple-use-keychain ~/.ssh/id_ed25519 &>/dev/null || true
    fi
}

setup_github_ssh() {
    if [[ ! -f ~/.ssh/id_ed25519.pub ]]; then
        warn "No SSH public key found"
        return
    fi

    if ! gh auth status &>/dev/null; then
        info "Authenticating with GitHub..."
        gh auth login -p ssh -w
    fi

    local key_fingerprint
    key_fingerprint=$(ssh-keygen -lf ~/.ssh/id_ed25519.pub 2>/dev/null | awk '{print $2}')
    if [[ -n "$key_fingerprint" ]] && ! gh ssh-key list 2>/dev/null | grep -q "$key_fingerprint"; then
        info "Adding SSH key to GitHub..."
        gh ssh-key add ~/.ssh/id_ed25519.pub -t "$(hostname)-$(date +%Y%m%d)"
        success "SSH key added to GitHub"
    else
        success "SSH key already on GitHub"
    fi
}

generate_ssh_key

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

# Install essential tools required before chezmoi applies git config.
info "Installing chezmoi, git, and gh..."
brew install chezmoi git gh

setup_github_ssh

# Initialize and apply dotfiles with chezmoi
if [[ -d "$DOTFILES_DIR" ]]; then
    info "Updating dotfiles..."
    chezmoi update
else
    if is_local_checkout; then
        info "Initializing dotfiles from local checkout: $REPO_ROOT"
    elif [[ -n "$DOTFILES_REF" ]]; then
        info "Initializing dotfiles from $DOTFILES_REPO (branch: $DOTFILES_REF)..."
    else
        info "Initializing dotfiles from $DOTFILES_REPO..."
    fi
    info "You will be prompted for your name, email, and GitHub username."
    # Use the current checkout when available so branch-local setup changes are preserved.
    # Otherwise allow an explicit branch override for remote bootstrap runs.
    run_chezmoi_init
fi

# Run the main setup script
SETUP_SCRIPT="$DOTFILES_DIR/scripts/02_setup.sh"
if [[ -f "$SETUP_SCRIPT" ]]; then
    info "Running setup script with profile: $SETUP_PROFILE"
    chmod +x "$SETUP_SCRIPT"
    SETUP_PROFILE="$SETUP_PROFILE" "$SETUP_SCRIPT"
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
if [[ "$SETUP_PROFILE" == "full" ]]; then
    info "Some macOS preferences may require a logout/restart."
fi
echo ""
