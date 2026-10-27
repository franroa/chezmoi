return {
  -- {
  --   "mfussenegger/nvim-dap",
  --   config = function()
  --     local dap = require("dap")
  --     -- Configure your debug adapters here
  --     -- https://github.com/mfussenegger/nvim-dap/blob/master/doc/dap.txt
  --   end,
  -- },
  {
    "miroshQa/debugmaster.nvim",
    config = function()
      local dm = require("debugmaster")
      -- make sure you don't have any other keymaps that starts with "<leader>d" to avoid delay
      vim.keymap.set({ "n", "v" }, "<leader>dD", dm.mode.toggle, { desc = "debug master", nowait = true })
      vim.keymap.set("t", "<C-/>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
    end,
  },
}
