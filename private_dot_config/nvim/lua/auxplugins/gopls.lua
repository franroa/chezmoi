return {
  "jackielii/gopls.nvim",
  keys = {
    {
      "<leader>kgl",
      function()
        require("gopls").list_known_packages({ with_parent = true, loclist = true })
      end,
      desc = "Gopls list known packages",
    },
    {
      "<leader>kgp",
      function()
        require("gopls.snacks_picker").list_package_symbols({ with_parent = true })
      end,
      desc = "Gopls list package symbols",
    },
    {
      "<leader>kgd",
      function()
        require("gopls").doc({ show_document = true })
      end,
      desc = "Gopls show documentation",
    },
  },
}
