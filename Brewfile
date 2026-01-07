# Brewfile - macOS Setup
# Run: brew bundle --file=Brewfile

# =============================================================================
# Taps
# =============================================================================
tap "nikitabobko/tap"

# =============================================================================
# Version & Config Management
# =============================================================================
brew "mise"              # Dev tool version manager
brew "chezmoi"           # Dotfiles manager

# =============================================================================
# CLI Essentials
# =============================================================================
brew "git"
brew "gh"                # GitHub CLI
brew "wget"
brew "curl"
brew "jq"                # JSON processing
brew "yq"                # YAML processing
brew "aria2"             # Download manager
brew "gnupg"             # GPG encryption
brew "tmux"              # Terminal multiplexer
brew "mas"               # Mac App Store CLI

# =============================================================================
# Modern CLI Replacements
# =============================================================================
brew "ripgrep"           # Fast search (rg)
brew "fd"                # Better find
brew "fzf"               # Fuzzy finder
brew "bat"               # Better cat
brew "eza"               # Better ls
brew "zoxide"            # Smarter cd
brew "duf"               # Better df (disk usage)
brew "dust"              # Better du (directory sizes)
brew "tree"              # Directory tree
brew "htop"              # Better top
brew "trash"             # Move to trash instead of rm
brew "xh"                # Better curl for APIs
brew "mcfly"             # Better shell history
brew "navi"              # Interactive cheatsheet
brew "glow"              # Markdown viewer
brew "yazi"              # Terminal file manager

# =============================================================================
# Shell & Terminal
# =============================================================================
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
brew "starship"          # Cross-shell prompt

# =============================================================================
# Development Tools
# =============================================================================
brew "neovim"            # Modern vim
brew "lazygit"           # Terminal UI for git
brew "git-delta"         # Better git diffs
brew "diff-so-fancy"     # Better diff output (used by chezmoi)
brew "xcodes"            # Xcode version manager

# =============================================================================
# Applications (Casks)
# =============================================================================

# Terminals
cask "ghostty"

# Development
cask "visual-studio-code"
cask "orbstack"          # Docker alternative
cask "rapidapi"          # API testing
cask "tableplus"         # Database GUI
cask "insomnia"          # API client

# Productivity
cask "raycast"           # Spotlight replacement
cask "notion"

# Utilities
cask "nikitabobko/tap/aerospace"  # Tiling window manager
cask "monitorcontrol"    # External monitor brightness

# AI
cask "claude"

# =============================================================================
# Fonts
# =============================================================================
cask "font-fira-code-nerd-font"
cask "font-jetbrains-mono-nerd-font"
cask "font-iosevka-nerd-font"
cask "font-symbols-only-nerd-font"

# =============================================================================
# VS Code Extensions
# =============================================================================
vscode "vscodevim.vim"
vscode "eamodio.gitlens"
vscode "bbenoist.nix"
vscode "anthropic.claude-code"

# =============================================================================
# Mac App Store Apps (requires `mas` and being signed into App Store)
# =============================================================================
mas "Numbers", id: 409203825
