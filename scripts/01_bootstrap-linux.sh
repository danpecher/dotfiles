#!/usr/bin/env bash
# Interactive Linux bootstrap for Fedora, Debian/Ubuntu, and Arch families.
# The personal profile installs the same portable Sway desktop on each.

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

detect_linux_family() {
    # shellcheck disable=SC1091
    source /etc/os-release
    case " ${ID:-} ${ID_LIKE:-} " in
        *" fedora "* | *" rhel "*) printf 'fedora\n' ;;
        *" debian "* | *" ubuntu "*) printf 'debian\n' ;;
        *" arch "*) printf 'arch\n' ;;
        *) return 1 ;;
    esac
}

install_bootstrap_packages() {
    case "$LINUX_FAMILY" in
        fedora)
            sudo dnf upgrade --refresh -y
            sudo dnf install -y chezmoi curl gh git openssh-clients
            ;;
        debian)
            sudo apt-get update
            sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
                curl gh git openssh-client
            if ! command -v chezmoi >/dev/null 2>&1; then
                temp_installer="$(mktemp "${TMPDIR:-/tmp}/chezmoi-install.XXXXXX")"
                curl -fsLS https://get.chezmoi.io -o "$temp_installer"
                install -d -m 0755 "$HOME/.local/bin"
                sh "$temp_installer" -b "$HOME/.local/bin"
                rm -f "$temp_installer"
            fi
            export PATH="$HOME/.local/bin:$PATH"
            ;;
        arch)
            sudo pacman -Syu --needed --noconfirm \
                chezmoi curl github-cli git openssh
            ;;
    esac
}

[[ "$(uname -s)" == Linux && -r /etc/os-release ]] || \
    error "This bootstrap requires Linux with /etc/os-release."
LINUX_FAMILY="$(detect_linux_family || true)"
[[ -n "$LINUX_FAMILY" ]] || \
    error "Supported Linux families are Fedora, Debian/Ubuntu, and Arch."
# shellcheck disable=SC1091
source /etc/os-release
[[ -t 0 ]] || error "This script requires an interactive terminal for sudo and review prompts."

echo ""
echo "=========================================="
echo "  ${PRETTY_NAME:-Linux} Sway Bootstrap"
echo "=========================================="
echo ""

info "Updating package metadata and installing bootstrap tools..."
install_bootstrap_packages

if skip_step github; then
    warn "Skipping SSH key setup and GitHub authentication"
else
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
fi

if [[ -n "$REPO_ROOT" ]]; then
    DOTFILES_DIR="$REPO_ROOT"
    info "Using local checkout: $DOTFILES_DIR"
elif [[ -d "$DOTFILES_DIR/.git" ]]; then
    info "Updating canonical checkout: $DOTFILES_DIR"
    git -C "$DOTFILES_DIR" pull --ff-only "$(dotfiles_repo_url)" "$DOTFILES_REF"
else
    info "Cloning canonical checkout to $DOTFILES_DIR..."
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
read -r -p "Apply these chezmoi changes? [y/N] " apply_dotfiles
if [[ ! "$apply_dotfiles" =~ ^[Yy]$ ]]; then
    warn "Dotfiles were not applied. Bootstrap stopped before package and service setup."
    exit 0
fi
chezmoi --source="$DOTFILES_DIR" apply --interactive

PROFILE="$PROFILE" SKIP_STEPS="$SKIP_STEPS" \
    "$DOTFILES_DIR/scripts/02_setup.sh" bootstrap

echo ""
success "${PRETTY_NAME:-Linux} bootstrap complete"
if [[ "$PROFILE" == personal ]]; then
    info "Choose Sway from the display manager at your next login."
fi
info "Log out and back in if the login shell or desktop session changed."
