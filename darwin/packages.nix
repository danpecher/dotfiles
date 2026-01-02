{ pkgs, ... }:

{
  # Packages installed via Nix (cross-platform CLI tools)
  environment.systemPackages = with pkgs; [
    # CLI Essentials
    git
    gh              # GitHub CLI
    wget
    curl
    jq              # JSON processing
    yq              # YAML processing
    aria2
    gnupg

    # Modern CLI replacements
    ripgrep         # Fast search (rg)
    fd              # Better find
    fzf             # Fuzzy finder
    bat             # Better cat
    eza             # Better ls
    zoxide          # Smarter cd
    duf             # Better df
    dust            # Better du
    tree
    htop
    trash-cli       # Move to trash instead of rm
    xh              # Better curl for APIs
    yazi            # Terminal file manager
    mcfly           # Better shell history
    navi            # Interactive cheatsheet

    # Shell & Terminal
    starship        # Cross-shell prompt

    # Development Tools
    lazygit         # Terminal UI for git
    delta           # Better git diffs
    neovim          # Modern vim
  ];
}
