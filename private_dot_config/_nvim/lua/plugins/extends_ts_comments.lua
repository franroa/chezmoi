return {
  {
    "folke/ts-comments.nvim",
    opts = function(_, opts)
      local lang = opts.langs or {}
      opts["lang"] = vim.tbl_deep_extend("force", lang, {
        json = "// %s",
        river = "// %s",
      })
    end,
  },
}
