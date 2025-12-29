-- Minimal Neovim config for script editing
-- No plugins, just sensible defaults

-- Leader key
vim.g.mapleader = " "

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Indentation
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- Visual
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.wrap = false

-- Files
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true

-- Clipboard (use system clipboard)
vim.opt.clipboard = "unnamedplus"

-- Mouse
vim.opt.mouse = "a"

-- Splits
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Faster updates
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

-- Keymaps
local keymap = vim.keymap.set

-- Clear search highlight
keymap("n", "<Esc>", ":noh<CR>", { silent = true })

-- Better window navigation
keymap("n", "<C-h>", "<C-w>h")
keymap("n", "<C-j>", "<C-w>j")
keymap("n", "<C-k>", "<C-w>k")
keymap("n", "<C-l>", "<C-w>l")

-- Move lines up/down
keymap("v", "J", ":m '>+1<CR>gv=gv", { silent = true })
keymap("v", "K", ":m '<-2<CR>gv=gv", { silent = true })

-- Keep cursor centered when scrolling
keymap("n", "<C-d>", "<C-d>zz")
keymap("n", "<C-u>", "<C-u>zz")

-- Save with Ctrl+S
keymap("n", "<C-s>", ":w<CR>", { silent = true })
keymap("i", "<C-s>", "<Esc>:w<CR>", { silent = true })

-- Quit shortcuts
keymap("n", "<leader>q", ":q<CR>")
keymap("n", "<leader>Q", ":q!<CR>")

-- Simple file explorer (built-in netrw)
keymap("n", "<leader>e", ":Ex<CR>")

-- Better indenting (stay in visual mode)
keymap("v", "<", "<gv")
keymap("v", ">", ">gv")
