local local_plugins_path = vim.fn.stdpath("config") .. "/lua/local_plugins/"

return {
  -- -- {
  -- --   dir = local_plugins_path .. "easy-dotnet.nvim",
  -- --   dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
  -- --   config = function()
  -- --     local function get_secret_path(secret_guid)
  -- --       local path = ""
  -- --       local home_dir = vim.fn.expand("~")
  -- --       if require("easy-dotnet.extensions").isWindows() then
  -- --         local secret_path = home_dir
  -- --           .. "\\AppData\\Roaming\\Microsoft\\UserSecrets\\"
  -- --           .. secret_guid
  -- --           .. "\\secrets.json"
  -- --         path = secret_path
  -- --       else
  -- --         local secret_path = home_dir .. "/.microsoft/usersecrets/" .. secret_guid .. "/secrets.json"
  -- --         path = secret_path
  -- --       end
  -- --       return path
  -- --     end
  -- --
  -- --     local logPath = vim.fn.stdpath("data") .. "/easy-dotnet/build.log"
  -- --     local dotnet = require("easy-dotnet")
  -- --     -- Options are not required
  -- --     dotnet.setup({
  -- --       test_runner = {
  -- --         noBuild = true,
  -- --         noRestore = true,
  -- --       },
  -- --       terminal = function(path, action)
  -- --         local commands = {
  -- --           run = function()
  -- --             return "dotnet run --project " .. path
  -- --           end,
  -- --           test = function()
  -- --             return "dotnet test " .. path
  -- --           end,
  -- --           restore = function()
  -- --             return "dotnet restore --configfile " .. os.getenv("NUGET_CONFIG") .. " " .. path
  -- --           end,
  -- --           build = function()
  -- --             return "dotnet build  " .. path .. " /flp:v=q /flp:logfile=" .. logPath
  -- --           end,
  -- --         }
  -- --
  -- --         local overseer_components = {
  -- --           { "on_complete_dispose", timeout = 30 },
  -- --           "default",
  -- --           { "unique", replace = true },
  -- --           {
  -- --             "on_output_parse",
  -- --             parser = {
  -- --               diagnostics = {
  -- --                 { "extract", filter_warnings, "filename", "lnum", "col", "text" },
  -- --               },
  -- --             },
  -- --           },
  -- --           {
  -- --             "on_result_diagnostics_quickfix",
  -- --             open = true,
  -- --             close = true,
  -- --           },
  -- --         }
  -- --
  -- --         if action == "run" or action == "test" then
  -- --           table.insert(overseer_components, { "restart_on_save", paths = { LazyVim.root.git() } })
  -- --         end
  -- --
  -- --         local command = commands[action]()
  -- --         local task = require("overseer").new_task({
  -- --           strategy = {
  -- --             "toggleterm",
  -- --             use_shell = false,
  -- --             direction = "horizontal",
  -- --             open_on_start = false,
  -- --           },
  -- --           name = action,
  -- --           cmd = command,
  -- --           cwd = LazyVim.root.git(),
  -- --           components = overseer_components,
  -- --         })
  -- --         task:start()
  -- --       end,
  -- --       secrets = {
  -- --         path = get_secret_path,
  -- --       },
  -- --     })
  -- --   end,
  -- -- },
  -- {
  --   "vstest",
  --   dir = "~/.config/nvim/lua/local_plugins/neotest-vstest",
  --   name = "vstest",
  -- },
  -- {
  --   "vitest",
  --   dir = "~/.config/nvim/lua/local_plugins/neotest-vitest",
  --   name = "vitest",
  -- },
  {
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
          require("telescope").extensions.git_worktree.git_worktree()
        end,
        desc = "Manage",
      },
      {
        "<leader>gwc",
        function()
          require("telescope").extensions.git_worktree.create_git_worktree()
        end,
        desc = "Create",
      },
    },
  },

  -- {
  --   "codecompanion.nvim",
  --   dir = local_plugins_path .. "codecompanion.nvim",
  --   dependencies = {
  --     {
  --       "franco-ruggeri/codecompanion-spinner.nvim",
  --     },
  --     {
  --       "franco-ruggeri/codecompanion-lualine.nvim",
  --     },
  --     {
  --       "olimorris/codecompanion.nvim",
  --       dependencies = {
  --         --other plugins
  --         "ravitemer/codecompanion-history.nvim",
  --       },
  --     },
  --     "nvim-lua/plenary.nvim",
  --     "nvim-treesitter/nvim-treesitter",
  --     { "MeanderingProgrammer/render-markdown.nvim", ft = { "markdown", "codecompanion" } },
  --   },
  --   config = function()
  --     require("codecompanion").setup({
  --       adapters = {
  --         my_openai = function()
  --           return require("codecompanion.adapters").extend("openai_compatible", {
  --             env = {
  --               url = "http[s]://open_compatible_ai_url", -- optional: default value is ollama url http://127.0.0.1:11434
  --               api_key = "OpenAI_API_KEY", -- optional: if your endpoint is authenticated
  --               chat_url = "/v1/chat/completions", -- optional: default value, override if different
  --               models_endpoint = "/v1/models", -- optional: attaches to the end of the URL to form the endpoint to retrieve models
  --             },
  --             schema = {
  --               model = {
  --                 default = "deepseek-r1-671b", -- define llm model to be used
  --               },
  --               temperature = {
  --                 order = 2,
  --                 mapping = "parameters",
  --                 type = "number",
  --                 optional = true,
  --                 default = 0.8,
  --                 desc = "What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. We generally recommend altering this or top_p but not both.",
  --                 validate = function(n)
  --                   return n >= 0 and n <= 2, "Must be between 0 and 2"
  --                 end,
  --               },
  --               max_completion_tokens = {
  --                 order = 3,
  --                 mapping = "parameters",
  --                 type = "integer",
  --                 optional = true,
  --                 default = nil,
  --                 desc = "An upper bound for the number of tokens that can be generated for a completion.",
  --                 validate = function(n)
  --                   return n > 0, "Must be greater than 0"
  --                 end,
  --               },
  --               stop = {
  --                 order = 4,
  --                 mapping = "parameters",
  --                 type = "string",
  --                 optional = true,
  --                 default = nil,
  --                 desc = "Sets the stop sequences to use. When this pattern is encountered the LLM will stop generating text and return. Multiple stop patterns may be set by specifying multiple separate stop parameters in a modelfile.",
  --                 validate = function(s)
  --                   return s:len() > 0, "Cannot be an empty string"
  --                 end,
  --               },
  --               logit_bias = {
  --                 order = 5,
  --                 mapping = "parameters",
  --                 type = "map",
  --                 optional = true,
  --                 default = nil,
  --                 desc = "Modify the likelihood of specified tokens appearing in the completion. Maps tokens (specified by their token ID) to an associated bias value from -100 to 100. Use https://platform.openai.com/tokenizer to find token IDs.",
  --                 subtype_key = {
  --                   type = "integer",
  --                 },
  --                 subtype = {
  --                   type = "integer",
  --                   validate = function(n)
  --                     return n >= -100 and n <= 100, "Must be between -100 and 100"
  --                   end,
  --                 },
  --               },
  --             },
  --           })
  --         end,
  --
  --         gitlab_duo = function()
  --           return require("codecompanion.adapters").extend("openai_compatible", {
  --             env = {
  --               url = os.getenv("GITLAB_URL") or "https://gitlab.com",
  --               api_key = "GITLAB_TOKEN",
  --               chat_url = "/chat/completions", -- Corrected endpoint
  --               -- models_endpoint = "/models", -- May not be available, comment out if causing issues
  --             },
  --             headers = {
  --               ["User-Agent"] = "codecompanion-nvim",
  --               ["Content-Type"] = "application/json",
  --             },
  --             schema = {
  --               model = {
  --                 order = 1,
  --                 mapping = "parameters",
  --                 type = "enum",
  --                 desc = "The GitLab Duo Chat model to use for completions.",
  --                 default = "claude-3-5-sonnet",
  --                 choices = {
  --                   "claude-3-5-sonnet",
  --                   "gpt-4o",
  --                   "gpt-4o-mini",
  --                   "claude-3-haiku",
  --                 },
  --               },
  --               max_tokens = {
  --                 order = 2,
  --                 mapping = "parameters",
  --                 type = "integer",
  --                 optional = true,
  --                 default = 4096,
  --                 desc = "The maximum number of tokens to generate in the response.",
  --                 validate = function(n)
  --                   return n > 0 and n <= 8192, "Must be between 1 and 8192"
  --                 end,
  --               },
  --               temperature = {
  --                 order = 3,
  --                 mapping = "parameters",
  --                 type = "number",
  --                 optional = true,
  --                 default = 0.7,
  --                 desc = "Controls the randomness of the output. Higher values make output more random.",
  --                 validate = function(n)
  --                   return n >= 0 and n <= 2, "Must be between 0 and 2"
  --                 end,
  --               },
  --               top_p = {
  --                 order = 4,
  --                 mapping = "parameters",
  --                 type = "number",
  --                 optional = true,
  --                 default = 0.9,
  --                 desc = "Controls diversity via nucleus sampling. Lower values focus on more probable tokens.",
  --                 validate = function(n)
  --                   return n > 0 and n <= 1, "Must be between 0 and 1"
  --                 end,
  --               },
  --               project_id = {
  --                 order = 5,
  --                 mapping = "parameters",
  --                 type = "string",
  --                 optional = true,
  --                 default = nil,
  --                 desc = "GitLab project ID for context-aware responses (optional).",
  --               },
  --             },
  --           })
  --         end,
  --       },
  --       extensions = {
  --         history = {
  --           enabled = true,
  --           opts = {
  --             -- Keymap to open history from chat buffer (default: gh)
  --             keymap = "gh",
  --             -- Keymap to save the current chat manually (when auto_save is disabled)
  --             save_chat_keymap = "sc",
  --             -- Save all chats by default (disable to save only manually using 'sc')
  --             auto_save = true,
  --             -- Number of days after which chats are automatically deleted (0 to disable)
  --             expiration_days = 0,
  --             -- Picker interface (auto resolved to a valid picker)
  --             picker = "telescope", --- ("telescope", "snacks", "fzf-lua", or "default")
  --             ---Optional filter function to control which chats are shown when browsing
  --             chat_filter = nil, -- function(chat_data) return boolean end
  --             -- Customize picker keymaps (optional)
  --             picker_keymaps = {
  --               rename = { n = "r", i = "<M-r>" },
  --               delete = { n = "d", i = "<M-d>" },
  --               duplicate = { n = "<C-y>", i = "<C-y>" },
  --             },
  --             ---Automatically generate titles for new chats
  --             auto_generate_title = true,
  --             title_generation_opts = {
  --               ---Adapter for generating titles (defaults to current chat adapter)
  --               adapter = nil, -- "copilot"
  --               ---Model for generating titles (defaults to current chat model)
  --               model = nil, -- "gpt-4o"
  --               ---Number of user prompts after which to refresh the title (0 to disable)
  --               refresh_every_n_prompts = 0, -- e.g., 3 to refresh after every 3rd user prompt
  --               ---Maximum number of times to refresh the title (default: 3)
  --               max_refreshes = 3,
  --               format_title = function(original_title)
  --                 -- this can be a custom function that applies some custom
  --                 -- formatting to the title.
  --                 return original_title
  --               end,
  --             },
  --             ---On exiting and entering neovim, loads the last chat on opening chat
  --             continue_last_chat = false,
  --             ---When chat is cleared with `gx` delete the chat from history
  --             delete_on_clearing_chat = false,
  --             ---Directory path to save the chats
  --             dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
  --             ---Enable detailed logging for history extension
  --             enable_logging = false,
  --
  --             -- Summary system
  --             summary = {
  --               -- Keymap to generate summary for current chat (default: "gcs")
  --               create_summary_keymap = "gcs",
  --               -- Keymap to browse summaries (default: "gbs")
  --               browse_summaries_keymap = "gbs",
  --
  --               generation_opts = {
  --                 adapter = nil, -- defaults to current chat adapter
  --                 model = nil, -- defaults to current chat model
  --                 context_size = 90000, -- max tokens that the model supports
  --                 include_references = true, -- include slash command content
  --                 include_tool_outputs = true, -- include tool execution results
  --                 system_prompt = nil, -- custom system prompt (string or function)
  --                 format_summary = nil, -- custom function to format generated summary e.g to remove <think/> tags from summary
  --               },
  --             },
  --
  --             -- Memory system (requires VectorCode CLI)
  --             memory = {
  --               -- Automatically index summaries when they are generated
  --               auto_create_memories_on_summary_generation = true,
  --               -- Path to the VectorCode executable
  --               vectorcode_exe = "vectorcode",
  --               -- Tool configuration
  --               tool_opts = {
  --                 -- Default number of memories to retrieve
  --                 default_num = 10,
  --               },
  --               -- Enable notifications for indexing progress
  --               notify = true,
  --               -- Index all existing memories on startup
  --               -- (requires VectorCode 0.6.12+ for efficient incremental indexing)
  --               index_on_startup = false,
  --             },
  --           },
  --         },
  --         vectorcode = {
  --           ---@type VectorCode.CodeCompanion.ExtensionOpts
  --           opts = {
  --             tool_group = {
  --               -- this will register a tool group called `@vectorcode_toolbox` that contains all 3 tools
  --               enabled = true,
  --               -- a list of extra tools that you want to include in `@vectorcode_toolbox`.
  --               -- if you use @vectorcode_vectorise, it'll be very handy to include
  --               -- `file_search` here.
  --               extras = {},
  --               collapse = false, -- whether the individual tools should be shown in the chat
  --             },
  --             tool_opts = {
  --               ---@type VectorCode.CodeCompanion.ToolOpts
  --               ["*"] = {},
  --               ---@type VectorCode.CodeCompanion.LsToolOpts
  --               ls = {},
  --               ---@type VectorCode.CodeCompanion.VectoriseToolOpts
  --               vectorise = {},
  --               ---@type VectorCode.CodeCompanion.QueryToolOpts
  --               query = {
  --                 max_num = { chunk = -1, document = -1 },
  --                 default_num = { chunk = 50, document = 10 },
  --                 include_stderr = false,
  --                 use_lsp = false,
  --                 no_duplicate = true,
  --                 chunk_mode = false,
  --                 ---@type VectorCode.CodeCompanion.SummariseOpts
  --                 summarise = {
  --                   ---@type boolean|(fun(chat: CodeCompanion.Chat, results: VectorCode.QueryResult[]):boolean)|nil
  --                   enabled = false,
  --                   adapter = nil,
  --                   query_augmented = true,
  --                 },
  --               },
  --               files_ls = {},
  --               files_rm = {},
  --             },
  --           },
  --         },
  --         mcphub = {
  --           callback = "mcphub.extensions.codecompanion",
  --           opts = {
  --             show_result_in_chat = true, -- Show mcp tool results in chat
  --             make_vars = true, -- Convert resources to #variables
  --             make_slash_commands = true, -- Add prompts as /slash commands
  --           },
  --         },
  --       },
  --
  --       strategies = {
  --         chat = {
  --           tools = {
  --             ["next_edit_suggestion"] = {
  --               opts = {
  --                 --- the default is to open in a new tab, and reuse existing tabs
  --                 --- where possible
  --                 ---@type string|fun(path: string):integer?
  --                 jump_action = "tabnew",
  --               },
  --             },
  --           },
  --           adapter = "gitlab_duo",
  --           slash_commands = {
  --             -- add the vectorcode command here.
  --             codebase = require("vectorcode.integrations").codecompanion.chat.make_slash_command(),
  --           },
  --         },
  --         inline = {
  --           adapter = "gitlab_duo",
  --         },
  --       },
  --     })
  --   end,
  -- },
  -- {
  --   "grapple-neotree",
  --   dir = local_plugins_path .. "grapple-neotree",
  -- },
  -- {
  --   "vim-dadbod-ui-fork",
  --   dir = local_plugins_path .. "vim-dadbod-ui",
  --   dependencies = {
  --     {
  --       "kristijanhusak/vim-dadbod-completion",
  --       dependencies = "vim-dadbod",
  --       ft = sql_ft,
  --       init = function()
  --         vim.api.nvim_create_autocmd("FileType", {
  --           pattern = sql_ft,
  --           callback = function()
  --             local cmp = require("cmp")
  --
  --             -- global sources
  --             ---@param source cmp.SourceConfig
  --             local sources = vim.tbl_map(function(source)
  --               return { name = source.name }
  --             end, cmp.get_config().sources)
  --
  --             -- add vim-dadbod-completion source
  --             table.insert(sources, { name = "vim-dadbod-completion" })
  --
  --             -- update sources for the current buffer
  --             cmp.setup.buffer({ sources = sources })
  --           end,
  --         })
  --       end,
  --     },
  --     { "tpope/vim-dadbod", cmd = "DB" },
  --   },
  --   cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
  --   keys = {
  --     { "<leader>D", "<cmd>DBUIToggle<CR>", desc = "Toggle DBUI" },
  --   },
  --   init = function()
  --     local data_path = vim.fn.stdpath("data")
  --
  --     vim.g.db_ui_auto_execute_table_helpers = 1
  --     vim.g.db_ui_save_location = data_path .. "/dadbod_ui"
  --     vim.g.db_ui_show_database_icon = true
  --     vim.g.db_ui_tmp_query_location = data_path .. "/dadbod_ui/tmp"
  --     vim.g.db_ui_use_nerd_fonts = true
  --     vim.g.db_ui_use_nvim_notify = true
  --
  --     -- NOTE: The default behavior of auto-execution of queries on save is disabled
  --     -- this is useful when you have a big query that you don't want to run every time
  --     -- you save the file running those queries can crash neovim to run use the
  --     -- default keymap: <leader>S
  --     vim.g.db_ui_execute_on_save = false
  --   end,
  -- },
}
