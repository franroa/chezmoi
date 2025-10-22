-- Show errors and warnings in a floating window
-- vim.api.nvim_create_autocmd("CursorHold", {
--   callback = function()
--     vim.diagnostic.open_float(nil, { focusable = false, source = "if_many" })
--   end,
-- })
--
--
-- TILTFILES
vim.filetype.add({
  pattern = {
    ["Tiltfile"] = "tiltfile", -- Sets the filetype to `angular.html` if it matches the pattern
    -- ["Taskfile.*.yaml"] = "taskfile", -- Sets the filetype to `angular.html` if it matches the pattern
  },
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "tiltfile",
  callback = function()
    vim.treesitter.language.register("python", "tiltfile")
  end,
})
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "*.csv",
  callback = function()
    vim.api.nvim_set_hl(0, "CsvViewHeaderLine", { fg = "#FFD700", bg = "#4A4A4A", underline = true, sp = "#FFD700" })
    vim.cmd("CsvViewEnable  delimiter=, display_mode=border")
  end,
})

-- vim.filetype.add({
--   pattern = {
--     ["Taskfile.yaml"] = "taskfile", -- Sets the filetype to `angular.html` if it matches the pattern
--   },
-- })
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "taskfile",
--   callback = function()
--     vim.treesitter.language.register("yaml", "taskfile")
--   end,
-- })

-- vim.api.nvim_create_autocmd("TermEnter", {
--   callback = function()
--     vim.cmd([[hi Cursor guifg=green guibg=green]])
--     vim.cmd([[hi Cursor2 guifg=red guibg=red]])
--     vim.cmd([[hi TermCursor guifg=red guibg=red]])
--     vim.cmd([[hi TermCursorNC guifg=red guibg=red]])
--     vim.cmd([[set guicursor=n-v-c:block-Cursor/lCursor,i-ci-ve:ver25-Cursor2/lCursor2,r-cr:hor20,o:hor50]])
--     -- vim.cmd([[set guicursor=n-v-c:block,i-ci-ve:hor25-Cursor]])
--     -- vim.cmd([[set guicursor=n-v-c-sm:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor]])
--     -- vim.cmd([[set guicursor=n-v-c-sm:hor25-Cursor,i-ci-ve:hor25-Cursor,r-cr-o:hor25-Cursor]])
--   end,
-- })
-- vim.api.nvim_create_autocmd("TermLeave", {
--   callback = function()
--     vim.cmd([[set guicursor=n-v-c-i:block]])
--   end,
-- })
-- vim.api.nvim_create_autocmd("InsertEnter", {
--   callback = function()
--     -- vim.cmd([[set guicursor=a:ver25]])
--     vim.cmd([[set guicursor=n-v-c-sm:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor]])
--   end,
-- })
-- vim.api.nvim_create_autocmd("InsertLeave", {
--   callback = function()
--     vim.cmd([[set guicursor=n-v-c-i:block]])
--   end,
-- })

