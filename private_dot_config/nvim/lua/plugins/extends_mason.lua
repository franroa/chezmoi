return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "netcoredbg",
        "harper-ls",
        "delve",
        "codespell",
        "misspell",
        "cspell",
        "gotests",
        "golangci-lint",
        "gofumpt",
        "goimports",
        "golangci-lint-langserver",
        "gitlab-ci-ls",
        "impl",
        "gomodifytags",
        "iferr",
        "gotestsum",
        "helm-ls", -- go
        "stylua",
        "csharpier",
        "css-lsp",
        "css-variables-language-server",
        "cssmodules-language-server",
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
    -- opts = function()
    --   require("mason").setup({
    --     registries = {
    --       "github:mason-org/mason-registry",
    --       "github:Crashdummyy/mason-registry",
    --     },
    --   })
    -- end,
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
