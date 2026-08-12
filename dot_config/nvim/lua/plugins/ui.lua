return {
  {
    "folke/snacks.nvim",
    init = function()
      vim.api.nvim_create_user_command("TerminalNew", function()
        vim.cmd("enew")
        vim.cmd("lcd " .. vim.fn.fnameescape(LazyVim.root()))
        vim.cmd("terminal")
        vim.cmd("startinsert")
      end, { desc = "Open a new full-window terminal buffer at the project root" })
    end,
    keys = {
      { "<leader>gd", false },
      -- {
      --   "<leader>z",
      --   function()
      --     Snacks.zen.zen()
      --   end,
      --   desc = "Toggle Zen",
      -- },
      {
        "<leader>z",
        function()
          Snacks.zen.zoom()
        end,
        desc = "Toggle Zoom",
        mode = { "n", "t" },
      },
      {
        "<leader>tn",
        function()
          vim.cmd("TerminalNew")
        end,
        desc = "New Terminal Buffer",
      },
      {
        "<m-p>",
        function()
          Snacks.picker.keymaps()
        end,
        desc = "Action Picker",
      },
    },
    ---@type snacks.Config
    opts = {
      dashboard = {
        preset = {
          header = [=[


▄▄ ▄▄ ▄▄ ▄▄▄▄  ▄▄▄▄▄   ▄▄▄▄▄ ▄▄▄▄▄ ▄▄    ▄▄     ▄▄▄  ▄▄   ▄▄  ▄▄▄▄
██▄██ ██ ██▄██ ██▄▄    ██▄▄  ██▄▄  ██    ██    ██▀██ ██ ▄ ██ ███▄▄
 ▀█▀  ██ ██▄█▀ ██▄▄▄   ██    ██▄▄▄ ██▄▄▄ ██▄▄▄ ▀███▀  ▀█▀█▀  ▄▄██▀  ▄
                                                                   ▀


                        ▄▄ ▄▄  ▄▄  ▄▄▄▄
                        ██ ███▄██ ██▀▀▀
                        ██ ██ ▀██ ▀████ ▄

          ]=],
        },
      },
      picker = {
        actions = {
          trouble_open = function(...)
            return require("trouble.sources.snacks").actions.trouble_open.action(...)
          end,
        },
        sources = {
          colorschemes = {
            confirm = function(picker, item)
              picker:close()
              if item then
                picker.preview.state.colorscheme = nil
                require("config.theme").persist(item.text)
                vim.schedule(function()
                  vim.cmd("colorscheme " .. item.text)
                end)
              end
            end,
          },
          explorer = {
            cycle = true,
            git_status_open = true,
            git_changes = false,
            toggles = {
              git_changes = { icon = "G" },
            },
            transform = function(item, ctx)
              if ctx.picker.opts.git_changes and not item.status and not item.dir_status then
                return false
              end
              return item
            end,
            layout = {
              preview = "main",
              auto_hide = { "input" },
            },
            win = {
              list = {
                keys = {
                  ["G"] = "toggle_git_changes",
                },
              },
            },
          },
        },
        win = {
          input = {
            keys = {
              ["T"] = { "trouble_open", mode = { "n", "i" } },
            },
          },
          list = {
            keys = {
              ["T"] = "trouble_open",
            },
          },
        },
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    enabled = true,
    opts = function(_, opts)
      local function is_sidekick_window(win)
        if not vim.api.nvim_win_is_valid(win) then
          return false
        end
        if vim.w[win].sidekick_cli then
          return true
        end
        local buf = vim.api.nvim_win_get_buf(win)
        return vim.bo[buf].filetype == "sidekick_terminal"
      end

      local function is_diffview_window(win)
        if not vim.api.nvim_win_is_valid(win) then
          return false
        end
        local buf = vim.api.nvim_win_get_buf(win)
        local name = vim.api.nvim_buf_get_name(buf)
        local ft = vim.bo[buf].filetype
        return name:match("^diffview://") ~= nil or ft == "DiffviewFiles" or ft == "DiffviewFileHistory"
      end

      local function is_targetable_window(win)
        return vim.api.nvim_win_is_valid(win) and not is_sidekick_window(win) and not is_diffview_window(win)
      end

      local function target_window()
        local current = vim.api.nvim_get_current_win()
        if is_targetable_window(current) then
          return current
        end

        local alternate = vim.fn.win_getid(vim.fn.winnr("#"))
        if alternate ~= 0 and alternate ~= current and is_targetable_window(alternate) then
          return alternate
        end

        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          if win ~= current and is_targetable_window(win) then
            return win
          end
        end

        for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
          if tab ~= vim.api.nvim_get_current_tabpage() then
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
              if is_targetable_window(win) then
                return win
              end
            end
          end
        end

        return current
      end

      opts.options = opts.options or {}
      opts.options.left_mouse_command = function(bufnr)
        local win = target_window()
        if win ~= vim.api.nvim_get_current_win() then
          vim.api.nvim_set_current_win(win)
        end
        vim.api.nvim_set_current_buf(bufnr)
      end
    end,
  },
}
