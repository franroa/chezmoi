return {
  {
    "phelipetls/jsonpath.nvim",
    dependencies = {
      {
        "folke/which-key.nvim",
        opts = function(_, opts)
          if require("lazyvim.util").has("noice.nvim") then
            opts.spec["<leader>j"] = { name = "+json" }
          end
        end,
      },
    },
    keys = {
      {
        "<leader>jp",
        function()
          vim.fn.setreg("+", require("jsonpath").get())
        end,
        desc = "Copy JSON path",
        mode = "n",
      },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      -- "Myzel394/easytables.nvim",
      -- "Myzel394/telescope-last-positions",
      -- Other dependencies
      -- ..
      "Myzel394/jsonfly.nvim",
    },
    keys = {
      {
        "<leader>jf",
        "<cmd>Telescope jsonfly<cr>",
        desc = "Open json(fly)",
        mode = "n",
      },
    },
  },
}
