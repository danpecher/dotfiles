return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      local harpoon = require("harpoon")
      harpoon:setup()

      vim.keymap.set("n", "<leader>ma", function()
        harpoon:list():add()
      end, { desc = "Harpoon Add File" })

      vim.keymap.set("n", "<leader>mm", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end, { desc = "Harpoon Menu" })

      vim.keymap.set("n", "<leader>mn", function()
        harpoon:list():next()
      end, { desc = "Harpoon Next" })

      vim.keymap.set("n", "<leader>mp", function()
        harpoon:list():prev()
      end, { desc = "Harpoon Prev" })

      vim.keymap.set("n", "<leader>m1", function()
        harpoon:list():select(1)
      end, { desc = "Harpoon File 1" })

      vim.keymap.set("n", "<leader>m2", function()
        harpoon:list():select(2)
      end, { desc = "Harpoon File 2" })

      vim.keymap.set("n", "<leader>m3", function()
        harpoon:list():select(3)
      end, { desc = "Harpoon File 3" })

      vim.keymap.set("n", "<leader>m4", function()
        harpoon:list():select(4)
      end, { desc = "Harpoon File 4" })
    end,
  },
}