-- -- Move the coursor to the beggining TODO: check how to keep cursor in other buffers
-- vim.api.nvim_create_autocmd("BufEnter", {
--   pattern = "*",
--   callback = function()
--     if
--       vim.bo.filetype == "neo-tree"
--       or vim.bo.filetype == "copilot-chat"
--       or vim.bo.filetype == "OverseerList"
--       or vim.bo.filetype == "dbui"
--     then
--       vim.defer_fn(function()
--         vim.api.nvim_win_set_cursor(0, { vim.fn.line("."), 1 })
--       end, 10)
--     end
--     if require("easy-dotnet").is_dotnet_project() then --TODO: improve this, call this when changing dir and on enter
--       vim.keymap.set("n", "<leader>oB", function()
--         require("easy-dotnet").build_solution()
--       end, { desc = "Build .NET App" })
--       vim.keymap.set("n", "<leader>oTr", function()
--         vim.cmd([[Dotnet testrunner]])
--       end, { desc = "Test Runner" })
--
--       vim.keymap.set("n", "<leader>oTs", function()
--         require("easy-dotnet").test_solution()
--       end, { desc = "Test .NET Solution" })
--
--       vim.keymap.set("n", "<leader>oTp", function()
--         require("easy-dotnet").test_project()
--       end, { desc = "Test .NET Project" })
--
--       vim.keymap.set("n", "<leader>or", function()
--         require("easy-dotnet").run_project()
--       end, { desc = "Run .NET App" })
--
--       vim.keymap.set("n", "<leader>oR", function()
--         require("easy-dotnet").restore()
--       end, { desc = "Restore .NET Nugets" })
--
--       vim.keymap.set("n", "<leader>oC", function()
--         require("easy-dotnet").clean()
--       end, { desc = "Dotnet Clean" })
--
--       vim.keymap.set("n", "<leader>oS", function()
--         require("easy-dotnet").secrets()
--       end, { desc = "Open User Secrets" })
--
--       vim.keymap.set("n", "<leader>op", function() end, { desc = "Push local .NET Nugets" })
--     end
--   end,
-- })

vim.api.nvim_create_autocmd({ "UIEnter", "ColorScheme" }, {
  callback = function()
    vim.notify("Test Entra")
  end,
})

-- vim.api.nvim_create_autocmd("BufReadPost", {
--   callback = function(args)
--     local filetype = vim.api.nvim_get_option_value("filetype", { buf = args.buf })
--     if filetype == "markdown" then
--       require("snacks").zen.zen()
--     end
--   end,
-- })
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
    elseif i == 3 then          -- last line
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
-- Terminal cursor
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
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client:supports_method("textDocument/foldingRange") then
      local win = vim.api.nvim_get_current_win()
      vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
    end
  end,
})

-- https://www.reddit.com/r/neovim/comments/1k7arqq/lsp_document_color_support_available_on_master/
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if client:supports_method("textDocument/documentColor") then
      vim.lsp.document_color.enable(true, args.buf, { style = "virtual" })
    end
  end,
})

vim.api.nvim_create_user_command("RunUnderCursor", function()
  local ts_utils = require("nvim-treesitter.utils")
  local query = vim.treesitter.query

  local function get_task_name_under_cursor()
    local function get_yaml_parent_node(node)
      -- If node is nil or already in the YAML tree, return it
      while node do
        local type = node:type()
        -- We treat these as "embedded/injected" languages, not part of YAML structure
        if type == "command" or type == "program" or type == "argument" or type == "word" then
          node = node:parent()
        else
          break
        end
      end
      return node
    end

    local current = get_yaml_parent_node(ts_utils.get_node_at_cursor())
    if not current then
      print("No node under cursor")
      return
    end
    -- Traverse upwards to find the 'tasks' block
    local tasks_node = nil
    local task_child_node = nil

    while current do
      local parent = current:parent()
      if parent:type() == "block_mapping_pair" then
        local key_node = parent:field("key")[1]
        if key_node and vim.treesitter.get_node_text(key_node, 0) == "tasks" then
          tasks_node = parent
          break
        end
        task_child_node = parent
      end
      current = current:parent()
    end

    if not tasks_node then
      print("Not inside a 'tasks' block")
      return
    end

    -- Now, find the task under the cursor within the 'tasks' block
    local tasks_value = tasks_node:field("value")[1]
    if not tasks_value then
      print("'tasks' has no value")
      return
    end

    vim.notify(vim.treesitter.get_node_text(task_child_node:field("key")[1], 0))
  end

  get_task_name_under_cursor()
end, {})

vim.api.nvim_set_keymap("n", "<leader>r", ":RunUnderCursor<CR>", { noremap = true, silent = true })

