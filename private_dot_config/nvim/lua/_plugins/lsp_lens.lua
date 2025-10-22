return {
  {
    "VidocqH/lsp-lens.nvim",
    event = "LspAttach",
    keys = {
      {
        "<leader>cL",
        "<cmd>LspLensToggle<cr>",
        desc = "Toggle code lens",
      },
    },
    config = function()
      require("lsp-lens").setup({
        enable = false,
      })
    end,
  },
}
