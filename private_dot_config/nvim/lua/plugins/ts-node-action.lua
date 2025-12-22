return {
  "ckolkey/ts-node-action",
  dir = vim.fn.expand("~/.config/nvim/lua/local_plugins/ts-node-action"),
  dev = true,
  config = function()
    vim.keymap.set({ "n" }, "<leader>a", require("ts-node-action").node_action, { desc = "Trigger Node Action" })
  end,
}
