#!/usr/bin/env bash
# Show what reconciliation would change. This script is read-only.

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

section "Chezmoi diff"
chezmoi --source "$DOTFILES_DIR" diff --no-pager

if [[ "$OS" == Darwin ]]; then
    BREWFILE="$(brewfile_for_profile)"
    section "Homebrew bundle check"
    if brew bundle check --file="$BREWFILE"; then
        printf 'satisfied\n'
    else
        warn "Homebrew dependencies are missing"
    fi
else
    section "Fedora package check"
    missing=0
    while IFS= read -r package_file; do
        while IFS= read -r package; do
            rpm -q --quiet "$package" || { printf 'missing: %s\n' "$package"; missing=1; }
        done < <(read_package_file "$package_file")
    done < <(fedora_package_files)
    (( missing == 0 )) && printf 'satisfied\n'
fi

section "Full desired-state audit"
PROFILE="$PROFILE" "$SCRIPT_DIR/04_audit.sh"
