-- Minimal config for VSCode Neovim extension
-- Basic options, keymaps, and minimal plugins (surround, leap)

local opt = vim.opt
local g = vim.g

-- Disable spell checking
opt.spell = false

-- Basic options
opt.ignorecase = true
opt.smartcase = true
opt.clipboard = "unnamedplus"

-- Leader key
g.mapleader = " "
g.maplocalleader = "\\"

-- Bootstrap lazy.nvim for plugin management
local lazypath = vim.fn.stdpath("data") .. "/lazy-vscode/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load minimal plugins
require("lazy").setup({
  {
    "ggandor/leap.nvim",
    config = function()
      vim.keymap.set({ "n", "x", "o" }, "s", "<Plug>(leap-forward)")
      vim.keymap.set({ "n", "x", "o" }, "S", "<Plug>(leap-backward)")
      -- Tokyo Night colors for leap
      vim.api.nvim_set_hl(0, "LeapBackdrop", { fg = "#545c7e" })
      vim.api.nvim_set_hl(0, "LeapLabel", { fg = "#ff9e64", bold = true })
      vim.api.nvim_set_hl(0, "LeapMatch", { fg = "#c0caf5", bold = true, underline = true })
    end,
  },
  {
    "ggandor/flit.nvim",
    dependencies = { "ggandor/leap.nvim" },
    config = function()
      require("flit").setup({
        labeled_modes = "nv",
      })
    end,
  },
  {
    "echasnovski/mini.surround",
    version = "*",
    config = function()
      require("mini.surround").setup({
        -- vim-surround style: ys = add, ds = delete, cs = change
        mappings = {
          add = "ys",
          delete = "ds",
          replace = "cs",
          find = "",
          find_left = "",
          highlight = "",
          update_n_lines = "",
        },
      })
      -- Remap adding surrounding to Visual mode selection
      vim.keymap.del("x", "ys")
      -- vim.keymap.set("x", "S", [[:<C-u>lua MiniSurround.add('visual')<CR>]], { silent = true })
      -- Make special mapping for "add surrounding for line"
      vim.keymap.set("n", "yss", "ys_", { remap = true })
    end,
  },
}, {
  root = vim.fn.stdpath("data") .. "/lazy-vscode",
  lockfile = vim.fn.stdpath("data") .. "/lazy-vscode/lazy-lock.json",
})

-- VSCode-specific keymaps using VSCode commands
local vscode = require("vscode")

local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = opts.silent ~= false
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- File navigation
map("n", "<leader><space>", function()
  vscode.action("workbench.action.quickOpen")
end)
map("n", "<leader>ff", function()
  vscode.action("workbench.action.quickOpen")
end)
map("n", "<leader>fg", function()
  vscode.action("workbench.action.findInFiles")
end)
map("n", "<leader>e", function()
  vscode.action("workbench.view.explorer")
end)

-- Buffer/editor management
map("n", "<leader>bd", function()
  vscode.action("workbench.action.closeActiveEditor")
end)
map("n", "<S-h>", function()
  vscode.action("workbench.action.previousEditor")
end)
map("n", "<S-l>", function()
  vscode.action("workbench.action.nextEditor")
end)

-- Code actions
map("n", "gd", function()
  vscode.action("editor.action.revealDefinition")
end)
map("n", "gr", function()
  vscode.action("editor.action.goToReferences")
end)
map("n", "gi", function()
  vscode.action("editor.action.goToImplementation")
end)
map("n", "K", function()
  vscode.action("editor.action.showHover")
end)
map("n", "<leader>ca", function()
  vscode.action("editor.action.quickFix")
end)
map("n", "<leader>cr", function()
  vscode.action("editor.action.rename")
end)
map("n", "<leader>cf", function()
  vscode.action("editor.action.formatDocument")
end)

-- Search
map("n", "<leader>/", function()
  vscode.action("workbench.action.findInFiles")
end)
map("n", "<leader>sr", function()
  vscode.action("editor.action.startFindReplaceAction")
end)

-- Git
map("n", "<leader>gg", function()
  vscode.action("workbench.view.scm")
end)

-- Terminal
map("n", "<leader>t", function()
  vscode.action("workbench.action.terminal.toggleTerminal")
end)

-- Window management
map("n", "<C-h>", function()
  vscode.action("workbench.action.focusLeftGroup")
end)
map("n", "<C-j>", function()
  vscode.action("workbench.action.focusBelowGroup")
end)
map("n", "<C-k>", function()
  vscode.action("workbench.action.focusAboveGroup")
end)
map("n", "<C-l>", function()
  vscode.action("workbench.action.focusRightGroup")
end)

-- Split management
map("n", "<leader>sv", function()
  vscode.action("workbench.action.splitEditorRight")
end)
map("n", "<leader>sh", function()
  vscode.action("workbench.action.splitEditorDown")
end)
map("n", "<leader>se", function()
  vscode.action("workbench.action.evenEditorWidths")
end)
map("n", "<leader>sx", function()
  vscode.action("workbench.action.closeEditorsInGroup")
end)

-- Comments (using VSCode's built-in)
map("n", "gcc", function()
  vscode.action("editor.action.commentLine")
end)
map("v", "gc", function()
  vscode.action("editor.action.commentLine")
end)

-- Folding
map("n", "za", function()
  vscode.action("editor.toggleFold")
end)
map("n", "zR", function()
  vscode.action("editor.unfoldAll")
end)
map("n", "zM", function()
  vscode.action("editor.foldAll")
end)
