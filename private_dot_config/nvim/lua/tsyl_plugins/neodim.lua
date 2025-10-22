return {
  {
    "zbirenbaum/neodim",
    event = "LspAttach",
    config = function()
      require("neodim").setup({
        alpha = 0.05,
        blend_color = "#FF0000",
        hide = {
          underline = true,
          virtual_text = true,
          signs = true,
        },
        regex = {
          "[nN]ever [rR]ead",
          "[nN]ot [rR]ead",
          "[uU]nused",
          cs = {
            "IDE0270",
          },
        },
        priority = 128,
        disable = {},
      })
    end,
  },
}
