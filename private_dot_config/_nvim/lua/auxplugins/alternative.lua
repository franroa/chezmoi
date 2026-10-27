return {
  "Goose97/alternative.nvim",
  version = "*", -- Use for stability; omit to use `main` branch for the latest features
  event = "VeryLazy",
  config = function()
    require("alternative").setup({
      -- Configuration here, or leave empty to use defaults
    })
  end,
}
