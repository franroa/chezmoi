return {
  "harrisoncramer/gitlab.nvim",
  requires = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "dlyongemallo/diffview.nvim", -- Maintained fork of "sindrets/diffview.nvim".
    "stevearc/dressing.nvim", -- Recommended but not required. Better UI for pickers.
    "nvim-tree/nvim-web-devicons", -- Recommended but not required. Icons in discussion tree.
  },
  run = function()
    require("gitlab.server").build()
  end, -- Builds the Go binary
  config = function()
    require("diffview") -- We require some global state from diffview
    require("gitlab").setup()
  end,
}
