function vira_issue()
  if vim.g.vira_active_issue then
    return vim.g.vira_active_issue
  end
  return "No Git"
end

function get_cwd()
  if vim.fn.getcwd() == LazyVim.root.git() then
    return ""
  else
    return "%#ErrorMsg# " .. vim.fn.getcwd()
  end
end

function kubernetes_cluster()
  if vim.g.kubernetes_cluster == "" then
    return ""
  end

  vim.api.nvim_set_hl(
    0,
    "K8sNamespace",
    { bold = true, fg = vim.g.kubernetes_cluster_fg, bg = vim.g.kubernetes_cluster_bg }
  )

  vim.api.nvim_set_hl(
    0,
    "K8sCluster",
    { bold = true, fg = vim.g.kubernetes_namespace_fg, bg = vim.g.kubernetes_namespace_bg }
  )

  return "%#K8sNamespace#󱃾 "
    .. "%#K8sCluster#"
    .. vim.g.kubernetes_cluster
    .. " %#K8sNamespace#("
    .. vim.g.kubernetes_namespace
    .. ")"
  -- .. "%#K8sWarningMsg# "
end

-- function battery()
--   local enabled = require("pigeon.config").options.battery.enabled
--   local battery = require("pigeon.battery").battery()

--
--   if enabled then
--     return battery
--   else
--     return ""
--   end
-- end

local tokyonight = require("lualine.themes.tokyonight")
tokyonight.normal.c.bg = "NONE"

local function test()
  return "test"
end

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local lineopts = {
        show_job_count = true, -- Default value is false
      }
      -- opts.tabline = {
      --   lualine_y = {
      --     require("vectorcode.integrations").lualine(lineopts),
      --   },
      --   lualine_z = {
      --     "test",
      --   },
      -- }
      table.insert(opts.sections.lualine_b, test)
      table.insert(opts.sections.lualine_b, require("vectorcode.integrations").lualine(lineopts))

      -- local nvimbattery = {
      --   function()
      --     return require("battery").get_status_line()
      --   end,
      -- }
      --
      -- local spotify = require("nvim-spotify").status
      --
      -- spotify:start()
      -- -- table.insert(opts.sections.lualine_c, require("neocomposer.ui").status_recording)
      -- -- table.insert(opts.sections.lualine_x, battery)
      -- -- table.insert(opts.sections.lualine_x, "ex.lsp.all")
      -- table.insert(opts.sections.lualine_x, "ex.spellcheck")
      table.insert(opts.sections.lualine_x, "overseer")
      table.insert(opts.sections.lualine_x, "codecompanion")
      -- table.insert(opts.sections.lualine_x, vira_issue)
      -- table.insert(opts.sections.lualine_b, get_cwd)
      -- table.insert(opts.sections.lualine_b, spotify.listen)
      -- table.insert(opts.sections.lualine_c, kubernetes_cluster)
      -- table.insert(opts.sections.lualine_x, nvimbattery)
      -- table.insert(opts.sections.lualine_b, require("grapple-line").status)
      -- table.insert(opts.sections.lualine_x, {
      --   function()
      --     return require("lazydo").get_lualine_stats()
      --   end,
      --   cond = function()
      --     return require("lazydo")._initialized
      --   end,
      -- })
      -- -- table.insert(
      -- --   opts.sections.lualine_x,
      -- --   function() -- TODO: crear una variable entorno para todos los plugins (kubernetes, o kulala, etc) y manejar el background color con ella
      -- --     vim.cmd("highlight RedIcon guifg=#cccccc")
      -- --     return "%#RedIcon#" .. ""
      -- --   end
      -- -- )
      --
      -- -- table.insert(opts.sections.lualine_c, require("auto-session.lib").current_session_name)
      --
      -- opts.options.theme = tokyonight
    end,

    -- keys = { {
    --   "<leader>us",
    --   function()
    --     require("lualine").setup()
    --   end,
    --   desc = "show statusline (lualine)"
    -- } },

    dependencies = {
      -- "ecthelionvi/neocomposer.nvim",
      { "dokwork/lualine-ex" },
      -- { "pheon-dev/pigeon", opts = {} },
    },
  },
}