-- vim.defer_fn(require("functions.autofold").fold_river_blocks, 100) -- delay by 100ms
-- require("functions.treesitter_autofold").setup("alloy") -- Pass the filetype(s) you want to target
--
--
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*:n",          -- any mode to Normal mode
  callback = function()
    vim.cmd([[normal! zi]]) -- Unfold everything to clear any existing manual folds
    -- vim.cmd([[normal! zi]]) -- Unfold everything to clear any existing manual folds
    vim.defer_fn(function()
      vim.cmd([[normal! zi]]) -- Unfold everything to clear any existing manual folds
    end, 300)                 -- Pequeño retraso para asegurar que Treesitter haya parseado
    -- vim.cmd([[normal! zi]]) -- Unfold everything to clear any existing manual folds
    -- Your logic here
  end,
})

-- vim.api.nvim_create_autocmd({ "InsertEnter" }, {
--   pattern = "*",
--   callback = function()
--     vim.cmd([[normal! zi]]) -- Unfold everything to clear any existing manual folds
--     -- vim.defer_fn(function()
--     --   require("functions.autofold").fold_river_blocks(0)
--     -- end, 100) -- Pequeño retraso para asegurar que Treesitter haya parseado
--   end,
-- })
-- vim.api.nvim_create_autocmd({ "InsertLeave" }, {
--   pattern = "*",
--   callback = function()
--     vim.cmd([[normal! zi]]) -- Unfold everything to clear any existing manual folds
--   end,
-- })
--
--
-- vim.lsp.enable("ty")
vim.lsp.enable("systemd")
vim.lsp.enable("river")
vim.lsp.enable("roslyn")
vim.lsp.enable("harper_ls")
vim.lsp.enable("ts")
-- vim.lsp.enable("markdown_oxide")
vim.lsp.config("*", {
  capabilities = {
    textDocuments = {
      onTypeFormatting = {
        dynamicRegistration = false,
      },
    },
  },
})
vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  if client and client.name == "vtsls" then
    require("ts-error-translator").translate_diagnostics(err, result, ctx)
  end
  vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx)
end
-- vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
--   update_in_insert = false,
--   virtual_text = true,
-- })

vim.lsp.config("*", {
  filetypes = {
    "markdown",
    "lua",
  },
})

vim.lsp.config("harper_ls", {
  userDictPath = "~/dict.txt",
  fileDictPath = "~/dict.txt",
  linters = {
    SpellCheck = true,
    SpelledNumbers = false,
    AnA = true,
    SentenceCapitalization = true,
    UnclosedQuotes = true,
    WrongQuotes = false,
    LongSentences = true,
    RepeatedWords = true,
    Spaces = true,
    Matcher = true,
    CorrectNumberSuffix = true,
  },
  codeActions = {
    ForceStable = false,
  },
  markdown = {
    IgnoreLinkTitle = false,
  },
  diagnosticSeverity = "hint",
  isolateEnglish = false,
  dialect = "American",
  maxFileLength = 120000,
})

vim.lsp.omnifunc = true

function get_lsp_client_by_name(name)
  local clients = vim.lsp.get_clients()
  for _, client in ipairs(clients) do
    if client.name == name then
      return client
    end
  end
  return nil
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    -- Get the LSP client that has just attached
    local client = get_lsp_client_by_name("terraformls")

    -- Check if the client exists and supports semantic tokens
    if client and client.server_capabilities.semanticTokensProvider then
      -- Disable semantic tokens by setting the provider to nil
      client.server_capabilities.semanticTokensProvider = nil
      print("Disabled semantic tokens for client: " .. client.name)
    end
  end,
})

-- vim.api.nvim_create_autocmd("LspAttach", {
--   group = vim.api.nvim_create_augroup("RiverLspConfig", { clear = true }),
--   callback = function(ev)
--     local client = vim.lsp.get_client_by_id(ev.data.client_id)
--
--     if client and client.name == "river" then
--       vim.lsp.buf.workspace_symbol("")
--       vim.diagnostic.config({
--         workspace = true,
--         signs = true,
--         virtual_text = true,
--         update_in_insert = false,
--       }, ev.buf)
--     end
--   end,
-- })

