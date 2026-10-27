vim.treesitter.language.add("river", {
  path = "/home/froa/Projects/tools/tree-sitter-river/river.so",
})
vim.treesitter.language.register("river", "alloy")

-- Force treesitter to re-initialize for this buffer
vim.schedule(function()
  if vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] then
    vim.treesitter.stop(0)
  end
  vim.treesitter.start(0, "river")
end)

vim.api.nvim_create_autocmd("BufWritePost", {
  buffer = 0,
  callback = function()
    require("functions.alloy").validate_alloy()
  end,
})
