# Useful, intentionally bounded macOS baseline managed by chezmoi.
# Install: brew bundle --file=Brewfile
# Audit:   brew bundle cleanup --file=Brewfile

# =============================================================================
# Taps
# =============================================================================
# AeroSpace disabled for now:
# tap "nikitabobko/tap"
tap "jetbrains/utils"

# =============================================================================
# Version & Config Management
# =============================================================================
brew "mise"              # Dev tool version manager
brew "chezmoi"           # Dotfiles manager

# =============================================================================
# CLI Essentials
# =============================================================================
brew "git"
brew "git-lfs"           # Git Large File Storage
brew "gh"                # GitHub CLI
brew "btop"              # Process monitor
brew "cmake"             # Cross-platform build system
brew "curl"              # Current curl independent of macOS
brew "diff-so-fancy"     # Readable chezmoi diffs
brew "glow"              # Markdown viewer
brew "hey"               # HTTP load generator
brew "beads"             # Local issue tracking for agent-assisted work
brew "jq"                # JSON processing
brew "yq"                # YAML processing
brew "mas"               # Mac App Store CLI
brew "kanata"            # Keyboard remapping
brew "mcfly"             # Searchable shell history
brew "mosh"              # Resilient remote shell
brew "navi"              # Interactive command cheatsheets
brew "mole"              # Mac cleanup tool; protected paths are managed by chezmoi
brew "tmux"              # Terminal multiplexer used directly by ~/.zprofile
brew "tmuxinator"        # tmux session manager
brew "tree"              # Directory tree
brew "wget"              # File downloader
brew "xh"                # Friendly HTTP client
brew "yazi"              # Terminal file manager

# =============================================================================
# Modern CLI Replacements
# =============================================================================
brew "ripgrep"           # Fast search (rg)
brew "fd"                # Better find
brew "fzf"               # Fuzzy finder
brew "bat"               # Better cat
brew "eza"               # Better ls
brew "zoxide"            # Smarter cd
brew "trash"             # Move to trash instead of rm

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
brew "rust"              # Rust toolchain
brew "lazygit"           # Terminal UI for git
brew "git-delta"         # Better git diffs
brew "jetbrains/utils/kotlin-lsp"
brew "xcode-build-server"
brew "xcodes"            # Xcode version manager
brew "cocoapods"         # iOS dependency manager
brew "libpq"             # PostgreSQL client libraries and psql
brew "flyctl"
brew "render"            # Render CLI

# =============================================================================
# Applications (Casks)
# =============================================================================
cask "zen"
cask "ghostty"

# Development
cask "visual-studio-code"
cask "android-studio"
cask "fork"
cask "orbstack"          # Docker alternative
cask "tableplus"         # Database GUI
cask "rapidapi"          # API client
cask "zed@preview"

# Productivity
cask "raycast"           # Spotlight replacement
cask "notion"
cask "figma"
cask "obsidian"
cask "xmind"

# AeroSpace and its workspace bar are intentionally disabled for now.
# cask "nikitabobko/local-tap/aerospace-dev"
cask "hammerspoon"
cask "karabiner-elements" # Supplies the VirtualHID driver required by Kanata
cask "mitmproxy"
cask "ngrok"
cask "proxyman"
cask "rectangle"
# cask "ubersicht"
cask "monitorcontrol"    # External monitor brightness

# AI
cask "codex"

# =============================================================================
# Fonts
# =============================================================================
cask "font-jetbrains-mono-nerd-font"
cask "font-fira-code-nerd-font"
cask "sf-symbols"

# =============================================================================
# VS Code Extensions
# =============================================================================
vscode "openai.chatgpt"
vscode "adpyke.vscode-sql-formatter"
vscode "alefragnani.bookmarks"
vscode "asvetliakov.vscode-neovim"
vscode "avetis.tokyo-night"
vscode "bierner.markdown-mermaid"
vscode "catppuccin.catppuccin-vsc"
vscode "charliermarsh.ruff"
vscode "dbaeumer.vscode-eslint"
vscode "esbenp.prettier-vscode"
vscode "github.vscode-pull-request-github"
vscode "github.github-vscode-theme"
vscode "golang.go"
vscode "howardzuo.vscode-favorites"
vscode "jetbrains.kotlin-server"
vscode "llvm-vs-code-extensions.lldb-dap"  # Swift extension dependency
vscode "ms-python.debugpy"                 # Python extension dependency
vscode "ms-python.python"
vscode "ms-python.vscode-pylance"
vscode "ms-python.vscode-python-envs"      # Python extension dependency
vscode "ms-vscode-remote.remote-containers"
vscode "maattdd.gitless"
vscode "martinortiz.codex-stats"
vscode "ms-pyright.pyright"
vscode "ms-vscode.makefile-tools"
vscode "patbenatar.advanced-new-file"
vscode "redhat.vscode-yaml"
vscode "rust-lang.rust-analyzer"
vscode "swiftlang.swift-vscode"
vscode "teabyii.ayu"
vscode "tompollak.lazygit-vscode"
vscode "vadimcn.vscode-lldb"
vscode "vitest.explorer"
vscode "vscode-icons-team.vscode-icons"
vscode "wayou.file-icons-mac"

# =============================================================================
# Mac App Store Apps (requires `mas` and being signed into App Store)
# =============================================================================
mas "Numbers", id: 409203825
mas "uBlock Origin Lite", id: 6745342698
