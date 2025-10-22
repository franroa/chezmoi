return {
  {
    "folke/tokyonight.nvim",
    -- opts = function(_, opts)
    --   if vim.g.transparent == true then
    --     opts.transparent = true
    --     opts.styles = {
    --       sidebars = "transparent",
    --       floats = "transparent",
    --     }
    --     opts.on_colors = function(colors)
    --       vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#55558F" })
    --       vim.api.nvim_set_hl(0, "LineNr", { fg = "white", bold = true })
    --       vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#55558F" })
    --       require("functions.kubernetes").UpdateGlobalValues()
    --       require("functions.tokyonight-colors").SetColorsByKubernetesEnv(colors)
    --     end
    --   end
    -- end,
    keys = {
      {
        "<leader>uU",
        function()
          if vim.g.transparent == true then
            vim.g.transparent = false
          else
            vim.g.transparent = true
          end
          require("functions.tokyonight-colors").UpdateColorSchemeAndTerminal()
        end,
        desc = "Toggle transparency",
      },
    },

    cond = vim.g.started_by_firenvim == nil,

    config = function()
      require("functions.kubernetes").UpdateGlobalValuesForTheFirstTime()
      require("functions.tokyonight-colors").UpdateTokyoNightTransparency()
    end,
    -- opts = {
    --   -- transparent = true,
    --   -- styles = {
    --   --   sidebars = "transparent",
    --   --   floats = "transparent",
    --   -- },
    --   -- on_highlights = function(hl, c)
    --   --   local prompt = "#2d3149"
    --   --   hl.TelescopeNormal = {
    --   --     bg = c.bg_dark,
    --   --     fg = c.fg_dark,
    --   --   }
    --   --   hl.TelescopeBorder = {
    --   --     bg = c.bg_dark,
    --   --     fg = c.bg_dark,
    --   --   }
    --   --   hl.TelescopePromptNormal = {
    --   --     bg = prompt,
    --   --   }
    --   --   hl.TelescopePromptBorder = {
    --   --     bg = prompt,
    --   --     fg = prompt,
    --   --   }
    --   --   hl.TelescopePromptTitle = {
    --   --     bg = prompt,
    --   --     fg = prompt,
    --   --   }
    --   --   hl.TelescopePreviewTitle = {
    --   --     bg = c.bg_dark,
    --   --     fg = c.bg_dark,
    --   --   }
    --   --   hl.TelescopeResultsTitle = {
    --   --     bg = c.bg_dark,
    --   --     fg = c.bg_dark,
    --   --   }
    --   -- end,
    --   on_colors = function(colors)
    --     -- vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#55558F" })
    --     -- vim.api.nvim_set_hl(0, "LineNr", { fg = "white", bold = true })
    --     -- vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#55558F" })
    --     -- require("functions.kubernetes").UpdateGlobalValues()
    --     require("functions.tokyonight-colors").UpdateTokyoNightColors()
    --   end,
    -- },
  },
}
