return {
  "ray-x/forgit.nvim",
  lazy = false,
  opts = function()
    require("forgit").setup({})
  end,
  dependencies = {
    "ray-x/guihua.lua",
  },
}