-- vim.api.nvim_create_user_command("SortColumn", function(opts)
--   if not tonumber(opts.args) then
--     print("Error: Argument must be a number")
--     return
--   end
--   local bang = opts.bang and "!" or ""
--   local range = opts.range == 0 and "" or ("%d,%d"):format(opts.line1, opts.line2)
--   local pattern = string.format("%ssort%s /^\\([^|]*|\\)\\{%s\\}/", range, bang, opts.args)
--   vim.cmd(pattern)
-- end, { nargs = 1, bang = true, range = true })
--
--
--
--
--
--
--
--
--
--
--
--
-------------------------------------------------------------------------------
--                           Folding section
-------------------------------------------------------------------------------

-- Checks each line to see if it matches a markdown heading (#, ##, etc.):
-- It’s called implicitly by Neovim’s folding engine by vim.opt_local.foldexpr
function _G.markdown_foldexpr()
  local lnum = vim.v.lnum
  local line = vim.fn.getline(lnum)
  local heading = line:match("^(#+)%s")
  if heading then
    local level = #heading
    if level == 1 then
      -- Special handling for H1
      if lnum == 1 then
        return ">1"
      else
        local frontmatter_end = vim.b.frontmatter_end
        if frontmatter_end and (lnum == frontmatter_end + 1) then
          return ">1"
        end
      end
    elseif level >= 2 and level <= 6 then
      -- Regular handling for H2-H6
      return ">" .. level
    end
  end
  return "="
end

local function set_markdown_folding()
  vim.opt_local.foldmethod = "expr"
  vim.opt_local.foldexpr = "v:lua.markdown_foldexpr()"
  vim.opt_local.foldlevel = 99

  -- Detect frontmatter closing line
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local found_first = false
  local frontmatter_end = nil
  for i, line in ipairs(lines) do
    if line == "---" then
      if not found_first then
        found_first = true
      else
        frontmatter_end = i
        break
      end
    end
  end
  vim.b.frontmatter_end = frontmatter_end
end

-- Use autocommand to apply only to markdown files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = set_markdown_folding,
})

-- Function to fold all headings of a specific level
local function fold_headings_of_level(level)
  -- Move to the top of the file without adding to jumplist
  vim.cmd("keepjumps normal! gg")
  -- Get the total number of lines
  local total_lines = vim.fn.line("$")
  for line = 1, total_lines do
    -- Get the content of the current line
    local line_content = vim.fn.getline(line)
    -- "^" -> Ensures the match is at the start of the line
    -- string.rep("#", level) -> Creates a string with 'level' number of "#" characters
    -- "%s" -> Matches any whitespace character after the "#" characters
    -- So this will match `## `, `### `, `#### ` for example, which are markdown headings
    if line_content:match("^" .. string.rep("#", level) .. "%s") then
      -- Move the cursor to the current line without adding to jumplist
      vim.cmd(string.format("keepjumps call cursor(%d, 1)", line))
      -- Check if the current line has a fold level > 0
      local current_foldlevel = vim.fn.foldlevel(line)
      if current_foldlevel > 0 then
        -- Fold the heading if it matches the level
        if vim.fn.foldclosed(line) == -1 then
          vim.cmd("normal! za")
        end
        -- else
        --   vim.notify("No fold at line " .. line, vim.log.levels.WARN)
      end
    end
  end
end

local function fold_markdown_headings(levels)
  -- I save the view to know where to jump back after folding
  local saved_view = vim.fn.winsaveview()
  for _, level in ipairs(levels) do
    fold_headings_of_level(level)
  end
  vim.cmd("nohlsearch")
  -- Restore the view to jump to where I was
  vim.fn.winrestview(saved_view)
end

