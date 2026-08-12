-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local function rename_buffer(name)
  if not name or name == "" then
    local current = vim.api.nvim_buf_get_name(0)
    local default = current ~= "" and vim.fn.fnamemodify(current, ":t") or ""
    vim.ui.input({ prompt = "Buffer name: ", default = default }, function(input)
      if input and input ~= "" then
        rename_buffer(input)
      end
    end)
    return
  end

  local ok, err = pcall(vim.api.nvim_buf_set_name, 0, name)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR, { title = "Buffer rename failed" })
    return
  end

  vim.bo.buflisted = true
end

vim.api.nvim_create_user_command("BufferRename", function(opts)
  rename_buffer(opts.args)
end, {
  nargs = "?",
  desc = "Rename the current buffer",
})

vim.keymap.set("n", "<leader>bR", "<cmd>BufferRename<cr>", { desc = "Rename Buffer" })
vim.keymap.set("t", "<esc><esc>", "<C-\\><C-n>", { desc = "Enter Normal Mode" })
vim.keymap.set({ "n", "t" }, "<C-t>", function()
  Snacks.terminal.focus(nil, { cwd = LazyVim.root() })
end, { desc = "Terminal (Root Dir)" })
vim.keymap.set({ "n", "t" }, "<M-t>", function()
  Snacks.terminal.focus(nil, { cwd = LazyVim.root() })
end, { desc = "Terminal (Root Dir)" })
vim.keymap.set("n", "<C-e>", function()
  require("neo-tree.command").execute({ toggle = true, dir = LazyVim.root() })
end, { desc = "Toggle Explorer (Root Dir)" })
vim.keymap.set("n", "<leader>gs", function()
  Snacks.picker.git_status()
end, { desc = "Git Status" })

vim.keymap.set("n", "<M-p>", function()
  require("snacks").picker.files()
end, { desc = "Find Files" })
