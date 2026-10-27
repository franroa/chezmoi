return {
  "KieranCanter/candela.nvim",
  opts = {
    matching = {
      auto_refresh = true,
    },
    syntax_highlighting = {
      enabled = true,
      file_types = { ".log", "text", "log" },
    },
  },
  keys = {
    {
      "<leader>cd",
      "<Plug>CandelaUi",
      desc = "Candela UI",
    },
    {
      "<leader>cr",
      "<Plug>CandelaRefresh",
      desc = "Candela Refresh",
    },
    {
      "<leader>cl",
      "<Plug>CandelaLightbox",
      desc = "Candela Lightbox",
    },
  },
}
