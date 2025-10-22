return {
  {
    "direnv/direnv.vim",
    config = function()
      vim.g.direnv_silent_load = 1
      vim.g.previous_root = LazyVim.root.git()
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*",
        callback = function()
          vim.cmd("silent! lcd %:p:h")
          if vim.g.previous_root ~= LazyVim.root.git() then
            vim.notify(
              "Local CWD changed to: " .. LazyVim.root.git(),
              vim.log.levels.WARN, -- You can change this to .INFO, .ERROR, etc.
              { title = "Working Directory" }
            )
          end
          vim.g.previous_root = LazyVim.root.git()
        end,
      })
      vim.api.nvim_create_autocmd("BufEnter", {
        callback = function(args)
          vim.cmd("DirenvExport")
        end,
      })
    end,
  },
}
