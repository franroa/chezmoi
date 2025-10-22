-- bootstrap lazy.nvim, LazyVim and your plugins
--
require("config.lazy")
require("plugins.local_plugins")
-- Enable diff syntax highlighting in gitcommit buffers on BufReadPost
vim.api.nvim_create_autocmd('BufReadPost', {
  callback = function()
    if vim.bo.filetype == 'gitcommit' then
      vim.cmd('syntax include @Diff syntax/diff.vim')
      vim.cmd('syntax region gitcommitDiff start=/^diff / end=/^@@/ contains=@Diff')
    end
  end,
})
