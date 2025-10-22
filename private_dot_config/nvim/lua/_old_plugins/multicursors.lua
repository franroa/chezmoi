return {
  {
    "mg979/vim-visual-multi"
  }
}

-- TODO: when is done
--
-- return {
--  {
--     "smoka7/multicursors.nvim",
--     event = "VeryLazy",
--     dependencies = {
--         'smoka7/hydra.nvim',
--     },
--     opts = function()
--         local N = require 'multicursors.normal_mode'
--         return {
--             normal_keys = {
--                 -- to change default lhs of key mapping change the key
--                 ['b'] = {
--                     -- assigning nil to method exits from multi cursor mode
--                     method = N.clear_others,
--                     -- description to show in hint window
--                     desc = 'Clear others'
--                 },
--             },
--         }
--     end,
--     keys = {
--             {
--                 '<Leader>m',
--                 '<cmd>MCstart<cr>',
--                 desc = 'Create a selection for word under the cursor',
--             },
--         },
-- }
-- }
