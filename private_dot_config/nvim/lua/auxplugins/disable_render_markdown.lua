return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    -- enabled = false,
    config = function()
      -- require("obsidian").setup({
      --   ui = { enable = false },
      -- })
      require("render-markdown").setup({
        quote = { repeat_linebreak = true },
        -- change_events = function()
        --   vim.notify("test")
        -- end,
        html = {
          enabled = true,
        },
        completions = { blink = { enabled = true } },
        file_types = {
          "alloy_tests",
          "markdown",
        },
        win_options = {
          showbreak = { default = vim.api.nvim_get_option_value("showbreak", {}), rendered = "  " },
          breakindent = { default = vim.api.nvim_get_option_value("breakindent", {}), rendered = true },
          breakindentopt = { default = vim.api.nvim_get_option_value("breakindentopt", {}), rendered = "" },
        },
      })
    end,
    -- opts = function(opts)
    --   opts.repeat_linebreak = true
    -- end,
    -- enabled = false,
  },
  {
    "OXY2DEV/markview.nvim",
    opts = {
      preview = {
        enable = true,
        filetypes = { "alloy_tests" },
      },
    },
  },
}
