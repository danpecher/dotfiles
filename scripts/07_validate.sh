#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

for script in "$SCRIPT_DIR"/*.sh; do
    bash -n "$script"
done
grep -q '^#!/usr/bin/env bash$' "$SCRIPT_DIR/01_bootstrap-linux.sh"
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
grep -q '^\[colors-dark\]$' "$DOTFILES_DIR/dot_config/foot/foot.ini"
if grep -q '^\[colors\]$' "$DOTFILES_DIR/dot_config/foot/foot.ini"; then
    printf 'Foot config uses the deprecated [colors] section\n' >&2
    exit 1
fi
grep -q '^font=JetBrainsMono Nerd Font Mono:' "$DOTFILES_DIR/dot_config/foot/foot.ini"
grep -q '^dpi-aware=yes$' "$DOTFILES_DIR/dot_config/foot/foot.ini"
grep -q '^gamma-correct-blending=yes$' "$DOTFILES_DIR/dot_config/foot/foot.ini"
grep -q '^    natural_scroll enabled$' "$DOTFILES_DIR/dot_config/sway/config"
grep -q '^if command -v direnv &>/dev/null; then$' "$DOTFILES_DIR/dot_zshrc.tmpl"
grep -q 'atuin init zsh --disable-up-arrow' "$DOTFILES_DIR/dot_zshrc.tmpl"
grep -q "exec tmux new-session -A -s main" "$DOTFILES_DIR/dot_zshrc.tmpl"
tmux_line="$(grep -n 'exec tmux new-session -A -s main' "$DOTFILES_DIR/dot_zshrc.tmpl" | cut -d: -f1)"
yazi_line="$(grep -n '^y # <------- will open yazi on start$' "$DOTFILES_DIR/dot_zshrc.tmpl" | cut -d: -f1)"
if [[ -z "$tmux_line" || -z "$yazi_line" || "$tmux_line" -ge "$yazi_line" ]]; then
    printf 'tmux auto-start must occur before Yazi auto-start\n' >&2
    exit 1
fi
grep -q 'run-shell ~/.config/tmux/plugins/tmux-gruvbox/gruvbox-tpm.tmux' \
    "$DOTFILES_DIR/dot_tmux.conf"
grep -q '9577de1ae84ec523df16fc69bac5338b89497a5b4fb91489e2dcb79dc06ac2b5' \
    "$SCRIPT_DIR/02_setup.sh"
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
validate_jsonc "$DOTFILES_DIR/dot_config/waybar/config.jsonc"
jq empty "$DOTFILES_DIR/dot_config/Code/User/keybindings.json"

for package_file in "$DOTFILES_DIR"/packages/fedora-*.txt; do
    if read_package_file "$package_file" | LC_ALL=C sort | uniq -d | grep -q .; then
        printf 'duplicate Fedora package in %s\n' "$package_file" >&2
        exit 1
    fi
done
for package in atuin direnv pgcli tailscale; do
    grep -q "^$package$" "$DOTFILES_DIR/packages/fedora-common.txt"
done
if read_package_file "$DOTFILES_DIR/packages/vscode-extensions.txt" \
    | LC_ALL=C sort | uniq -d | grep -q .; then
    printf 'duplicate VS Code extension in Fedora manifest\n' >&2
    exit 1
fi
grep -q '^baseurl=https://packages.microsoft.com/yumrepos/vscode$' \
    "$DOTFILES_DIR/packages/vscode.repo"
comm -12 \
    <(read_package_file "$DOTFILES_DIR/packages/fedora-common.txt" | LC_ALL=C sort) \
    <(read_package_file "$DOTFILES_DIR/packages/fedora-sway.txt" | LC_ALL=C sort) \
    | if grep -q .; then
        printf 'Fedora package appears in both common and Sway manifests\n' >&2
        exit 1
    fi
grep -q '^ExecStart=/usr/local/bin/kanata --cfg {{HOME}}/.config/kanata/kanata.kbd$' \
    "$DOTFILES_DIR/systemd/kanata.service.tmpl"
grep -q 'Skipping Kanata installation (SKIP_STEPS includes kanata)' "$SCRIPT_DIR/02_setup.sh"
grep -q 'Skipping GitHub authentication (SKIP_STEPS includes github)' "$SCRIPT_DIR/02_setup.sh"
grep -q 'skipped (SKIP_STEPS includes kanata)' "$SCRIPT_DIR/04_audit.sh"

if command -v kanata >/dev/null 2>&1; then
    kanata --check -c "$DOTFILES_DIR/dot_config/kanata/kanata.kbd" >/dev/null
fi

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-validate.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/home"

SKIP_STEPS='github, kanata' bash -c '
    source "$1"
    skip_step github && skip_step kanata && ! skip_step nonexistent
' validate-skip-steps "$SCRIPT_DIR/lib.sh"

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
        printf 'github_auth = true\n'
        printf 'profile = "%s"\n' "$profile"
    } > "$config"
    PROFILE="$profile" chezmoi --config "$config" --source "$DOTFILES_DIR" \
        --destination "$tmp_dir/home" apply --dry-run >/dev/null
done

githubless_init="$tmp_dir/init-githubless.toml"
PROFILE=personal SKIP_STEPS=github \
    chezmoi --persistent-state "$tmp_dir/init-githubless.boltdb" \
    init --source "$DOTFILES_DIR" --config-path "$githubless_init" \
    --destination "$tmp_dir/home" --no-tty --promptDefaults
grep -q '^    github_auth = false$' "$githubless_init"
grep -q '^    github_username = ""$' "$githubless_init"

for profile in personal minimal; do
    rendered_zshrc="$tmp_dir/zshrc-$profile"
    PROFILE="$profile" chezmoi --config "$tmp_dir/$profile.toml" --source "$DOTFILES_DIR" \
        execute-template < "$DOTFILES_DIR/dot_zshrc.tmpl" > "$rendered_zshrc"
    zsh -n "$rendered_zshrc"
done

rendered_zprofile="$tmp_dir/zprofile-personal"
PROFILE=personal chezmoi --config "$tmp_dir/personal.toml" --source "$DOTFILES_DIR" \
    execute-template < "$DOTFILES_DIR/dot_zprofile.tmpl" > "$rendered_zprofile"
zsh -n "$rendered_zprofile"

rendered_ssh_config="$tmp_dir/ssh-config-personal"
PROFILE=personal chezmoi --config "$tmp_dir/personal.toml" --source "$DOTFILES_DIR" \
    execute-template < "$DOTFILES_DIR/private_dot_ssh/config.tmpl" > "$rendered_ssh_config"
ssh -G -T -F "$rendered_ssh_config" github.com >/dev/null

grep -q '^y # <------- will open yazi on start$' "$tmp_dir/zshrc-personal"
if grep -Eq '^(alias tm=tmuxinator|y # <------- will open yazi on start|export PNPM_HOME=)' \
    "$tmp_dir/zshrc-minimal"; then
    printf 'minimal profile unexpectedly includes personal shell behavior\n' >&2
    exit 1
fi

rendered_mise="$tmp_dir/mise-personal.toml"
PROFILE=personal chezmoi --config "$tmp_dir/personal.toml" --source "$DOTFILES_DIR" \
    execute-template < "$DOTFILES_DIR/dot_config/mise/config.toml.tmpl" > "$rendered_mise"
if grep -Eq '^(starship|lazygit|yazi|"gem:tmuxinator"|"pipx:mitmproxy") = ' "$rendered_mise"; then
    printf 'macOS mise config unexpectedly includes Linux-managed tools\n' >&2
    exit 1
fi

if PROFILE=minimal chezmoi --config "$tmp_dir/minimal.toml" --source "$DOTFILES_DIR" managed |
    grep -Eq '^(\.hammerspoon|\.config/kanata|\.config/tmux-palette|\.tmux\.conf|\.zprofile|bin/ios-build)'; then
    printf 'minimal profile unexpectedly includes personal targets\n' >&2
    exit 1
fi

rendered_gitconfig="$tmp_dir/gitconfig"
PROFILE=personal chezmoi --config "$tmp_dir/personal.toml" --source "$DOTFILES_DIR" \
    execute-template < "$DOTFILES_DIR/dot_gitconfig.tmpl" > "$rendered_gitconfig"
git config --file "$rendered_gitconfig" --list >/dev/null

githubless_config="$tmp_dir/githubless.toml"
sed 's/github_auth = true/github_auth = false/' "$tmp_dir/personal.toml" > "$githubless_config"
githubless_gitconfig="$tmp_dir/gitconfig-githubless"
PROFILE=personal chezmoi --config "$githubless_config" --source "$DOTFILES_DIR" \
    execute-template < "$DOTFILES_DIR/dot_gitconfig.tmpl" > "$githubless_gitconfig"
if git config --file "$githubless_gitconfig" --get-regexp '^url\..*\.insteadof$' >/dev/null; then
    printf 'GitHub-less config unexpectedly rewrites HTTPS URLs to SSH\n' >&2
    exit 1
fi

rendered_linux_vscode_settings="$tmp_dir/linux-vscode-settings.jsonc"
PROFILE=personal chezmoi --config "$tmp_dir/personal.toml" --source "$DOTFILES_DIR" \
    execute-template < "$DOTFILES_DIR/dot_config/Code/User/settings.json.tmpl" \
    > "$rendered_linux_vscode_settings"
validate_jsonc "$rendered_linux_vscode_settings"

printf 'validation passed\n'
