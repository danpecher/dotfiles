#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
PROFILE="${PROFILE:-personal}"
SKIP_STEPS="${SKIP_STEPS:-}"
if [[ "${SKIP_KANATA:-0}" == 1 ]]; then
    SKIP_STEPS="${SKIP_STEPS:+$SKIP_STEPS,}kanata"
fi
OS="$(uname -s)"

export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1

info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
fail() { printf '[FAIL] %s\n' "$*" >&2; }
section() { printf '\n%s\n' "$*"; }

skip_step() {
    case ",${SKIP_STEPS// /,}," in
        *,"$1",*) return 0 ;;
        *) return 1 ;;
    esac
}

brewfile_for_profile() {
    case "$PROFILE" in
        personal|full)
            printf '%s/Brewfile\n' "$DOTFILES_DIR"
            ;;
        minimal|work)
            printf '%s/Brewfile.minimal\n' "$DOTFILES_DIR"
            ;;
        *)
            fail "Unknown PROFILE=$PROFILE (expected personal or minimal)"
            return 2
            ;;
    esac
}

fedora_package_files() {
    printf '%s/packages/fedora-common.txt\n' "$DOTFILES_DIR"
    if [[ "$PROFILE" == personal || "$PROFILE" == full ]]; then
        printf '%s/packages/fedora-sway.txt\n' "$DOTFILES_DIR"
    fi
}

read_package_file() {
    sed -E 's/[[:space:]]*#.*$//; /^[[:space:]]*$/d' "$1"
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        fail "Required command is missing: $1"
        return 1
    }
}

normalize_brew_names() {
    sed 's#.*/##' | LC_ALL=C sort -u
}

list_vscode_extensions() {
    local manifest
    [[ -d "$HOME/.vscode/extensions" ]] || return 0
    for manifest in "$HOME"/.vscode/extensions/*/package.json; do
        [[ -f "$manifest" ]] || continue
        jq -r 'select(.publisher and .name) | "\(.publisher).\(.name)"' "$manifest"
    done | tr '[:upper:]' '[:lower:]' | LC_ALL=C sort -u
}
