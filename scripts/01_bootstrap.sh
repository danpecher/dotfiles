#!/bin/bash
#
# Bootstrap script - Complete macOS setup from scratch
#
# Usage (run in a new shell to preserve TTY for sudo prompts):
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/danpecher/dotfiles/master/scripts/01_bootstrap.sh)"
#
# Or clone and run:
#   git clone https://github.com/danpecher/dotfiles.git
#   cd dotfiles && ./scripts/01_bootstrap.sh
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_REPO="danpecher/dotfiles"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Code/dotfiles}"
DOTFILES_REF="${DOTFILES_REF:-master}"
PROFILE="${PROFILE:-personal}"
SKIP_STEPS="${SKIP_STEPS:-}"
if [[ "${SKIP_KANATA:-0}" == 1 ]]; then
    SKIP_STEPS="${SKIP_STEPS:+$SKIP_STEPS,}kanata"
fi
REPO_ROOT=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    candidate_root="$(cd "$SCRIPT_DIR/.." && pwd)"
    [[ -d "$candidate_root/.git" ]] && REPO_ROOT="$candidate_root"
fi

if [[ "$(uname -s)" == Linux ]]; then
    if [[ -n "$REPO_ROOT" && -x "$REPO_ROOT/scripts/01_bootstrap-linux.sh" ]]; then
        exec "$REPO_ROOT/scripts/01_bootstrap-linux.sh"
    fi
    PROFILE="$PROFILE" SKIP_STEPS="$SKIP_STEPS" DOTFILES_DIR="$DOTFILES_DIR" DOTFILES_REF="$DOTFILES_REF" \
        /bin/bash -c "$(curl -fsSL "https://raw.githubusercontent.com/$DOTFILES_REPO/$DOTFILES_REF/scripts/01_bootstrap-linux.sh")"
    exit
fi

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

skip_step() {
    case ",${SKIP_STEPS// /,}," in
        *,"$1",*) return 0 ;;
        *) return 1 ;;
    esac
}

dotfiles_repo_url() {
    if skip_step github; then
        printf 'https://github.com/%s.git\n' "$DOTFILES_REPO"
    else
        printf 'git@github.com:%s.git\n' "$DOTFILES_REPO"
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
    error "This script requires interactive input for sudo prompts.\nPlease run with: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/danpecher/dotfiles/master/scripts/01_bootstrap.sh)\""
fi

# Generate SSH key early (needed because git config rewrites HTTPS to SSH)
generate_ssh_key() {
    if skip_step github; then
        warn "Skipping SSH key setup (SKIP_STEPS includes github)"
        return
    fi
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
    else
        success "SSH key already exists"
        # Ensure key is in agent
        eval "$(ssh-agent -s)" &>/dev/null
        ssh-add --apple-use-keychain ~/.ssh/id_ed25519 &>/dev/null || true
    fi
}

# Add SSH key to GitHub using gh CLI
setup_github_ssh() {
    if skip_step github; then
        warn "Skipping GitHub authentication (SKIP_STEPS includes github)"
        return
    fi
    if [[ ! -f ~/.ssh/id_ed25519.pub ]]; then
        warn "No SSH key found"
        return
    fi

    # Authenticate with GitHub if needed
    if ! gh auth status &>/dev/null; then
        info "Authenticating with GitHub..."
        gh auth login -p ssh -w
    fi

    # Add SSH key if not already on GitHub
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

# Install essential tools (gh needed to add SSH key to GitHub before chezmoi applies git config)
info "Installing chezmoi, git, and gh..."
brew install chezmoi git gh

# Add SSH key to GitHub (before chezmoi applies git config with SSH URL rewriting)
setup_github_ssh

is_local_checkout() {
    [[ -n "$REPO_ROOT" && -d "$REPO_ROOT/.git" ]]
}

# Initialize chezmoi configuration without touching destination files. Applying
# is a separate, reviewed step even during bootstrap.
if is_local_checkout; then
    info "Initializing chezmoi from local checkout: $REPO_ROOT"
    DOTFILES_DIR="$REPO_ROOT"
elif [[ -d "$DOTFILES_DIR/.git" ]]; then
    info "Updating canonical checkout: $DOTFILES_DIR"
    git -C "$DOTFILES_DIR" pull --ff-only "$(dotfiles_repo_url)" "$DOTFILES_REF"
else
    info "Cloning canonical checkout to $DOTFILES_DIR..."
    info "You will be prompted for your name, email, and GitHub username."
    mkdir -p "$(dirname "$DOTFILES_DIR")"
    git clone --branch "$DOTFILES_REF" "$(dotfiles_repo_url)" "$DOTFILES_DIR"
fi

export PROFILE SKIP_STEPS
chezmoi init --source="$DOTFILES_DIR"

echo ""
info "Reviewing destination changes before apply..."
chezmoi --source="$DOTFILES_DIR" status
chezmoi --source="$DOTFILES_DIR" diff --no-pager
echo ""
read -p "Apply these chezmoi changes? [y/N] " apply_dotfiles
if [[ "$apply_dotfiles" =~ ^[Yy]$ ]]; then
    chezmoi --source="$DOTFILES_DIR" apply --interactive
else
    warn "Dotfiles were not applied. Bootstrap is stopping before package and service setup."
    info "Review later with: cd $DOTFILES_DIR && make plan"
    exit 0
fi

# Run the main setup script from the source repository. Helper scripts are
# intentionally ignored by chezmoi and are not copied into the home directory.
SETUP_SCRIPT="$DOTFILES_DIR/scripts/02_setup.sh"
if [[ -f "$SETUP_SCRIPT" ]]; then
    info "Running setup script with profile: $PROFILE"
    chmod +x "$SETUP_SCRIPT"
    PROFILE="$PROFILE" SKIP_STEPS="$SKIP_STEPS" "$SETUP_SCRIPT" bootstrap
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
