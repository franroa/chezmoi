-- https://github.com/erichlf/devcontainer-cli.nvim
--https://cadu.dev/running-neovim-on-devcontainers/
return {
  "https://codeberg.org/esensar/nvim-dev-container",
  dependencies = "nvim-treesitter/nvim-treesitter",
  opts = function()
    require("devcontainer").setup({})
  end,
  -- keys = {
  --   {
  --     "<leader>Db",
  --     function()
  --       vim.notify(vim.env.HOME .. "/.config/nvim/.devcontainers.json")
  --       require("devcontainer.container").build(vim.env.HOME .. "/.config/nvim/.devcontainers.json")
  --     end,
  --     desc = "Build image for devcontaienrs",
  --   },
  -- },
}
