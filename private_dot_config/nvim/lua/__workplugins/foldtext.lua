return {
  "OXY2DEV/foldtext.nvim",
  event = "VeryLazy",
  config = function()
    require("foldtext").setup()
  end,
}
