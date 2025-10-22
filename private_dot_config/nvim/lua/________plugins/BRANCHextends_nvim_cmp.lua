return {
  {
    "llllvvuu/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-emoji",
      "hrsh7th/cmp-cmdline",
      "petertriho/cmp-git", -- only works in gitconfig and octo
      { "Gelio/cmp-natdat", config = true },
    },
    branch = "feat/above",
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        prevCharacter = vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%w") or "nil"
        postCharacter = vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col + 1, col + 1):match("%p")
          or "nil"

        vim.notify("Prev char: " .. prevCharacter)
        vim.notify("Post char: " .. postCharacter)

        return col ~= 0 and prevCharacter == nil and postCharacter == nil
      end

      require("cmp_git").setup(
        -- github = {
        --   hosts = { "github.com" }, -- TODO: also add cmp-jira
        -- },
        -- gitlab = {
        --     hosts = { "gitlab.mycompany.com", }
        -- }
      )
      local luasnip = require("luasnip")
      local cmp = require("cmp")
      opts.window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      }

      opts.sorting = {
        -- TODO: https://www.reddit.com/r/neovim/comments/14k7pbc/what_is_the_nvimcmp_comparatorsorting_you_are/
        -- TODO: Would be cool to add stuff like "See variable names before method names" in rust, or something like that.
        comparators = {
          cmp.config.compare.offset,
          cmp.config.compare.exact,
          cmp.config.compare.score,

          -- copied from cmp-under
          function(entry1, entry2)
            local _, entry1_under = entry1.completion_item.label:find("^_+")
            local _, entry2_under = entry2.completion_item.label:find("^_+")
            entry1_under = entry1_under or 0
            entry2_under = entry2_under or 0
            if entry1_under > entry2_under then
              return false
            elseif entry1_under < entry2_under then
              return true
            end
          end,

          -- cmp.config.compare.recently_used,
          -- cmp.config.compare.locality,
          cmp.config.compare.kind,
          cmp.config.compare.sort_text,
          cmp.config.compare.length,
          cmp.config.compare.order,
        },
      }

      -- TODO: add this
      --
      -- opts.cmdline({ '/', '?' }, {
      --   mapping = cmp.mapping.preset.cmdline(),
      --   sources = {
      --     { name = 'buffer' }
      --   }
      -- })
      --
      -- -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
      -- opts.cmdline(':', {
      --   mapping = cmp.mapping.preset.cmdline(),
      --   sources = cmp.config.sources({
      --     { name = 'path' }
      --   }, {
      --     { name = 'cmdline' }
      --   })
      -- })
      -- opts.filetype('gitcommit', {
      --   sources = cmp.config.sources({
      --     { name = 'git' }, -- You can specify the `git` source if [you were installed it](https://github.com/petertriho/cmp-git).
      --   }, {
      --     { name = 'buffer' },
      --   })
      -- })
      opts.sources = cmp.config.sources(
        vim.list_extend(
          opts.sources,
          { { name = "emoji" }, { name = "cmdline" }, { name = "natdat" }, { name = "git" } }
        )
      )
      opts.view = {
        entries = {
          vertical_positioning = "above",
        },
      }

      opts.preselect = cmp.PreselectMode.None
      opts.completion = {
        completeopt = "menu,menuone,noinsert,noselect",
      }

      opts.mapping = vim.tbl_extend("force", opts.mapping, {
        ["<CR>"] = cmp.mapping.confirm({ select = false }), -- 'select = false' to only confirm explicitly selected item
        ["<S-CR>"] = cmp.mapping.confirm({ select = false, behavior = cmp.ConfirmBehavior.Replace }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.

        ["<C-j>"] = cmp.mapping.select_next_item({ select = false, behavior = cmp.SelectBehavior.Select }),
        ["<C-k>"] = cmp.mapping.select_prev_item({ select = false, behavior = cmp.SelectBehavior.Select }),
        ["<Tab>"] = function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif has_words_before() then -- TODO: add this but check also that
            cmp.complete()
          elseif luasnip.expand_or_jumpable() then
            vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-expand-or-jump", true, true, true), "")
          else
            fallback()
          end
        end,
        ["<S-Tab>"] = function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-jump-prev", true, true, true), "")
          else
            fallback()
          end
        end,
      })
    end,
  },
}
