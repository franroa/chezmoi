return {
  "nickjvandyke/opencode.nvim",
  version = "*", -- Latest stable release
  dependencies = {
    {
      -- `snacks.nvim` integration is recommended, but optional
      ---@module "snacks" <- Loads `snacks.nvim` types for configuration intellisense
      "folke/snacks.nvim",
      optional = true,
      opts = {
        input = {}, -- Enhances `ask()`
        picker = { -- Enhances `select()`
          actions = {
            opencode_send = function(...)
              return require("opencode").snacks_picker_send(...)
            end,
          },
          win = {
            input = {
              keys = {
                ["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
              },
            },
          },
        },
      },
    },
  },
  config = function()
    local opencode_cmd = "opencode --port"
    ---@type snacks.terminal.Opts
    local snacks_terminal_opts = {
      win = {
        position = "right",
        enter = false,
        on_win = function(win)
          -- Set up keymaps and cleanup for an arbitrary terminal
          require("opencode.terminal").setup(win.win)
        end,
      },
    }
    ---@type opencode.Opts
    vim.g.opencode_opts = {
      server = {
        start = function()
          require("snacks.terminal").open(opencode_cmd, snacks_terminal_opts)
        end,
        stop = function()
          require("snacks.terminal").get(opencode_cmd, snacks_terminal_opts):close()
        end,
        toggle = function()
          require("snacks.terminal").toggle(opencode_cmd, snacks_terminal_opts)
        end,
      },
    }
    vim.o.autoread = true -- Required for `opts.events.reload`

    -- Recommended/example keymaps
    vim.keymap.set({ "n", "x" }, "<C-a>", function()
      require("opencode").ask("@this: ", { submit = true })
    end, { desc = "Ask opencode…" })
    vim.keymap.set({ "n", "x" }, "<C-x>", function()
      require("opencode").select()
    end, { desc = "Execute opencode action…" })
    vim.keymap.set({ "n", "t" }, "<C-.>", function()
      require("opencode").toggle()
    end, { desc = "Toggle opencode" })

    vim.keymap.set({ "n", "x" }, "go", function()
      return require("opencode").operator("@this ")
    end, { desc = "Add range to opencode", expr = true })
    vim.keymap.set("n", "goo", function()
      return require("opencode").operator("@this ") .. "_"
    end, { desc = "Add line to opencode", expr = true })

    vim.keymap.set("n", "<S-C-u>", function()
      require("opencode").command("session.half.page.up")
    end, { desc = "Scroll opencode up" })
    vim.keymap.set("n", "<S-C-d>", function()
      require("opencode").command("session.half.page.down")
    end, { desc = "Scroll opencode down" })

    -- You may want these if you use the opinionated `<C-a>` and `<C-x>` keymaps above — otherwise consider `<leader>o…` (and remove terminal mode from the `toggle` keymap)
    vim.keymap.set("n", "+", "<C-a>", { desc = "Increment under cursor", noremap = true })
    vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement under cursor", noremap = true })
  end,
}
-- return {
--   "NickvanDyke/opencode.nvim",
--   dependencies = {
--     "folke/snacks.nvim",
--   },
--   ---@type opencode.Config
--   opts = {
--     -- Your configuration, if any
--   },
--   -- stylua: ignore
--   keys = {
--     -- opencode.nvim exposes a general, flexible API — customize it to your workflow!
--     -- But here are some examples to get you started :)
--     --
--     { '<leader>ot', function() require('opencode').toggle() end, desc = 'Toggle embedded opencode', },
--     { '<leader>oa', function() require('opencode').ask('@cursor: ') end, desc = 'Ask opencode', mode = 'n', },
--     { '<leader>oa', function() require('opencode').ask('@selection: ') end, desc = 'Ask opencode about selection', mode = 'v', },
--     { '<leader>op', function() require('opencode').select_prompt() end, desc = 'Select prompt', mode = { 'n', 'v', }, },
--     { '<leader>on', function() require('opencode').command('session_new') end, desc = 'New session', },
--     { '<leader>oy', function() require('opencode').command('messages_copy') end, desc = 'Copy last message', },
--     { '<leader>oy', function() require('opencode').command('messages_copy') end, desc = 'Copy last message', },
--     { '<S-C-u>',    function() require('opencode').command('messages_half_page_up') end, desc = 'Scroll messages up', },
--     { '<S-C-d>',    function() require('opencode').command('messages_half_page_down') end, desc = 'Scroll messages down', },
--     { '<leader>Ot', function() require('opencode').toggle() end, desc = 'Toggle opencode', },
--     { '<leader>Oa', function() require('opencode').ask() end, desc = 'Ask opencode', mode = { 'n', 'v' }, },
--     { '<leader>OA', function() require('opencode').ask('@file ') end, desc = 'Ask opencode about current file', mode = { 'n', 'v' }, },
--     { '<leader>Og', function() require('opencode').ask('@grapple ') end, desc = 'Ask opencode about grappled files', mode = { 'n', 'v' }, },
--     { '<leader>On', function() require('opencode').command('/new') end, desc = 'New session', },
--     { '<leader>Oe', function() require('opencode').prompt('Explain @cursor and its context') end, desc = 'Explain code near cursor' },
--     { '<leader>Or', function() require('opencode').prompt('Review @file for correctness and readability') end, desc = 'Review file', },
--     { '<leader>Of', function() require('opencode').prompt('Fix these @diagnostics') end, desc = 'Fix errors', },
--     { '<leader>Oo', function() require('opencode').prompt('Optimize @selection for performance and readability') end, desc = 'Optimize selection', mode = 'v', },
--     { '<leader>Od', function() require('opencode').prompt('Add documentation comments for @selection') end, desc = 'Document selection', mode = 'v', },
--     { '<leader>Ot', function() require('opencode').prompt('Add tests for @selection') end, desc = 'Test selection', mode = 'v', },
--   },
-- }
--
-- -- return {
-- --   "sudo-tee/opencode.nvim",
-- --   config = function()
-- --     require("opencode").setup({
-- --       default_global_keymaps = true, -- If false, disables all default global keymaps
-- --       default_mode = "build", -- 'build' or 'plan' or any custom configured. @see [OpenCode Modes](https://opencode.ai/docs/modes/)
-- --       prefered_picker = "snacks",
-- --       config_file_path = "/home/froa/.opencode.json",
-- --     })
-- --   end,
-- --   dependencies = {
-- --     "nvim-lua/plenary.nvim",
-- --     {
-- --       "MeanderingProgrammer/render-markdown.nvim",
-- --       opts = {
-- --         anti_conceal = { enabled = false },
-- --         file_types = { "markdown", "opencode_output" },
-- --       },
-- --       ft = { "markdown", "Avante", "copilot-chat", "opencode_output" },
-- --     },
-- --   },
-- -- }
