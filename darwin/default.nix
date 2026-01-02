{ pkgs, username, ... }:

{
  imports = [
    ./packages.nix
    ./homebrew.nix
    ./system-defaults.nix
  ];

  # Nix configuration
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" username ];
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable nix-daemon
  services.nix-daemon.enable = true;

  # System state version
  system.stateVersion = 5;

  # User configuration
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  # Enable zsh as default shell
  programs.zsh.enable = true;

  # Touch ID for sudo
  security.pam.enableSudoTouchIdAuth = true;
}
