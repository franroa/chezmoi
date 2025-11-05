vim.treesitter.language.add("bruno", {
  path = "/home/froa/Projects/tools/tree-sitter-bruno/bruno.so",
})
vim.treesitter.language.register("bruno", "bruno")
vim.treesitter.start()
