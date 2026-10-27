return {
  {
    "echasnovski/mini-git",
    version = false,
    config = function()
      require("mini.git").setup()
      local align_blame = function(au_data)
        if au_data.data.git_subcommand ~= "blame" then
          return
        end

        -- Align blame output with source
        local win_src = au_data.data.win_source
        vim.wo.wrap = false
        vim.fn.winrestview({ topline = vim.fn.line("w0", win_src) })
        vim.api.nvim_win_set_cursor(0, { vim.fn.line(".", win_src), 0 })

        -- Bind both windows so that they scroll together
        vim.wo[win_src].scrollbind, vim.wo.scrollbind = true, true
      end

      local au_opts = { pattern = "MiniGitCommandSplit", callback = align_blame }
      vim.api.nvim_create_autocmd("User", au_opts)
    end,
    keys = {
      {
        "<leader>gC",
        "<Cmd>lua MiniGit.show_at_cursor()<CR>",
        desc = "Show at cursor",
      },
      {
        "<leader>gB",
        "<Cmd>:vertical Git blame -- %<CR>",
        desc = "Blame all",
      },
    },
  },
}
