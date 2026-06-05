local local_plugins_path = vim.fn.stdpath("config") .. "/lua/local_plugins/"
return {
  "git-worktree",
  dir = local_plugins_path .. "git-worktree.nvim",
  config = function()
    vim.g.GIT_WORKTREE_CREATED = false
    local function ask_for_confirmation(title, message, on_confirm)
      local choice = vim.fn.confirm(title .. "\n" .. message, "&Yes\n&No", 2)

      if choice == 1 then
        on_confirm()
      end
    end

    require("telescope").load_extension("git_worktree")

    local function copy_appsettings_file()
      local lfs = require("lfs")
      function find_file_in_parents(filename, dir)
        local file_path = dir .. "/" .. filename
        if lfs.attributes(file_path) then
          return file_path
        end

        local parent_dir = dir:match("(.*)/[^/]*")
        if parent_dir then
          return find_file_in_parents(filename, parent_dir)
        end

        return nil
      end

      local file_path = find_file_in_parents("appsettings.GITIGNORE.json", LazyVim.root.git())
      local command = "cp "
        .. file_path
        .. " "
        .. LazyVim.root.git()
        .. "/"
        .. vim.g.DOTNET_DLL_PATH
        .. "/appsettings.GITIGNORE.json"
      local task = require("overseer").new_task({
        name = "Copy Appsettings",
        cmd = command,
        cwd = LazyVim.root.git(),
      })
      task:start()
    end

    local Hooks = require("git-worktree.hooks")
    Hooks.register(Hooks.type.SWITCH, function()
      if vim.g.GIT_WORKTREE_CREATED then
        if require("easy-dotnet").is_dotnet_project() then
          copy_appsettings_file()
        end
      end
      vim.notify("Hook On Change")
      vim.g.GIT_WORKTREE_CREATED = false
    end)
    Hooks.register(Hooks.type.CREATE, function()
      vim.g.GIT_WORKTREE_CREATED = true
      if require("easy-dotnet").is_dotnet_project() then
        vim.g.DOTNET_DLL_PATH = require("easy-dotnet").get_debug_dll().project_path
      end
      vim.cmd(":bufdo bd")
    end)
    Hooks.register(Hooks.type.DELETE, function(data)
      branch_name = data:match(".*/(.*/.*)$")
      ask_for_confirmation(
        "Delete branch",
        "Are you sure you want to delete the branch " .. branch_name .. "?",
        function()
          vim.fn.system("git branch -D " .. branch_name)
          vim.notify("Branch " .. branch_name .. " deleted")
        end
      )
    end)
  end,
  keys = {
    {
      "<leader>gwm",
      function()
        require("snacks").extensions.git_worktree.git_worktree()
      end,
      desc = "Manage",
    },
    {
      "<leader>gwc",
      function()
        require("snacks").extensions.git_worktree.create_git_worktree()
      end,
      desc = "Create",
    },
  },
}
