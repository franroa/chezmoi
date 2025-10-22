return {
  {
    "f-person/git-blame.nvim",
    lazy = false,
  },
  {
    "FabijanZulj/blame.nvim",
    config = function()
      require("blame").setup()
    end,
  },
}
