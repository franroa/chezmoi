return {
  {
    "windwp/nvim-ts-autotag",
    config = function(_, opts)
      require("nvim-ts-autotag").setup({
        filetypes = {
          "html",
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "svelte",
          "vue",
          "xml",
          "markdown",
          "pug",
          "tsx",
          "jsx",
          "css",
          "scss",
          "json",
        },
        opts = {
          -- Defaults
          enable_close = true, -- Auto close tags
          enable_rename = true, -- Auto rename pairs of tags
          enable_close_on_slash = false, -- Auto close on trailing </
        },
        aliases = {
          ["angular.html"] = "html",
          ["angular"] = "html",
          ["angularls"] = "html",
        },
      })
    end,
  },
}
