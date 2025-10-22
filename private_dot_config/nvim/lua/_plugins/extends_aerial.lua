return {
  "stevearc/aerial.nvim",
  config = function(_, opts)
    opts.backends = { "lsp", "treesitter", "markdown", "asciidoc", "man" }
    opts.filter_kind = false
    require("aerial").setup(opts)
  end,
}
