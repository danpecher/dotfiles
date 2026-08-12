return {
  {
    "folke/persistence.nvim",
    lazy = false,
    opts = {},
    config = function(_, opts)
      local persistence = require("persistence")
      persistence.setup(opts)

      vim.api.nvim_create_autocmd("User", {
        pattern = "PersistenceLoadPost",
        callback = function()
          vim.schedule(function()
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              local buf = vim.api.nvim_win_get_buf(win)
              if vim.bo[buf].filetype == "kotlin" then
                vim.wo[win].foldmethod = "manual"
                vim.wo[win].foldenable = true
                vim.wo[win].foldlevel = 0
                vim.api.nvim_win_call(win, function()
                  vim.cmd("silent! normal! zE")
                  local ok, fold_imports = pcall(require, "fold_imports")
                  if ok then
                    fold_imports.fold_imports()
                  end
                end)
              end
            end
          end)
        end,
      })

      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          if vim.g.vscode or vim.fn.argc(-1) ~= 0 then
            return
          end

          vim.schedule(function()
            local branch_session = persistence.current()
            local project_session = persistence.current({ branch = false })
            if vim.fn.filereadable(branch_session) == 1 or vim.fn.filereadable(project_session) == 1 then
              persistence.load()
            end
          end)
        end,
      })
    end,
  },
}
