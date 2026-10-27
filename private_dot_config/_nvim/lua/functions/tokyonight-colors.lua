local M = {}
function M.UpdateColorSchemeAndTerminal()
  require("functions.kubernetes").UpdateGlobalValues()
  require("functions.wezterm").wezterm()
  require("functions.tokyonight-colors").UpdateTokyoNightTransparency()
  vim.cmd([[Lazy reload mason.nvim]])
  if vim.g.transparent == true then
    require("lspconfig.ui.windows").default_options.border = "rounded"
  else
    require("lspconfig.ui.windows").default_options.border = "none"
  end

  -- TODO:
  -- put the mason values as require function to not be needed to reload plugins
  -- check borders in lazy, mason, lsp
  -- Set colors in lualine when changing transparency,
  -- Put all transparency config in this function
  -- vim.cmd([[Lazy reload transparent.nvim]])
  -- better place UpdateGLobalValues
  --

  vim.cmd([[colorscheme tokyonight]])
  vim.cmd([[Lazy reload incline.nvim]])
  local winbar_bg = "#303b33"
  vim.api.nvim_set_hl(0, "Winbar", { bold = true, bg = winbar_bg })
  im_set_hl(0, "WinbarNC", { bold = true, bg = winbar_bg })
end

function M.UpdateTokyoNightTransparency()
  if vim.g.transparent == true then
    require("tokyonight").setup({
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
      on_colors = function(colors)
        vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#55558F" })
        vim.api.nvim_set_hl(0, "LineNr", { fg = "white", bold = true })
        vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#55558F" })
        require("functions.tokyonight-colors").SetColorsByKubernetesEnv(colors)
      end,
    })
  end
  if vim.g.transparent == false or vim.g.transparent == nil then
    require("tokyonight").setup({

      sidebars = { "qf", "vista_kind", "terminal", "packer", "help" },
      on_highlights = function(hl, c)
        local prompt = "#2d3149"
        hl.TelescopeNormal = {
          bg = c.bg_dark,
          fg = c.fg_dark,
        }
        hl.TelescopeBorder = {
          bg = c.bg_dark,
          fg = c.bg_dark,
        }
        hl.TelescopePromptNormal = {
          bg = prompt,
        }
        hl.TelescopePromptBorder = {
          bg = prompt,
          fg = prompt,
        }
        hl.TelescopePromptTitle = {
          bg = prompt,
          fg = prompt,
        }
        hl.TelescopePreviewTitle = {
          bg = c.bg_dark,
          fg = c.bg_dark,
        }
        hl.TelescopeResultsTitle = {
          bg = c.bg_dark,
          fg = c.bg_dark,
        }
      end,
      on_colors = function(colors)
        require("functions.tokyonight-colors").SetColorsByKubernetesEnv(colors)
      end,
    })
  end
end

function M.SetColorsByKubernetesEnv(colors)
  if vim.g.kubernetes_cluster == "" then
    colors.bg = "#222436"
    colors.bg_dark = "#222436"
    return
  end

  if string.find(vim.g.kubernetes_cluster, "fran") or string.find(vim.g.kubernetes_cluster, "kind") then
    colors.bg = "#303b33"

    colors.bg_search = "#3a463d"
    colors.bg_sidebar = "#3a463d"
    colors.bg_float = "#3a463d"

    -- colors.error = colors.red1
    -- colors.warning = colors.yellow
    -- colors.info = colors.blue2
    -- colors.hint = colors.teal
    return
  end

  if string.find(vim.g.kubernetes_cluster, "dev") then
    colors.bg = "#182f6d"

    colors.bg_search = "#253f96"
    colors.bg_sidebar = "#253f96"
    colors.bg_float = "#253f96"

    return
  end

  if string.find(vim.g.kubernetes_cluster, "prd") or string.find(vim.g.kubernetes_cluster, "stg") then
    colors.bg = "#ff0000"

    colors.bg_search = "#ff0000"
    colors.bg_sidebar = "#ff0000"
    colors.bg_float = "#ff0000"

    return
  end
  -- colors.hint = colors.orange
  -- colors.error = "#ff0000"
end

return M
