{ ... }:

{
  # Starship prompt - configuration is sourced from the existing starship.toml
  # via home.file in home/default.nix
  programs.starship = {
    enable = true;
    enableZshIntegration = false;  # We handle this manually in shell.nix initExtra
  };
}
