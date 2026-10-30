-- Custom parsers, registered when nvim-treesitter (main branch) refreshes its parser list.
vim.api.nvim_create_autocmd("User", {
  pattern = "TSUpdate",
  callback = function()
    local parsers = require("nvim-treesitter.parsers")

    -- https://github.com/franroa/tree-sitter-river
    parsers.river = {
      install_info = {
        url = "https://github.com/franroa/tree-sitter-river",
        queries = "queries",
      },
    }

    -- quickfix list (queries/qf)
    parsers.qf = {
      install_info = {
        url = "https://github.com/OXY2DEV/tree-sitter-qf",
      },
    }
  end,
})

-- Alloy config files are parsed with the river grammar.
vim.treesitter.language.register("river", "alloy")
-- Ansible buffers (yaml.ansible) and helm values use the plain yaml grammar.
vim.treesitter.language.register("yaml", { "yaml.ansible", "yaml.helm-values" })

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "river",
        "qf",
        "promql",
        "csv",
        "css",
        "http",
        "c_sharp",
        "gotmpl",
        "helm",
        "hcl",
        "terraform",
        "gitcommit",
        "git_config",
        "gitignore",
        "dockerfile",
        "go",
        "gomod",
        "sql",
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    opts = {
      select = { lookahead = true },
    },
    -- `config` stays LazyVim's (it sets up the ]f/[f... move keymaps)
    keys = function()
      local function swap(fn, query)
        return function()
          require("nvim-treesitter-textobjects.swap")[fn](query)
        end
      end

      local keys = {}
      local function x(lhs, query, desc)
        table.insert(keys, {
          lhs,
          function()
            require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
          end,
          mode = { "x", "o" },
          desc = desc or ("Select " .. query),
        })
      end

      x("a=", "@attribute.outer")
      x("l=", "@assignment.lhs", "Select left hand side of an assignment")
      x("r=", "@assignment.rhs", "Select right hand side of an assignment")
      x("a:", "@property.outer", "Select outer part of an object property")
      x("i:", "@property.inner", "Select inner part of an object property")
      x("l:", "@property.lhs", "Select left part of an object property")
      x("r:", "@property.rhs", "Select right part of an object property")
      x("ai", "@conditional.outer", "Select outer part of a conditional")
      x("ii", "@conditional.inner", "Select inner part of a conditional")
      x("al", "@loop.outer", "Select outer part of a loop")
      x("il", "@loop.inner", "Select inner part of a loop")

      vim.list_extend(keys, {
        { "<leader>na", swap("swap_next", "@parameter.inner"), desc = "Swap parameter with next" },
        { "<leader>n:", swap("swap_next", "@property.outer"), desc = "Swap property with next" },
        { "<leader>nm", swap("swap_next", "@function.outer"), desc = "Swap function with next" },
        { "<leader>pa", swap("swap_previous", "@parameter.inner"), desc = "Swap parameter with previous" },
        { "<leader>p:", swap("swap_previous", "@property.outer"), desc = "Swap property with previous" },
        { "<leader>pm", swap("swap_previous", "@function.outer"), desc = "Swap function with previous" },
      })
      return keys
    end,
    init = function()
      -- terraform/hcl block objects (queries/hcl/textobjects.scm). Buffer-local so they
      -- don't shadow mini.ai's `ao`, `am`... in other filetypes.
      local objects = {
        ar = "resource.outer",
        ir = "resource.inner",
        ad = "data.outer",
        id = "data.inner",
        ap = "provider.outer",
        ip = "provider.inner",
        av = "variable.outer",
        iv = "variable.inner",
        ao = "output.outer",
        io = "output.inner",
        am = "module.outer",
        im = "module.inner",
        aB = "top_level_block.outer",
        iB = "top_level_block.inner",
        ib = "block.inner",
      }
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("hcl_textobjects", { clear = true }),
        pattern = { "terraform", "hcl", "terraform-vars" },
        callback = function(ev)
          for lhs, query in pairs(objects) do
            vim.keymap.set({ "x", "o" }, lhs, function()
              require("nvim-treesitter-textobjects.select").select_textobject("@" .. query, "textobjects")
            end, { buffer = ev.buf, desc = "Select " .. query })
          end
        end,
      })
    end,
  },
}
