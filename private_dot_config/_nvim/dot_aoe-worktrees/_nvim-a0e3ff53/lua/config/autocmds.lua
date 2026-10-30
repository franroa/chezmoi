-- TILTFILES
vim.filetype.add({
  pattern = {
    ["Tiltfile"] = "tiltfile", -- Sets the filetype to `angular.html` if it matches the pattern
  },
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "tiltfile",
  callback = function()
    vim.treesitter.language.register("python", "tiltfile") -- Register the filetype with treesitter for the `angular` language/parser
  end,
})

-- Move the coursor to the beggining TODO: check how to keep cursor in other buffers
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = function()
    if
      vim.bo.filetype == "neo-tree"
      or vim.bo.filetype == "copilot-chat"
      or vim.bo.filetype == "OverseerList"
      or vim.bo.filetype == "dbui"
    then
      vim.defer_fn(function()
        vim.api.nvim_win_set_cursor(0, { vim.fn.line("."), 1 })
      end, 10)
    end
    if require("easy-dotnet").is_dotnet_project() then --TODO: improve this, call this when changing dir and on enter
      vim.keymap.set("n", "<leader>oB", function()
        require("easy-dotnet").build_solution()
      end, { desc = "Build .NET App" })
      vim.keymap.set("n", "<leader>oTr", function()
        vim.cmd([[Dotnet testrunner]])
      end, { desc = "Test Runner" })

      vim.keymap.set("n", "<leader>oTs", function()
        require("easy-dotnet").test_solution()
      end, { desc = "Test .NET Solution" })

      vim.keymap.set("n", "<leader>oTp", function()
        require("easy-dotnet").test_project()
      end, { desc = "Test .NET Project" })

      vim.keymap.set("n", "<leader>or", function()
        require("easy-dotnet").run_project()
      end, { desc = "Run .NET App" })

      vim.keymap.set("n", "<leader>oR", function()
        require("easy-dotnet").restore()
      end, { desc = "Restore .NET Nugets" })

      vim.keymap.set("n", "<leader>oC", function()
        require("easy-dotnet").clean()
      end, { desc = "Dotnet Clean" })

      vim.keymap.set("n", "<leader>oS", function()
        require("easy-dotnet").secrets()
      end, { desc = "Open User Secrets" })

      vim.keymap.set("n", "<leader>op", function() end, { desc = "Push local .NET Nugets" })
    end
  end,
})

vim.api.nvim_create_autocmd({ "UIEnter", "ColorScheme" }, {
  callback = function()
    vim.notify("Test Entra")
  end,
})

vim.api.nvim_create_autocmd("UILeave", {
  callback = function()
    vim.notify("Test Sale")
  end,
})

-- git-worktrees
vim.api.nvim_create_autocmd({ "TabEnter" }, {
  callback = function(args)
    vim.cmd("cd " .. LazyVim.root.git())
  end,
})

