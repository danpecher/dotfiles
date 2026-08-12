return {
  {
    "dlyongemallo/diffview-plus.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    opts = {
      hooks = {
        diff_buf_read = function()
          vim.opt_local.foldmethod = "manual"
          vim.opt_local.foldexpr = "0"
          vim.opt_local.foldenable = false
          vim.opt_local.foldcolumn = "0"
        end,
      },
    },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Diffview Close" },
    },
  },
}
