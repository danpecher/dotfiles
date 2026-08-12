#!/usr/bin/env bash
# Show what reconciliation would change. This script is read-only.

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

BREWFILE="$(brewfile_for_profile)"

section "Chezmoi diff"
chezmoi --source "$DOTFILES_DIR" diff --no-pager

section "Homebrew bundle check"
if brew bundle check --file="$BREWFILE"; then
    printf 'satisfied\n'
else
    warn "Homebrew dependencies are missing"
fi

section "Full desired-state audit"
PROFILE="$PROFILE" "$SCRIPT_DIR/04_audit.sh"
