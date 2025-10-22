return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    require("which-key").add({
      { "<leader>tc", group = "+coverage" },
      { "<leader>oT", group = "+tests" },
      { "ga", group = "+alternate" },
      { "gaT", group = "+tests" },
      { "gaTh", group = "+handler" },
      { "gaTc", group = "+controller" },
    })
  end,
  opts = {
    -- preset = "helix",
    -- plugins = {
    --   presets = {
    --     windows = false,
    --   },
    -- },
    -- win = {
    --   height = { max = 20 },
    --   border = "single",
    --   padding = { 0, 1 },
    -- },
    -- keys = {
    --   scroll_down = "<c-f>",
    --   scroll_up = "<c-u>",
    -- },
    -- replace = {
    --   key = {
    --     { "<BS>", "ret" },
    --     { "<Space>", "spc" },
    --     { "<S%-Tab>", "stab" },
    --   },
    -- },
    icons = {
      rules = {
        { pattern = "grapple", icon = "󱡀", hl = "@string" },
        { pattern = "coverage", icon = "", hl = "NeotestFailed" },
        { pattern = "update", icon = "󰚰" },
        { pattern = "insert", icon = "" },
        { pattern = "delete", icon = "󰗨" },
        { pattern = "controller", icon = "󰊴" },
        { pattern = "repository", icon = "󱙋" },
        { pattern = "requests", icon = "󰡷" },
        { pattern = "get", icon = "" },
        { pattern = "secret", icon = "" },
        { pattern = "run", icon = "" },
        { pattern = "build", icon = "" },
        { pattern = "clean", icon = "󰿞" },
        { pattern = "clear", icon = "󰿞" },
      },
      -- rules = false,
      -- separator = "→",
    },
    -- show_help = false,
  },
}
