{ ... }:

{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    # Default options
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
    ];

    # Use fd for file finding
    defaultCommand = "fd --type f --hidden --follow --exclude .git";

    # Ctrl+T to search files
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidgetOptions = [
      "--preview 'bat --style=numbers --color=always --line-range :500 {}'"
    ];

    # Alt+C to change directory
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
    changeDirWidgetOptions = [
      "--preview 'eza --tree --color=always {} | head -200'"
    ];
  };
}
