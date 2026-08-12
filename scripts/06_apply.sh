#!/usr/bin/env bash
# Reconcile chezmoi-managed files only. Package and service provisioning are
# deliberately separate so daily dotfile application is unprivileged.

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

info "Applying profile: $PROFILE"
PROFILE="$PROFILE" chezmoi --source "$DOTFILES_DIR" apply
info "Dotfiles applied. Run 'make packages', 'make services', or 'make doctor' separately."
