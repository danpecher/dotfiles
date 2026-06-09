# Dotfiles

Personal macOS configuration managed with [chezmoi](https://chezmoi.io/).

## Quick Install

Run this on a fresh macOS installation:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/danpecher/dotfiles/main/scripts/01_bootstrap.sh)"
```

This defaults to the `minimal` profile for a work VM. It will:
1. Install Xcode Command Line Tools
2. Install Homebrew
3. Setup SSH keys and GitHub authentication
4. Install chezmoi and apply dotfiles
5. Install a minimal package set for daily development
6. Install development tools via mise
7. Optionally apply the standard macOS system preferences from this repo

For the full workstation setup instead:

```bash
SETUP_PROFILE=full ./scripts/01_bootstrap.sh
```

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

### Packages

**Minimal profile (`Brewfile.minimal`):**
- Dev essentials: `git`, `gh`, `chezmoi`, `mise`, `neovim`
- Shell comfort: `ripgrep`, `fd`, `fzf`, `bat`, `eza`, `zoxide`, `starship`
- Git ergonomics: `git-delta`, `lazygit`, `trash`, `zsh-autosuggestions`, `zsh-syntax-highlighting`
- GUI basics: `ghostty`, `visual-studio-code`, `raycast`
- Main terminal fonts: JetBrains Mono Nerd Font, Fira Code Nerd Font, Iosevka Nerd Font, Symbols Only Nerd Font

**Full profile (`Brewfile`):**
- Everything above, plus the larger workstation package set and GUI apps

### Development Tools (mise)

- Node.js (LTS)
- Python (latest)
- Bun (latest)

## Scripts

| Script | Purpose |
|--------|---------|
| `01_bootstrap.sh` | Bootstrap macOS and run the selected setup profile |
| `02_setup.sh` | Install packages and configure the shell for `minimal` or `full` |
| `03_macos-defaults.sh` | Apply the standard macOS preferences used by this repo |

## macOS Preferences

The `03_macos-defaults.sh` script configures:

- General UI, keyboard, and text input preferences
- Dock behavior and Dock contents
- Finder, trackpad, spaces, and window manager preferences
- Safari, Control Center, Activity Monitor, TextEdit, and Time Machine tweaks
- Login items, screenshots, software update, and related system defaults

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
