return {
  "nuvic/fzf-kit.nvim",
  dependencies = { "ibhagwan/fzf-lua" },
  config = function()
    require("fzf-kit").setup({
      -- Optional configuration
    })
  end,
}
