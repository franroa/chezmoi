vim.api.nvim_create_user_command("FormatDisable", function(args)
  if args.bang then
    -- FormatDisable! will disable formatting just for this buffer
    vim.b.disable_autoformat = true
  else
    vim.g.disable_autoformat = true
    vim.g.autoformat = false
  end
end, {
  desc = "Disable autoformat-on-save",
  bang = true,
})
vim.api.nvim_create_user_command("FormatEnable", function()
  vim.b.disable_autoformat = false
  vim.g.autoformat = true
  vim.g.disable_autoformat = false
end, {
  desc = "Re-enable autoformat-on-save",
})
vim.api.nvim_create_user_command("FormatAlloy", function()
  vim.g.autoformat = false
  vim.cmd(":retab")
  vim.cmd(":w")
  vim.g.autoformat = true
end, {
  desc = "Re-enable autoformat-on-save",
})
vim.api.nvim_create_user_command("FormatRange", function(args)
  local range = nil
  if args.count ~= -1 then
    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
    range = {
      start = { args.line1, 0 },
      ["end"] = { args.line2, end_line:len() },
    }
  end
  require("conform").format({ async = true, formatters = { "alloy" }, lsp_format = "fallback", range = range })
end, { range = true })

return {
  -- { -- Autoformat
  --   "stevearc/conform.nvim",
  --   enabled = true,
  --   opts = function()
  --     require("conform").setup({
  --       notify_on_error = false,
  --       format_on_save = {
  --         timeout_ms = 500,
  --         lsp_fallback = true,
  --       },
  --       formatters_by_ft = {
  --         lua = { "mystylua" },
  --         python = { "isort", "black" },
  --         quarto = { "injected" },
  --         alloy = { "injected" },
  --         river = { "injected" },
  --       },
  --       formatters = {
  --         mystylua = {
  --           command = "stylua",
  --           args = { "--indent-type", "Spaces", "--indent-width", "2", "-" },
  --         },
  --
  --         alloy = {
  --           command = "alloy",
  --           -- args = { "fmt", "-" },
  --           args = { "fmt", "$FILENAME" },
  --         },
  --       },
  --     })
  --     -- Customize the "injected" formatter
  --     require("conform").formatters.injected = {
  --       -- Set the options field
  --       options = {
  --         -- Set to true to ignore errors
  --         ignore_errors = false,
  --         -- Map of treesitter language to file extension
  --         -- A temporary file name with this extension will be generated during formatting
  --         -- because some formatters care about the filename.
  --         lang_to_ext = {
  --           bash = "sh",
  --           c_sharp = "cs",
  --           elixir = "exs",
  --           javascript = "js",
  --           julia = "jl",
  --           latex = "tex",
  --           markdown = "md",
  --           python = "py",
  --           ruby = "rb",
  --           rust = "rs",
  --           river = "alloy",
  --           teal = "tl",
  --           r = "r",
  --           typescript = "ts",
  --         },
  --         -- Map of treesitter language to formatters to use
  --         -- (defaults to the value from formatters_by_ft)
  --         lang_to_formatters = {},
  --       },
  --     }
  --   end,
  -- },

  {
    "stevearc/conform.nvim",
    -- enabled = false,
    -- config = function()
    --   require("conform").formatters.injected = {
    --     -- Set the options field
    --     options = {
    --       lang_to_ext = {
    --         river = "alloy",
    --         yaml = "alloy",
    --       },
    --       lang_to_ft = {
    --         river = "river",
    --         yaml = "alloy",
    --       },
    --       lang_to_formatters = {
    --         river = "alloy",
    --         yaml = "alloy",
    --       },
    --       formatters_by_ft = {
    --         javascript = { { "prettierd", "prettier" } },
    --         html = { { "prettierd", "prettier" } },
    --         http = { { "kulala" } },
    --         alloy = { { "alloy" } },
    --         ["*"] = { "injected" },
    --       },
    --       formatters = {
    --         kulala = {
    --           command = "kulala-fmt",
    --         },
    --         alloy = {
    --           command = "alloy fmt",
    --         },
    --       },
    --       -- Set individual option values
    --       ignore_errors = false,
    --       -- lang_to_formatters = {
    --       --   json = { "jq" },
    --       -- },
    --     },
    --   }
    -- end,
    opts = {
      -- format_on_save = function(bufnr)
      --   -- Disable with a global or buffer-local variable
      --   vim.notify("test")
      --   if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      --     return
      --   end
      --   return { timeout_ms = 500, lsp_format = "fallback" }
      -- end,
      log_level = vim.log.levels.DEBUG,
      -- injected = {
      --   options = {
      --     lang_to_ext = {
      --       river = "alloy",
      --       markdown_inline = "md",
      --     },
      --     lang_to_ft = {
      --       river = "alloy",
      --       markdown_inline = "markdown",
      --     },
      --     lang_to_formatters = {
      --       river = { "alloy" },
      --       markdown_inline = "markdown",
      --     },
      --     ignore_errors = false,
      --   },
      -- },
      -- lang_to_ext = {
      --   river = "alloy",
      --   markdown_inline = "md",
      -- },
      -- lang_to_ft = {
      --   river = "alloy",
      --   markdown_inline = "markdown",
      -- },
      -- lang_to_formatters = {
      --   river = { "alloy" },
      --   markdown_inline = "markdownlint-cli2",
      -- },
      ignore_errors = false,
      formatters_by_ft = {
        cs = { "csharpier" },
        -- alloy = { "alloy" },
        -- river = { "alloy" },
        -- ["markdown"] = { "prettier", "markdownlint-cli2", "markdown-toc" },
        -- ["markdown.mdx"] = { "prettier", "markdownlint-cli2", "markdown-toc" },
        -- -- yaml = { "yamlfix" },
        -- ["*"] = { "injected" },
      },
      formatters = {
        -- kulala = {
        --   command = "kulala-fmt",
        -- },
        -- alloy = {
        --   command = "alloy",
        --   args = { "fmt", "-" },
        -- },
        csharpier = {
          command = "csharpier",
          args = { "format" },
        },
        -- ["markdown-toc"] = {
        --   condition = function(_, ctx)
        --     for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
        --       if line:find("<!%-%- toc %-%->") then
        --         return true
        --       end
        --     end
        --   end,
        -- },
        -- ["markdownlint-cli2"] = {
        --   condition = function(_, ctx)
        --     local diag = vim.tbl_filter(function(d)
        --       return d.source == "markdownlint"
        --     end, vim.diagnostic.get(ctx.buf))
        --     return #diag > 0
        --   end,
        -- },
      },
    },
    keys = {
      {
        "<leader>cF",
        function()
          require("conform").format({ formatters = { "injected" } })
        end,
        mode = { "n", "v" },
        desc = "Format Injected Langs",
      },
    },
  },
}
