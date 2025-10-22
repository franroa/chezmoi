return {
  "ruifm/gitlinker.nvim",
  event = "VeryLazy",
  config = function()
    require("gitlinker").setup({})
  end,
  dependencies = "nvim-lua/plenary.nvim",
}
