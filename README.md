# Dotfiles

Personal macOS configuration managed with [chezmoi](https://chezmoi.io/).

## Quick Install

Run this on a fresh macOS installation:

```bash
curl -fsSL https://raw.githubusercontent.com/danpecher/dotfiles/main/scripts/01_bootstrap.sh | bash
```

This will:
1. Install Xcode Command Line Tools
2. Install Homebrew
3. Install chezmoi and apply dotfiles
4. Install all packages from Brewfile
5. Setup SSH keys and GitHub authentication
6. Install Xcode via xcodes
7. Install development tools via mise
8. Optionally apply macOS system preferences

## Manual Installation

```bash
# Clone the repository
git clone https://github.com/danpecher/dotfiles.git
cd dotfiles

# Run bootstrap
./scripts/01_bootstrap.sh
```

## What's Included

### Configuration Files

- **zsh** - Shell configuration with aliases, history, and plugins
- **git** - Git config with delta, aliases, and signing
- **neovim** - Minimal config without plugins
- **ghostty** - Terminal emulator settings
- **aerospace** - Tiling window manager for macOS
- **kanata** - Keyboard remapping (home row mods, symbol/number layers)
- **starship** - Cross-shell prompt
- **mise** - Development tool version manager

### Packages (Brewfile)

**CLI Tools:**
- Modern replacements: `ripgrep`, `fd`, `bat`, `eza`, `zoxide`, `dust`, `duf`
- Utilities: `fzf`, `jq`, `yq`, `htop`, `trash`, `lazygit`, `git-delta`
- Shell: `starship`, `zsh-autosuggestions`, `zsh-syntax-highlighting`

**Applications:**
- Development: `visual-studio-code`, `ghostty`, `orbstack`
- Productivity: `raycast`, `notion`, `aerospace`
- Utilities: `monitorcontrol`

**Fonts:**
- JetBrains Mono Nerd Font
- Fira Code Nerd Font
- Iosevka Nerd Font

### Development Tools (mise)

- Node.js (LTS)
- Python (latest)
- Bun (latest)

## Scripts

| Script | Purpose |
|--------|---------|
| `01_bootstrap.sh` | Full setup from scratch (can be piped from curl) |
| `02_setup.sh` | Install packages and configure tools |
| `03_macos-defaults.sh` | Apply macOS system preferences |

## macOS Preferences

The `03_macos-defaults.sh` script configures:

- Dark mode, fast key repeat, disabled auto-correct
- Dock: auto-hide, no recents, fast animations
- Finder: show hidden files, path bar, column view
- Trackpad: tap to click, three-finger drag
- Safari: developer tools, session restore
- Spotlight disabled (using Raycast)
- Login items: Raycast, AeroSpace, MonitorControl

## Updating

```bash
chezmoi update
```

## Adding New Dotfiles

```bash
chezmoi add ~/.some-config
chezmoi cd
git add -A && git commit -m "Add some-config"
git push
```
