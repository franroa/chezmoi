return {
  {
    "benlubas/wrapping-paper.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    keys = {
      {

        "<leader>uW",
        function()
          require("wrapping-paper").wrap_line()
        end,
        desc = "fake wrap current line",
      },
    },
  },
}
