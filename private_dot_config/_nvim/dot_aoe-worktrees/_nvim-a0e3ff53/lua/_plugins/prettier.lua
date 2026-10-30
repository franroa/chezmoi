return {
  "prettier/vim-prettier",
  lazy = false,
  keys = {
    {
      "<leader>cf",
      [[:<C-u>'<,'>Prettier<CR>:normal! gv=<CR>]],
      desc = "Format visual selection",
      ft = "angular.html",
      mode = "v",
      { noremap = true, silent = true },
    },
  },
}
