{ ... }:

{
  # Homebrew - managed declaratively by nix-darwin
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";  # Remove unlisted packages
      upgrade = true;
    };

    taps = [
      "nikitabobko/tap"  # For AeroSpace
    ];

    # Homebrew formulae (macOS-specific or better via brew)
    brews = [
      "mas"         # Mac App Store CLI
      "mise"        # Dev tool version manager
      "cocoapods"   # iOS dependency manager
      "fastlane"    # iOS automation
      "flyctl"      # Fly.io CLI
      "foreman"     # Process manager
      "kanata"      # Keyboard remapping
      "xcodes"      # Xcode version manager
      "ffmpeg"      # Media processing
    ];

    # GUI Applications (casks)
    casks = [
      # Browsers
      "zen"

      # Development
      "zed"
      "ghostty"
      "orbstack"
      "rapidapi"
      "tableplus"
      "proxyman"

      # Productivity
      "raycast"
      "notion"

      # AI
      "claude"

      # Utilities
      "aerospace"
      "monitorcontrol"
      "the-unarchiver"

      # Fonts
      "font-fira-code-nerd-font"
      "font-jetbrains-mono-nerd-font"
      "font-meslo-lg-nerd-font"
    ];

    # Mac App Store apps (requires being signed in)
    masApps = {
      "Numbers" = 409203825;
    };
  };
}
