return {
  "mtrajano/tssorter.nvim",
  config = function()
    require("tssorter").setup({
      -- leave empty for the default config or define your own sortables in here. They will add, rather than
      -- replace, the defaults for the given filetype
    })
  end, -- latest stable version, use `main` to keep up with the latest changes
  version = "*",
  keys = {
    {
      "<leader>uS",
      function()
        require("tssorter").sort()
      end,
      desc = "Treesitter Sort",
    },
  },
}
