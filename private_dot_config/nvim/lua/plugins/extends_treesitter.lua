-- vim.api.nvim_create_autocmd("User", {
--   pattern = "TSUpdate",
--   callback = function()
--     require("nvim-treesitter.parsers").river = {
--       install_info = {
--         path = "/home/froa/Projects/tools/tree-sitter-river",
--         location = "src/parser.c",
--         generate = true,
--         generate_from_json = false,
--         -- queries = "queries/neovim", -- symlink queries from given directory
--       },
--     }
--   end,
-- })
-- vim.treesitter.language.register("river", { "alloy" })

--https://github.com/nvim-treesitter/nvim-treesitter-textobjects?tab=readme-ov-file#built-in-textobjects
-- https://github.com/gmr458/nvim/blob/main/queries/typescript/injections.scm
return {
  {
    "LiadOz/nvim-dap-repl-highlights",
    config = function()
      require("nvim-dap-repl-highlights").setup()
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    enable = false,
    dependencies = { "HiPhish/rainbow-delimiters.nvim" },
    opts = function(_, opts)
      -- Add this after your config to debug
      -- local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
      --
      -- parser_config.river = {
      --   install_info = {
      --     url = "/home/froa/Projects/tools/tree-sitter-river",
      --     files = { "src/parser.c" },
      --     generate_requires_npm = false,
      --     requires_generate_from_grammar = false,
      --   },
      --   filetype = "river",
      -- }
      --
      -- parser_config.lua_patterns = {
      --   install_info = {
      --     url = "https://github.com/OXY2DEV/tree-sitter-lua_patterns",
      --     files = { "src/parser.c" },
      --     branch = "main",
      --   },
      -- }
      --
      -- parser_config.qf = {
      --   install_info = {
      --     url = "https://github.com/OXY2DEV/tree-sitter-qf",
      --     files = { "src/parser.c" },
      --     branch = "main",
      --   },
      -- }

      -- opts.highlight = { enable = true, disable = { "yaml" } }
      opts.highlight = { enable = true, disable = {} }
      -- opts.highlight = { enable = true, disable = {} }
      opts.fold = { enable = true, disable = { "yaml" } }
      opts.ignore_install = { "help" }

      vim.list_extend(opts.ensure_installed, {
        "promql",
        "csv",
        "bash",
        "river",
        "css",
        "helm",
        "http",
        "c_sharp",
        "dap_repl",
        "vimdoc",
        "lua_patterns",
        "qf",
        "gotmpl",
      })
      opts.textobjects = {
        swap = {
          enable = true,
          swap_next = {
            ["<leader>na"] = "@parameter.inner", -- swap parameters/argument with next
            ["<leader>n:"] = "@property.outer", -- swap object property with next
            ["<leader>nm"] = "@function.outer", -- swap function with next
          },
          swap_previous = {
            ["<leader>pa"] = "@parameter.inner", -- swap parameters/argument with prev
            ["<leader>p:"] = "@property.outer", -- swap object property with prev
            ["<leader>pm"] = "@function.outer", -- swap function with previous
          },
        },
        select = {
          enable = true,

          -- Automatically jump forward to textobj, similar to targets.vim
          lookahead = true,

          keymaps = {
            ["ar"] = "@resource.outer",
            ["ir"] = "@resource.inner",
            ["ad"] = "@data.outer",
            ["id"] = "@data.inner",
            ["ap"] = "@provider.outer",
            ["ip"] = "@provider.inner",
            ["av"] = "@variable.outer",
            ["iv"] = "@variable.inner",
            ["ao"] = "@output.outer",
            ["io"] = "@output.inner",
            ["am"] = "@module.outer",
            ["im"] = "@module.inner",
            ["aB"] = "@top_level_block.outer",
            ["iB"] = "@top_level_block.inner",

            -- Generic block
            ["ib"] = "@block.inner",

            -- Mappings for attributes
            ["a="] = "@attribute.outer", -- Around attribute (e.g., name = "value")
            ["i="] = "@attribute.inner", -- NEW: Inside attribute (e.g., just "value")

            -- Mappings for HCL object literals
            ["a{"] = "@object.outer", -- NEW: Around object (including braces)
            ["i{"] = "@object.inner", -- NEW: Inside object (just the key-value pairs)
            -- You can use the capture groups defined in textobjects.scm
            -- ["a="] = { query = "@assignment.outer", desc = "Select outer part of an assignment" },
            ["i="] = { query = "@assignment.inner", desc = "Select inner part of an assignment" },
            ["l="] = { query = "@assignment.lhs", desc = "Select left hand side of an assignment" },
            ["r="] = { query = "@assignment.rhs", desc = "Select right hand side of an assignment" },

            ["aa"] = { query = "@parameter.outer", desc = "Select outer part of a parameter/argument" },
            ["ia"] = { query = "@parameter.inner", desc = "Select inner part of a parameter/argument" },

            ["ai"] = { query = "@conditional.outer", desc = "Select outer part of a conditional" },
            ["ii"] = { query = "@conditional.inner", desc = "Select inner part of a conditional" },

            ["al"] = { query = "@loop.outer", desc = "Select outer part of a loop" },
            ["il"] = { query = "@loop.inner", desc = "Select inner part of a loop" },

            ["af"] = { query = "@call.outer", desc = "Select outer part of a function call" },
            ["if"] = { query = "@call.inner", desc = "Select inner part of a function call" },

            ["am"] = { query = "@function.outer", desc = "Select outer part of a method/function definition" },
            ["im"] = { query = "@function.inner", desc = "Select inner part of a method/function definition" },

            ["ac"] = { query = "@class.outer", desc = "Select outer part of a class" },
            ["ic"] = { query = "@class.inner", desc = "Select inner part of a class" },

            -- works for javascript/typescript files (custom captures I created in after/queries/ecma/textobjects.scm)
            ["a:"] = { query = "@property.outer", desc = "Select outer part of an object property" },
            ["i:"] = { query = "@property.inner", desc = "Select inner part of an object property" },
            ["l:"] = { query = "@property.lhs", desc = "Select left part of an object property" },
            ["r:"] = { query = "@property.rhs", desc = "Select right part of an object property" },
          },
        },

        move = {
          enable = true,
          set_jumps = true, -- whether to set jumps in the jumplist
          -- goto_next_start = {
          --   ["]m"] = "@function.outer",
          --   ["]]"] = { query = "@class.outer", desc = "Next class start" },
          --   --
          --   -- You can use regex matching (i.e. lua pattern) and/or pass a list in a "query" key to group multiple queires.
          --   ["]o"] = "@loop.*",
          --   -- ["]o"] = { query = { "@loop.inner", "@loop.outer" } }
          --   --
          --   -- You can pass a query group to use query from `queries/<lang>/<query_group>.scm file in your runtime path.
          --   -- Below example nvim-treesitter's `locals.scm` and `folds.scm`. They also provide highlights.scm and indent.scm.
          --   ["]S"] = { query = "@scope", query_group = "locals", desc = "Next scope" },
          --   ["]z"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
          -- },
          -- goto_next_end = {
          --   ["]M"] = "@function.outer",
          --   ["]["] = "@class.outer",
          -- },
          -- goto_previous_start = {
          --   ["[m"] = "@function.outer",
          --   ["[["] = "@class.outer",
          -- },
          -- goto_previous_end = {
          --   ["[M"] = "@function.outer",
          --   ["[]"] = "@class.outer",
          -- },
          --
          goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner" },
          goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
          goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer", ["[a"] = "@parameter.inner" },
          goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer", ["[A"] = "@parameter.inner" },

          -- Below will go to either the start or the end, whichever is closer.
          -- Use if you want more granular movements
          -- Make it even more gradual by adding multiple queries and regex.
          goto_next = {
            ["]d"] = "@conditional.outer",
          },
          goto_previous = {
            ["[d"] = "@conditional.outer",
          },
        },
      }

      -- local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")
      --
      -- -- vim way: ; goes to the direction you were moving.
      -- vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move)
      -- vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_opposite)
      --
      -- -- Optionally, make builtin f, F, t, T also repeatable with ; and ,
      -- vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f)
      -- vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F)
      -- vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t)
      -- vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T)
    end,
    -- opts = {
    --   highlight = { enable = true, disable = { "yaml" } },
    --   ensure_installed = { "go", "gomod", "java", "html", "css" },
    --   ignore_install = { "help" }
    -- }
  },
}
