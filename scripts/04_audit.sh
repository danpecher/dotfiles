#!/usr/bin/env bash
# Read-only desired-state audit. Exits non-zero when drift is found.

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
source "$SCRIPT_DIR/macos-defaults-lib.sh"

BREWFILE=""
[[ "$OS" == Darwin ]] && BREWFILE="$(brewfile_for_profile)"
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

capture_checked() {
    local title="$1"
    local output="$2"
    shift 2
    local errors="$output.stderr"
    if "$@" > "$output" 2> "$errors"; then
        rm -f "$errors"
        return 0
    fi

    section "$title"
    fail "command failed: $*"
    [[ ! -s "$errors" ]] || sed 's/^/  /' "$errors" >&2
    : > "$output"
    drift=1
    return 1
}

section "Profile"
if [[ "$OS" == Darwin ]]; then
    printf '%s (%s)\n' "$PROFILE" "$BREWFILE"
else
    printf '%s (%s package manifests)\n' "$PROFILE" "${LINUX_DISTRO:-unsupported Linux}"
fi

section "Chezmoi"
if capture_checked "Chezmoi audit failed" "$TMP_DIR/chezmoi-status" \
    chezmoi --source "$DOTFILES_DIR" status; then
    if [[ -s "$TMP_DIR/chezmoi-status" ]]; then
        cat "$TMP_DIR/chezmoi-status"
        drift=1
    else
        printf 'clean\n'
    fi
fi

if [[ "$OS" == Darwin ]] && command -v brew >/dev/null 2>&1; then
    brew_inventory_ok=1
    capture_checked "Homebrew Brewfile formula audit failed" "$TMP_DIR/wanted-brews.raw" \
        brew bundle list --file="$BREWFILE" --brews || brew_inventory_ok=0
    capture_checked "Homebrew installed formula audit failed" "$TMP_DIR/all-brews.raw" \
        brew list --formula || brew_inventory_ok=0
    capture_checked "Homebrew leaf audit failed" "$TMP_DIR/leaf-brews.raw" \
        brew leaves || brew_inventory_ok=0
    capture_checked "Homebrew Brewfile cask audit failed" "$TMP_DIR/wanted-casks.raw" \
        brew bundle list --file="$BREWFILE" --casks || brew_inventory_ok=0
    capture_checked "Homebrew installed cask audit failed" "$TMP_DIR/all-casks.raw" \
        brew list --cask || brew_inventory_ok=0

    if (( brew_inventory_ok )); then
        normalize_brew_names < "$TMP_DIR/wanted-brews.raw" > "$TMP_DIR/wanted-brews"
        normalize_brew_names < "$TMP_DIR/all-brews.raw" > "$TMP_DIR/all-brews"
        normalize_brew_names < "$TMP_DIR/leaf-brews.raw" > "$TMP_DIR/leaf-brews"
        normalize_brew_names < "$TMP_DIR/wanted-casks.raw" > "$TMP_DIR/wanted-casks"
        LC_ALL=C sort -u < "$TMP_DIR/all-casks.raw" > "$TMP_DIR/all-casks"

        comm -23 "$TMP_DIR/wanted-brews" "$TMP_DIR/all-brews" > "$TMP_DIR/missing-brews"
        comm -23 "$TMP_DIR/leaf-brews" "$TMP_DIR/wanted-brews" > "$TMP_DIR/extra-brews"
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
    fi
elif [[ "$OS" == Linux && -n "$LINUX_FAMILY" ]]; then
    : > "$TMP_DIR/missing-linux"
    while IFS= read -r package_file; do
        while IFS= read -r package; do
            linux_package_installed "$package" || printf '%s\n' "$package" >> "$TMP_DIR/missing-linux"
        done < <(read_package_file "$package_file")
    done < <(linux_package_files)
    LC_ALL=C sort -u -o "$TMP_DIR/missing-linux" "$TMP_DIR/missing-linux"
    report_file "Missing $LINUX_DISTRO packages" "$TMP_DIR/missing-linux"
else
    section "Packages"
    fail "Unsupported package backend for $OS"
    drift=1
fi

