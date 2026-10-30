--https://github.com/iabdelkareem/csharp.nvim
-- vim.g.OmniSharp_server_path = "/mnt/c/Users/francisco.roa/Omnisharp/OmniSharp.exe"
-- vim.g.nuget_install_with_neomake = 1
-- vim.g.OmniSharp_translate_cygwin_wsl = 1
return {
  -- {
  --   "abdulrahmanDev1/nuget.nvim",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "nvim-telescope/telescope.nvim",
  --   },
  --   config = function()
  --     require("nuget").setup()
  --   end,
  -- },
  -- {
  --   "Decodetalkers/csharpls-extended-lsp.nvim",
  --   lazy = false,
  -- },
  -- {
  --
  --   "OmniSharp/Omnisharp-vim",
  -- },
  -- {
  --   "markwoodhall/vim-nuget",
  --   lazy = false,
  --   dependencies = {
  --     {
  --       "mattn/webapi-vim",
  --     },
  --     {
  --       "Shougo/deoplete.nvim",
  --     },
  --     {
  --       "junegunn/fzf.vim",
  --     },
  --     {
  --       "neomake/neomake",
  --     },
  --   },
  -- },
  {
    "pgdanes/nug.nvim",
    config = function()
      require("nug")
    end,
  },
  -- lazy.nvim
  {

    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      "Issafalcon/neotest-dotnet",
    },
    opts = {
      adapters = {
        ["neotest-dotnet"] = {
          dap = {
            -- Extra arguments for nvim-dap configuration
            -- See https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for values
            args = { justMyCode = false },
            -- Enter the name of your dap adapter, the default value is netcoredbg
            adapter_name = "netcoredbg",
          },

          -- Let the test-discovery know about your custom attributes (otherwise tests will not be picked up)
          -- Note: Only custom attributes for non-parameterized tests should be added here. See the support note about parameterized tests
          custom_attributes = {
            xunit = { "MyCustomFactAttribute" },
            nunit = { "MyCustomTestAttribute" },
            mstest = { "MyCustomTestMethodAttribute" },
          },
          -- Provide any additional "dotnet test" CLI commands here. These will be applied to ALL test runs performed via neotest. These need to be a table of strings, ideally with one key-value pair per item.
          dotnet_additional_args = {
            "--no-build",
            "--no-restore",
            -- "--verbosity detailed",
            -- "/p:CollectCoverage=true",
            -- "/p:CoverletOutputFormat=lcov",
            -- "/p:CoverletOutput=" .. LazyVim.root.git() .. "/coverage/lcov.info",
          },
          -- Tell neotest-dotnet to use either solution (requires .sln file) or project (requires .csproj or .fsproj file) as project root
          -- Note: If neovim is opened from the solution root, using the 'project' setting may sometimes find all nested projects, however,
          --       to locate all test projects in the solution more reliably (if a .sln file is present) then 'solution' is better.
          discovery_root = "solution", -- Default
        },
      },
    },
    keys = {
      {
        "<leader>tcm",
        function()
          local function get_method_name()
            local line_number = vim.api.nvim_win_get_cursor(0)[1]
            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            local method_name = ""

            for i = line_number, 1, -1 do
              local line = lines[i]
              local match = line:match("public .- ([%w_]+)%(")
              if match then
                method_name = match
                break
              end
            end

            return method_name
          end
          require("neotest").run.run({
            vim.fn.expand("%"),
            dotnet_additional_args = {
              "--no-build",
              "--filter FullyQualifiedName~" .. get_method_name(),
              "/p:CollectCoverage=true",
              "/p:CoverletOutputFormat=lcov",
              "/p:CoverletOutput=" .. LazyVim.root.git() .. "/coverage/lcov.info",
            },
          })
        end,
        desc = "Run current method with coverage",
        ft = "cs",
      },
      {
        "<leader>tca",
        function()
          local task = require("overseer").new_task({
            cmd = "dotnet test "
              .. "--no-build "
              .. "/p:CollectCoverage=true "
              .. "/p:CoverletOutputFormat=lcov "
              .. "/p:CoverletOutput="
              .. LazyVim.root.git()
              .. "/coverage/lcov.info",
            cwd = LazyVim.root.git(),
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
        end,
        desc = "Run ALL with coverage",
        ft = "cs",
      },
      {
        "<leader>tcc",
        function()
          local function get_class_name()
            local line_number = vim.api.nvim_win_get_cursor(0)[1]
            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            local class_name = ""
            for i = line_number, 1, -1 do
              local line = lines[i]
              local match = line:match("public class ([%w_]+)")
              if match then
                class_name = match
                break
              end
            end
            return class_name
          end
          require("neotest").run.run({
            vim.fn.expand("%"),
            dotnet_additional_args = {
              "--no-build",
              "--filter FullyQualifiedName~" .. get_class_name(),
              "/p:CollectCoverage=true",
              "/p:CoverletOutputFormat=lcov",
              "/p:CoverletOutput=" .. LazyVim.root.git() .. "/coverage/lcov.info",
            },
          })
        end,
        desc = "Run class with coverage",
        ft = "cs",
      },
      {
        "<leader>tce",
        function()
          local function get_entity_name()
            local entity_name = vim.fn.input("Please enter the entity name: ")
            return entity_name
          end
          local task = require("overseer").new_task({
            cmd = "dotnet test "
              .. "--no-build "
              .. "--filter FullyQualifiedName~"
              .. get_entity_name()
              .. "/p:CollectCoverage=true "
              .. "/p:CoverletOutputFormat=lcov "
              .. "/p:CoverletOutput="
              .. LazyVim.root.git()
              .. "/coverage/lcov.info",
            cwd = LazyVim.root.git(),
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
        end,
        desc = "Run entity related code with coverage",
        ft = "cs",
      },
    },
    -- config = function(_, opts)
    --   opts.test_framework = {
    --     ["*.Tests.cs"] = "xunit",
    --     ["*.Tests.fs"] = "xunit",
    --     ["*.Tests.vb"] = "xunit",
    --     ["*.Test.cs"] = "mstest",
    --     ["*.Test.fs"] = "mstest",
    --     ["*.Test.vb"] = "mstest",
    --   }
    -- en{d,
  },
}
