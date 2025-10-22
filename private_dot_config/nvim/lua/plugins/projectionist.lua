return {
  -- Projectionist plugin
  {
    'tpope/vim-projectionist',
    lazy = false,
  },

  -- Which-Key configuration for Projectionist
  {
    'folke/which-key.nvim',
    optional = true,
    opts = function(_, opts)
      opts.spec = opts.spec or {}

      -- Add Projectionist keymaps to which-key
      vim.list_extend(opts.spec, {
        -- Alternate files group
        { '<leader>a',   group = 'alternate' },
        { '<leader>a',   ':A<CR>',            desc = 'Alternate file',      mode = 'n' },
        { '<leader>av',  ':AV<CR>',           desc = 'Alternate (vsplit)',  mode = 'n' },
        { '<leader>as',  ':AS<CR>',           desc = 'Alternate (split)',   mode = 'n' },
        { '<leader>at',  ':AT<CR>',           desc = 'Alternate (tab)',     mode = 'n' },

        -- Related files group
        { '<leader>r',   group = 'related' },
        { '<leader>r',   ':R<CR>',            desc = 'Related file',        mode = 'n' },
        { '<leader>rv',  ':RV<CR>',           desc = 'Related (vsplit)',    mode = 'n' },
        { '<leader>rs',  ':RS<CR>',           desc = 'Related (split)',     mode = 'n' },
        { '<leader>rt',  ':RT<CR>',           desc = 'Related (tab)',       mode = 'n' },

        -- Edit by type group
        { '<leader>e',   group = 'edit' },

        -- Component
        { '<leader>ec',  group = 'component' },
        { '<leader>ec',  ':Ecomponent ',      desc = 'Component',           mode = 'n' },
        { '<leader>ecc', ':Ecomponent ',      desc = 'Edit component',      mode = 'n' },
        { '<leader>ecv', ':Vcomponent ',      desc = 'Component (vsplit)',  mode = 'n' },
        { '<leader>ecs', ':Scomponent ',      desc = 'Component (split)',   mode = 'n' },
        { '<leader>ect', ':Tcomponent ',      desc = 'Component (tab)',     mode = 'n' },

        -- Composable
        { '<leader>eu',  group = 'composable' },
        { '<leader>eu',  ':Ecomposable ',     desc = 'Composable',          mode = 'n' },
        { '<leader>euu', ':Ecomposable ',     desc = 'Edit composable',     mode = 'n' },
        { '<leader>euv', ':Vcomposable ',     desc = 'Composable (vsplit)', mode = 'n' },
        { '<leader>eus', ':Scomposable ',     desc = 'Composable (split)',  mode = 'n' },
        { '<leader>eut', ':Tcomposable ',     desc = 'Composable (tab)',    mode = 'n' },

        -- Story
        { '<leader>es',  group = 'story' },
        { '<leader>es',  ':Estory ',          desc = 'Story',               mode = 'n' },
        { '<leader>ess', ':Estory ',          desc = 'Edit story',          mode = 'n' },
        { '<leader>esv', ':Vstory ',          desc = 'Story (vsplit)',      mode = 'n' },
        { '<leader>ess', ':Sstory ',          desc = 'Story (split)',       mode = 'n' },
        { '<leader>est', ':Tstory ',          desc = 'Story (tab)',         mode = 'n' },

        -- Test
        { '<leader>et',  group = 'test' },
        { '<leader>et',  ':Etest ',           desc = 'Test',                mode = 'n' },
        { '<leader>ett', ':Etest ',           desc = 'Edit test',           mode = 'n' },
        { '<leader>etv', ':Vtest ',           desc = 'Test (vsplit)',       mode = 'n' },
        { '<leader>ets', ':Stest ',           desc = 'Test (split)',        mode = 'n' },
        { '<leader>ett', ':Ttest ',           desc = 'Test (tab)',          mode = 'n' },

        -- Service
        { '<leader>ea',  group = 'service' },
        { '<leader>ea',  ':Eservice ',        desc = 'Service',             mode = 'n' },
        { '<leader>eaa', ':Eservice ',        desc = 'Edit service',        mode = 'n' },
        { '<leader>eav', ':Vservice ',        desc = 'Service (vsplit)',    mode = 'n' },
        { '<leader>eas', ':Sservice ',        desc = 'Service (split)',     mode = 'n' },
        { '<leader>eat', ':Tservice ',        desc = 'Service (tab)',       mode = 'n' },

        -- Locale
        { '<leader>el',  group = 'locale' },
        { '<leader>el',  ':Elocale ',         desc = 'Locale',              mode = 'n' },
        { '<leader>ell', ':Elocale ',         desc = 'Edit locale',         mode = 'n' },
        { '<leader>elv', ':Vlocale ',         desc = 'Locale (vsplit)',     mode = 'n' },
        { '<leader>els', ':Slocale ',         desc = 'Locale (split)',      mode = 'n' },
        { '<leader>elt', ':Tlocale ',         desc = 'Locale (tab)',        mode = 'n' },
      })

      return opts
    end,
  },
}
