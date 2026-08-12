if vim.g.vscode then
  -- Minimal config for VSCode
  require("config.vscode")
else
  -- Full LazyVim setup for standalone Neovim
  require("config.lazy")
end
