return {
  "dmtrKovalenko/fold-imports.nvim",
  opts = {
    -- Kotlin uses manual folds so only imports are folded automatically.
    auto_fold = true,
    auto_fold_after_code_action = false,
    languages = {
      kotlin = {
        enabled = true,
        parsers = { "kotlin" },
        queries = {
          "(import_header) @import",
        },
        filetypes = { "kotlin" },
        patterns = { "*.kt", "*.kts" },
      },
    },
  },
  event = "BufRead",
}