-- vim-dadbod-ui
vim.api.nvim_create_autocmd(
  --FIX:
  --this should be revisited because is firing many times
  { "BufWinLeave", "BufWritePost", "WinLeave" },
  {
    desc = "Save view with mkview for real files",
    -- group = view_group,
    callback = function(args)
      local filetype = vim.api.nvim_get_option_value("filetype", { buf = args.buf })
      if filetype == "dbout" then
        vim.cmd([[setlocal modifiable]])
        transform_buffer_table()
        vim.cmd([[setlocal nomodifiable]])
      end
    end,
  }
)
function transform_buffer_table()
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  for i, line in ipairs(lines) do
    if i == 1 then -- first line
      line = line:gsub("^%+", "┌"):gsub("%+$", "┐")
      line = line:gsub("%+", "┬")
    elseif i == 3 then -- last line
      line = line:gsub("^%+", "├"):gsub("%+$", "┤")
    elseif i == #lines - 1 then -- last line
      line = line:gsub("^%+", "└"):gsub("%+$", "┘")
      line = line:gsub("%+", "┴")
    end
    line = line:gsub("-", "─")
    line = line:gsub("|", "│")
    line = line:gsub("+", "┼")
    lines[i] = line
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end
-- TODO: https://alpha2phi.medium.com/modern-neovim-configuration-hacks-93b13283969f
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "*",
--   callback = function()
--     if vim.bo.filetype == "copilot-chat" then
--       vim.opt.clipboard = ""
--     else
--       vim.opt.clipboard = "unnamedplus"
--     end
--   end,
-- })
--
-- vim.api.nvim_create_autocmd({ "FocusGained" }, {
--   pattern = { "*" },
--   callback = function()
--     if vim.bo.filetype ~= "copilot-chat" then
--       vim.cmd([[call setreg("@", getreg("+"))]])
--     end
--   end,
-- })
-- -- -- sync with system clipboard on focus
-- -- vim.api.nvim_create_autocmd({ "focuslost" }, {
-- --   pattern = { "*" },
-- --   command = [[call setreg("+", getreg("@"))]],
-- -- })
--
-- -- -- only highlight when searching TODO: check this
-- -- vim.api.nvim_create_autocmd("CmdlineEnter", {
-- --   callback = function()
-- --     local cmd = vim.v.event.cmdtype
-- --     if cmd == "/" or cmd == "?" then
-- --       vim.opt.hlsearch = true
-- --     end
-- --   end,
-- -- })
-- -- vim.api.nvim_create_autocmd("CmdlineLeave", {
-- --   callback = function()
-- --     local cmd = vim.v.event.cmdtype
-- --     if cmd == "/" or cmd == "?" then
-- --       vim.opt.hlsearch = false
-- --     end
-- --   end,
-- -- })
--
-- -- TODO: Get Relative Path of file
-- -- local yank_relative_path = function()
-- --   local path = MiniFiles.get_fs_entry().path
-- --   vim.fn.setreg('"', vim.fn.fnamemodify(path, ":."))
-- -- end
-- --
-- -- vim.api.nvim_create_autocmd("User", {
-- --   pattern = "MiniFilesBufferCreate",
-- --   callback = function(args)
-- --     vim.keymap.set("n", "gy", yank_relative_path, { buffer = args.data.buf_id })
-- --   end,
-- -- })
--
-- -- Make folds persistent
-- -- TODO: check this view_group
-- -- local view_group = augroup("auto_view", { clear = true })
-- vim.api.nvim_create_autocmd({ "BufWinLeave", "BufWritePost", "WinLeave" }, {
--   desc = "Save view with mkview for real files",
--   -- group = view_group,
--   callback = function(args)
--     if vim.b[args.buf].view_activated then
--       vim.cmd.mkview({ mods = { emsg_silent = true } })
--     end
--   end,
-- })
-- vim.api.nvim_create_autocmd("BufWinEnter", {
--   desc = "Try to load file view if available and enable view saving for real files",
--   -- group = view_group,
--   callback = function(args)
--     if not vim.b[args.buf].view_activated then
--       local filetype = vim.api.nvim_get_option_value("filetype", { buf = args.buf })
--       local buftype = vim.api.nvim_get_option_value("buftype", { buf = args.buf })
--       local ignore_filetypes = { "gitcommit", "gitrebase", "svg", "hgcommit" }
--       if buftype == "" and filetype and filetype ~= "" and not vim.tbl_contains(ignore_filetypes, filetype) then
--         vim.b[args.buf].view_activated = true
--         vim.cmd.loadview({ mods = { emsg_silent = true } })
--       end
--     end
--   end,
-- })
--
-- -- Disable the concealing in some file formats
-- -- The default conceallevel is 3 in LazyVim
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = { "json", "jsonc", "markdown" },
--   callback = function()
--     vim.wo.conceallevel = 0
--   end,
-- })
--
-- -- Terminal cursor
-- vim.api.nvim_set_hl(0, "TerminalCursorShape", { underline = true })
-- vim.api.nvim_create_autocmd("TermEnter", {
--   callback = function()
--     vim.cmd([[setlocal winhighlight=TermCursor:TerminalCursorShape]])
--   end,
-- })
-- vim.api.nvim_create_autocmd("VimLeave", {
--   callback = function()
--     vim.cmd([[set guicursor=a:ver25]])
--   end,
-- })
--
-- vim.g.is_comming_from_toggleterm_window = false
-- vim.g.previous_toggleterm_edgy_window = nil
-- vim.api.nvim_create_autocmd("WinLeave", {
--   callback = function()
--     if vim.bo.filetype == "toggleterm" and vim.g.is_comming_from_toggleterm_window == false then
--       resize_all_terminal_windows(-30)
--     end
--     if vim.bo.filetype == "dbout" then
--       require("edgy").get_win(vim.api.nvim_get_current_win()):resize("height", -30)
--       return
--     end
--   end,
-- })
--
-- function resize_all_terminal_windows(height)
--   local terms_table = GetAllTerminals()
--   for _, term in pairs(terms_table) do
--     if term:is_open() then
--       require("edgy").get_win(term.window):resize("height", height)
--     end
--   end
-- end
-- vim.api.nvim_create_autocmd("WinEnter", {
--   callback = function()
--     if vim.bo.filetype == "toggleterm" then
--       if vim.g.is_comming_from_toggleterm_window then
--         vim.g.is_comming_from_toggleterm_window = true
--         return
--       end
--       -- If I am entering a toggleterm from other filetype
--       resize_all_terminal_windows(30)
--       return
--     end
--
--     vim.g.is_comming_from_toggleterm_window = false
--
--     if vim.bo.filetype == "dbout" then
--       require("edgy").get_win(vim.api.nvim_get_current_win()):resize("height", 30)
--       return
--     end
--   end,
-- })
--
-- vim.api.nvim_create_autocmd("WinLeave", {
--   pattern = "*",
--   callback = function()
--     if vim.bo.filetype == "gitcommit" and vim.g.is_lazygit_opened then
--       term = GetTerminalById("(default) lazygit")
--       term:toggle()
--     end
--   end,
-- })
-- local function copilot_commit()
--   local chat = require("CopilotChat")
--   -- Run the CopilotChat /Commit command
--
--   chat.ask(
--     [[
--     Write commit message for the change. Make sure the title has maximum 50
--     characters and message is wrapped at 72 characters. Answer just with the
--     message, without explanations and without back tilts. Dont write new lines
--     Please use the given template as hint of the info I need, as following:
--     - All words in brackets starting a line needs to be in your output
--     - After the first word in brackets you have to give a short explanation of what has been changed.
--       It must be done in imperative with a sentence for each change. Each sentence starting a new line
--     - After the second word in brackets you have to explain why it was done
--     ]],
--     {
--       callback = function(response)
--         -- Remove null characters from response
--         response = string.gsub(response, "\0", "")
--         -- Split the response into lines
--         local lines = {}
--         for line in response:gmatch("([^\n]*)\n?") do
--           table.insert(lines, line)
--         end
--         -- Set the lines in the current buffer
--         vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
--       end,
--     }
--   )
-- end
--
-- vim.api.nvim_create_augroup("CopilotCommitGroup", { clear = true })
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "gitcommit",
--   callback = copilot_commit,
--   group = "CopilotCommitGroup",
-- })
--
-- vim.api.nvim_create_autocmd("BufLeave", {
--   pattern = "*",
--   callback = function()
--     if vim.bo.filetype == "toggleterm" and vim.g.has_previous_terminal_to_be_set then
--       vim.g.previous_terminal = GetCurrentTerminal()
--     end
--
--     if vim.bo.filetype == "vira_menu" then
--       vim.g.is_comming_from_vira = true
--     end
--
--     if vim.bo.filetype == "dashboard" then
--       vim.fn.timer_start(1000, function()
--         require("lualine").setup()
--       end)
--     end
--   end,
-- })
--
-- vim.api.nvim_create_autocmd("BufEnter", {
--   pattern = "*",
--   callback = function()
--     if vim.bo.filetype == "vira_menu" then -- TODO: more excludes
--       return
--     end
--     if vim.g.is_comming_from_vira and is_a_new_vira_chosen() then
--       vim.g.VIRA_ISSUE = vim.g.vira_active_issue
--       vim.notify("Set Jira Issue: " .. vim.g.VIRA_ISSUE)
--       local timer = vim.loop.new_timer()
--       timer:start(
--         50,
--         0,
--         vim.schedule_wrap(function()
--           UpdateGitBranchFromViraIssue()
--           local git_path = require("functions.utils").get_git_path()
--           vim.g.VIRA_ISSUE_DESCRIPTION = vim.fn.system(
--             "echo -n $(cut -d '_' -f 3- <<< $(cut -d '/' -f2 <<<$(git --git-dir="
--               .. git_path
--               .. "/.git branch --show-current)) --output-delimiter=' ')"
--           )
--           vim.g.is_comming_from_vira = false
--         end)
--       )
--       -- elseif vim.g.is_comming_from_vira == false then -- TODO: check if works when changin branch with fugitive
--     elseif vim.g.is_comming_from_vira == false then -- TODO: check if works when changin branch with fugitive
--       set_vira_issue_from_branch()
--     end
--   end,
-- })
--
-- -- Automatically enter in insert mode
-- vim.api.nvim_create_autocmd({ "BufEnter" }, {
--   pattern = "*",
--   callback = function()
--     if vim.bo.filetype == "toggleterm" then
--       vim.cmd("startinsert")
--     end
--   end,
-- })
--
-- vim.g.should_track_neotree_window = true
-- vim.g.was_neotree_manually_opened = false
-- vim.g.min_width_to_show_explorer = 80
-- vim.api.nvim_create_autocmd({ "VimResized" }, {
--   pattern = "*",
--   callback = function()
--     if vim.g.was_neotree_manually_opened == false then
--       return
--     end
--
--     vim.g.should_track_neotree_window = false
--     if vim.opt.columns._value <= vim.g.min_width_to_show_explorer then
--       -- if vim.api.nvim_win_get_width(vim.api.nvim_get_current_win()) <= vim.g.min_width_to_show_explorer then
--       vim.cmd("Neotree close")
--     else
--       vim.cmd("Neotree show")
--     end
--     vim.g.should_track_neotree_window = true
--   end,
-- })
--
-- -- TODO: THis is just a work around (witing for https://github.com/neovim/neovim/pull/22865)
-- vim.api.nvim_create_autocmd("User", {
--   pattern = "MiniFilesWindowUpdate",
--   callback = function(args)
--     vim.wo[args.data.win_id].relativenumber = true
--   end,
-- })
--
-- vim.api.nvim_create_autocmd("User", {
--   pattern = "FugitiveChanged",
--   callback = function()
--     set_vira_issue_from_branch()
--   end,
-- })
--
-- -- Disable autoformat for lua files SYNAOS
-- vim.api.nvim_create_autocmd({ "FileType" }, {
--   pattern = { "yaml", "yml" },
--   callback = function()
--     vim.b.autoformat = false
--   end,
-- })
