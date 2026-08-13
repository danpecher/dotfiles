#!/bin/bash
#
# Explicit package, service, and first-machine provisioning workflows.
#
# This script is called by 01_bootstrap.sh but can also be run standalone
# after dotfiles have been applied via chezmoi.
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
PROFILE="${PROFILE:-${SETUP_PROFILE:-personal}}"
SKIP_STEPS="${SKIP_STEPS:-}"
if [[ "${SKIP_KANATA:-0}" == 1 ]]; then
    SKIP_STEPS="${SKIP_STEPS:+$SKIP_STEPS,}kanata"
fi
ACTION="${1:-bootstrap}"
OS="$(uname -s)"

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

skip_step() {
    case ",${SKIP_STEPS// /,}," in
        *,"$1",*) return 0 ;;
        *) return 1 ;;
    esac
}

# Ensure Homebrew is in PATH on macOS. Fedora uses dnf instead.
if [[ "$OS" == Darwin ]]; then
    if ! command -v brew &>/dev/null; then
        error "Homebrew not found. Run 01_bootstrap.sh first."
    fi
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
elif [[ "$OS" != Linux || ! -f /etc/fedora-release ]]; then
    error "Unsupported platform. This setup supports macOS and Fedora Linux."
fi

echo ""
echo "=========================================="
echo "  Setup - $PROFILE Profile"
echo "=========================================="
echo ""

# Setup SSH key (needed before brew bundle for taps that use git@github.com)
setup_ssh() {
    if skip_step github; then
        warn "Skipping SSH key setup (SKIP_STEPS includes github)"
        return
    fi
    if [[ ! -f ~/.ssh/id_ed25519 ]]; then
        info "Generating SSH key..."
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh

        read -p "Enter your email for SSH key: " email
        ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519

        # Add to keychain
        eval "$(ssh-agent -s)"
        if [[ "$OS" == Darwin ]]; then
            ssh-add --apple-use-keychain ~/.ssh/id_ed25519
        else
            ssh-add ~/.ssh/id_ed25519
        fi

        success "SSH key generated"
    else
        success "SSH key already exists"
    fi
}

# Add SSH key to GitHub (requires gh CLI from Brewfile)
setup_github_ssh() {
    if skip_step github; then
        warn "Skipping GitHub authentication (SKIP_STEPS includes github)"
        return
    fi
    if [[ ! -f ~/.ssh/id_ed25519.pub ]]; then
        warn "No SSH key found, skipping GitHub setup"
        return
    fi

    if ! command -v gh &>/dev/null; then
        warn "gh CLI not found, skipping GitHub SSH setup"
        return
    fi

    # Check if already authenticated
    if ! gh auth status &>/dev/null; then
        info "Authenticating with GitHub..."
        gh auth login -p ssh -w
    fi

    # Check if key already added
    local key_fingerprint
    key_fingerprint=$(ssh-keygen -lf ~/.ssh/id_ed25519.pub 2>/dev/null | awk '{print $2}')
    if [[ -n "$key_fingerprint" ]] && ! gh ssh-key list 2>/dev/null | grep -q "$key_fingerprint"; then
        info "Adding SSH key to GitHub..."
        gh ssh-key add ~/.ssh/id_ed25519.pub -t "$(hostname)-$(date +%Y%m%d)" 2>/dev/null || true
        success "SSH key added to GitHub"
    else
        success "SSH key already on GitHub"
    fi
}

brewfile_for_profile() {
    case "$PROFILE" in
        personal|full) printf '%s/Brewfile\n' "$DOTFILES_DIR" ;;
        minimal|work) printf '%s/Brewfile.minimal\n' "$DOTFILES_DIR" ;;
        *) error "Unknown profile: $PROFILE" ;;
    esac
}

# Install packages from the selected Brewfile. This is additive; cleanup is a
# separate preview-only workflow.
install_macos_packages() {
    local brewfile
    brewfile="$(brewfile_for_profile)"
    info "Installing packages from $(basename "$brewfile")..."
    if [[ -f "$brewfile" ]]; then
        # Homebrew 6 requires explicit trust for third-party formulae/casks.
        # Scope trust to the exact packages instead of trusting whole taps.
        if grep -q 'jetbrains/utils/kotlin-lsp' "$brewfile"; then
            brew tap jetbrains/utils
            brew trust --formula jetbrains/utils/kotlin-lsp
        fi

        local bundle_file="$brewfile"
        local temp_brewfile=""
        if grep -Eq '^mas ' "$brewfile" && command -v mas >/dev/null 2>&1 && ! mas account &>/dev/null; then
            temp_brewfile="$(mktemp "${TMPDIR:-/tmp}/Brewfile.XXXXXX")"
            grep -Ev '^mas ' "$brewfile" > "$temp_brewfile"
            bundle_file="$temp_brewfile"
            warn "Not signed into the App Store; skipping mas entries"
        fi

        brew bundle --file="$bundle_file"
        [[ -z "$temp_brewfile" ]] || rm -f "$temp_brewfile"
        success "Brewfile packages installed"
    else
        error "Brewfile not found: $brewfile"
    fi
}

