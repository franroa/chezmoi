vim.o.completeopt = "menu,menuone"
-- https://docs.gitlab.com/editor_extensions/neovim/setup/?tab=%60lazy.nvim%60
--https://docs.gitlab.com/editor_extensions/gitlab_cli/
return {
  "https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim.git",
  -- Activate when a file is created/opened
  event = { "BufReadPre", "BufNewFile" },
  -- Activate when a supported filetype is open
  ft = { "go", "javascript", "python", "ruby", "yaml", "yml", "terraform" },
  cond = function()
    -- Only activate if token is present in environment variable.
    -- Remove this line to use the interactive workflow.
    return vim.env.GITLAB_TOKEN ~= nil and vim.env.GITLAB_TOKEN ~= ""
  end,
  opts = {
    statusline = {
      -- Hook into the built-in statusline to indicate the status
      -- of the GitLab Duo Code Suggestions integration
      enabled = true,
    },

    code_suggestions = {
      -- For the full list of default languages, see the 'auto_filetypes' array in
      -- https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/blob/main/lua/gitlab/config/defaults.lua
      auto_filetypes = { "ruby", "javascript", "yaml", "yml", "terraform" }, -- Default is { 'ruby' }
      ghost_text = {
        enabled = true, -- ghost text is an experimental feature
        toggle_enabled = "<C-h>",
        accept_suggestion = "<C-l>",
        clear_suggestions = "<C-k>",
        stream = true,
      },
    },
  },
  {
    "harrisoncramer/gitlab.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim", -- Recommended but not required. Better UI for pickers.
    },
    build = function()
      require("gitlab.server").build()
    end, -- Builds the Go binary
    config = function()
      require("gitlab").setup()
    end,
  },
}

-- https://github.com/huyhoang8398/gitlab-lsp
