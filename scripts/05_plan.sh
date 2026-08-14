#!/usr/bin/env bash
# Browse the managed-file changes that chezmoi would apply. This is read-only.

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_command delta
chezmoi --source "$DOTFILES_DIR" diff \
    --pager "delta --navigate --line-numbers --paging=always"
