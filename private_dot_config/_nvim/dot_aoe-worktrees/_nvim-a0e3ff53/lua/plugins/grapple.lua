return {
  {
    "cbochs/grapple.nvim",
    event = "VeryLazy",
    keys = function()
      local keys = {
        {
          "<leader>H",
          function()
            require("grapple").toggle()
          end,
          desc = "Grapple File",
        },
        {
          "<leader>hm",
          function()
            require("grapple").toggle_tags()
          end,
          desc = "Grapple Quick Menu",
        },
        {
          "<leader>he",
          function()
            require("neo-tree.command").execute({ toggle = true, source = "grapple-neotree" })
          end,
          desc = "Neotree grapple-neotree",
        },
      }

      for i = 1, 5 do
        table.insert(keys, {
          "<leader>" .. i,
          "<cmd>Grapple select index=" .. i .. "<cr>",
          desc = "Grapple File " .. i,
        })
      end
      return keys
    end,
    config = function()
      require("grapple").setup({
        icons = false,
        win_opts = {
          border = "single",
          width = 0.3,
          height = 0.2,
        },
      })
    end,
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
