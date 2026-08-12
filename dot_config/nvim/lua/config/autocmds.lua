-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local group = vim.api.nvim_create_augroup("user_startup_ui", { clear = true })
local appearance_group = vim.api.nvim_create_augroup("user_appearance_sync", { clear = true })

local function apply_system_appearance()
  if vim.fn.has("mac") == 0 then
    return
  end

  local background = "light"
  local result

  if vim.system then
    result = vim.system({ "defaults", "read", "-g", "AppleInterfaceStyle" }, { text = true }):wait()
    if result.code == 0 and result.stdout and result.stdout:match("Dark") then
      background = "dark"
    end
  else
    local output = vim.fn.system({ "defaults", "read", "-g", "AppleInterfaceStyle" })
    if vim.v.shell_error == 0 and output:match("Dark") then
      background = "dark"
    end
  end

  local colorscheme = vim.g.user_colorscheme or vim.g.colors_name or "habamax"

  if vim.o.background == background and vim.g.colors_name == colorscheme then
    return
  end

  vim.o.background = background
  pcall(vim.cmd.colorscheme, colorscheme)
end

vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  callback = function()
    apply_system_appearance()
  end,
})

vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, {
  group = appearance_group,
  callback = apply_system_appearance,
})
