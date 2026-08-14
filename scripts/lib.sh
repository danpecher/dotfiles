#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
PROFILE="${PROFILE:-personal}"
SKIP_STEPS="${SKIP_STEPS:-}"
if [[ "${SKIP_KANATA:-0}" == 1 ]]; then
    SKIP_STEPS="${SKIP_STEPS:+$SKIP_STEPS,}kanata"
fi
# Consumers of this sourced library use OS even though this file does not.
# shellcheck disable=SC2034
OS="$(uname -s)"
LINUX_DISTRO=""
LINUX_FAMILY=""

detect_linux_distribution() {
    local release_file="${OS_RELEASE_FILE:-/etc/os-release}"
    [[ -r "$release_file" ]] || return 1
    (
        # os-release is a shell-compatible, system-owned data file.
        # shellcheck disable=SC1090
        source "$release_file"
        printf '%s\n' "${ID:-}"
    )
}

detect_linux_family() {
    local release_file="${OS_RELEASE_FILE:-/etc/os-release}"
    [[ -r "$release_file" ]] || return 1
    (
        # shellcheck disable=SC1090
        source "$release_file"
        case " ${ID:-} ${ID_LIKE:-} " in
            *" fedora "* | *" rhel "*) printf 'fedora\n' ;;
            *" debian "* | *" ubuntu "*) printf 'debian\n' ;;
            *" arch "*) printf 'arch\n' ;;
            *) return 1 ;;
        esac
    )
}

if [[ "$OS" == Linux || -n "${LINUX_DISTRO_OVERRIDE:-}${LINUX_FAMILY_OVERRIDE:-}" ]]; then
    LINUX_DISTRO="${LINUX_DISTRO_OVERRIDE:-$(detect_linux_distribution || true)}"
    LINUX_FAMILY="${LINUX_FAMILY_OVERRIDE:-$(detect_linux_family || true)}"
fi

export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1

info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
fail() { printf '[FAIL] %s\n' "$*" >&2; }
section() { printf '\n%s\n' "$*"; }

skip_step() {
    case ",${SKIP_STEPS// /,}," in
        *,"$1",*) return 0 ;;
        *) return 1 ;;
    esac
}

brewfile_for_profile() {
    case "$PROFILE" in
        personal|full)
            printf '%s/Brewfile\n' "$DOTFILES_DIR"
            ;;
        minimal|work)
            printf '%s/Brewfile.minimal\n' "$DOTFILES_DIR"
            ;;
        *)
            fail "Unknown PROFILE=$PROFILE (expected personal or minimal)"
            return 2
            ;;
    esac
}

linux_package_files() {
    [[ -n "$LINUX_DISTRO" && -n "$LINUX_FAMILY" ]] || {
        fail "Unsupported Linux distribution; expected Fedora, Debian/Ubuntu, or Arch"
        return 2
    }

    local prefix="$LINUX_DISTRO"
    [[ -f "$DOTFILES_DIR/packages/$prefix-common.txt" ]] || prefix="$LINUX_FAMILY"
    printf '%s/packages/%s-common.txt\n' "$DOTFILES_DIR" "$prefix"
    if [[ "$PROFILE" == personal || "$PROFILE" == full ]]; then
        printf '%s/packages/%s-sway.txt\n' "$DOTFILES_DIR" "$prefix"
    fi
}

linux_package_installed() {
    local package="$1"
    case "$LINUX_FAMILY" in
        fedora) rpm -q --quiet "$package" ;;
        debian) dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii ' ;;
        arch) pacman -Qq "$package" >/dev/null 2>&1 ;;
        *) return 2 ;;
    esac
}

read_package_file() {
    sed -E 's/[[:space:]]*#.*$//; /^[[:space:]]*$/d' "$1"
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        fail "Required command is missing: $1"
        return 1
    }
}

normalize_brew_names() {
    sed 's#.*/##' | LC_ALL=C sort -u
}

list_vscode_extensions() {
    command -v code >/dev/null 2>&1 || return 0
    code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]' | LC_ALL=C sort -u
}
