return {
  {
    "folke/edgy.nvim",
    event = "VeryLazy",
    keys = {
      -- {
      --   "<leader>ue",
      --   function()
      --     require("edgy").toggle()
      --   end,
      --   desc = "Edgy Toggle",
      -- },
      {
        "<leader>uq",
        function()
          vim.cmd("OverseerClose")
          require("edgy").close()
        end,
        desc = "Edgy Toggle",
      },
      {
        "<leader>uE",
        function()
          require("edgy").select()
        end,
        desc = "Edgy Select Window",
      },
    },
    opts = function()
      local edgy_idx = LazyVim.plugin.extra_idx("ui.edgy")
      local aerial_idx = LazyVim.plugin.extra_idx("editor.aerial")

      if edgy_idx and edgy_idx > aerial_idx then
        LazyVim.warn("The `edgy.nvim` extra must be **imported** before the `aerial.nvim` extra to work properly.", {
          title = "LazyVim",
        })
      end

      local opts = {
        bottom = {
          {
            ft = "markdown",
            title = "Alloy Tests",
            filter = function(buf, win)
              return vim.fn.expand("%") == "alloy_tests"
            end,
            size = { height = 0.5 },
          },
          {
            ft = "easy-dotnet",
            size = { height = 0.4 },
            filter = function(buf, win)
              return vim.api.nvim_win_get_config(win).relative == ""
            end,
          },
          {
            ft = "toggleterm",
            size = { height = 0.4 },
            filter = function(buf, win)
              return vim.api.nvim_win_get_config(win).relative == ""
            end,
          },
          {
            ft = "noice",
            size = { height = 0.4 },
            filter = function(buf, win)
              return vim.api.nvim_win_get_config(win).relative == ""
            end,
          },
          {
            title = "DB Query Result",
            ft = "dbout",
          },
          {
            ft = "lazyterm",
            title = "LazyTerm",
            size = { height = 0.4 },
            filter = function(buf)
              return not vim.b[buf].lazyterm_cmd
            end,
          },
          "Trouble",
          { ft = "qf",                title = "QuickFix" },
          {
            ft = "help",
            size = { height = 20 },
            -- don't open help files in edgy that we're editing
            filter = function(buf)
              return vim.bo[buf].buftype == "help"
            end,
          },
          { title = "Spectre",        ft = "spectre_panel",        size = { height = 0.4 } },
          { title = "Neotest Output", ft = "neotest-output-panel", size = { height = 15 } },
        },
        left = {
          { title = "Neotest Summary", ft = "neotest-summary", size = { height = 15 } },
          -- "neo-tree",
        },
        -- top = {
        --   { title = "Alloy Pipeline", ft = "alloy_horizontal_diagram" },
        --   -- "neo-tree",
        -- },
        right = {
          {
            ft = "copilot-chat",
            title = "Copilot Chat",
            size = { width = 80 },
          },
          right = {
            {
              ft = "opencode",
              size = { width = 0.3 },
            },
          },
          -- {
          --   ft = "oil",
          --   title = "Oil Explorer",
          --   -- filter = function(buf, win)
          --   --   return vim.fn.expand("%"):find("oil-ssh://", 1, true)
          --   -- end,
          --   size = { width = 50 },
          -- },
          {
            ft = "alloy_vertical_diagram",
            title = "Alloy Pipeline",
            size = { width = 55 },
          },
          -- {
          --   ft = "snacks_terminal",
          --   title = "Snacks Terminal",
          --   size = { width = 80 },
          -- },
          { title = "Grug Far", ft = "grug-far", size = { width = 50 } },
          {
            title = "Rest",
            ft = "json",
            size = { width = 50 },
            open = function()
              require("kulala").replay()
            end,
            filter = function(buf, win)
              return vim.api.nvim_buf_get_name(buf) == "kulala://ui"
            end,
          },
          {
            title = "Overseer",
            ft = "OverseerList",
            size = { width = 30 },
            pinned = true,
            open = function()
              require("overseer").open()
            end,
          },
          {
            title = "Database",
            ft = "dbui",
            pinned = true,
            width = 0.3,
            open = function()
              vim.cmd("DBUI")
            end,
          },
          {
            title = "Aerial",
            ft = "aerial",
            open = "AerialOpen",
          },
        },
        keys = {
          -- increase width
          ["<c-Right>"] = function(win)
            win:resize("width", 2)
          end,
          -- decrease width
          ["<c-Left>"] = function(win)
            win:resize("width", -2)
          end,
          -- increase height
          ["<c-Up>"] = function(win)
            win:resize("height", 2)
          end,
          -- decrease height
          ["<c-Down>"] = function(win)
            win:resize("height", -2)
          end,
        },
      }

      if LazyVim.has("neo-tree.nvim") then
        local pos = {
          filesystem = "left",
          buffers = "top",
          git_status = "right",
          document_symbols = "bottom",
          diagnostics = "bottom",
        }
        local sources = LazyVim.opts("neo-tree.nvim").sources or {}
        for i, v in ipairs(sources) do
          local pinned = false
          local title = "Neo-Tree " .. v:gsub("_", " "):gsub("^%l", string.upper)
          local height = nil
          local collapse = true
          if v == "filesystem" then
            pinned = true
          end
          if v == "grapple-neotree" then
            title = "Neo-Tree Grapple"
            pinned = true
            height = 10
            collapse = false
          end
          if v == "netman.ui.neo-tree" then
            title = "Neo-Tree Remote"
            v = "remote"
          end
          local item = {
            title = title,
            ft = "neo-tree",
            filter = function(buf)
              return vim.b[buf].neo_tree_source == v
            end,
            pinned = pinned,
            open = function()
              vim.cmd(("Neotree show position=%s %s dir=%s"):format(pos[v] or "bottom", v, LazyVim.root()))
            end,
            collapse = collapse,
          }

          if height ~= nil then
            item.size = { height = height }
          end

          table.insert(opts.left, i, item)
        end
      end

      for _, pos in ipairs({ "top", "bottom", "left", "right" }) do
        opts[pos] = opts[pos] or {}
        table.insert(opts[pos], {
          ft = "trouble",
          filter = function(_buf, win)
            return vim.w[win].trouble
                and vim.w[win].trouble.position == pos
                and vim.w[win].trouble.type == "split"
                and vim.w[win].trouble.relative == "editor"
                and not vim.w[win].trouble_preview
          end,
        })
      end
      return opts
    end,
  },
}
