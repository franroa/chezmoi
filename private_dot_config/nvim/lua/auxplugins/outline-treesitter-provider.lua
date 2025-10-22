return {
  "hedyhli/outline.nvim",
  config = function()
    require("outline").setup({
      providers = {
        priority = { "lsp", "coc", "markdown", "norg", "treesitter" },
      },
    })
  end,
  event = "VeryLazy",
  dependencies = {
    "epheien/outline-treesitter-provider.nvim",
  },
}
