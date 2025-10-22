return { {
  "yousefhadder/markdown-plus.nvim",
  ft = "markdown", -- Load on markdown files by default
  config = function()
    require("markdown-plus").setup({
      -- Configuration options (all optional)
      enabled = true,
      features = {
        list_management = true, -- Enable list management features
        text_formatting = true, -- Enable text formatting features
        headers_toc = true,     -- Enable headers and TOC features
        links = true,           -- Enable link management features
      },
      keymaps = {
        enabled = true,           -- Enable default keymaps
      },
      filetypes = { "markdown" }, -- Filetypes to enable the plugin for
    })
  end,
},
  {
    "OXY2DEV/markdoc.nvim"
  },
}
