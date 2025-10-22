return {
  "echasnovski/mini.keymap",
  opts = function()
    -- SMART Tab
    local map_multistep = require("mini.keymap").map_multistep

    -- NOTE: this will never insert tab, press <C-v><Tab> for that
    local tab_steps = {
      "minisnippets_next",
      "minisnippets_expand",
      "blink_next",
      "pmenu_next",
      "jump_after_tsnode",
      "jump_after_close",
    }
    map_multistep("i", "<Tab>", tab_steps)

    local shifttab_steps = {
      "minisnippets_prev",
      "blink_prev",
      "pmenu_next",
      "jump_before_tsnode",
      "jump_before_open",
    }
    map_multistep("i", "<S-Tab>", shifttab_steps)

    map_multistep("i", "<CR>", { "pmenu_accept", "minipairs_cr" })
    map_multistep("i", "<BS>", { "minipairs_bs" })

    -- Show bad navigation habits ~
    -- local notify_many_keys = function(key)
    --   local lhs = string.rep(key, 5)
    --   local action = function()
    --     vim.notify("Too many " .. key)
    --   end
    --   require("mini.keymap").map_combo({ "n", "x" }, lhs, action)
    -- end
    -- notify_many_keys("h")
    -- notify_many_keys("j")
    -- notify_many_keys("k")
    -- notify_many_keys("l")
  end,
  version = false,
}
