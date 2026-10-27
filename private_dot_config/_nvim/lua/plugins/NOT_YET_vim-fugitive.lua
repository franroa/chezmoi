return {
  {
    "tpope/vim-fugitive",
    lazy = false,
    keys = {
      {
        "<leader>gp",
        function()
          -- if vim.fn.expand("%:t") == "COMMIT_EDITMSG" then
          --   vim.cmd(":w|bd")
          -- end

          vim.cmd("Git push")
        end,
        desc = "Push",
      },
      {
        "<leader>gB",
        function()
          vim.cmd("Git blame")
        end,
        desc = "Git Blame All",
      },
      {
        "<leader>gC",
        function()
          term = GetCurrentTerminal()
          if term ~= nil then
            term:toggle()
          end

          vim.cmd("Git commit")

          if term ~= nil then
            term:toggle()
          end
        end,
        desc = "Hide lazygit and open commit template",
      },
    },
  },
}
