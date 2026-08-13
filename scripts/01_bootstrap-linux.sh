#!/usr/bin/env bash
# Interactive Fedora bootstrap. Fedora Sway Spin is preferred, but this also
# adds the Sway package set to a regular Fedora Workstation installation.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_REPO="danpecher/dotfiles"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Code/dotfiles}"
DOTFILES_REF="${DOTFILES_REF:-master}"
PROFILE="${PROFILE:-personal}"
SKIP_KANATA="${SKIP_KANATA:-0}"
REPO_ROOT=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    candidate_root="$(cd "$SCRIPT_DIR/.." && pwd)"
    [[ -d "$candidate_root/.git" ]] && REPO_ROOT="$candidate_root"
fi

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

[[ "$(uname -s)" == Linux && -f /etc/fedora-release ]] || \
    error "This bootstrap supports Fedora Linux only."
[[ -t 0 ]] || error "This script requires an interactive terminal for sudo and review prompts."

echo ""
echo "=========================================="
echo "  Fedora Sway Bootstrap"
echo "=========================================="
echo ""

info "Updating Fedora package metadata and installing bootstrap tools..."
sudo dnf upgrade --refresh -y
sudo dnf install -y chezmoi curl gh git openssh-clients

if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
    info "Generating an SSH key for GitHub..."
    install -d -m 0700 "$HOME/.ssh"
    read -r -p "Enter your email for SSH key: " ssh_email
    ssh-keygen -t ed25519 -C "$ssh_email" -f "$HOME/.ssh/id_ed25519"
fi

eval "$(ssh-agent -s)" >/dev/null
ssh-add "$HOME/.ssh/id_ed25519" >/dev/null 2>&1 || true
if ! gh auth status >/dev/null 2>&1; then
    info "Authenticating with GitHub..."
    gh auth login -p ssh -w
fi

key_fingerprint="$(ssh-keygen -lf "$HOME/.ssh/id_ed25519.pub" | awk '{print $2}')"
if ! gh ssh-key list 2>/dev/null | grep -q "$key_fingerprint"; then
    gh ssh-key add "$HOME/.ssh/id_ed25519.pub" -t "$(hostname)-$(date +%Y%m%d)"
fi

if [[ -n "$REPO_ROOT" ]]; then
    DOTFILES_DIR="$REPO_ROOT"
    info "Using local checkout: $DOTFILES_DIR"
elif [[ -d "$DOTFILES_DIR/.git" ]]; then
    info "Updating canonical checkout: $DOTFILES_DIR"
    git -C "$DOTFILES_DIR" pull --ff-only
else
    info "Cloning canonical checkout to $DOTFILES_DIR..."
    mkdir -p "$(dirname "$DOTFILES_DIR")"
    git clone --branch "$DOTFILES_REF" "git@github.com:$DOTFILES_REPO.git" "$DOTFILES_DIR"
fi

export PROFILE SKIP_KANATA
chezmoi init --source="$DOTFILES_DIR"

echo ""
info "Reviewing destination changes before apply..."
chezmoi --source="$DOTFILES_DIR" status
chezmoi --source="$DOTFILES_DIR" diff --no-pager
echo ""
read -r -p "Apply these chezmoi changes? [y/N] " apply_dotfiles
if [[ ! "$apply_dotfiles" =~ ^[Yy]$ ]]; then
    warn "Dotfiles were not applied. Bootstrap stopped before package and service setup."
    exit 0
fi
chezmoi --source="$DOTFILES_DIR" apply --interactive

PROFILE="$PROFILE" SKIP_KANATA="$SKIP_KANATA" \
    "$DOTFILES_DIR/scripts/02_setup.sh" bootstrap

echo ""
success "Fedora bootstrap complete"
if [[ "$PROFILE" == personal ]]; then
    info "Choose Sway from the display manager, or install Fedora Sway Spin directly on the next machine."
fi
info "Log out and back in if the login shell or desktop session changed."