fedora_package_files() {
    printf '%s/packages/fedora-common.txt\n' "$DOTFILES_DIR"
    if [[ "$PROFILE" == personal || "$PROFILE" == full ]]; then
        printf '%s/packages/fedora-sway.txt\n' "$DOTFILES_DIR"
    fi
}

install_fedora_packages() {
    local package_file
    local -a packages=()
    for package_file in $(fedora_package_files); do
        while IFS= read -r package; do
            [[ -n "$package" ]] && packages+=("$package")
        done < <(sed -E 's/[[:space:]]*#.*$//; /^[[:space:]]*$/d' "$package_file")
    done
    info "Enabling the official mise COPR for Fedora..."
    sudo dnf install -y dnf-plugins-core
    sudo dnf copr enable -y jdxcode/mise
    info "Enabling the official Microsoft VS Code repository..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo install -o root -g root -m 0644 \
        "$DOTFILES_DIR/packages/vscode.repo" /etc/yum.repos.d/vscode.repo
    info "Installing ${#packages[@]} packages with dnf..."
    sudo dnf install -y "${packages[@]}"
    success "Fedora packages installed"
}

setup_vscode_extensions() {
    [[ "$OS" == Linux ]] || return
    command -v code >/dev/null 2>&1 || {
        warn "VS Code is not installed; skipping extensions"
        return
    }
    info "Installing declared VS Code extensions..."
    while IFS= read -r extension; do
        code --install-extension "$extension"
    done < <(sed -E 's/[[:space:]]*#.*$//; /^[[:space:]]*$/d' \
        "$DOTFILES_DIR/packages/vscode-extensions.txt")
    success "VS Code extensions installed"
}

install_linux_nerd_font() {
    [[ "$OS" == Linux && ( "$PROFILE" == personal || "$PROFILE" == full ) ]] || return
    local version="3.5.0"
    local font_dir="$HOME/.local/share/fonts/nerd-fonts/JetBrainsMono-$version"
    if find "$font_dir" -maxdepth 1 -name '*NerdFont*.ttf' -print -quit 2>/dev/null | grep -q .; then
        success "JetBrainsMono Nerd Font $version is already installed"
        return
    fi

    local archive temp_dir
    temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/nerd-font.XXXXXX")"
    archive="$temp_dir/JetBrainsMono.zip"
    info "Installing JetBrainsMono Nerd Font $version..."
    curl -L --fail --silent --show-error \
        -o "$archive" \
        "https://github.com/ryanoasis/nerd-fonts/releases/download/v$version/JetBrainsMono.zip"
    printf '%s  %s\n' \
        9577de1ae84ec523df16fc69bac5338b89497a5b4fb91489e2dcb79dc06ac2b5 \
        "$archive" | sha256sum --check --status || error "Nerd Font checksum verification failed"
    install -d -m 0755 "$font_dir"
    unzip -oq "$archive" '*.ttf' -d "$font_dir"
    rm -rf "$temp_dir"
    fc-cache -f "$HOME/.local/share/fonts"
    success "JetBrainsMono Nerd Font $version installed"
}

install_linux_kanata() {
    [[ "$PROFILE" == personal || "$PROFILE" == full ]] || return
    if skip_step kanata; then
        warn "Skipping Kanata installation (SKIP_STEPS includes kanata)"
        return
    fi
    local version="1.11.0"
    if [[ -x /usr/local/bin/kanata ]] && /usr/local/bin/kanata --version 2>/dev/null | grep -q "$version"; then
        success "Kanata $version is already installed"
        return
    fi

    case "$(uname -m)" in
        x86_64)
            local archive temp_dir
            temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/kanata.XXXXXX")"
            archive="$temp_dir/kanata.zip"
            info "Installing pinned Kanata $version binary..."
            curl -L --fail --silent --show-error \
                -o "$archive" \
                "https://github.com/jtroo/kanata/releases/download/v$version/linux-binaries-x64.zip"
            printf '%s  %s\n' \
                d9f634afb4c7f078cc2aacf3998fd65b432d4d83296cc48a89f941525459b4e2 \
                "$archive" | sha256sum --check --status || error "Kanata checksum verification failed"
            unzip -q "$archive" -d "$temp_dir"
            sudo install -o root -g root -m 0755 "$temp_dir/kanata_linux_x64" /usr/local/bin/kanata
            rm -rf "$temp_dir"
            ;;
        *)
            error "The pinned Kanata Linux binary currently supports x86_64 only; unsupported architecture: $(uname -m)"
            ;;
    esac
}

