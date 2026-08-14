#!/usr/bin/env bash
# Verify package names and third-party repository declarations against
# disposable distro repositories.

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
require_command docker

validate_fedora() {
    docker run --rm -i -v "$DOTFILES_DIR/packages:/packages:ro" fedora:44 bash -s <<'FEDORA'
set -euo pipefail
dnf -q makecache
dnf -q install -y dnf-plugins-core >/dev/null
dnf -q copr enable -y jdxcode/mise
rpm --import https://packages.microsoft.com/keys/microsoft.asc
install -m 0644 /packages/vscode.repo /etc/yum.repos.d/vscode.repo
dnf -q makecache
sed -E 's/[[:space:]]*#.*$//; /^[[:space:]]*$/d' \
    /packages/fedora-common.txt /packages/fedora-sway.txt | sort -u > /tmp/wanted
missing=0
while IFS= read -r package; do
    if ! dnf -q repoquery --available "$package" 2>/dev/null | grep -q .; then
        printf 'Fedora package unavailable: %s\n' "$package" >&2
        missing=1
    fi
done < /tmp/wanted
exit "$missing"
FEDORA
}

validate_apt() {
    local image="$1"
    local prefix="$2"
    docker run --rm -i -v "$DOTFILES_DIR/packages:/packages:ro" \
        "$image" bash -s -- "$prefix" <<'APT'
set -euo pipefail
prefix="$1"
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -qq -y ca-certificates curl gnupg >/dev/null
install -d -m 0755 /etc/apt/keyrings /usr/share/keyrings
curl -LfsS https://mise.jdx.dev/gpg-key.pub -o /etc/apt/keyrings/mise-archive-keyring.pub
install -m 0644 /packages/mise.sources /etc/apt/sources.list.d/mise.sources
curl -LfsS https://packages.microsoft.com/keys/microsoft.asc -o /tmp/microsoft.asc
gpg --dearmor --yes --output /usr/share/keyrings/microsoft.gpg /tmp/microsoft.asc
install -m 0644 /packages/vscode.sources /etc/apt/sources.list.d/vscode.sources
# shellcheck disable=SC1091
source /etc/os-release
case "$prefix" in
    ubuntu)
        tailscale_distribution=ubuntu
        tailscale_codename="$VERSION_CODENAME"
        ;;
    debian)
        tailscale_distribution=debian
        tailscale_codename="$VERSION_CODENAME"
        ;;
esac
curl -LfsS \
    "https://pkgs.tailscale.com/stable/$tailscale_distribution/$tailscale_codename.noarmor.gpg" \
    -o /usr/share/keyrings/tailscale-archive-keyring.gpg
curl -LfsS \
    "https://pkgs.tailscale.com/stable/$tailscale_distribution/$tailscale_codename.tailscale-keyring.list" \
    -o /etc/apt/sources.list.d/tailscale.list
apt-get update -qq
sed -E 's/[[:space:]]*#.*$//; /^[[:space:]]*$/d' \
    "/packages/$prefix-common.txt" "/packages/$prefix-sway.txt" | sort -u > /tmp/wanted
missing=0
while IFS= read -r package; do
    if ! apt-cache show "$package" >/dev/null 2>&1; then
        printf '%s package unavailable: %s\n' "$prefix" "$package" >&2
        missing=1
    fi
done < /tmp/wanted
exit "$missing"
APT
}

validate_arch() {
    # Docker's official Arch image is currently x86_64-only. Disable its
    # download sandbox inside this disposable emulated container.
    docker run --platform linux/amd64 --security-opt seccomp=unconfined --rm -i \
        -v "$DOTFILES_DIR/packages:/packages:ro" archlinux:latest bash -s <<'ARCH'
set -euo pipefail
sed -i 's/^DownloadUser/# DownloadUser/' /etc/pacman.conf
pacman -Sy --noconfirm >/dev/null
sed -E 's/[[:space:]]*#.*$//; /^[[:space:]]*$/d' \
    /packages/arch-common.txt /packages/arch-sway.txt | sort -u > /tmp/wanted
missing=0
while IFS= read -r package; do
    if ! pacman -Si "$package" >/dev/null 2>&1; then
        printf 'Arch package unavailable: %s\n' "$package" >&2
        missing=1
    fi
done < /tmp/wanted
exit "$missing"
ARCH
}

validate_fedora
validate_apt ubuntu:24.04 ubuntu
validate_apt debian:13 debian
validate_arch
printf 'Fedora, Ubuntu, Debian, and Arch package validation passed\n'
