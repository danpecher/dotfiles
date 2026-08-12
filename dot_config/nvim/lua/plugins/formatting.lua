local js_formatters = {
  "biome-check",
  "oxfmt",
  "prettier",
  stop_after_first = true,
}

local js_filetypes = {
  "javascript",
  "javascriptreact",
  "javascript.jsx",
  "typescript",
  "typescriptreact",
  "typescript.tsx",
  "json",
  "jsonc",
}

local function has_root(ctx, markers)
  return vim.fs.root(ctx.buf, markers) ~= nil
end

return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "biome",
        "oxfmt",
        "prettier",
        "ktlint",
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      for _, ft in ipairs(js_filetypes) do
        opts.formatters_by_ft[ft] = js_formatters
      end

      opts.formatters = opts.formatters or {}
      opts.formatters["biome-check"] = vim.tbl_deep_extend("force", opts.formatters["biome-check"] or {}, {
        require_cwd = true,
        condition = function(_, ctx)
          return has_root(ctx, { "biome.json", "biome.jsonc", ".biome.json", ".biome.jsonc" })
        end,
      })
      opts.formatters.oxfmt = vim.tbl_deep_extend("force", opts.formatters.oxfmt or {}, {
        require_cwd = true,
        condition = function(_, ctx)
          return has_root(ctx, {
            ".oxfmtrc.json",
            ".oxfmtrc.jsonc",
            "oxfmt.config.ts",
            "oxlint.config.ts",
            ".oxlintrc.json",
            ".oxlintrc.jsonc",
          })
        end,
      })
      opts.formatters.prettier = vim.tbl_deep_extend("force", opts.formatters.prettier or {}, {
        require_cwd = true,
        condition = function(_, ctx)
          return has_root(ctx, {
            ".prettierrc",
            ".prettierrc.json",
            ".prettierrc.json5",
            ".prettierrc.yaml",
            ".prettierrc.yml",
            ".prettierrc.toml",
            ".prettierrc.js",
            ".prettierrc.cjs",
            ".prettierrc.mjs",
            ".prettierrc.ts",
            "prettier.config.js",
            "prettier.config.cjs",
            "prettier.config.mjs",
            "prettier.config.ts",
          })
        end,
      })
    end,
  },
}
