return {
  {
    "rmagatti/goto-preview",
    event = "BufEnter",
    config = true, -- necessary as per https://github.com/rmagatti/goto-preview/issues/88
    opts = function()
      vim.api.nvim_set_keymap(
        "n",
        "<leader>Gpd",
        "<cmd>lua require('goto-preview').goto_preview_definition()<CR>",
        { noremap = true }
      )
      vim.api.nvim_set_keymap(
        "n",
        "<leader>Gpt",
        "<cmd>lua require('goto-preview').goto_preview_type_definition()<CR>",
        { noremap = true }
      )
      vim.api.nvim_set_keymap(
        "n",
        "<leader>Gpi",
        "<cmd>lua require('goto-preview').goto_preview_implementation()<CR>",
        { noremap = true }
      )
      vim.api.nvim_set_keymap(
        "n",
        "<leader>GpD",
        "<cmd>lua require('goto-preview').goto_preview_declaration()<CR>",
        { noremap = true }
      )
      vim.api.nvim_set_keymap("n", "gq", "<cmd>lua require('goto-preview').close_all_win()<CR>", { noremap = true })
      vim.api.nvim_set_keymap(
        "n",
        "<leader>Gpr",
        "<cmd>lua require('goto-preview').goto_preview_references()<CR>",
        { noremap = true }
      )
    end,
  },
}
