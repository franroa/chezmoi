return {
  {
    "ramilito/kubectl.nvim",
    keys = {
      {
        "<leader>kk",
        function()
          require("kubectl").open()
        end,
        desc = "Kubectl",
      },
    },
    config = function()
      require("kubectl").setup()
    end,
  },
}
