vim.g.mkdp_browser = '/usr/bin/brave-browser'

return {
  {
    "iamcco/markdown-preview.nvim",
    build = function() vim.fn["mkdp#util#install"]() end,
    lazy = false,
  }
}
