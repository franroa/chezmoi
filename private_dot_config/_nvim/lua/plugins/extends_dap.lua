return {
  {
    "mfussenegger/nvim-dap",
    opts = function(_, opts)
      local dap = require("dap")
      if not dap.adapters["netcoredbg"] then
        require("dap").adapters["netcoredbg"] = {
          type = "executable",
          command = vim.fn.exepath("netcoredbg"),
          args = { "--interpreter=vscode" },
          -- console = "internalConsole",
        }
        -- Configure the launch configuration
      end

      local dotnet = require("easy-dotnet")
      local debug_dll = nil
      local function ensure_dll()
        if debug_dll ~= nil then
          return debug_dll
        end
        local dll = dotnet.get_debug_dll()
        debug_dll = dll
        return dll
      end

      for _, lang in ipairs({ "cs", "fsharp", "vb" }) do
        dap.configurations[lang] = {
          {
            log_level = "DEBUG",
            type = "netcoredbg",
            justMyCode = false,
            stopAtEntry = false,
            name = "Default",
            request = "launch",
            env = function()
              local dll = ensure_dll()
              local vars = dotnet.get_environment_variables(dll.project_name, dll.relative_project_path)
              return vars or nil
            end,
            -- env = {
            --   ASPNETCORE_ENVIRONMENT = function()
            --     -- todo: request input from ui
            --     return "Development"
            --   end,
            --   ASPNETCORE_URLS = function()
            --     -- todo: request input from ui
            --     return "https://localhost:5005;http://localhost:5006"
            --   end,
            -- },
            program = function()
              require("overseer").enable_dap()
              local dll = ensure_dll()
              return dll.relative_dll_path
            end,
            cwd = function()
              local dll = ensure_dll()
              return dll.relative_project_path
            end,
            preLaunchTask = "Build .NET App With Spinner",
          },
        }

        dap.listeners.before["event_terminated"]["easy-dotnet"] = function()
          debug_dll = nil
        end
      end
    end,
    keys = {
      {
        "<leader>d<space>",
        function()
          require("which-key").show({ delay = 1000000000, keys = "<leader>d", loop = true })
        end,
        desc = "DAP Hydra Mode (which-key)",
      },
      {
        "<leader>dR",
        function()
          local dap = require("dap")
          local extension = vim.fn.expand("%:e")
          dap.run(dap.configurations[extension][1])
        end,
        desc = "Run default configuration",
      },
    },
  },
}
