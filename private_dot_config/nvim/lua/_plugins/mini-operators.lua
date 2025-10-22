-- https://alpha2phi.medium.com/neovim-plugins-and-configuration-recipes-3d508798eab7
return {
  {
    "echasnovski/mini.operators",
    -- dependencies = {
    --   -- which key integration
    --   {
    --     "folke/which-key.nvim",
    --     opts = function(_, opts) -- Change this to not to have +
    --       if require("lazyvim.util").has("noice.nvim") then
    --         opts.spec["gR"] = { name = "Replace" }
    --         opts.spec["g="] = { name = "Evaluate and Replace" }
    --         opts.spec["gX"] = { name = "Exchange text regions" }
    --         opts.spec["go"] = { name = "Sort/Organize text" }
    --       end
    --     end,
    --   },
    -- },
    config = function(_, opts)
      opts.replace = {
        prefix = "gR",
        reindent_linewise = true,
      }
      opts.exchange = {
        prefix = "gX",
        reindent_linewise = true,
      }
      require("mini.operators").setup(opts)
    end,
    event = "VeryLazy",
    -- opts = function(_, opts)
    --   local test = (1 + 2)
    --   opts.sort = {
    --     prefix = "go",
    --   }
    --   opts.evaluate = {
    --     prefix = "g=",
    --
    --     -- Function which does the evaluation
    --     func = nil,
    --   }
    --   -- opts.exchange = {
    --   --   prefix = "g",
    --   --   reindent_linewise = true,
    --   -- }
    --   -- opts.replace = {
    --   --   prefix = "M",
    --   --   reindent_linewise = true,
    --   -- }
    -- end,
  },
}
