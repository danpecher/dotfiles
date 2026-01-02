{ ... }:

{
  programs.git = {
    enable = true;

    # User info - update these with your details
    userName = "Dan Pecher";
    userEmail = "your@email.com";  # TODO: Update this

    # Use delta for diffs
    delta = {
      enable = true;
      options = {
        navigate = true;
        dark = true;
        line-numbers = true;
      };
    };

    extraConfig = {
      init.defaultBranch = "main";

      core = {
        editor = "nvim";
        excludesfile = "~/.gitignore_global";
      };

      pull.rebase = true;

      push = {
        default = "current";
        autoSetupRemote = true;
      };

      fetch.prune = true;
      rebase.autoStash = true;

      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";

      credential.helper = "osxkeychain";

      url."git@github.com:".insteadOf = "https://github.com/";
    };

    aliases = {
      # Status
      st = "status -sb";

      # Commit
      ci = "commit";
      cm = "commit -m";
      ca = "commit --amend";

      # Branch
      br = "branch";
      co = "checkout";
      sw = "switch";

      # Log
      lg = "log --oneline --graph --decorate";
      ll = "log --pretty=format:'%C(yellow)%h%Creset %s %C(cyan)<%an>%Creset %C(green)(%cr)%Creset' --abbrev-commit";

      # Diff
      df = "diff";
      dc = "diff --cached";

      # Reset
      undo = "reset HEAD~1 --mixed";

      # Stash
      sl = "stash list";
      sp = "stash pop";
      ss = "stash save";

      # Clean up merged branches
      cleanup = "!git branch --merged | grep -v '\\*\\|main\\|master' | xargs -n 1 git branch -d";
    };

    ignores = [
      # macOS
      ".DS_Store"
      ".AppleDouble"
      ".LSOverride"

      # Editor
      "*.swp"
      "*.swo"
      "*~"
      ".idea/"
      ".vscode/"

      # Environment
      ".env"
      ".env.local"
      ".envrc"

      # Dependencies
      "node_modules/"
      "vendor/"

      # Build
      "dist/"
      "build/"
      "*.log"
    ];
  };
}
