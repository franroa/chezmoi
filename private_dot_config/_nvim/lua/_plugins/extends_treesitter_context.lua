return {
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "LazyFile",
    enabled = true,
    opts = { mode = "cursor", max_lines = 3 },
    dependencies = {
      {
        "folke/which-key.nvim",
        opts = function(_, opts) -- Change this to not to have +
          if require("lazyvim.util").has("noice.nvim") then
            opts.spec["<leader>ut"] = { name = "+treesitter-context" }
          end
        end,
      },
    },
    keys = {
      {
        "<leader>utg",
        function()
          require("treesitter-context").go_to_context()
        end,
        desc = "Go to Treesitter Context",
      },
      {
        "<leader>utt",
        function()
          local Util = require("lazyvim.util")
          local tsc = require("treesitter-context")
          tsc.toggle()
          if Util.inject.get_upvalue(tsc.toggle, "enabled") then
            Util.info("Enabled Treesitter Context", { title = "Option" })
          else
            Util.warn("Disabled Treesitter Context", { title = "Option" })
          end
        end,
        desc = "Toggle Treesitter Context",
      },
    },
  },
}