install_packages() {
    if [[ "$OS" == Darwin ]]; then
        install_macos_packages
    else
        install_fedora_packages
        install_linux_nerd_font
        install_linux_kanata
    fi
}

# Setup mise
setup_mise() {
    if ! command -v mise &>/dev/null; then
        warn "mise not found"
        return
    fi

    info "Activating mise..."
    eval "$(mise activate bash)"

    if [[ -f ~/.config/mise/config.toml ]]; then
        info "Installing development tools via mise..."
        mise install
        success "mise tools installed"
    else
        warn "mise config not found - should have been applied by chezmoi"
    fi
}

# Setup shell
setup_shell() {
    if [[ "$SHELL" != *"zsh"* ]]; then
        info "Changing default shell to zsh..."
        if [[ "$OS" == Darwin ]]; then
            chsh -s "$(which zsh)"
        else
            sudo usermod --shell "$(command -v zsh)" "$USER"
        fi
        success "Default shell changed to zsh"
    else
        success "zsh is already the default shell"
    fi
}

# Setup fzf
setup_fzf() {
    if [[ "$OS" == Darwin ]] && command -v fzf &>/dev/null; then
        info "Setting up fzf key bindings..."
        "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish 2>/dev/null || true
        success "fzf configured"
    fi
}

# Install the exact tmux plugin revisions used by this configuration. Keeping
# plugins outside chezmoi avoids vendoring repositories while retaining a
# reproducible terminal setup.
install_tmux_plugin() {
    local name="$1"
    local url="$2"
    local commit="$3"
    local plugin_dir="$HOME/.config/tmux/plugins/$name"

    if [[ ! -d "$plugin_dir/.git" ]]; then
        info "Installing tmux plugin: $name"
        mkdir -p "$(dirname "$plugin_dir")"
        git clone --filter=blob:none --no-checkout "$url" "$plugin_dir"
    elif [[ -n "$(git -C "$plugin_dir" status --porcelain)" ]]; then
        warn "tmux plugin $name has local changes; leaving it untouched"
        return
    fi

    if [[ "$(git -C "$plugin_dir" rev-parse HEAD 2>/dev/null || true)" == "$commit" ]]; then
        return
    fi

    git -C "$plugin_dir" fetch --depth 1 origin "$commit"
    git -C "$plugin_dir" checkout --detach "$commit"
}

setup_tmux() {
    [[ "$PROFILE" == personal || "$PROFILE" == full ]] || return
    command -v tmux >/dev/null 2>&1 || {
        warn "tmux is not installed"
        return
    }

    install_tmux_plugin tpm \
        https://github.com/tmux-plugins/tpm.git \
        e261deb1b47614eed3400089ce7197dc68acc4eb
    install_tmux_plugin tmux-sensible \
        https://github.com/tmux-plugins/tmux-sensible.git \
        25cb91f42d020f675bb0a2ce3fbd3a5d96119efa
    install_tmux_plugin tmux-palette \
        https://github.com/eduwass/tmux-palette.git \
        7caa11e845e0aa0515d013158df85613f3ec507f
    install_tmux_plugin tmux-resurrect \
        https://github.com/tmux-plugins/tmux-resurrect.git \
        cff343cf9e81983d3da0c8562b01616f12e8d548
    install_tmux_plugin tmux-gruvbox \
        https://github.com/egel/tmux-gruvbox.git \
        aeb30c7172a8ed8663409207814cf47d9df10d15
    success "tmux plugins installed at pinned revisions"
}

