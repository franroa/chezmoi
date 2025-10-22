return {
  "mhartington/formatter.nvim",
  config = function(_, opts)
    local util = require("formatter.util")
    opts.filetype = {
      javascript = {
        function()
          return {
            exe = "prettier",
            args = { "--stdin-filepath", vim.api.nvim_buf_get_name(0) },
            stdin = true,
          }
        end,
      },
      typescript = {
        function()
          return {
            exe = "prettier",
            args = { "--stdin-filepath", vim.api.nvim_buf_get_name(0) },
            stdin = true,
          }
        end,
      },
      css = {
        function()
          return {
            exe = "prettier",
            args = { "--stdin-filepath", vim.api.nvim_buf_get_name(0) },
            stdin = true,
          }
        end,
      },
      angular = {
        function()
          return {
            exe = "prettier",
            args = { "--stdin-filepath", vim.api.nvim_buf_get_name(0) },
            stdin = true,
          }
        end,
      },
      html = {
        function()
          return {
            exe = "prettier",
            args = {
              "--stdin-filepath",
              "/home/francisco/Projects/support-innovation-gims-npm.git/branches/develop/src/app/features/client/components/client-detail/client-detail.component.html",
              "--write",
            },
            stdin = true,
          }
        end,
      },
      json = {
        function()
          return {
            exe = "prettier",
            args = { "--stdin-filepath", vim.api.nvim_buf_get_name(0) },
            stdin = true,
          }
        end,
      },
      markdown = {
        function()
          return {
            exe = "prettier",
            args = { "--stdin-filepath", vim.api.nvim_buf_get_name(0) },
            stdin = true,
          }
        end,
      },
      lua = {
        function()
          return {
            exe = "stylua",
            args = { "-" },
            stdin = true,
          }
        end,
      },
      rust = {
        function()
          return {
            exe = "rustfmt",
            args = { "--emit=stdout" },
            stdin = true,
          }
        end,
      },
      python = {
        function()
          return {
            exe = "black",
            args = { "-" },
            stdin = true,
          }
        end,
      },
    }
  end,
}
