return {
  "xeind/vallow.nvim",
  cmd = { "Vallow", "VallowRefresh", "VallowSearch" },
  keys = {
    { "<leader>V", "<cmd>Vallow<cr>", desc = "Vallow: toggle" },
    { "<leader>vr", "<cmd>VallowRefresh<cr>", desc = "Vallow: refresh" },
    { "<leader>vs", "<cmd>VallowSearch<cr>", desc = "Vallow: search findings" },
  },
  opts = {},
}
