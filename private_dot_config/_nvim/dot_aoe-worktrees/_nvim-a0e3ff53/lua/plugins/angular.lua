----https://github.com/williamboman/mason.nvim/issues/1404
vim.filetype.add({
  pattern = {
    [".*%.component%.html"] = "htmlangular", -- Sets the filetype to `angular.html` if it matches the pattern
    [".*%.container%.html"] = "htmlangular", -- Sets the filetype to `angular.html` if it matches the pattern
  },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "htmlangular",
  callback = function()
    vim.treesitter.language.register("angular", "angular.html", "htmlangular") -- Register the filetype with treesitter for the `angular` language/parser
  end,
})

-- TODO: do this as alternate file
return {
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      "nvim-neotest/neotest-jest",
      -- config = function()
      --   require("neotest").setup({
      --     test_framework = {
      --       ["*.spec.ts"] = "jest",
      --       ["*.test.ts"] = "jest",
      --     },
      --   })
      -- end,
    },
    opts = {
      adapters = {
        ["neotest-jest"] = {
          jestCommand = "npm test -- --coverage",
          jestConfigFile = "custom.jest.config.ts",
          env = { CI = true },
          cwd = function(path)
            return vim.fn.getcwd()
          end,
        },
      },
    },
  },
  {
    "joeveiga/ng.nvim",
    keys = {
      {
        "gt",
        function()
          require("ng").goto_template_for_component()
        end,
        -- ft = "typescript",
        desc = "Go to angular Template",
        ft = "typescript",
      },
      {
        "gC",
        function()
          require("ng").goto_component_with_template_file()
        end,
        -- ft = "typescript",
        desc = "Go to angular Component",
        ft = "angular.html",
      },
      {
        "gT",
        function()
          require("ng").get_template_tcb()
        end,
        -- ft = "typescript",
        desc = "Display template typecheck block",
        ft = "angular.html",
      },
    },
  },
}
