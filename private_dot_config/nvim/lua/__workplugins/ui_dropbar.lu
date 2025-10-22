return {
  {
    "Bekaboo/dropbar.nvim",
    event = "VeryLazy",
    keys = {
      {
        "<leader>ub",
        function()
          require("dropbar.api").pick()
        end,
        desc = "Dropbar Pick mode",
      },
    },
    config = function()
      require("functions.winbar").UpdateHlValues()
    end,
    -- opts = function(_, opts)
    --   -- require("functions.kubernetes").UpdateGlobalValues()
    --   -- require("functions.winbar").UpdateDevIconsInDropbar()
    --   local bar = require("dropbar.bar")
    --   local custom_source = {
    --     get_symbols = function(_, _, _)
    --       if vim.g.kubernetes_cluster == "" then
    --         return {}
    --       end
    --
    --       return {
    --         bar.dropbar_symbol_t:new({
    --           icon = "󱃾 ",
    --           icon_hl = "K8sCluster",
    --           name = vim.g.kubernetes_cluster,
    --           name_hl = "K8sIcon",
    --           on_click = function(self)
    --             vim.notify("Have you smiled today? " .. self.icon)
    --           end,
    --         }),
    --         bar.dropbar_symbol_t:new({
    --           name = vim.g.kubernetes_namespace,
    --           name_hl = "K8sNamespace",
    --         }),
    --       }
    --     end,
    --   }
    --
    --   local warning = {
    --     get_symbols = function(_, _, _)
    --       if
    --         string.find(vim.g.kubernetes_cluster, "dev")
    --         or string.find(vim.g.kubernetes_cluster, "prd")
    --         or string.find(vim.g.kubernetes_cluster, "stg")
    --       then
    --         return {
    --           bar.dropbar_symbol_t:new({
    --             icon = " ",
    --             icon_hl = "WarningMsg",
    --             -- name = "Shared!",
    --             -- name_hl = "WarningMsg",
    --           }),
    --         }
    --       end
    --       return {}
    --     end,
    --   }
    --
    --   local sources = require("dropbar.sources")
    --   opts.general = {
    --     update_events = {
    --       win = {
    --         "CursorMoved",
    --         "CursorMovedI",
    --         "WinEnter",
    --         -- "WinResized",
    --       },
    --     },
    --   }
    --   opts.bar = {
    --     sources = {
    --       warning,
    --       sources.path,
    --       {
    --         get_symbols = function(buf, win, cursor)
    --           if vim.bo[buf].ft == "markdown" then
    --             return sources.markdown.get_symbols(buf, win, cursor)
    --           end
    --           for _, source in ipairs({
    --             sources.lsp,
    --             sources.treesitter,
    --           }) do
    --             local symbols = source.get_symbols(buf, win, cursor)
    --             if not vim.tbl_isempty(symbols) then
    --               return symbols
    --             end
    --           end
    --           return {}
    --         end,
    --       },
    --       custom_source,
    --     },
    --   }
    -- end,
    lazy = true,
  },
}
