-- The "river" parser/queries are managed by nvim-treesitter (see extends_treesitter.lua)
-- Force treesitter to re-initialize for this buffer
vim.schedule(function()
  if vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] then
    vim.treesitter.stop(0)
  end
  pcall(vim.treesitter.start, 0, "river")
end)

vim.api.nvim_create_autocmd("BufWritePost", {
  buffer = 0,
  callback = function()
    require("functions.alloy").validate_alloy()
  end,
})
