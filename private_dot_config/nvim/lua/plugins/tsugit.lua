---@module "lazy"
---@type LazySpec
return {
  "mikavilpas/tsugit.nvim",
  keys = {
    {
      "<right>",
      function()
        -- if lazygit is running in the background but hidden, show it.
        -- otherwise, start it and focus it.
        require("tsugit").toggle()
      end,
      { silent = true, desc = "toggle lazygit" },
    },
    {
      "<leader>gl",
      function()
        -- display the commit history for the current file in lazygit.
        -- do not keep lazygit open after it has been closed.
        require("tsugit").toggle_for_file()
      end,
      { silent = true, desc = "lazygit file commits" },
    },
  },
  -- NOTE: opts is required in lazy.nvim so that setup() is called
  ---@type tsugit.UserConfig
  opts = {
    -- The key mappings that are active when lazygit is open. They are
    -- completely unusable by lazygit, so set the to rare keys.
    --
    -- If you want to completely disable keys, you can set them to `false`.
    -- You can also set `keys = false` to disable automatically creating keymaps.
    keys = {
      -- when lazygit is open and focused, hide it but keep it running in the
      -- background
      toggle = "<right>",
      -- when lazygit is open and focused, kill it and warm up the next
      -- instance
      force_quit = "<c-c>",
    },
    debug = false, -- set to true to enable debug logging

    integrations = {
      -- off by default. The structure is shown here for reference.
      conform = {
        -- use conform.nvim and https://github.com/fsouza/prettierd to format
        -- git COMMIT_EDITMSG files as markdown. More details are available in
        -- the readme.
        formatter = "prettierd",
      },
    },
  },
}
