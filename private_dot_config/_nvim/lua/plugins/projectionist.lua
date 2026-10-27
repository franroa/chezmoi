return {
  -- Projectionist plugin
  {
    "tpope/vim-projectionist",
    lazy = false,
  },

  -- Which-Key configuration for Projectionist
  {
    "folke/which-key.nvim",
    optional = true,
    opts = function(_, opts)
      opts.spec = opts.spec or {}

      -- Add Projectionist keymaps to which-key
      vim.list_extend(opts.spec, {
        -- Alternate files group
        { "<leader>A", group = "alternate" },
        { "<leader>Aa", ":A<CR>", desc = "Alternate file", mode = "n" },
        { "<leader>Av", ":AV<CR>", desc = "Alternate (vsplit)", mode = "n" },
        { "<leader>As", ":AS<CR>", desc = "Alternate (split)", mode = "n" },
        { "<leader>At", ":AT<CR>", desc = "Alternate (tab)", mode = "n" },

        -- Related files group
        { "<leader>Ar", group = "related" },
        { "<leader>Ar", ":R<CR>", desc = "Related file", mode = "n" },
        { "<leader>Arv", ":RV<CR>", desc = "Related (vsplit)", mode = "n" },
        { "<leader>Ars", ":RS<CR>", desc = "Related (split)", mode = "n" },
        { "<leader>Art", ":RT<CR>", desc = "Related (tab)", mode = "n" },

        -- Edit by type group
        { "<leader>Ae", group = "edit" },

        -- Component
        { "<leader>Aec", group = "component" },
        { "<leader>Aec", ":Ecomponent ", desc = "Component", mode = "n" },
        { "<leader>Aecc", ":Ecomponent ", desc = "Edit component", mode = "n" },
        { "<leader>Aecv", ":Vcomponent ", desc = "Component (vsplit)", mode = "n" },
        { "<leader>Aecs", ":Scomponent ", desc = "Component (split)", mode = "n" },
        { "<leader>Aect", ":Tcomponent ", desc = "Component (tab)", mode = "n" },

        -- Composable
        { "<leader>Aeu", group = "composable" },
        { "<leader>Aeu", ":Ecomposable ", desc = "Composable", mode = "n" },
        { "<leader>Aeuu", ":Ecomposable ", desc = "Edit composable", mode = "n" },
        { "<leader>Aeuv", ":Vcomposable ", desc = "Composable (vsplit)", mode = "n" },
        { "<leader>Aeus", ":Scomposable ", desc = "Composable (split)", mode = "n" },
        { "<leader>Aeut", ":Tcomposable ", desc = "Composable (tab)", mode = "n" },

        -- Story
        { "<leader>Aes", group = "story" },
        { "<leader>Aes", ":Estory ", desc = "Story", mode = "n" },
        { "<leader>Aess", ":Estory ", desc = "Edit story", mode = "n" },
        { "<leader>Aesv", ":Vstory ", desc = "Story (vsplit)", mode = "n" },
        { "<leader>Aess", ":Sstory ", desc = "Story (split)", mode = "n" },
        { "<leader>Aest", ":Tstory ", desc = "Story (tab)", mode = "n" },

        -- Test
        { "<leader>Aet", group = "test" },
        { "<leader>Aet", ":Etest ", desc = "Test", mode = "n" },
        { "<leader>Aett", ":Etest ", desc = "Edit test", mode = "n" },
        { "<leader>Aetv", ":Vtest ", desc = "Test (vsplit)", mode = "n" },
        { "<leader>Aets", ":Stest ", desc = "Test (split)", mode = "n" },
        { "<leader>Aett", ":Ttest ", desc = "Test (tab)", mode = "n" },

        -- Service
        { "<leader>Aea", group = "service" },
        { "<leader>Aea", ":Eservice ", desc = "Service", mode = "n" },
        { "<leader>Aeaa", ":Eservice ", desc = "Edit service", mode = "n" },
        { "<leader>Aeav", ":Vservice ", desc = "Service (vsplit)", mode = "n" },
        { "<leader>Aeas", ":Sservice ", desc = "Service (split)", mode = "n" },
        { "<leader>Aeat", ":Tservice ", desc = "Service (tab)", mode = "n" },

        -- Locale
        { "<leader>Ael", group = "locale" },
        { "<leader>Ael", ":Elocale ", desc = "Locale", mode = "n" },
        { "<leader>Aell", ":Elocale ", desc = "Edit locale", mode = "n" },
        { "<leader>Aelv", ":Vlocale ", desc = "Locale (vsplit)", mode = "n" },
        { "<leader>Aels", ":Slocale ", desc = "Locale (split)", mode = "n" },
        { "<leader>Aelt", ":Tlocale ", desc = "Locale (tab)", mode = "n" },
      })

      return opts
    end,
  },
}
