#!/usr/bin/env bash
# Preview only. Deliberately has no --force mode.

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

if [[ "$OS" == Darwin ]]; then
    BREWFILE="$(brewfile_for_profile)"
    brew bundle cleanup --file="$BREWFILE"
else
    warn "Fedora cleanup is intentionally not automated; review: dnf repoquery --userinstalled"
fi
