#!/usr/bin/env bash
# Capture observed machine state for review. This does not change desired state.

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

host="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
host="$(printf '%s' "$host" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9._-' '-')"
OUT_DIR="${SNAPSHOT_DIR:-$DOTFILES_DIR/state/observed/$host}"
mkdir -p "$OUT_DIR"

capture() {
    local output="$1"
    shift
    "$@" > "$OUT_DIR/$output" 2>&1 || true
}

{
    printf 'captured_at=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf 'profile=%s\n' "$PROFILE"
    printf 'hostname=%s\n' "$host"
    printf 'macos=%s\n' "$(sw_vers -productVersion 2>/dev/null || true)"
    printf 'architecture=%s\n' "$(uname -m)"
} > "$OUT_DIR/metadata.txt"

if command -v brew >/dev/null 2>&1; then
    capture brew-leaves.txt brew leaves
    capture brew-formulae.txt brew list --formula --versions
    capture brew-casks.txt brew list --cask --versions
    brew services list 2>&1 | sed 's/[[:space:]]*$//' > "$OUT_DIR/brew-services.txt" || true
fi

if [[ "${SNAPSHOT_MAS:-0}" == 1 ]] && command -v mas >/dev/null 2>&1; then
    capture mas-apps.txt mas list
else
    printf 'Set SNAPSHOT_MAS=1 to query the signed-in App Store account.\n' > "$OUT_DIR/mas-apps.txt"
fi

if command -v jq >/dev/null 2>&1 && [[ -d "$HOME/.vscode/extensions" ]]; then
    {
        for manifest in "$HOME"/.vscode/extensions/*/package.json; do
            [[ -f "$manifest" ]] || continue
            jq -r 'select(.publisher and .name and .version) | "\(.publisher).\(.name)@\(.version)"' "$manifest"
        done
    } | LC_ALL=C sort -u > "$OUT_DIR/vscode-extensions.txt"
fi

if command -v mise >/dev/null 2>&1; then
    capture mise-tools.txt mise ls --global
fi

{
    find /Applications -maxdepth 1 -type d -name '*.app' -print 2>/dev/null || true
    find "$HOME/Applications" -maxdepth 1 -type d -name '*.app' -print 2>/dev/null || true
} | sed "s#^$HOME#~#" | LC_ALL=C sort -u > "$OUT_DIR/applications.txt"

if [[ "${SNAPSHOT_GUI:-0}" == 1 ]] && command -v osascript >/dev/null 2>&1; then
    osascript -e 'tell application "System Events" to get the name of every login item' \
        > "$OUT_DIR/login-items.txt" 2>&1 || true
else
    printf 'Set SNAPSHOT_GUI=1 to query login items interactively.\n' > "$OUT_DIR/login-items.txt"
fi

capture system-extensions.txt systemextensionsctl list

info "Snapshot written to $OUT_DIR"
info "Raw snapshots are git-ignored private diagnostics; review files in place."
