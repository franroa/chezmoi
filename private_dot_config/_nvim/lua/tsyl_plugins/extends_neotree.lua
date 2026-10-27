vim.g.is_git_diff_buffer = false
vim.api.nvim_create_autocmd({ "BufReadPost" }, {
  callback = function(args)
    if vim.g.is_git_diff_buffer then
      vim.defer_fn(function()
        vim.cmd("normal! gg")
        require("mini.diff").toggle_overlay(vim.fn.bufnr("%"))
        vim.cmd("BufferLineCloseOthers")
      end, 200)
      vim.g.is_git_diff_buffer = false
    end
  end,
})
-- -- https://github.com/nvim-neo-tree/neo-tree.nvim/wiki/Recipes#open-with-system-viewer
return {
  -- file explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
      -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
      {
        "s1n7ax/nvim-window-picker",
        version = "2.*",
        config = function()
          package.cpath = package.cpath .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/lib/lua/5.1/?.so"
          package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?.lua;"
          require("window-picker").setup({
            filter_rules = {
              include_current_win = false,
              autoselect_one = true,
              -- filter using buffer options
              bo = {
                -- if the file type is one of following, the window will be ignored
                filetype = { "neo-tree", "neo-tree-popup", "notify" },
                -- if the buffer type is one of following, the window will be ignored
                buftype = { "terminal", "quickfix" },
              },
            },
          })
        end,
      },
    },
    keys = {
      {
        "<leader>fe",
        function()
          require("edgy").toggle("left")
        end,
        desc = "Edgy-Neotree Toggle",
      },
    },
    opts = function(_, opts)
      -- table.insert(opts.sources, "netman.ui.neo-tree") -- Insert the first dummy string
      -- table.insert(opts.sources, "grapple-neotree") -- Insert the first dummy string
      -- opts.event_handlers = opts.event_handlers or {}
      -- table.insert(opts.event_handlers, {
      --
      --   {
      --     event = "neo_tree_window_after_open",
      --     handler = function()
      --       -- require("tint").refresh()
      --       if vim.g.should_track_neotree_window then
      --         vim.g.was_neotree_manually_opened = true
      --       end
      --     end,
      --   },
      --   {
      --     event = "neo_tree_window_after_close",
      --     handler = function()
      --       if vim.g.should_track_neotree_window then
      --         vim.g.was_neotree_manually_opened = false
      --       end
      --     end,
      --   },
      -- })
      --
      opts.filesystem = {
        commands = {
          -- over write default 'delete' command to 'trash'.
          delete = function(state)
            local inputs = require("neo-tree.ui.inputs")
            local path = state.tree:get_node().path
            local msg = "Are you sure you want to trash " .. path
            inputs.confirm(msg, function(confirmed)
              if not confirmed then
                return
              end

              vim.notify("trash-put " .. vim.fn.fnameescape(path))
              vim.fn.system("trash-put " .. vim.fn.fnameescape(path))
              require("neo-tree.sources.manager").refresh(state.name)
            end)
          end,

          -- over write default 'delete_visual' command to 'trash' x n.
          delete_visual = function(state, selected_nodes)
            local inputs = require("neo-tree.ui.inputs")

            -- get table items count
            function GetTableLen(tbl)
              local len = 0
              for n in pairs(tbl) do
                len = len + 1
              end
              return len
            end

            local count = GetTableLen(selected_nodes)
            local msg = "Are you sure you want to trash " .. count .. " files ?"
            inputs.confirm(msg, function(confirmed)
              if not confirmed then
                return
              end
              for _, node in ipairs(selected_nodes) do
                vim.fn.system("trash-put " .. vim.fn.fnameescape(node.path))
              end
              require("neo-tree.sources.manager").refresh(state.name)
            end)
          end,
        },
        bind_to_cwd = false,
        follow_current_file = {
          enabled = true,
        },
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
          -- hide_by_name = {
          --   ".DS_Store",
          --   "thumbs.db",
          --   "node_modules",
          -- },
        },
      }
      opts.git_status = {
        commands = {
          open_git_diff = function(state)
            local node = state.tree:get_node()
            local path = node:get_id()
            vim.g.is_git_diff_buffer = true
            vim.cmd(":e " .. path)
          end,
        },
        window = {
          mappings = {
            ["d"] = "open_git_diff",
          },
        },
      }
      opts.commands = {
        open_terminal = function(state)
          local node = state.tree:get_node() -- node in focus when keybind is pressed
          local abs_path = node.path

          local cwd = vim.fn.fnamemodify(abs_path, ":h")

          OpenOrCreateTerminal({
            non_k8s = true,
            name = cwd,
            dir = cwd,
            instruction = vim.o.shell,
          })
        end,
        system_open = function(state)
          local node = state.tree:get_node()
          local path = node:get_id()
          -- Linux: open file in default application
          vim.fn.jobstart({ "zathura", path }, { detach = true })
        end,
        restore_last_removed = function(state)
          -- TODO:
          vim.notify("Restoring last removed: TODO")
        end,
        execute_bash = function(state)
          local node = state.tree:get_node() -- node in focus when keybind is pressed
          local abs_path = node.path
          local file_ext = node.ext
          local cwd = nil

          if file_ext ~= "sh" then
            vim.notify("Not a sh script")
            return
          end

          local mode = require("lfs").attributes(abs_path, "mode")
          if mode == "file" then
            cwd = string.match(abs_path, "(.+)/")
          else
            cwd = abs_path
          end

          local task = require("overseer").new_task({
            strategy = {
              "toggleterm",
              use_shell = false,
              direction = "horizontal",
              open_on_start = false,
            },
            name = node.name,
            cmd = "bash" .. " " .. abs_path,
            cwd = cwd,
          })
          task:start()
          -- OpenOrCreateTerminal({
          --   non_k8s = true,
          --   name = abs_path,
          --   instruction = "bash" .. " " .. abs_path,
          -- })
        end,
        execute_fish = function(state)
          local node = state.tree:get_node() -- node in focus when keybind is pressed
          local abs_path = node.path
          local file_ext = node.ext

          if file_ext ~= "fish" then
            vim.notify("Not a fish script")
            return
          end

          OpenOrCreateTerminal({
            non_k8s = true,
            name = abs_path,
            instruction = "fish" .. " " .. abs_path,
          })
        end,
        search_in_folder = function(state)
          local node = state.tree:get_node() -- node in focus when keybind is pressed
          local abs_path = node.path

          local lfs = require("lfs")
          local mode = lfs.attributes(abs_path, "mode")
          if mode == "file" then
            abs_path = string.match(abs_path, "(.+)/")
          end

          require("grug-far").with_visual_selection({ prefills = { flags = abs_path } })
        end,
      }

      opts.window = {
        mappings = {
          ["B"] = "execute_bash",
          ["S"] = "search_in_folder",
          ["F"] = "execute_fish",
          ["Ot"] = "open_terminal",
          ["Os"] = "system_open",
          ["u"] = "restore_last_removed",
          ["P"] = { "toggle_preview", config = { use_float = false, use_image_nvim = true } },
        },
      }
    end,
  },
}
