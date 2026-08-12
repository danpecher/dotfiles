return {
  {
    "folke/sidekick.nvim",
    init = function()
      vim.api.nvim_create_user_command("AISessions", function()
        require("config.ai_sessions").pick()
      end, { desc = "Resume a saved AI chat session" })
    end,
    opts = {
      -- The CLI integration does not require GitHub Copilot. Keep next-edit
      -- suggestions disabled unless Copilot is intentionally configured later.
      nes = { enabled = false },
      cli = {
        watch = true,
        win = {
          layout = "right",
          split = {
            width = 90,
            height = 20,
          },
        },
        mux = {
          enabled = true,
          backend = "tmux",
          create = "terminal",
        },
      },
    },
    keys = {
      {
        "<leader>ac",
        function()
          require("sidekick.cli").toggle({ name = "claude", focus = true })
        end,
        desc = "Toggle Claude",
      },
      {
        "<leader>ax",
        function()
          require("sidekick.cli").toggle({ name = "codex", focus = true })
        end,
        desc = "Toggle Codex",
      },
      {
        "<leader>aa",
        function()
          require("sidekick.cli").toggle({ focus = true })
        end,
        desc = "Toggle AI CLI",
      },
      {
        "<leader>al",
        function()
          vim.cmd("AISessions")
        end,
        desc = "Resume AI Session",
      },
      {
        "<leader>ah",
        function()
          require("sidekick.cli").hide()
        end,
        desc = "Hide AI CLI",
      },
      {
        "<leader>a=",
        function()
          require("sidekick.cli").focus()
          vim.cmd("vertical resize 90")
        end,
        desc = "Reset AI Width",
      },
      {
        "<leader>a+",
        function()
          require("sidekick.cli").focus()
          vim.cmd("vertical resize +10")
        end,
        desc = "Widen AI Window",
      },
      {
        "<leader>a-",
        function()
          require("sidekick.cli").focus()
          vim.cmd("vertical resize -10")
        end,
        desc = "Narrow AI Window",
      },
    },
  },
}
