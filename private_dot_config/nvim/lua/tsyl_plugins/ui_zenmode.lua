return {
  {
    "folke/zen-mode.nvim",
    lazy = true,
    cmd = "ZenMode",
    keys = {
      {
        "<leader>uz",
        function()
          vim.cmd("ZenMode")
        end,
        desc = "Zen mode",
      },
    },
    opts = function(_, opts)
      opts.plugins = {
        kitty = {
          enable = true,
        },
        wezterm = {
          enabled = true, -- TODO: do this when closing zenmode reverts wezterm changes
          -- can be either an absolute font size or the number of incremental steps
          font = "+2", -- (10% increase per step)
        },
      }
      opts.on_open = function()
        vim.cmd("TWEnable")
      end
      opts.on_close = function()
        vim.cmd("TWDisable")
      end
    end,
  },
}
