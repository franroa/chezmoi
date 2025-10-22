return {
  "davesavic/dadbod-ui-yank",
  dependencies = { "kristijanhusak/vim-dadbod-ui" },
  config = function()
    require("dadbod-ui-yank").setup()
  end,
}
