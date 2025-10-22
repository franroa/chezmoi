return {
  {
    "cbochs/grapple.nvim",
    dependencies = {
      { "nvim-tree/nvim-web-devicons", lazy = true },
    },
    opts = {
      scope = "git_branch",
      statusline = {
        icon = "♥",
        active = "%%#GrappleActive#%s %%*",
        inactive = "%%#GrappleInactive#%s %%*",
      },
    },
    keys = {
      {
        "<C-g>",
        function()
          require("grapple").toggle()
        end,
        desc = "Add file to grapple",
      },
      {
        "<C-e>",
        function()
          require("grapple").toggle_tags()
        end,
        desc = "Toggle grapple menu",
      },
      {
        "<C-1>",
        function()
          require("grapple").select({ index = 1 })
        end,
        desc = "Navigate to file 1",
      },
      {
        "<C-2>",
        function()
          require("grapple").select({ index = 2 })
        end,
        desc = "Navigate to file 2",
      },
      {
        "<C-3>",
        function()
          require("grapple").select({ index = 3 })
        end,
        desc = "Navigate to file 3",
      },
      {
        "<C-4>",
        function()
          require("grapple").select({ index = 4 })
        end,
        desc = "Navigate to file 4",
      },
      {
        "<C-5>",
        function()
          require("grapple").select({ index = 5 })
        end,
        desc = "Navigate to file 5",
      },
    },
  },
  {
    "will-lynas/grapple-line.nvim",
    dependencies = {
      "cbochs/grapple.nvim",
    },
    version = "1.x",
    opts = {
      number_of_files = 4,
      colors = {
        active = "lualine_a_normal",
        inactive = "lualine_a_inactive",
      },
      -- Accepted values:
      -- "unique_filename" shows the filename and parent directories if needed
      -- "filename" shows the filename only
      mode = "unique_filename",
    },
  },
}