if command -v jq >/dev/null 2>&1 && command -v brew >/dev/null 2>&1; then
    vscode_inventory_ok=1
    capture_checked "VS Code Brewfile extension audit failed" "$TMP_DIR/wanted-vscode.raw" \
        brew bundle list --file="$BREWFILE" --vscode || vscode_inventory_ok=0
    capture_checked "Installed VS Code extension audit failed" "$TMP_DIR/all-vscode.raw" \
        list_vscode_extensions || vscode_inventory_ok=0
    if (( vscode_inventory_ok )); then
        tr '[:upper:]' '[:lower:]' < "$TMP_DIR/wanted-vscode.raw" | LC_ALL=C sort -u > "$TMP_DIR/wanted-vscode"
        LC_ALL=C sort -u < "$TMP_DIR/all-vscode.raw" > "$TMP_DIR/all-vscode"
        comm -23 "$TMP_DIR/wanted-vscode" "$TMP_DIR/all-vscode" > "$TMP_DIR/missing-vscode"
        comm -23 "$TMP_DIR/all-vscode" "$TMP_DIR/wanted-vscode" > "$TMP_DIR/extra-vscode"
        report_file "Missing VS Code extensions" "$TMP_DIR/missing-vscode"
        if [[ "$PROFILE" == personal || "$PROFILE" == full ]]; then
            report_file "Undeclared VS Code extensions" "$TMP_DIR/extra-vscode"
        fi
    fi
elif [[ "$OS" == Linux ]] && command -v jq >/dev/null 2>&1 && command -v code >/dev/null 2>&1; then
    read_package_file "$DOTFILES_DIR/packages/vscode-extensions.txt" \
        | tr '[:upper:]' '[:lower:]' | LC_ALL=C sort -u > "$TMP_DIR/wanted-vscode"
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
    # configuration rendered from dot_config/mise/config.toml.tmpl.
    if capture_checked "mise audit failed" "$TMP_DIR/missing-mise" \
        mise ls --global --missing; then
        report_file "Missing mise tools" "$TMP_DIR/missing-mise"
    fi
else
    section "mise"
    fail "mise is not installed"
    drift=1
fi

if [[ "$(uname)" == Darwin && ( "$PROFILE" == personal || "$PROFILE" == full ) ]]; then
    if ! audit_managed_defaults "$TMP_DIR/macos-defaults"; then
        report_file "macOS defaults drift (domain, key, actual, expected)" "$TMP_DIR/macos-defaults"
    fi
fi

if skip_step kanata && [[ "$PROFILE" == personal || "$PROFILE" == full ]]; then
    section "Kanata service"
    printf 'skipped (SKIP_STEPS includes kanata)\n'
elif [[ "$OS" == Linux && ( "$PROFILE" == personal || "$PROFILE" == full ) ]] && ! command -v kanata >/dev/null 2>&1; then
    section "Kanata service"
    fail "Kanata is not installed"
    drift=1
elif [[ "$PROFILE" == personal || "$PROFILE" == full ]] && command -v kanata >/dev/null 2>&1; then
    section "Kanata service"
    karabiner_config="$HOME/.config/karabiner/karabiner.json"
    if [[ "$OS" == Darwin ]] && command -v jq >/dev/null 2>&1 && [[ -f "$karabiner_config" ]] &&
        jq -e '
            .profiles[]?
            | select(.selected == true)
            | ((.simple_modifications // []) | length > 0)
              or ((.complex_modifications.rules // []) | length > 0)
        ' "$karabiner_config" >/dev/null; then
        fail "Karabiner mappings are enabled and can conflict with Kanata"
        drift=1
    fi
    if [[ "$OS" == Darwin ]] && launchctl print system/homebrew.mxcl.kanata 2>/dev/null | grep -q 'state = running'; then
        printf 'running\n'
    elif [[ "$OS" == Linux ]] && systemctl is-active --quiet kanata.service; then
        printf 'running\n'
    else
        if [[ "$OS" == Darwin ]]; then
            fail "not running (run: sudo brew services start kanata)"
        else
            fail "not running (run: sudo systemctl enable --now kanata.service)"
        fi
        drift=1
    fi
fi

if [[ "$OS" == Linux ]]; then
    section "Tailscale service"
    if systemctl is-active --quiet tailscaled.service; then
        printf 'running\n'
    else
        fail "not running (run: sudo systemctl enable --now tailscaled.service)"
        drift=1
    fi
fi

section "Result"
if (( drift )); then
    fail "drift detected"
    exit 1
fi
printf 'clean\n'
