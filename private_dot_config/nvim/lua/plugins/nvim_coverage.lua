vim.g.is_coverage_loaded = false

local function is_vue_project()
  local git_worktree_root = os.getenv("GIT_WORK_TREE")
  if not git_worktree_root then
    return false
  end

  -- Check for package.json
  local package_json_path = git_worktree_root .. "/package.json"
  local package_json = io.open(package_json_path, "r")
  if not package_json then
    return false
  end

  local content = package_json:read("*a")
  package_json:close()

  -- Check if Vue is listed as a dependency or devDependency
  if content:match('"vue"') then
    return true
  end

  return false
end

return {
  "andythigpen/nvim-coverage",
  requires = "nvim-lua/plenary.nvim",
  -- Optional: needed for PHP when using the cobertura parser
  -- rocks = { "lua-xmlreader" }, TODO:
  lazy = false,
  config = function()
    require("coverage").setup({
      -- load_coverage_cb = function(ftype)
      --   vim.notify("Loaded " .. ftype .. " coverage")
      -- end,
      highlights = {
        covered = {
          fg = "#98FB98",
        },
      },
      -- coverage_file = LazyVim.root.git() .. "/../../coverage/lcov.info",
      -- auto_reload = true,
    })
    vim.api.nvim_create_autocmd({ "BufEnter" }, {
      pattern = { "typescript", "cs" },
      callback = function()
        if vim.g.is_coverage_loaded then
          local git_worktree_root = os.getenv("GIT_WORK_TREE")
          if git_worktree_root then
            local coverage_output = git_worktree_root .. "/coverage/lcov.info"
            require("coverage").load_lcov(coverage_output)
          end
        end
      end,
    })
  end,
  keys = {
    {
      "<leader>tcf",
      function()
        local git_worktree_root = os.getenv("GIT_WORK_TREE")
        if not git_worktree_root then
          vim.notify("GIT_WORK_TREE environment variable not set", vim.log.levels.ERROR)
          return
        end

        if not is_vue_project() then
          local function find_test_project()
            local git_worktree_root = os.getenv("GIT_WORK_TREE")
            if not git_worktree_root then
              error("GIT_WORK_TREE environment variable not set")
            end

            local handle = io.popen("find " .. git_worktree_root .. " -name '*Tests.csproj' -type f 2>/dev/null")
            local result = handle:read("*a")
            handle:close()

            local project_path = result:match("([^\n]+)")

            if not project_path then
              error("Could not find test project")
            end

            return project_path
          end

          local project_path = find_test_project()
          local coverage_output = git_worktree_root .. "/coverage/lcov.info"
          local task = require("overseer").new_task({
            cmd = "dotnet test "
              .. "--no-build "
              -- .. project_path
              .. require("easy-dotnet").try_get_selected_solution().path
              .. " "
              .. "/p:CollectCoverage=true "
              .. "/p:CoverletOutputFormat=lcov "
              .. "/p:CoverletOutput="
              .. coverage_output,
            cwd = git_worktree_root,
            components = {
              {
                "on_output_quickfix",
                errorformat = vim.o.grepformat,
                open_height = 8,
                items_only = true,
              },
              -- We don't care to keep this around as long as most tasks
              { "on_complete_dispose", timeout = 30 },
              "default",
            },
          })
          task:start()
        else
          local task = require("overseer").new_task({
            cmd = "npm run test:coverage",
            components = {
              {
                "on_output_quickfix",
                errorformat = vim.o.grepformat,
                open_height = 8,
                items_only = true,
              },
              { "on_complete_dispose", timeout = 30 },
              "default",
            },
          })
          task:start()
        end
      end,
      desc = "Run ALL with coverage",
      ft = { "typescript", "cs" },
    },

    {
      "<leader>Ct",
      function()
        local git_worktree_root = os.getenv("GIT_WORK_TREE")
        if not git_worktree_root then
          vim.notify("GIT_WORK_TREE environment variable not set", vim.log.levels.ERROR)
          return
        end
        local coverage_output = git_worktree_root .. "/coverage/lcov.info"
        require("coverage").load_lcov(coverage_output)
        require("coverage").toggle()
        vim.g.is_coverage_loaded = not vim.g.is_coverage_loaded
      end,
      desc = "Toggle coverage",
      mode = "n",
    },
    {
      "<leader>Cs",
      function()
        if not vim.g.is_coverage_loaded then
          local git_worktree_root = os.getenv("GIT_WORK_TREE")
          if not git_worktree_root then
            vim.notify("GIT_WORK_TREE environment variable not set", vim.log.levels.ERROR)
            return
          end
          local coverage_output = git_worktree_root .. "/coverage/lcov.info"
          require("coverage").load_lcov(coverage_output)
          vim.g.is_coverage_loaded = false
        end
        require("coverage").summary()
      end,
      desc = "Open Summary",
      mode = "n",
    },
  },
}
