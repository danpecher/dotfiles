#!/usr/bin/env bash
# Preview only. Deliberately has no --force mode.

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

if [[ "$OS" == Darwin ]]; then
    BREWFILE="$(brewfile_for_profile)"
    brew bundle cleanup --file="$BREWFILE"
else
    case "$LINUX_FAMILY" in
        fedora) command_hint='dnf repoquery --userinstalled' ;;
        debian) command_hint='apt-mark showmanual' ;;
        arch) command_hint='pacman -Qqe' ;;
        *) command_hint='your distribution package manager' ;;
    esac
    warn "Linux cleanup is intentionally not automated; review: $command_hint"
fi
