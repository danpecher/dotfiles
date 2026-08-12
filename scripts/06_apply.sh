#!/usr/bin/env bash
# Reconcile additive desired state. Never removes undeclared software.

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

info "Applying profile: $PROFILE"
chezmoi --source "$DOTFILES_DIR" apply
PROFILE="$PROFILE" "$SCRIPT_DIR/02_setup.sh"

if [[ "${APPLY_MACOS_DEFAULTS:-0}" == 1 ]]; then
    "$SCRIPT_DIR/03_macos-defaults.sh"
else
    info "macOS defaults skipped; run 'make macos-defaults' explicitly"
fi

info "Apply complete. Running doctor..."
PROFILE="$PROFILE" "$SCRIPT_DIR/04_audit.sh"
