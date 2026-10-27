return {
  {
    "Isrothy/neominimap.nvim",
    enabled = true,
    lazy = false, -- WARN: NO NEED to Lazy load
    init = function()
      vim.opt.wrap = false -- Recommended
      vim.opt.sidescrolloff = 36 -- It's recommended to set a large value
      vim.g.neominimap = {
        -- Enable the plugin by default
        auto_enable = false,

        -- Log level
        log_level = vim.log.levels.OFF,

        -- Notification level
        notification_level = vim.log.levels.INFO,

        -- Path to the log file
        log_path = vim.fn.stdpath("data") .. "/neominimap.log",

        -- Minimap will not be created for buffers of these types
        exclude_filetypes = { "help", "dashboard" },

        -- Minimap will not be created for buffers of these types
        exclude_buftypes = {
          "nofile",
          "nowrite",
          "quickfix",
          "terminal",
          "prompt",
        },

        -- When false is returned, the minimap will not be created for this buffer
        buf_filter = function(bufnr)
          return true
        end,

        -- When false is returned, the minimap will not be created for this window
        win_filter = function(winid)
          return true
        end,

        -- Maximum height for the minimap
        -- If set to nil, there is no maximum height restriction
        max_minimap_height = nil,

        -- Width of the minimap window
        minimap_width = 20,

        -- How many columns a dot should span
        x_multiplier = 4,

        -- How many rows a dot should span
        y_multiplier = 1,

        -- For performance issue, when text changed,
        -- minimap is refreshed after a certain delay
        -- Set the delay in milliseconds
        delay = 200,

        -- Z-index for the floating window
        z_index = 1,

        -- Diagnostic integration
        diagnostic = {
          enabled = true,
          severity = vim.diagnostic.severity.WARN,
          priority = {
            ERROR = 100,
            WARN = 90,
            INFO = 80,
            HINT = 70,
          },
        },

        treesitter = {
          enabled = true,
          priority = 200,
        },

        -- Border style of the floating window
        -- Accepts all usual border style options (e.g., "single", "double")
        window_border = "single",
      }
    end,
  },
}
