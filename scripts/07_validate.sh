#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

for script in "$SCRIPT_DIR"/*.sh; do
    bash -n "$script"
done
bash -n "$DOTFILES_DIR/bin/executable_ios-build"
zsh -n "$DOTFILES_DIR/dot_zshrc"
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
for profile in personal minimal; do
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
    chezmoi --config "$config" --source "$DOTFILES_DIR" --destination "$tmp_dir/home" apply --dry-run >/dev/null
done

rendered_gitconfig="$tmp_dir/gitconfig"
chezmoi --config "$tmp_dir/personal.toml" --source "$DOTFILES_DIR" \
    execute-template < "$DOTFILES_DIR/dot_gitconfig.tmpl" > "$rendered_gitconfig"
git config --file "$rendered_gitconfig" --list >/dev/null

rendered_claude_settings="$tmp_dir/claude-settings.json"
chezmoi --config "$tmp_dir/personal.toml" --source "$DOTFILES_DIR" \
    execute-template < "$DOTFILES_DIR/private_dot_claude/private_settings.json.tmpl" \
    > "$rendered_claude_settings"
jq empty "$rendered_claude_settings"

printf 'validation passed\n'
