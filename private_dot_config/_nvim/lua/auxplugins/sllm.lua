return {
  {
    "mozanunal/sllm.nvim",
    dependencies = {
      "echasnovski/mini.notify",
      "echasnovski/mini.pick",
    },
    config = function()
      require("sllm").setup({
        -- your custom options here
      })
    end,
  },
}
