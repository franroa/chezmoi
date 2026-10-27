return {
  {
    "chrisgrieser/nvim-rip-substitute",
    lazy = "VeryLazy",
    keys = {
      {
        "<leader>sR",
        function()
          require("rip-substitute").sub()
        end,
        mode = { "x" },
        desc = " rip substitute",
      },
    },
  },
}