# Kanata uses Karabiner's VirtualHID driver on macOS, but Karabiner's own
# remapper should not process the same keyboard at the same time.
setup_kanata() {
    [[ "$PROFILE" == personal || "$PROFILE" == full ]] || return
    if skip_step kanata; then
        warn "Skipping Kanata service setup (SKIP_STEPS includes kanata)"
        return
    fi
    command -v kanata >/dev/null 2>&1 || {
        warn "kanata is not installed"
        return
    }

    if [[ "$OS" == Linux ]]; then
        [[ -x /usr/local/bin/kanata ]] || error "Kanata is not installed; run 'make packages' first"
        local unit_source="$DOTFILES_DIR/systemd/kanata.service.tmpl"
        local unit_file
        unit_file="$(mktemp "${TMPDIR:-/tmp}/kanata.service.XXXXXX")"
        sed "s|{{HOME}}|$HOME|g" "$unit_source" > "$unit_file"
        printf 'uinput\n' | sudo tee /etc/modules-load.d/kanata.conf >/dev/null
        sudo modprobe uinput
        sudo install -o root -g root -m 0644 "$unit_file" /etc/systemd/system/kanata.service
        rm -f "$unit_file"
        sudo systemctl daemon-reload
        sudo systemctl enable kanata.service
        sudo systemctl restart kanata.service
        success "Kanata system service enabled and started"
        return
    fi

    local karabiner_config="$HOME/.config/karabiner/karabiner.json"
    if command -v jq >/dev/null 2>&1 && [[ -f "$karabiner_config" ]] &&
        jq -e '
            .profiles[]?
            | select(.selected == true)
            | ((.simple_modifications // []) | length > 0)
              or ((.complex_modifications.rules // []) | length > 0)
        ' "$karabiner_config" >/dev/null; then
        error "Karabiner mappings are enabled. Disable them before starting Kanata to avoid competing remappers."
    fi

    local driver_manager="/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager"
    if [[ -x "$driver_manager" ]]; then
        info "Activating the Karabiner VirtualHID driver used by Kanata..."
        sudo "$driver_manager" activate
    else
        warn "Karabiner VirtualHID manager not found; open Karabiner-Elements once to finish driver installation"
    fi

    info "Enabling Kanata as a root Homebrew service at boot..."
    sudo brew services restart kanata
    success "Kanata service enabled and started"
}

setup_tailscale() {
    [[ "$OS" == Linux ]] || return
    command -v tailscale >/dev/null 2>&1 || {
        warn "Tailscale is not installed"
        return
    }

    info "Enabling the Tailscale daemon..."
    sudo systemctl enable --now tailscaled.service
    if ! tailscale status >/dev/null 2>&1; then
        warn "Tailscale is not authenticated; connect later with: sudo tailscale up"
    else
        success "Tailscale daemon enabled and connected"
    fi
}

# Configure an existing Xcode installation. A bootstrap should not silently
# download a multi-gigabyte application; install Xcode explicitly when needed.
setup_xcode() {
    if ! command -v xcodes &>/dev/null; then
        warn "xcodes not found - should have been installed via Brewfile"
        return
    fi

    # Find any Xcode installation (xcodes uses versioned names like Xcode-16.2.0.app)
    local xcode_app
    xcode_app=$(find /Applications -maxdepth 1 -name "Xcode*.app" -type d 2>/dev/null | head -1)

    if [[ -z "$xcode_app" ]]; then
        warn "Xcode is not installed; install it explicitly with: xcodes install --latest"
        return
    fi

    success "Xcode already installed: $(basename "$xcode_app")"

    # Set Xcode as active developer directory (must happen before xcodebuild commands)
    if [[ -n "$xcode_app" && -d "$xcode_app/Contents/Developer" ]]; then
        info "Setting Xcode as active developer directory..."
        sudo xcode-select -s "$xcode_app/Contents/Developer"
        success "Xcode set as active developer directory"

        # Accept Xcode license
        if ! sudo xcodebuild -license check &>/dev/null 2>&1; then
            info "Accepting Xcode license..."
            sudo xcodebuild -license accept
            success "Xcode license accepted"
        else
            success "Xcode license already accepted"
        fi
    else
        warn "Xcode Developer directory not found - Xcode may need to be reinstalled"
        warn "Try: xcodes install --latest"
    fi
}

# Dispatch explicit workflows. "packages" and "services" are suitable for
# repeat use; "bootstrap" contains interactive, account, and system setup.
case "$ACTION" in
    packages)
        install_packages
        setup_vscode_extensions
        setup_mise
        setup_tmux
        setup_fzf
        ;;
    services)
        setup_kanata
        setup_tailscale
        ;;
    bootstrap)
        setup_ssh
        install_packages
        setup_github_ssh
        setup_vscode_extensions
        setup_tmux
        setup_kanata
        setup_tailscale
        if [[ "$OS" == Darwin && ( "$PROFILE" == personal || "$PROFILE" == full ) ]]; then
            setup_xcode
        fi
        setup_mise
        setup_shell
        setup_fzf
        ;;
    *)
        error "Unknown action: $ACTION (expected packages, services, or bootstrap)"
        ;;
esac

echo ""
success "Setup complete!"
echo ""
