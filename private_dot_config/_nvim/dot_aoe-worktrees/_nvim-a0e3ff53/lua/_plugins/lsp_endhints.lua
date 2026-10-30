return {
  -- lazy.nvim
  {
    "chrisgrieser/nvim-lsp-endhints",
    event = "LspAttach",
    opts = {}, -- required, even if empty
    config = function(_, opts)
      require("lsp-endhints").setup({
        icons = {
          type = "󰜁 ",
          parameter = "󰏪 ",
        },
        label = {
          padding = 1,
          marginLeft = 0,
          bracketedParameters = true,
        },
        autoEnableHints = true,
      })
    end,
  },
}
