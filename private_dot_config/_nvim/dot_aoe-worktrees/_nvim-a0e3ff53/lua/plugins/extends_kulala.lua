return {
  {
    -- enabled = false,
    "mistweaverco/kulala.nvim",
    ft = "http",
    keys = {
      { "<leader>R", "", desc = "+Rest" },
      { "<leader>Rs", "<cmd>lua require('kulala').run()<cr>", desc = "Send the request" },
      { "<leader>Rt", "<cmd>lua require('kulala').toggle_view()<cr>", desc = "Toggle headers/body" },
      { "<leader>Rp", "<cmd>lua require('kulala').jump_prev()<cr>", desc = "Jump to previous request" },
      { "<leader>Rn", "<cmd>lua require('kulala').jump_next()<cr>", desc = "Jump to next request" },
      { "<leader>Rr", "<cmd>lua require('kulala').replay()<cr>", desc = "Replay" },
      { "<leader>Rc", "<cmd>lua require('kulala').copy()<cr>", desc = "Replay" },
    },
    opts = function(_, opts)
      opts.debug = true
      opts.additional_curl_options = { "--insecure" }
    end,
  },
  -- {
  --   "jellydn/hurl.nvim",
  --   dependencies = {
  --     "MunifTanjim/nui.nvim",
  --     "nvim-lua/plenary.nvim",
  --     "nvim-treesitter/nvim-treesitter",
  --   },
  --   ft = "hurl",
  --   opts = {
  --     -- Show debugging info
  --     debug = false,
  --     -- Show notification on run
  --     show_notification = false,
  --     -- Show response in popup or split
  --     mode = "split",
  --     -- Default formatter
  --     formatters = {
  --       json = { "jq" }, -- Make sure you have install jq in your system, e.g: brew install jq
  --       html = {
  --         "prettier", -- Make sure you have install prettier in your system, e.g: npm install -g prettier
  --         "--parser",
  --         "html",
  --       },
  --       xml = {
  --         "tidy", -- Make sure you have installed tidy in your system, e.g: brew install tidy-html5
  --         "-xml",
  --         "-i",
  --         "-q",
  --       },
  --     },
  --     -- Default mappings for the response popup or split views
  --     mappings = {
  --       close = "q", -- Close the response popup or split view
  --       next_panel = "<C-n>", -- Move to the next response popup window
  --       prev_panel = "<C-p>", -- Move to the previous response popup window
  --     },
  --   },
  --   keys = {
  --     -- Run API request
  --     { "<leader>RA", "<cmd>HurlRunner<CR>", desc = "Run All requests" },
  --     { "<leader>Rs", "<cmd>HurlRunnerAt<CR>", desc = "Run Api request" },
  --     { "<leader>Re", "<cmd>HurlRunnerToEntry<CR>", desc = "Run Api request to entry" },
  --     { "<leader>Rt", "<cmd>HurlToggleMode<CR>", desc = "Hurl Toggle Mode" },
  --     { "<leader>Rv", "<cmd>HurlVerbose<CR>", desc = "Run Api in verbose mode" },
  --     -- Run Hurl request in visual mode
  --     { "<leader>Rr", ":HurlRunner<CR>", desc = "Hurl Runner", mode = "v" },
  --   },
  -- },
  -- {
  --   "vhyrro/luarocks.nvim",
  --   priority = 1000,
  --   config = true,
  --   opts = {
  --     rocks = { "lua-curl", "nvim-nio", "mimetypes", "xml2lua" },
  --   },
  -- },
  -- {
  --   "rest-nvim/rest.nvim",
  --   ft = "http",
  --   dependencies = { "luarocks.nvim" },
  --   config = function()
  --     require("rest-nvim").setup()
  --   end,
  -- },
}
