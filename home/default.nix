{ pkgs, ... }:

{
  imports = [
    ./shell.nix
    ./git.nix
    ./programs/starship.nix
    ./programs/fzf.nix
  ];

  home.stateVersion = "24.05";

  # Let home-manager manage itself
  programs.home-manager.enable = true;

  # Dotfiles that are sourced from existing files
  home.file = {
    # AeroSpace (tiling window manager)
    ".aerospace.toml".source = ../dot_aerospace.toml;

    # Starship config
    ".config/starship.toml".source = ../dot_config/starship/starship.toml;

    # Ghostty config
    ".config/ghostty/config".source = ../dot_config/ghostty/config;

    # Neovim config
    ".config/nvim/init.lua".source = ../dot_config/nvim/init.lua;

    # Kanata (keyboard remapping)
    ".config/kanata/kanata.kbd".source = ../dot_config/kanata/kanata.kbd;

    # mise (dev tool versions)
    ".config/mise/config.toml".source = ../dot_config/mise/config.toml;

    # SSH config
    ".ssh/config".source = ../private_dot_ssh/config;
  };
}
