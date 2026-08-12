return {
  {
    "andyg/leap.nvim",
    config = function(_, opts)
      local leap = require("leap")

      for key, value in pairs(opts) do
        leap.opts[key] = value
      end

      leap.add_default_mappings(true)
      vim.keymap.del({ "x", "o" }, "x")
      vim.keymap.del({ "x", "o" }, "X")

      vim.keymap.set({ "n", "x", "o" }, "s", "<Plug>(leap-forward)")
      vim.keymap.set({ "n", "x", "o" }, "S", "<Plug>(leap-backward)")

      vim.api.nvim_set_hl(0, "LeapBackdrop", { fg = "#545c7e" })
      vim.api.nvim_set_hl(0, "LeapLabel", { fg = "#ff9e64", bold = true })
      vim.api.nvim_set_hl(0, "LeapMatch", { fg = "#c0caf5", bold = true, underline = true })
    end,
  },
  {
    "nvimtools/hydra.nvim",
    enabled = false,
  },
}