-- HACK: Fold markdown headings in Neovim with a keymap
-- https://youtu.be/EYczZLNEnIY
--
-- Keymap for folding markdown headings of level 1 or above
vim.keymap.set("n", "zj", function()
  -- "Update" saves only if the buffer has been modified since the last save
  vim.cmd("silent update")
  -- vim.keymap.set("n", "<leader>mfj", function()
  -- Reloads the file to refresh folds, otheriise you have to re-open neovim
  vim.cmd("edit!")
  -- Unfold everything first or I had issues
  vim.cmd("normal! zR")
  fold_markdown_headings({ 6, 5, 4, 3, 2, 1 })
  vim.cmd("normal! zz") -- center the cursor line on screen
end, { desc = "[P]Fold all headings level 1 or above" })

-- HACK: Fold markdown headings in Neovim with a keymap
-- https://youtu.be/EYczZLNEnIY
--
-- Keymap for folding markdown headings of level 2 or above
-- I know, it reads like "madafaka" but "k" for me means "2"
vim.keymap.set("n", "zk", function()
  -- "Update" saves only if the buffer has been modified since the last save
  vim.cmd("silent update")
  -- vim.keymap.set("n", "<leader>mfk", function()
  -- Reloads the file to refresh folds, otherwise you have to re-open neovim
  vim.cmd("edit!")
  -- Unfold everything first or I had issues
  vim.cmd("normal! zR")
  fold_markdown_headings({ 6, 5, 4, 3, 2 })
  vim.cmd("normal! zz") -- center the cursor line on screen
end, { desc = "[P]Fold all headings level 2 or above" })

-- HACK: Fold markdown headings in Neovim with a keymap
-- https://youtu.be/EYczZLNEnIY
--
-- Keymap for folding markdown headings of level 3 or above
vim.keymap.set("n", "zl", function()
  -- "Update" saves only if the buffer has been modified since the last save
  vim.cmd("silent update")
  -- vim.keymap.set("n", "<leader>mfl", function()
  -- Reloads the file to refresh folds, otherwise you have to re-open neovim
  vim.cmd("edit!")
  -- Unfold everything first or I had issues
  vim.cmd("normal! zR")
  fold_markdown_headings({ 6, 5, 4, 3 })
  vim.cmd("normal! zz") -- center the cursor line on screen
end, { desc = "[P]Fold all headings level 3 or above" })

-- HACK: Fold markdown headings in Neovim with a keymap
-- https://youtu.be/EYczZLNEnIY
--
-- Keymap for folding markdown headings of level 4 or above
vim.keymap.set("n", "z;", function()
  -- "Update" saves only if the buffer has been modified since the last save
  vim.cmd("silent update")
  -- vim.keymap.set("n", "<leader>mf;", function()
  -- Reloads the file to refresh folds, otherwise you have to re-open neovim
  vim.cmd("edit!")
  -- Unfold everything first or I had issues
  vim.cmd("normal! zR")
  fold_markdown_headings({ 6, 5, 4 })
  vim.cmd("normal! zz") -- center the cursor line on screen
end, { desc = "[P]Fold all headings level 4 or above" })

-- HACK: Fold markdown headings in Neovim with a keymap
-- https://youtu.be/EYczZLNEnIY
--
-- Use <CR> to fold when in normal mode
-- To see help about folds use `:help fold`
vim.keymap.set("n", "<CR>", function()
  -- Get the current line number
  local line = vim.fn.line(".")
  -- Get the fold level of the current line
  local foldlevel = vim.fn.foldlevel(line)
  if foldlevel == 0 then
    vim.notify("No fold found", vim.log.levels.INFO)
  else
    vim.cmd("normal! za")
    vim.cmd("normal! zz") -- center the cursor line on screen
  end
end, { desc = "[P]Toggle fold" })

vim.keymap.set("n", "<S-CR>", "zMzxzz", { desc = "Fold everything but current block" })

-- HACK: Fold markdown headings in Neovim with a keymap
-- https://youtu.be/EYczZLNEnIY
--
-- Keymap for unfolding markdown headings of level 2 or above
-- Changed all the markdown folding and unfolding keymaps from <leader>mfj to
-- zj, zk, zl, z; and zu respectively lamw25wmal
vim.keymap.set("n", "zu", function()
  -- "Update" saves only if the buffer has been modified since the last save
  vim.cmd("silent update")
  -- vim.keymap.set("n", "<leader>mfu", function()
  -- Reloads the file to reflect the changes
  vim.cmd("edit!")
  vim.cmd("normal! zR") -- Unfold all headings
  vim.cmd("normal! zz") -- center the cursor line on screen
end, { desc = "[P]Unfold all headings level 2 or above" })

-- HACK: Fold markdown headings in Neovim with a keymap
-- https://youtu.be/EYczZLNEnIY
--
-- gk jummps to the markdown heading above and then folds it
-- zi by default toggles folding, but I don't need it lamw25wmal
vim.keymap.set("n", "zi", function()
  -- "Update" saves only if the buffer has been modified since the last save
  vim.cmd("silent update")
  -- Difference between normal and normal!
  -- - `normal` executes the command and respects any mappings that might be defined.
  -- - `normal!` executes the command in a "raw" mode, ignoring any mappings.
  vim.cmd("normal gk")
  -- This is to fold the line under the cursor
  vim.cmd("normal! za")
  vim.cmd("normal! zz") -- center the cursor line on screen
end, { desc = "[P]Fold the heading cursor currently on" })

local list_snips = function()
  local ft_list = require("luasnip").available()[vim.o.filetype]
  local ft_snips = {}
  for _, item in pairs(ft_list) do
    ft_snips[item.trigger] = item.name
  end
  print(vim.inspect(ft_snips))
end
-- Setup markdown/wrapped line mode
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "txt" },
  callback = function()
    -- Enable line wrapping
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true

    -- Map j and k to move by visual lines
    vim.api.nvim_buf_set_keymap(0, "n", "j", "gj", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, "n", "k", "gk", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, "v", "j", "gj", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, "v", "k", "gk", { noremap = true, silent = true })

    -- Map $ and 0 to move by visual lines
    vim.api.nvim_buf_set_keymap(0, "n", "$", "g$", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, "n", "0", "g0", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, "v", "$", "g$", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, "v", "0", "g0", { noremap = true, silent = true })
  end,
})
vim.api.nvim_create_user_command("SnipList", list_snips, {})

-- Create an autocommand group to keep things organized

local kubectl_alloy_format_group = vim.api.nvim_create_augroup("KubectlAlloyFormat", { clear = true })
vim.api.nvim_create_autocmd({ "BufReadPost" }, {
  group = kubectl_alloy_format_group,
  pattern = { "*/kubectl-edit-*.yaml", "*/kube-editor-*.yaml" },
  callback = function()
    -- Check if this looks like a kubernetes edit session
    local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or ""
    if first_line:match("^# Please edit the object below") then
      local file_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local is_configmap = false
      local has_alloy_config = false

      for _, line in ipairs(file_content) do
        if line:match("kind:%s*ConfigMap") then
          is_configmap = true
        end
        if line:match("config.alloy:") then
          has_alloy_config = true
        end
      end

      if is_configmap and has_alloy_config then
        -- Process the file line by line
        local in_alloy_block = false
        local alloy_indent = ""
        local alloy_content = {}
        local start_line = 0
        local end_line = 0

        for i, line in ipairs(file_content) do
          if line:match('config.alloy:%s*"') then
            in_alloy_block = true
            start_line = i
            alloy_indent = line:match("^(%s*)config%.alloy")
            local content_start = line:match('config%.alloy:%s*"(.*)$')

            if content_start then
              table.insert(alloy_content, content_start)
            end
          elseif in_alloy_block then
            if line:match('"$') and not line:match('\\"$') then
              -- End of the alloy block
              in_alloy_block = false
              end_line = i
              local content_end = line:match('^(.*)"$')
              if content_end then
                table.insert(alloy_content, content_end)
              end

              -- Now process the collected content
              local joined = table.concat(alloy_content, "")
              -- Unescape the content
              local unescaped =
                  joined:gsub("\\n", "\n"):gsub("\\t", "\t"):gsub('\\"', '"'):gsub("\\\\", "\\"):gsub("\\(%s)", "%1") -- Remove escape before whitespace

              -- Split into lines and preserve indentation
              local lines = {}
              for uline in unescaped:gmatch("[^\n]+") do
                table.insert(lines, uline)
              end

              -- Format the output with proper indentation
              local output_lines = {}
              table.insert(output_lines, alloy_indent .. "config.alloy: |")
              for _, content_line in ipairs(lines) do
                -- Remove any remaining escape sequences
                content_line = content_line:gsub("\\", "")
                table.insert(output_lines, alloy_indent .. "  " .. content_line)
              end

              -- Replace the original lines with our processed ones
              vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, output_lines)

              -- Reset for next block
              alloy_content = {}
            else
              -- Middle of the block
              table.insert(alloy_content, line)
            end
          end
        end
      end
    end
  end,
})

-- vim.api.nvim_create_user_command(
--   "AlloyPipelineDiagram",
--   require("functions.alloy_visualizer").CreatePipelineDiagram,
--   {}
-- )
-- -- vim.api.nvim_create_user_command("GitlabPipelineDiagram", require("functions.gitlab").CreatePipelineDiagram, {})
-- vim.api.nvim_create_user_command(
--   "FoldUnrelatedPipelines",
--   require("functions.alloy_visualizer").FoldUnrelatedPipelines,
--   {}
-- )
-- require("functions.alloy_visualizer").setup_keymaps()
-- vim.api.nvim_create_user_command("FocusPipeline", require("functions.alloy_visualizer").FocusPipeline, {})
--
-- lua
-- This code sets up the automatic pipeline refresh for alloy files.

-- Create a dedicated, clearable group for our autocommands.
--
--

-- :lua for k,_ in pairs(package.loaded) do if k:match('local_plugins%.alloy') then package.loaded[k]=nil end end; require('local_plugins.alloy.lua.features.
-- visualizer.main').CreateVerticalPipelineDiagram()
--
--
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "cs" },
  callback = function()
    vim.api.nvim_clear_autocmds({
      group = "noice_lsp_progress",
      event = "LspProgress",
      pattern = "*",
    })
  end,
})

-- vim.g.last_cwd = vim.fn.getcwd(0)
-- vim.api.nvim_create_autocmd("BufEnter", {
--   callback = function()
--     vim.notify(vim.g.last_cwd)
--     local current_cwd = vim.fn.getcwd(0)
--     if current_cwd ~= vim.g.last_cwd then
--       vim.notify("Directory changed to: " .. current_cwd)
--       vim.g.last_cwd = current_cwd
--     end
--   end,
-- })
--
--

vim.diagnostic.config({ virtual_text = false })

---------------- MEMORY USAGE ----------------
-- Monitor memory usage
local function check_memory()
  local mem_kb = collectgarbage("count")
  if mem_kb > 100000 then -- 100MB
    collectgarbage("collect")
    print(string.format("Memory cleaned: %.2f MB", mem_kb / 1024))
  end
end

-- Periodic garbage collection
local gc_timer = vim.loop.new_timer()
gc_timer:start(60000, 60000, vim.schedule_wrap(check_memory)) -- every minute

-- Clean up on buffer delete
vim.api.nvim_create_autocmd("BufDelete", {
  callback = function()
    collectgarbage("collect")
  end,
})
---------------- MEMORY USAGE ----------------
