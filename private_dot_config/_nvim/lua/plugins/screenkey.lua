return {
  "NStefan002/screenkey.nvim",
  lazy = false,
  version = "*", -- or branch = "main", to use the latest commit
  opts = {
    win_opts = {
      row = vim.o.lines - vim.o.cmdheight - 1,
      col = 1,
      relative = "editor",
      anchor = "SE",
      width = 40,
      height = 3,
      border = "single",
      title = "Screenkey",
      title_pos = "center",
      style = "minimal",
      focusable = false,
      noautocmd = true,
    },
  },
}
