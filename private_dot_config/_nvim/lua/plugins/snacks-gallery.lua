return {
  "TKasperczyk/snacks-gallery.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = {},
  keys = {
    {
      "<leader>gi",
      function()
        require("snacks-gallery").open()
      end,
      desc = "Gallery",
    },
  },
}
