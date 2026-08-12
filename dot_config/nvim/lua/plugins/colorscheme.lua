vim.g.user_colorscheme = require("config.theme").get()

return {
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      background = {
        dark = "wave",
        light = "lotus",
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = vim.g.user_colorscheme,
    },
  },
}
