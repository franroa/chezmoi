local Hydra = require("hydra")
local minidiff = require("mini.diff")
local gitsigns = require("gitsigns")

local hint = [[
 _n_: next hunk   _s_: stage hunk        _d_: show deleted   _b_: blame line
 _N_: prev hunk   _u_: undo last stage   _o_: toggle overlay _B_: blame show full 
 ^ ^              _S_: stage buffer      ^ ^                 _/_: show base file
 ^
 ^ ^              _<Enter>_: Neogit              _q_: exit
]]

local git_hydra = Hydra({
  name = "Git",
  hint = hint,
  config = {
    buffer = bufnr,
    color = "pink",
    invoke_on_body = true,
    hint = {
      border = "rounded",
    },
    on_enter = function()
      -- minidiff.toggle_overlay()
      -- vim.cmd("mkview")
      -- vim.cmd("silent! %foldopen!")
      -- vim.bo.modifiable = false
      -- minidiff.toggle_signs(true)
      -- minidiff.toggle_linehl(true)
    end,
    on_exit = function()
      -- local cursor_pos = vim.api.nvim_win_get_cursor(0)
      -- vim.cmd("loadview")
      -- vim.api.nvim_win_set_cursor(0, cursor_pos)
      -- vim.cmd("normal zv")
      -- minidiff.toggle_signs(false)
      -- minidiff.toggle_linehl(false)
      -- minidiff.toggle_deleted(false)
    end,
  },
  mode = { "n", "x" },
  body = "<leader>G",
  heads = {
    {
      "n",
      function()
        if vim.wo.diff then
          return "]c"
        end
        vim.schedule(function()
          minidiff.goto_hunk("next")
        end)
        return "<Ignore>"
      end,
      { expr = true, desc = "next hunk" },
    },
    {
      "N",
      function()
        if vim.wo.diff then
          return "[c"
        end
        vim.schedule(function()
          minidiff.goto_hunk("prev")
        end)
        return "<Ignore>"
      end,
      { expr = true, desc = "prev hunk" },
    },
    { "s", ":Gitsigns stage_hunk<CR>", { silent = true, desc = "stage hunk" } },
    { "u", minidiff.undo_stage_hunk, { desc = "undo last stage" } },
    { "S", gitsigns.stage_buffer, { desc = "stage buffer" } },
    { "o", minidiff.toggle_overlay(0), { desc = "toggle overlay" } },
    { "d", gitsigns.toggle_deleted, { nowait = true, desc = "toggle deleted" } },
    { "b", gitsigns.blame_line, { desc = "blame" } },
    {
      "B",
      gitsigns.blame,
      { desc = "blame all" },
    },
    { "/", gitsigns.show, { exit = true, desc = "show base file" } }, -- show the base of the file
    { "<Enter>", "<Cmd>Neogit<CR>", { exit = true, desc = "Neogit" } },
    { "q", nil, { exit = true, nowait = true, desc = "exit" } },
  },
})
Hydra.spawn = function(head)
  if head == "Git" then
    git_hydra:activate()
  end
end
