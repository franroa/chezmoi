local function map(mode, lhs, rhs, opts)
  local keys = require("lazy.core.handler").handlers.keys
  ---@cast keys LazyKeysHandler
  -- do not create the keymap if a lazy keys handler exists
  if not keys.active[keys.parse({ lhs, mode = mode }).id] then
    opts = opts or {}
    opts.silent = opts.silent ~= false
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end
map("n", "<leader>gn", function()
  vim.cmd("Neotree focus git_status")
  vim.api.nvim_command("normal! j")
  vim.api.nvim_command("normal d")
end, { noremap = true, desc = "Go to the next neotree git file" })
map("n", "<leader>gN", function()
  vim.cmd("Neotree focus git_status")
  vim.api.nvim_command("normal! k")
  vim.api.nvim_command("normal d")
end, { noremap = true, desc = "Go to the previous neotree git file" })
map("n", "<leader>gR", function()
  vim.cmd("Neotree focus git_status")
end, { noremap = true, desc = "Go to the previous neotree git file" })

-- -- Keymaps are automatically loaded on the VeryLazy event
-- -- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- -- Add any additional keymaps here
-- -- TODO: https://github.com/elijahmanor/dotfiles/blob/master/nvim/.config/nvim/lua/config/autocmds.lua
-- -- For warn/info/float-term dialogue
--
-- local Util = require("lazyvim.util")
--
-- -- " Edit: TODO: NEOVIM
-- -- nnoremap dd "_dd
-- -- nnoremap d "_d
-- -- nnoremap D "_D
-- -- nnoremap ciw "_ciw
-- -- nnoremap caw "_caw
-- -- nnoremap C "_C
-- -- nnoremap cc "_cc
-- -- nnoremap Y y$
-- --
-- -- "-- Replace word with paste TODO: NEOVIM
-- -- nnoremap <a-p> "_diwP
-- -- "-- Replace line with paste
-- -- nnoremap <a-s-p> "_ddP"
-- --
-- -- " Alt keymaps TODO: NEOVIM
-- -- nnoremap <a-d> "_diw
-- -- nnoremap <a-c> "_ciw
-- -- nnoremap <a-s-d> ]b[w"_d]w
-- -- nnoremap <a-s-c> ]b[w"_c]w
-- -- nnoremap <a-z> "_ci"
-- -- nnoremap <a-x> "_ci(
-- -- " "-- Change function argument
-- -- " nnoremap <a-a> c<Plug>(InnerArgument)
-- -- " nnoremap <a-s> d<Plug>(InnerArgument)
-- -- vnoremap v ^o$
-- -- map W [w
-- -- map B [b
-- -- map E ]w
-- -- map <C-S-H> ^
-- -- map <C-S-L> $
-- -- Better escape
-- -- imap jk <Esc>
-- -- vnoremap jk <Esc>
--
-- -- Toggle Input Suggestion with <TAB>
-- -- * https://github.com/hrsh7th/nvim-cmp/issues/429
-- -- * https://github.com/hrsh7th/nvim-cmp/issues/261
-- map("n", "<leader>cc", function()
--   -- vim.g.input_suggestion == nil is treated as true
--   vim.g.input_suggestion = vim.g.input_suggestion == false
--   if vim.g.input_suggestion then
--     Util.warn("Enabled Input Suggestion", { title = "Input Suggestion (global)" })
--   else
--     Util.info("Disabled Input Suggestion", { title = "Input Suggestion (global)" })
--   end
--   require("cmp").setup({
--     enabled = function()
--       if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
--         return false
--       else
--         return vim.g.input_suggestion
--       end
--     end,
--   })
-- end, { desc = "Toggle Input Suggestion †" })
--
-- -- Visual trimmed lines
-- map("v", "v", "^o$", { desc = "Visual select Trimmed lines" })
--
-- -- Select all
-- map("n", "<C-a>", "ggVG", { desc = "Select all" })
-- map("v", "<C-a>", "ggOG", { desc = "Select all" })
--
-- -- Toggle LSP
-- vim.g.is_lsp_enabled = true
-- map("n", "<leader>cL", function()
--   if vim.g.is_lsp_enabled then
--     vim.g.is_lsp_enabled = false
--     vim.cmd([[LspStop]])
--     Util.warn("Disabled LSP", { title = "LSP" })
--   else
--     vim.g.is_lsp_enabled = true
--     vim.cmd([[LspStart]])
--     Util.info("Enabled LSP", { title = "LSP" })
--   end
-- end, { desc = "Toggle LSP", noremap = true, silent = true })
--
-- -- map("n", "<TAB>", ":bn<CR>")
-- -- map("n", "<S-TAB>", ":bp<CR>")
--
-- -- -- TODO: check offscroll search
-- -- map("n", "<C-d>", "<C-d>zz", { desc = "Scroll downwards" })
-- -- map("n", "<C-u>", "<C-u>zz", { desc = "Scroll upwards" })
-- -- map("n", "n", "nzzzv", { desc = "Next result" })
-- -- map("n", "N", "Nzzzv", { desc = "Previous result" })
-- -- Execute macro over a visual region.
-- map("x", "@", function()
--   return ":norm @" .. vim.fn.getcharstr() .. "<cr>"
-- end, { expr = true })
--
-- for i = 1, 9, 1 do
--   map("n", "<leader>" .. i, i .. "gt", {})
-- end
-- map("n", "<leader>0", ":tablast<cr>", {})
--
-- -- Add new empty lines
-- map("n", "<CR>", "mao<ESC>`a")
-- map("n", "<leader><CR>", "maO<ESC>`a")
--
-- -- -- Scrolling TODO: add this when you find a suitable alternative to K map
-- -- map("n", "J", "<c-d>")
-- -- map("n", "K", "<c-u>")
-- -- map("n", "<c-d>", "J")
-- -- map("n", "g<c-d>", "gJ")
-- -- map("n", "<c-u>", "K")
-- -- map("n", "g<c-u>", "gK")
--
-- -- -- Navigation
-- -- map("n", "<A-h>", "0")
-- -- map("n", "<A-l>", "$")
-- --
--
-- map("n", "<leader>kr", "<cmd>LspStop<CR><cmd>LspStart<CR><cmd>LspStop<CR>", { desc = "Stop LSP" })
-- --
-- -- Save as sudo
-- map("c", "w!!", "<esc>:lua require'functions.utils'.sudo_write()<CR>", { silent = true })
--
-- map("v", "<", "<gv", { desc = "indent with <" })
-- map("v", ">", ">gv", { desc = "indent with >" })
-- -- Prevent copy highlighted word
-- map("v", "p", '"_dP', { desc = "prevent copy highlighted word" })
--
-- -- Show changes to save TODO:Not working
-- map("n", "<C-S-s>", function()
--   vim.cmd(":w !diff % -")
-- end, { desc = "Show changes to save" })
--
-- -- Save as sudo TODO:Not working
-- map("n", "<C-A-s>", function()
--   vim.cmd(":w !sudo tee %")
-- end, { desc = "Save as sudo" })
--
-- -- indent empty line
-- map("n", "i", function()
--   if #vim.fn.getline(".") == 0 then
--     return [["_cc]]
--   else
--     return "i"
--   end
-- end, { expr = true })
--
-- -- Git commit template navigation
-- map("i", "<A-i>", function()
--   vim.cmd("/^$")
--   vim.cmd.stopinsert()
-- end)
-- map("n", "<A-i>", function()
--   vim.cmd(":0")
--   vim.cmd("/]:")
--   vim.cmd("startinsert!")
-- end)
--
-- -- Commit
-- -- map({ "t", "n" }, "<A-c>", function()
-- --   vim.g.has_previous_terminal_to_be_set = false
-- --   term = GetCurrentTerminal()
-- --   if term ~= nil then
-- --     term:toggle()
-- --     vim.notify(term)
-- --   end
-- --
-- --   vim.g.is_lazygit_opened = true
-- --   vim.cmd("Git commit")
-- -- end)
--
-- -- Terminal TODO: move to toggleterm lua plugin file
-- vim.g.has_previous_terminal_to_be_set = true
--
-- -- map('t', '<esc>', [[<C-\><C-n>]])
-- -- map('t', '<esc>', [[<C-\><C-n>]])
-- map("t", "<C-h>", function()
--   vim.g.has_previous_terminal_to_be_set = true
--   vim.cmd("wincmd h")
-- end)
-- map("t", "<C-j>", function()
--   vim.g.has_previous_terminal_to_be_set = true
--   vim.cmd("wincmd j")
-- end)
-- map("t", "<C-k>", function()
--   vim.g.has_previous_terminal_to_be_set = true
--   vim.cmd("wincmd k")
-- end)
-- map("t", "<C-l>", function()
--   vim.g.has_previous_terminal_to_be_set = true
--   vim.cmd("wincmd l")
-- end)
-- map("t", "<C-w>", [[<C-\><C-n><C-w>]])
--
-- map({ "t" }, "<C-Up>", [[<C-\><C-n>]])
-- map({ "t" }, "<C-Down>", [[<C-\><C-n>]])
--
-- map({ "t", "n" }, "<A-s>", function()
--   vim.cmd("Telescope termfinder")
-- end)
--
-- -- Quit terminal: TODO: make it gracefully
-- map({ "t", "n" }, "<A-e>", function()
--   vim.g.has_previous_terminal_to_be_set = false
--   GetCurrentOrPreviousTerminal():shutdown()
-- end)
--
-- -- Hover current terminal
-- map({ "t", "n" }, "<A-h>", function()
--   vim.g.has_previous_terminal_to_be_set = false
--   local current_term = GetCurrentOrPreviousTerminal()
--   for _, term in pairs(GetAllTerminals()) do
--     if term.name ~= current_term.name then
--       term:close()
--     end
--   end
-- end)
--
-- function GetPreviousTerminal()
--   if vim.g.previous_terminal then
--     vim.g.has_previous_terminal_to_be_set = true
--     term = GetTerminalById(vim.g.previous_terminal.id)
--     if term:is_open() then
--       term:focus()
--       return
--     end
--     term:toggle()
--   end
-- end
--
-- map({ "t", "n" }, "<A-p>", function()
--   if vim.g.previous_terminal then
--     vim.g.has_previous_terminal_to_be_set = true
--     term = GetTerminalById(vim.g.previous_terminal.id)
--     if term:is_open() then
--       term:focus()
--       return
--     end
--     term:toggle()
--   end
-- end)
--
-- -- Hide all terminals
-- map({ "t", "n" }, "<A-a>", function()
--   vim.g.has_previous_terminal_to_be_set = false
--   for _, term in pairs(GetAllTerminals()) do
--     term:close()
--   end
-- end)
--
-- -- Hide one terminal
-- map({ "t", "n" }, "<A-t>", function()
--   vim.g.has_previous_terminal_to_be_set = true
--   GetCurrentOrPreviousTerminal():close()
-- end)
--
-- -- Open new terminal
-- map({ "t", "n" }, "<A-o>", function()
--   vim.g.has_previous_terminal_to_be_set = true
--   OpenOrCreateTerminal({ instruction = vim.o.shell, name = vim.fn.expand("%:h"), dir = vim.fn.expand("%:h") })
-- end)
--
-- -- Open new terminal
-- map({ "t", "n" }, "<A-n>", function()
--   vim.g.has_previous_terminal_to_be_set = true
--   ExecuteFunctionFromInput({
--     prompt = "Terminal Name",
--     fun = function(name)
--       OpenOrCreateTerminal({ instruction = vim.o.shell, name = name })
--     end,
--   })
-- end)
--
-- -- Format current terminal
-- map({ "t", "n" }, "<A-f>", function()
--   vim.g.has_previous_terminal_to_be_set = false
--   local term = GetCurrentOrPreviousTerminal()
--   if term.direction == "horizontal" then
--     term.direction = "float"
--   else
--     term.direction = "horizontal"
--   end
--
--   term:close()
--   term:toggle()
-- end)
--
--
-- local term_clear = function()
--   vim.notify("test")
--   -- vim.fn.feedkeys("^L", "n")
--   -- local sb = vim.bo.scrollback
--   -- vim.bo.scrollback = 1
--   -- vim.bo.scrollback = sb
-- end

-- vim.keymap.set("t", "<C-l>", term_clear)
--
map({ "t" }, "<A-l>", function()
  vim.fn.feedkeys("^L", "n")
  local sb = vim.bo.scrollback
  vim.bo.scrollback = 1
  vim.bo.scrollback = sb
end)

map({ "n" }, "<leader>oD", function()
  if vim.g.ENV_TF_LOG_ENABLED then
    vim.g.ENV_TF_LOG_ENABLED = false
    vim.notify("Disabling Terraform Debug")
  else
    vim.g.ENV_TF_LOG_ENABLED = true
    vim.notify("Enabling Terraform Debug")
  end
end, { noremap = true, desc = "Toggle Terraform Debug" })

map({ "n" }, "<leader>k", function()
  Snacks.terminal.open("k9s", {
    use_shell = false,
    auto_close = false,
    start_insert = false,
    auto_insert = false,
    win = {
      position = "float",
    },
  })
end)

-- https://www.reddit.com/r/neovim/comments/1k3lhac/tiny_quality_of_life_rebind_make_j_and_k/
vim.keymap.set("n", "j", function()
  if vim.v.count > 0 then
    return "m'" .. vim.v.count .. "j"
  end
  return "j"
end, { expr = true })

vim.keymap.set("n", "k", function()
  if vim.v.count > 0 then
    return "m'" .. vim.v.count .. "k"
  end
  return "k"
end, { expr = true })

-- tmux sessions
vim.keymap.set("n", "<leader>fw", function()
  local function get_tmux_windows()
    local windows_raw = vim.fn.system("tmux list-windows -F '#{window_index}: #{window_name}'")
    local windows = {}

    for window in windows_raw:gmatch("[^\r\n]+") do
      table.insert(windows, { text = window })
    end

    return windows
  end

  local windows = get_tmux_windows()

  Snacks.picker.pick({
    source = "tmux_windows",
    items = windows,
    format = "text",
    layout = {
      preset = "vscode",
    },
    confirm = function(picker, item)
      picker:close()
      local window_index = item.text:match("^(%d+):")
      if window_index then
        vim.fn.system(string.format("tmux select-window -t %s", window_index))
      end
    end,
  })
end, { desc = "Find Tmux Window" })
