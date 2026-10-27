-- return {
--   -- "simnalamburt/vim-mundo",
--   "mbbill/undotree",
--   keys = {
--     { "<leader>uu", ":UndotreeToggle<CR>", desc = "Toggle Undo Tree" },
--   },
--   config = function()
--
--   local current_file = vim.fn.expand("%")
--     vim.g.undotree_DiffCommand = "term git diff -- " .. vim.fn.shellescape(current_file) .. " | delta""
--   end,
-- }
--
-- https://github.com/Ruskei/undotree
return {
  "jiaoshijie/undotree",
  dependencies = "nvim-lua/plenary.nvim",
  config = true,
  keys = { -- load the plugin only when using it's keybinding:
    { "<leader>uu", "<cmd>lua require('undotree').toggle()<cr>" },
  },
}
