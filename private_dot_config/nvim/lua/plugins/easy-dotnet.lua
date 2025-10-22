-- Integrate with snack explorer
local local_plugins_path = vim.fn.stdpath("config") .. "/lua/local_plugins/"
return {
  {
    "GustavEikaas/easy-dotnet.nvim",
    -- branch = "feat/roslyn-lsp",
    -- dir = local_plugins_path .. "easy-dotnet.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
    config = function()
      local function get_secret_path(secret_guid)
        local path = ""
        local home_dir = vim.fn.expand("~")
        if require("easy-dotnet.extensions").isWindows() then
          local secret_path = home_dir
            .. "\\AppData\\Roaming\\Microsoft\\UserSecrets\\"
            .. secret_guid
            .. "\\secrets.json"
          path = secret_path
        else
          local secret_path = home_dir .. "/.microsoft/usersecrets/" .. secret_guid .. "/secrets.json"
          path = secret_path
        end
        return path
      end

      local logPath = vim.fn.stdpath("data") .. "/easy-dotnet/build.log"
      local dotnet = require("easy-dotnet")
      -- Options are not required
      dotnet.setup({
        lsp = {
          enabled = true,
          analyzer_assemblies = {
            vim.fn.expand("~") .. "/global-analyzers/SonarQube.Net.1.0.5/lib/net46/SonarQube.Net.dll",
          },
          roslynator_enabled = false,
        },
        test_runner = {
          noBuild = true,
          noRestore = true,
          vstest_path = "/home/froa/dotnet8/sdk/8.0.408/vstest.console.dll",
        },
        picker = "snacks",
        csproj_mappings = true,
        fsproj_mappings = true,
        auto_bootstrap_namespace = {
          --block_scoped, file_scoped
          type = "block_scoped",
          enabled = true,
        },
        new = {
          project = {
            prefix = "sln", -- "sln" | "none"
          },
        },
        background_scanning = true,
        terminal = function(path, action)
          local commands = {
            run = function()
              return "dotnet run --project " .. path
            end,
            test = function()
              return "dotnet test " .. path
            end,
            restore = function()
              return "dotnet restore --configfile " .. os.getenv("NUGET_CONFIG") .. " " .. path
            end,
            build = function()
              return "dotnet build  " .. path .. " /flp:v=q /flp:logfile=" .. logPath
            end,
            watch = function()
              return string.format("dotnet watch --project %s %s", path, args)
            end,
          }

          local function filter_warnings(line)
            if not line:find("warning") then
              return line:match("^(.+)%((%d+),(%d+)%)%: (.+)$")
            end
          end

          local overseer_components = {
            { "on_complete_dispose", timeout = 30 },
            "default",
            { "unique", replace = true },
            {
              "on_output_parse",
              parser = {
                diagnostics = {
                  { "extract", filter_warnings, "filename", "lnum", "col", "text" },
                },
              },
            },
            {
              "on_result_diagnostics_quickfix",
              open = true,
              close = true,
            },
          }

          if action == "run" or action == "test" then
            table.insert(overseer_components, { "restart_on_save", paths = { LazyVim.root.git() } })
          end

          local command = commands[action]()
          local task = require("overseer").new_task({
            -- strategy = {
            --   "snacks",
            --   -- use_shell = false,
            --   -- direction = "horizontal",
            --   -- open_on_start = false,
            -- },
            name = action,
            cmd = command,
            cwd = LazyVim.root.git(),
            components = overseer_components,
          })
          task:start()
        end,
        secrets = {
          path = get_secret_path,
        },
      })
    end,
  },
}
