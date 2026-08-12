#!/usr/bin/env bash
# Read-only desired-state audit. Exits non-zero when drift is found.

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

BREWFILE="$(brewfile_for_profile)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-doctor.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT
drift=0

report_file() {
    local title="$1"
    local file="$2"
    if [[ -s "$file" ]]; then
        section "$title"
        sed 's/^/  /' "$file"
        drift=1
    fi
}

section "Profile"
printf '%s (%s)\n' "$PROFILE" "$BREWFILE"

section "Chezmoi"
chezmoi_status="$(chezmoi --source "$DOTFILES_DIR" status || true)"
if [[ -n "$chezmoi_status" ]]; then
    printf '%s\n' "$chezmoi_status"
    drift=1
else
    printf 'clean\n'
fi

if command -v brew >/dev/null 2>&1; then
    brew bundle list --file="$BREWFILE" --brews 2>/dev/null | normalize_brew_names > "$TMP_DIR/wanted-brews"
    brew list --formula 2>/dev/null | normalize_brew_names > "$TMP_DIR/all-brews"
    brew leaves 2>/dev/null | normalize_brew_names > "$TMP_DIR/leaf-brews"
    comm -23 "$TMP_DIR/wanted-brews" "$TMP_DIR/all-brews" > "$TMP_DIR/missing-brews"
    comm -23 "$TMP_DIR/leaf-brews" "$TMP_DIR/wanted-brews" > "$TMP_DIR/extra-brews"

    brew bundle list --file="$BREWFILE" --casks 2>/dev/null | normalize_brew_names > "$TMP_DIR/wanted-casks"
    brew list --cask 2>/dev/null | LC_ALL=C sort -u > "$TMP_DIR/all-casks"
    comm -23 "$TMP_DIR/wanted-casks" "$TMP_DIR/all-casks" > "$TMP_DIR/missing-casks"
    comm -23 "$TMP_DIR/all-casks" "$TMP_DIR/wanted-casks" > "$TMP_DIR/extra-casks"

    report_file "Missing Homebrew formulae" "$TMP_DIR/missing-brews"
    report_file "Missing Homebrew casks" "$TMP_DIR/missing-casks"

    if [[ "$PROFILE" == personal || "$PROFILE" == full ]]; then
        report_file "Undeclared Homebrew leaves" "$TMP_DIR/extra-brews"
        report_file "Undeclared Homebrew casks" "$TMP_DIR/extra-casks"
    else
        section "Additional machine-wide Homebrew packages (informational for minimal profile)"
        cat "$TMP_DIR/extra-brews" "$TMP_DIR/extra-casks" | LC_ALL=C sort -u | sed 's/^/  /'
    fi
else
    section "Homebrew"
    fail "Homebrew is not installed"
    drift=1
fi

if command -v jq >/dev/null 2>&1 && command -v brew >/dev/null 2>&1; then
    brew bundle list --file="$BREWFILE" --vscode 2>/dev/null | tr '[:upper:]' '[:lower:]' | LC_ALL=C sort -u > "$TMP_DIR/wanted-vscode"
    list_vscode_extensions > "$TMP_DIR/all-vscode"
    comm -23 "$TMP_DIR/wanted-vscode" "$TMP_DIR/all-vscode" > "$TMP_DIR/missing-vscode"
    comm -23 "$TMP_DIR/all-vscode" "$TMP_DIR/wanted-vscode" > "$TMP_DIR/extra-vscode"
    report_file "Missing VS Code extensions" "$TMP_DIR/missing-vscode"
    if [[ "$PROFILE" == personal || "$PROFILE" == full ]]; then
        report_file "Undeclared VS Code extensions" "$TMP_DIR/extra-vscode"
    fi
fi

if command -v mise >/dev/null 2>&1; then
    # Ignore project/parent mise.toml files; this audit owns only the global
    # configuration applied from dot_config/mise/config.toml.
    mise ls --global --missing 2>/dev/null > "$TMP_DIR/missing-mise" || true
    report_file "Missing mise tools" "$TMP_DIR/missing-mise"
else
    section "mise"
    fail "mise is not installed"
    drift=1
fi

if [[ "$PROFILE" == personal || "$PROFILE" == full ]] && command -v kanata >/dev/null 2>&1; then
    section "Kanata service"
    if launchctl print system/homebrew.mxcl.kanata >/dev/null 2>&1; then
        printf 'running\n'
    else
        fail "not running (run: sudo brew services start kanata)"
        drift=1
    fi
fi

section "Result"
if (( drift )); then
    fail "drift detected"
    exit 1
fi
printf 'clean\n'
