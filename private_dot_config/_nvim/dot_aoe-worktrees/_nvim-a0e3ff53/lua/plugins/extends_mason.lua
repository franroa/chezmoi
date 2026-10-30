return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "netcoredbg",
        "delve",
        "gotests",
        "golangci-lint",
        "gofumpt",
        "goimports",
        "golangci-lint-langserver",
        "impl",
        "gomodifytags",
        "iferr",
        "gotestsum",
        "helm-ls", -- go
        "stylua",
        "tflint",
        "eslint_d",
        "terraform-ls",
        "shellcheck",
        "shellharden",
        "shfmt",
        "flake8",
        -- "roslyn", this must be added manually when a cs file is opened
        "sqlfluff",
        "csharpier",
      },
    },
    -- opts = function(_, opts)
    --   local border = "none"
    --   if vim.g.transparent == true then
    --     border = "rounded"
    --   end
    --
    --   opts.ui = {
    --     icons = {
    --       package_installed = "✓",
    --       package_pending = "➜",
    --       package_uninstalled = "✗",
    --     },
    --     border = border,
    --     height = 0.8,
    --   }
    -- end,
  },
}
