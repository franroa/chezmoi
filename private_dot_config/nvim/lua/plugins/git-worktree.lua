return {
  {
    "polarmutex/git-worktree.nvim",
    version = "^2",
    dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim" },
    dir = vim.fn.expand("~/.config/nvim/lua/local_plugins/git-worktree.nvim"),
    dev = true,
    config = function()
      -- Add local plugin to Lua path if it exists
      local local_path = vim.fn.expand("~/.config/nvim/lua/local_plugins/git-worktree.nvim/lua")
      if vim.fn.isdirectory(local_path) == 1 then
        package.path = local_path .. "/?.lua;" .. local_path .. "/?/init.lua;" .. package.path
      end

      -- Plugin configuration
      vim.g.git_worktree = {
        change_directory_command = "cd",
        update_on_change = true,
        update_on_change_command = "e .",
        clearjumps_on_change = true,
        confirm_telescope_deletions = true,
        -- autopush = true,
        branches_dir = "branches",
      }

      -- Setup hooks for automatic directory changes and notifications
      local Hooks = require("git-worktree.hooks")

      -- On switch: close all buffers and switch worktree
      Hooks.register(Hooks.type.SWITCH, function(path, prev_path)
        -- Close all non-empty buffers before switching
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(bufnr) then
            -- Don't close buffers that are terminal or special
            local buftype = vim.bo[bufnr].buftype
            if buftype ~= "terminal" and buftype ~= "quickfix" then
              vim.api.nvim_buf_delete(bufnr, { force = true })
            end
          end
        end

        Hooks.builtins.update_current_buffer_on_switch(path, prev_path)

        -- Create .env file in the new worktree with GIT_DIR BEFORE switching
        local git_root = require("git-worktree.git").gitroot_dir()
        local Config = require("git-worktree.config")
        local Path = require("plenary.path")

        if git_root then
          -- Resolve the absolute path using same logic as worktree module
          local abs_path = path
          if Config.branches_dir and not Path:new(path):is_absolute() then
            abs_path = Path:new(git_root, Config.branches_dir, path):absolute()
          elseif not Path:new(path):is_absolute() then
            abs_path = Path:new(git_root, path):absolute()
          end

          local env_file = git_root .. "/.env"
          local worktree_root = abs_path
          -- In a git worktree, the actual git dir is in the main repo's .git/worktrees/<name>
          -- Get the worktree directory name
          local worktree_name = vim.fn.fnamemodify(abs_path, ":t")
          local git_dir = git_root .. "/worktrees/" .. worktree_name
          local env_content = "export GIT_DIR=" .. git_dir .. "\n"
          env_content = env_content .. "export GIT_WORK_TREE=" .. worktree_root .. "\n"

          -- Ensure directory exists
          local dir_path = Path:new(abs_path)
          if not dir_path:exists() then
            dir_path:mkdir({ parents = true })
          end

          -- Write .env file immediately (synchronously)
          local file = io.open(env_file, "w")
          if file then
            file:write(env_content)
            file:close()
            vim.fn.system("direnv allow .")
          else
            vim.notify("Failed to create .env at: " .. env_file, vim.log.levels.WARN)
          end

          -- Change to the new worktree directory
          vim.cmd("cd " .. worktree_root)

          -- Refresh oil.nvim if it's available
          if package.loaded["oil"] then
            local oil = require("oil")
            -- Open oil with the new worktree directory
            oil.open(worktree_root)
          end
        end
      end)

      -- On create: automatically switch to the new worktree after creation
      Hooks.register(Hooks.type.CREATE, function(path, branch, upstream)
        vim.cmd(vim.g.git_worktree.update_on_change_command)
        vim.schedule(function()
          require("git-worktree").switch_worktree(path)
        end)
      end)

      -- On delete: refresh buffer after deletion
      Hooks.register(Hooks.type.DELETE, function(path)
        vim.cmd(vim.g.git_worktree.update_on_change_command)
        vim.notify("Deleted worktree: " .. path, vim.log.levels.INFO)
      end)

      -- Monkey-patch snacks-worktree to show red arrow for current worktree
      local ok, snacks_worktree = pcall(require, "snacks-worktree")
      if ok then
        local original_pick = snacks_worktree.pick_git_worktree
        function snacks_worktree.pick_git_worktree()
          -- Read and patch the module's format function
          local Snacks = require("snacks")
          local Git = require("git-worktree.git")
          local uv = vim.uv or vim.loop

          local finder = function(opts, ctx)
            local args = { "worktree", "list" }
            local cwd = vim.fs.normalize(opts and opts.cwd or uv.cwd() or ".") or nil
            cwd = Snacks.git.get_root(cwd)
            local current = Git.toplevel_dir()
            return require("snacks.picker.source.proc").proc({
              opts,
              {
                cwd = cwd,
                cmd = "git",
                args = args,
                transform = function(item)
                  item.cwd = cwd
                  local fields = vim.split(string.gsub(item.text, "%s+", " "), " ")
                  item.path = fields[1]
                  item.current = current == item.path
                  item.sha = fields[2]
                  item.branch = fields[3]
                  if item.sha == "(bare)" then
                    return false
                  end
                end,
              },
            }, ctx)
          end

          local format = function(item, _)
            local a = Snacks.picker.util.align
            local ret = {}
            if item.current then
              ret[#ret + 1] = { a("➜", 2), "ErrorMsg" }
            else
              ret[#ret + 1] = { a(" ", 2) }
            end
            ret[#ret + 1] = { a(item.branch, 30, { truncate = true }), "SnacksPickerGitBranch" }
            ret[#ret + 1] = { a(item.sha, 8, { truncate = true }), "SnacksPickerGitCommit" }
            ret[#ret + 1] = { " " }
            ret[#ret + 1] = { a(item.path, 100, { truncate = true }), "SnacksPickerDirectory" }
            return ret
          end

          local switch_worktree = function(picker, item)
            local worktree_path = item.path
            if worktree_path == nil then
              vim.print("no worktree selected")
            end
            picker:close()
            require("git-worktree").switch_worktree(worktree_path)
          end

           local config = {
             all = false,
             preview = "none",
             finder = finder,
             format = format,
             layout = {
               preview = false,
             },
            confirm = switch_worktree,
            multiselect = true,
            actions = {
              delete_worktree = function(picker, item)
                local Git = require("git-worktree.git")
                local Snacks = require("snacks")
                local git_worktree = require("git-worktree")
                local current_path = Git.toplevel_dir()
                
                -- Get selected items (handles both single and multiselect)
                local items_to_delete = picker:selected()
                if not items_to_delete or #items_to_delete == 0 then
                  vim.notify("No worktree selected", vim.log.levels.WARN)
                  return
                end
                
                -- Check if any selected item is the current worktree
                for _, sel_item in ipairs(items_to_delete) do
                  if sel_item.current or sel_item.path == current_path then
                    vim.notify("Cannot delete the current worktree", vim.log.levels.WARN)
                    return
                  end
                end
                
                -- Build confirmation message
                local paths = {}
                for _, sel_item in ipairs(items_to_delete) do
                  table.insert(paths, sel_item.path)
                end
                local msg = #paths == 1 
                  and ("Delete worktree %q?"):format(paths[1])
                  or ("Delete %d worktrees?"):format(#paths)
                
                Snacks.picker.select(
                  { "Yes", "No" },
                  { prompt = msg },
                  function(_, idx)
                    if idx ~= 1 then
                      vim.notify("Deletion cancelled", vim.log.levels.INFO)
                      return
                    end
                    picker:close()
                    for _, sel_item in ipairs(items_to_delete) do
                      git_worktree.delete_worktree(sel_item.path, false)
                    end
                  end
                )
              end,
            },
            win = {
              input = {
                keys = {
                  ["<c-d>"] = { "delete_worktree", mode = { "n", "i" } },
                },
              },
            },
            on_show = function(picker)
              for i, item in ipairs(picker:items()) do
                if item.current then
                  picker.list:view(i)
                  Snacks.picker.actions.list_scroll_center(picker)
                  break
                end
              end
            end,
          }

          Snacks.picker.pick(config)
        end
      end
    end,
    keys = {
      {
        "<leader>gwm",
        function()
          require("snacks-worktree").pick_git_worktree()
        end,
        desc = "Manage Worktrees",
      },
      {
        "<leader>gwc",
        function()
          require("snacks-worktree").create_worktree()
        end,
        desc = "Create Worktree",
      },
      {
        "<leader>gwd",
        function()
          local Snacks = require("snacks")
          local Git = require("git-worktree.git")
          local git_worktree = require("git-worktree")

          -- Get current worktree
          local current_path = Git.toplevel_dir()
          if not current_path then
            vim.notify("Not in a git repository", vim.log.levels.WARN)
            return
          end

          -- Open worktree picker to select which one to delete
          Snacks.picker {
            all = false,
            preview = "none",
            finder = function(opts, ctx)
              local args = { "worktree", "list" }
              local cwd = vim.fs.normalize(opts and opts.cwd or vim.uv.cwd() or ".") or nil
              cwd = Snacks.git.get_root(cwd)
              return require("snacks.picker.source.proc").proc({
                opts,
                {
                  cwd = cwd,
                  cmd = "git",
                  args = args,
                  transform = function(item)
                    item.cwd = cwd
                    local fields = vim.split(string.gsub(item.text, "%s+", " "), " ")
                    item.path = fields[1]
                    item.current = current_path == item.path
                    item.sha = fields[2]
                    item.branch = fields[3]
                    if item.sha == "(bare)" then
                      return false
                    end
                  end,
                },
              }, ctx)
            end,
            format = function(item, _)
              local a = Snacks.picker.util.align
              local ret = {}
              if item.current then
                ret[#ret + 1] = { a("✓", 2), "SnacksPickerGitBranchCurrent" }
              else
                ret[#ret + 1] = { a(" ", 2) }
              end
              ret[#ret + 1] = { a(item.branch, 30, { truncate = true }), "SnacksPickerGitBranch" }
              ret[#ret + 1] = { a(item.sha, 8, { truncate = true }), "SnacksPickerGitCommit" }
              ret[#ret + 1] = { " " }
              ret[#ret + 1] = { a(item.path, 100, { truncate = true }), "SnacksPickerDirectory" }
              return ret
            end,
            layout = {
              preview = false,
            },
            confirm = function(picker, item)
              if item.current then
                vim.notify("Cannot delete the current worktree", vim.log.levels.WARN)
                return
              end
              Snacks.picker.select(
                { "Yes", "No" },
                { prompt = ("Delete worktree %q?"):format(item.path) },
                function(_, idx)
                  if idx ~= 1 then
                    vim.notify("Deletion cancelled", vim.log.levels.INFO)
                    return
                  end
                  picker:close()
                  git_worktree.delete_worktree(item.path, false)
                end
              )
            end,
          }
        end,
        desc = "Delete Worktree",
      },
    },
  },
}
