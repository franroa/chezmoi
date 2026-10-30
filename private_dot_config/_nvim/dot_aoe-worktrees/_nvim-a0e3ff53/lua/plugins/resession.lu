return {
  {
    "stevearc/resession.nvim",
    -- config = function()
    --   require("resession").setup({
    --     extensions = {
    --       overseer = {
    --         -- {
    --         -- name = "Build App " .. LazyVim.root.git():match("([^/]+)$"),
    --         -- },
    --       },
    --     },
    --   })
    -- end,
    opts = function()
      local resession = require("resession")
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          -- Only load the session if nvim was started with no args
          if vim.fn.argc(-1) == 0 and os.getenv("REPO_NAME") ~= nil then
            resession.load(os.getenv("REPO_NAME"), { dir = "nvimsession10", silence_errors = true })
          end
        end,
      })
      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
          if os.getenv("REPO_NAME") ~= nil then
            resession.save(os.getenv("REPO_NAME"), { dir = "nvimsession10", notify = false })
          end
        end,
      })
    end,
  },
}
