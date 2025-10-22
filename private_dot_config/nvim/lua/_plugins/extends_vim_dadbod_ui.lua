vim.api.nvim_create_autocmd("FileType", {
  pattern = "mysql",
  callback = function()
    vim.treesitter.language.register("sql", "mysql") -- Register the filetype with treesitter for the `angular` language/parser
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "dbout",
  callback = function()
    vim.treesitter.language.register("markdown", "dbout") -- Register the filetype with treesitter for the `angular` language/parser
  end,
})

vim.g.db_ui_auto_execute_table_helpers = 1
return {}
