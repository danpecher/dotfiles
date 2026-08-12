#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

for script in "$SCRIPT_DIR"/*.sh; do
    bash -n "$script"
done
awk -F '\t' '
    /^#/ || NF == 0 { next }
    NF != 5 { exit 1 }
    $1 !~ /^(user|system)$/ { exit 1 }
    $4 !~ /^(bool|int|float|string)$/ { exit 1 }
' "$SCRIPT_DIR/macos-defaults.tsv"
bash -n "$DOTFILES_DIR/bin/executable_ios-build"
ruby -c "$DOTFILES_DIR/Brewfile" >/dev/null
ruby -c "$DOTFILES_DIR/Brewfile.minimal" >/dev/null
jq empty "$DOTFILES_DIR/dot_config/tmux-palette/theme.json"
jq empty "$DOTFILES_DIR/dot_config/tmux-palette/palettes/tools.json"
yq eval '.' "$DOTFILES_DIR/dot_config/private_gh/private_config.yml" >/dev/null
if command -v luac >/dev/null 2>&1; then
    luac -p "$DOTFILES_DIR/dot_hammerspoon/init.lua"
    luac -p "$DOTFILES_DIR/dot_hammerspoon/window_chooser.lua"
fi
# VS Code stores JSONC. The tracked files currently use full-line comments and
# trailing commas, so normalize those features before validating as JSON.
validate_jsonc() {
    ruby -rjson -e '
        text = File.read(ARGV.fetch(0))
        text.gsub!(/^\s*\/\/.*$\n?/, "")
        text.gsub!(/,\s*([}\]])/, "\\1")
        JSON.parse(text)
    ' "$1"
}
validate_jsonc "$DOTFILES_DIR/private_Library/Application Support/Code/User/settings.json"
validate_jsonc "$DOTFILES_DIR/private_Library/Application Support/Code/User/keybindings.json"
validate_jsonc "$DOTFILES_DIR/private_Library/Application Support/Code/User/snippets/pie.code-snippets"

if command -v kanata >/dev/null 2>&1; then
    kanata --check -c "$DOTFILES_DIR/dot_config/kanata/kanata.kbd" >/dev/null
fi

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-validate.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/home"

defaults_home="$tmp_dir/defaults-home"
mkdir -p "$defaults_home"
HOME="$defaults_home" bash -c 'source "$1"; prepare_managed_defaults' \
    validate-defaults "$SCRIPT_DIR/macos-defaults-lib.sh"
test -d "$defaults_home/Downloads/screenshots"

for profile in personal minimal; do
    init_config="$tmp_dir/init-$profile.toml"
    PROFILE="$profile" chezmoi --persistent-state "$tmp_dir/init-$profile.boltdb" \
        init --source "$DOTFILES_DIR" --config-path "$init_config" \
        --destination "$tmp_dir/home" --no-tty --promptDefaults
    grep -q "profile = \"$profile\"" "$init_config"

    config="$tmp_dir/$profile.toml"
    {
        printf 'sourceDir = "%s"\n' "$DOTFILES_DIR"
        printf 'destDir = "%s"\n' "$tmp_dir/home"
        printf '[data]\n'
        printf 'name = "Validation User"\n'
        printf 'email = "validation@example.invalid"\n'
        printf 'github_username = ""\n'
        printf 'profile = "%s"\n' "$profile"
    } > "$config"
    PROFILE="$profile" chezmoi --config "$config" --source "$DOTFILES_DIR" \
        --destination "$tmp_dir/home" apply --dry-run >/dev/null
done

for profile in personal minimal; do
    rendered_zshrc="$tmp_dir/zshrc-$profile"
    PROFILE="$profile" chezmoi --config "$tmp_dir/$profile.toml" --source "$DOTFILES_DIR" \
        execute-template < "$DOTFILES_DIR/dot_zshrc.tmpl" > "$rendered_zshrc"
    zsh -n "$rendered_zshrc"
done

grep -q '^y # <------- will open yazi on start$' "$tmp_dir/zshrc-personal"
if grep -Eq '^(alias tm=tmuxinator|y # <------- will open yazi on start|export PNPM_HOME=)' \
    "$tmp_dir/zshrc-minimal"; then
    printf 'minimal profile unexpectedly includes personal shell behavior\n' >&2
    exit 1
fi

if PROFILE=minimal chezmoi --config "$tmp_dir/minimal.toml" --source "$DOTFILES_DIR" managed |
    grep -Eq '^(\.claude|\.hammerspoon|\.config/kanata|\.config/tmux-palette|\.tmux\.conf|\.zprofile|bin/ios-build)'; then
    printf 'minimal profile unexpectedly includes personal targets\n' >&2
    exit 1
fi

rendered_gitconfig="$tmp_dir/gitconfig"
PROFILE=personal chezmoi --config "$tmp_dir/personal.toml" --source "$DOTFILES_DIR" \
    execute-template < "$DOTFILES_DIR/dot_gitconfig.tmpl" > "$rendered_gitconfig"
git config --file "$rendered_gitconfig" --list >/dev/null

rendered_claude_settings="$tmp_dir/claude-settings.json"
PROFILE=personal chezmoi --config "$tmp_dir/personal.toml" --source "$DOTFILES_DIR" \
    execute-template < "$DOTFILES_DIR/private_dot_claude/private_settings.json.tmpl" \
    > "$rendered_claude_settings"
jq empty "$rendered_claude_settings"

printf 'validation passed\n'
