#!/usr/bin/env bash
# Render both profiles on Linux and parse the Sway configuration. This uses a
# disposable container and does not change the host.

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
require_command docker

docker run --rm -i -v "$DOTFILES_DIR:/src:ro" alpine:latest sh -s <<'LINUX_VALIDATION'
set -eu
apk add --no-cache chezmoi git jq libcap openssh-client sway zsh >/dev/null 2>&1
mkdir -p /tmp/home

for profile in personal minimal; do
    config="/tmp/$profile.toml"
    printf 'sourceDir = "/src"\ndestDir = "/tmp/home"\n[data]\nname = "Validation User"\nemail = "validation@example.invalid"\ngithub_username = ""\nprofile = "%s"\n' \
        "$profile" > "$config"
    PROFILE="$profile" chezmoi --config "$config" --source /src \
        --destination /tmp/home apply --dry-run >/dev/null
    PROFILE="$profile" chezmoi --config "$config" --source /src \
        execute-template < /src/dot_zshrc.tmpl > "/tmp/zshrc-$profile"
    zsh -n "/tmp/zshrc-$profile"
    PROFILE="$profile" chezmoi --config "$config" --source /src \
        execute-template < /src/dot_config/mise/config.toml.tmpl > "/tmp/mise-$profile.toml"
done

for tool in starship lazygit yazi; do
    grep -q "^$tool = \"latest\"$" /tmp/mise-personal.toml
    grep -q "^$tool = \"latest\"$" /tmp/mise-minimal.toml
done

PROFILE=personal chezmoi --config /tmp/personal.toml --source /src \
    execute-template < /src/dot_zprofile.tmpl > /tmp/zprofile-personal
zsh -n /tmp/zprofile-personal
PROFILE=personal chezmoi --config /tmp/personal.toml --source /src \
    execute-template < /src/private_dot_ssh/config.tmpl > /tmp/ssh-config-personal
ssh -G -T -F /tmp/ssh-config-personal github.com >/dev/null

PROFILE=personal chezmoi --config /tmp/personal.toml --source /src managed > /tmp/personal-managed
grep -q '^.config/sway/config$' /tmp/personal-managed
grep -q '^.config/Code/User/settings.json$' /tmp/personal-managed
jq empty /src/dot_config/Code/User/keybindings.json
PROFILE=personal chezmoi --config /tmp/personal.toml --source /src \
    execute-template < /src/dot_config/Code/User/settings.json.tmpl > /tmp/vscode-settings-linux.jsonc
if grep -q '/Users/dan' /tmp/vscode-settings-linux.jsonc; then
    printf 'Linux VS Code settings retain a macOS home path\n' >&2
    exit 1
fi
if grep -Eq '^(Library|.hammerspoon|.config/ghostty|bin/ios-build)' /tmp/personal-managed; then
    printf 'personal Linux profile includes a macOS target\n' >&2
    exit 1
fi

PROFILE=minimal chezmoi --config /tmp/minimal.toml --source /src managed > /tmp/minimal-managed
if grep -Eq '^.config/(sway|waybar|kanata)' /tmp/minimal-managed; then
    printf 'minimal Linux profile includes a personal desktop target\n' >&2
    exit 1
fi

# Container runtimes cannot execute sway while its packaged file capability is
# present. Removing it inside this disposable container permits parser-only use.
setcap -r /usr/bin/sway 2>/dev/null || true
install -d -m 0700 /tmp/runtime
sway_output=""
if ! sway_output="$(
    XDG_RUNTIME_DIR=/tmp/runtime WLR_BACKENDS=headless WLR_RENDERER=pixman \
        sway --validate -c /src/dot_config/sway/config 2>&1
)"; then
    printf '%s\n' "$sway_output" >&2
    exit 1
fi
if printf '%s\n' "$sway_output" | grep -q 'Overwriting binding'; then
    printf '%s\n' "$sway_output" >&2
    exit 1
fi
printf 'Linux rendering and Sway validation passed\n'
LINUX_VALIDATION
