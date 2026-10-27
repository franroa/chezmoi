return {
  "folke/flash.nvim",
  event = "VeryLazy",
  keys = {
    -- Enhanced search with Flash
    -- {
    --   "s",
    --   mode = { "n", "x", "o" },
    --   function()
    --     require("flash").jump({
    --       search = {
    --         mode = "search",
    --         max_length = 0,
    --       },
    --       label = {
    --         after = { 0, 0 },
    --         before = { 0, 0 },
    --         uppercase = false,
    --         format = function(opts)
    --           return {
    --             { opts.match.label, "FlashMatch" },
    --             { " ", "FlashCurrent" },
    --           }
    --         end,
    --       },
    --       pattern = ".",
    --     })
    --   end,
    --   desc = "Flash",
    -- },
    -- Flash Treesitter nodes
    -- {
    --   "S",
    --   mode = { "n", "x", "o" },
    --   function()
    --     require("flash").treesitter()
    --   end,
    --   desc = "Flash Treesitter",
    -- },
    -- -- Remote Flash (multi-window)
    -- {
    --   "r",
    --   mode = "o",
    --   function()
    --     require("flash").remote()
    --   end,
    --   desc = "Remote Flash",
    -- },
    -- -- Treesitter search with toggle
    -- {
    --   "R",
    --   mode = { "o", "x" },
    --   function()
    --     require("flash").treesitter_search()
    --   end,
    --   desc = "Treesitter Search",
    -- },
    -- Cool word-based jumping
    {
      "<leader>Fw",
      mode = { "n", "x" },
      function()
        require("flash").jump({
          pattern = "\\<\\w*\\>", -- whole words only
          search = {
            mode = "search",
            max_length = false,
          },
          label = {
            before = true,
            after = false,
            style = "overlay",
          },
          highlight = {
            matches = true,
            backdrop = true,
            groups = {
              match = "FlashMatch",
              current = "FlashCurrent",
              backdrop = "FlashBackdrop",
              label = "FlashLabel",
            },
          },
        })
      end,
      desc = "Flash Words",
    },
    -- Line-based jumping
    {
      "<leader>Fl",
      mode = { "n", "x" },
      function()
        require("flash").jump({
          search = { mode = "search", max_length = 0 },
          label = { after = { 0, 0 }, before = { 0, 0 } },
          pattern = "^",
          action = function(match, state)
            state:hide()
            vim.api.nvim_win_set_cursor(0, { match.pos[1], 0 })
          end,
        })
      end,
      desc = "Flash Lines",
    },
    -- Function jumping with Treesitter
    {
      "<leader>Ff",
      mode = { "n", "x" },
      function()
        require("flash").jump({
          matcher = function(win)
            -- Get treesitter query for functions
            local query = vim.treesitter.query.parse(
              vim.bo[vim.api.nvim_win_get_buf(win)].filetype,
              [[
                (function_definition) @function
                (method_definition) @function
                (function_declaration) @function
              ]]
            )
            local parser = vim.treesitter.get_parser(vim.api.nvim_win_get_buf(win))
            local tree = parser:parse()[1]
            local matches = {}

            for _, match in query:iter_matches(tree:root(), vim.api.nvim_win_get_buf(win)) do
              for id, node in pairs(match) do
                local start_row, start_col = node:start()
                table.insert(matches, {
                  pos = { start_row + 1, start_col },
                  end_pos = { node:end_() },
                })
              end
            end
            return matches
          end,
          label = {
            before = true,
            after = false,
            style = "overlay",
          },
        })
      end,
      desc = "Flash Functions",
    },
    -- Remote diagnostics with Flash (all visible windows)
    {
      "<leader>FD",
      mode = { "n", "x" },
      function()
        require("flash").jump({
          search = { multi_window = true },
          matcher = function(win)
            ---@param diag Diagnostic
            return vim.tbl_map(function(diag)
              return {
                pos = { diag.lnum + 1, diag.col },
                end_pos = { diag.end_lnum + 1, diag.end_col > 0 and diag.end_col - 1 or diag.end_col },
                severity = diag.severity,
                message = diag.message,
              }
            end, vim.diagnostic.get(vim.api.nvim_win_get_buf(win)))
          end,
          label = {
            before = true,
            after = false,
            style = "overlay",
            format = function(opts)
              local severity_icons = { "❌", "⚠️", "ℹ️", "💡" }
              local icon = severity_icons[opts.match.severity] or "•"
              return {
                { icon, "FlashLabel" },
                { opts.match.label, "FlashMatch" },
              }
            end,
          },
          action = function(match, state)
            vim.api.nvim_win_call(match.win, function()
              vim.api.nvim_win_set_cursor(match.win, match.pos)
              vim.diagnostic.open_float()
            end)
            state:restore()
          end,
        })
      end,
      desc = "Flash Remote Diagnostics (All Windows)",
    },
    -- Jump to LSP references with Flash
    -- Jump to LSP references with Flash
    -- Jump to LSP references with Flash
    {
      "<leader>Fr",
      mode = { "n", "x" },
      function()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients == 0 then
          vim.notify("No LSP clients attached", vim.log.levels.WARN)
          return
        end

        local client = clients[1]
        local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
        params.context = { includeDeclaration = true }
        local bufnr = vim.api.nvim_get_current_buf()

        vim.lsp.buf_request(bufnr, "textDocument/references", params, function(err, result)
          if err then
            vim.notify("LSP error: " .. (err.message or "Unknown error"), vim.log.levels.ERROR)
            return
          end

          if not result or vim.tbl_isempty(result) then
            vim.notify("No references found", vim.log.levels.INFO)
            return
          end

          local matches = {}
          for _, ref in ipairs(result) do
            local uri = ref.uri
            local ref_bufnr = vim.uri_to_bufnr(uri)

            -- Load buffer if not loaded
            if not vim.api.nvim_buf_is_loaded(ref_bufnr) then
              vim.fn.bufload(ref_bufnr)
            end

            local start_pos = ref.range.start
            table.insert(matches, {
              pos = { start_pos.line + 1, start_pos.character },
              end_pos = { ref.range["end"].line + 1, ref.range["end"].character },
              bufnr = ref_bufnr,
              uri = uri,
            })
          end

          if #matches == 0 then
            vim.notify("No valid references found", vim.log.levels.INFO)
            return
          end

          require("flash").jump({
            search = {
              mode = "search",
              max_length = 0,
              multi_window = true,
            },
            matcher = function(win)
              local win_matches = {}
              local current_bufnr = vim.api.nvim_win_get_buf(win)

              for _, match in ipairs(matches) do
                if match.bufnr == current_bufnr then
                  table.insert(win_matches, match)
                end
              end
              return win_matches
            end,
            label = {
              before = true,
              after = false,
              style = "overlay",
              format = function(opts)
                return {
                  { "⭆", "FlashLabel" },
                  { opts.match.label, "FlashMatch" },
                }
              end,
            },
            action = function(match, state)
              if match.bufnr ~= vim.api.nvim_get_current_buf() then
                vim.cmd("buffer " .. match.bufnr)
              end
              vim.api.nvim_win_set_cursor(0, match.pos)
              vim.cmd("normal! zz")
            end,
          })
        end)
      end,
      desc = "Flash LSP References",
    },
    -- Enhanced search with preview
    -- {
    --   "/",
    --   mode = { "n", "x", "o" },
    --   function()
    --     require("flash").jump({
    --       search = {
    --         mode = "search",
    --         forward = true,
    --         multi_window = false,
    --         wrap = true,
    --         incremental = true,
    --       },
    --       label = {
    --         format = function(opts)
    --           return {
    --             { "[", "FlashPrompt" },
    --             { opts.match.label, "FlashMatch" },
    --             { "]", "FlashPrompt" },
    --           }
    --         end,
    --       },
    --     })
    --   end,
    --   desc = "Flash Search",
    -- },
    -- Jump to diagnostics with Flash
    {
      "<leader>Fd",
      mode = { "n", "x" },
      function()
        local diagnostics = vim.diagnostic.get(0)
        if #diagnostics == 0 then
          vim.notify("No diagnostics in current buffer", vim.log.levels.WARN)
          return
        end

        require("flash").jump({
          matcher = function(win)
            local matches = {}
            local current_bufnr = vim.api.nvim_win_get_buf(win)

            for _, diag in ipairs(diagnostics) do
              table.insert(matches, {
                pos = { diag.lnum + 1, diag.col },
                end_pos = { diag.end_lnum + 1, diag.end_col },
                severity = diag.severity,
                message = diag.message,
              })
            end
            return matches
          end,
          label = {
            before = true,
            after = false,
            style = "overlay",
            format = function(opts)
              local severity_icons = { "❌", "⚠️", "ℹ️", "💡" }
              local icon = severity_icons[opts.match.severity] or "•"
              return {
                { icon, "FlashLabel" },
                { opts.match.label, "FlashMatch" },
              }
            end,
          },
          action = function(match, state)
            vim.api.nvim_win_set_cursor(0, match.pos)
            vim.diagnostic.open_float(nil, { focus = false })
          end,
        })
      end,
      desc = "Flash Diagnostics",
    },
    -- Backwards search
    -- {
    --   "?",
    --   mode = { "n", "x", "o" },
    --   function()
    --     require("flash").jump({
    --       search = {
    --         mode = "search",
    --         forward = false,
    --         multi_window = false,
    --         wrap = true,
    --         incremental = true,
    --       },
    --       label = {
    --         format = function(opts)
    --           return {
    --             { "⬅", "FlashPrompt" },
    --             { opts.match.label, "FlashMatch" },
    --           }
    --         end,
    --       },
    --     })
    --   end,
    --   desc = "Flash Search Backward",
    -- },
    -- Jump to symbols with Flash (document symbols)
    {
      "<leader>Fs",
      mode = { "n", "x" },
      function()
        local params = { textDocument = vim.lsp.util.make_text_document_params() }
        local bufnr = vim.api.nvim_get_current_buf()

        vim.lsp.buf_request(bufnr, "textDocument/documentSymbol", params, function(err, result)
          if err or not result or vim.tbl_isempty(result) then
            vim.notify("No symbols found", vim.log.levels.INFO)
            return
          end

          local function extract_symbols(symbols, matches)
            matches = matches or {}
            for _, symbol in ipairs(symbols) do
              local range = symbol.range or symbol.location.range
              table.insert(matches, {
                pos = { range.start.line + 1, range.start.character },
                end_pos = { range["end"].line + 1, range["end"].character },
                name = symbol.name,
                kind = symbol.kind,
              })

              -- Recursively extract nested symbols
              if symbol.children then
                extract_symbols(symbol.children, matches)
              end
            end
            return matches
          end

          local matches = extract_symbols(result)

          require("flash").jump({
            matcher = function(win)
              return matches
            end,
            label = {
              before = true,
              after = false,
              style = "overlay",
              format = function(opts)
                local kind_icons = {
                  [1] = "📄",
                  [2] = "📁",
                  [3] = "📦",
                  [4] = "📝",
                  [5] = "🏷️",
                  [6] = "⚙️",
                  [7] = "🔧",
                  [8] = "📊",
                  [9] = "🎛️",
                  [10] = "🔗",
                  [11] = "📋",
                  [12] = "🆔",
                  [13] = "🔢",
                  [14] = "📐",
                  [15] = "🔤",
                  [16] = "🔒",
                  [17] = "📑",
                  [18] = "🔑",
                  [19] = "🎯",
                  [20] = "📎",
                  [21] = "🏗️",
                  [22] = "🔄",
                  [23] = "📖",
                  [24] = "🔘",
                  [25] = "🎨",
                }
                local icon = kind_icons[opts.match.kind] or "•"
                return {
                  { icon, "FlashLabel" },
                  { opts.match.label, "FlashMatch" },
                }
              end,
            },
            action = function(match, state)
              vim.api.nvim_win_set_cursor(0, match.pos)
              vim.cmd("normal! zz")
            end,
          })
        end)
      end,
      desc = "Flash Document Symbols",
    },
    -- Toggle Flash in current search
    {
      "<c-s>",
      mode = { "c" },
      function()
        require("flash").toggle()
      end,
      desc = "Toggle Flash Search",
    },
  },
  opts = {
    -- Cool label configuration
    label = {
      uppercase = true,
      exclude = "",
      current = true,
      after = true,
      before = false,
      style = "overlay", -- "eol" | "overlay" | "right_align" | "inline"
      reuse = "lowercase",
      distance = true,
      min_pattern_length = 0,
      -- rainbow = {
      --   enabled = true,
      --   shade = 5,
      -- },
      format = function(opts)
        return {
          { " ", "FlashBackdrop" },
          { opts.match.label, opts.hl_group },
          { " ", "FlashBackdrop" },
        }
      end,
    },
    -- Enhanced search options
    search = {
      multi_window = true,
      forward = true,
      wrap = true,
      mode = "exact", -- "exact" | "search" | "fuzzy"
      incremental = false,
      exclude = {
        "notify",
        "cmp_menu",
        "noice",
        "flash_prompt",
        function(win)
          return vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "TelescopePrompt"
        end,
      },
      trigger = "",
      max_length = false,
    },
    -- Jump behavior
    jump = {
      jumplist = true,
      pos = "start", -- "start" | "end" | "range"
      history = false,
      register = false,
      nohlsearch = false,
      autojump = false,
      inclusive = nil,
      offset = nil,
    },
    -- Highlight groups
    highlight = {
      backdrop = true,
      matches = true,
      priority = 5000,
      groups = {
        match = "FlashMatch",
        current = "FlashCurrent",
        backdrop = "FlashBackdrop",
        label = "FlashLabel",
      },
    },
    -- Action configuration
    action = nil,
    -- Pattern configuration
    pattern = "",
    -- Continue after first jump
    continue = false,
    -- Custom modes
    modes = {
      -- Disable default 's' and 'S' bindings
      search = {
        enabled = false,
      },
      char = {
        enabled = true,
        -- Dynamic configuration for f, F, t, T
        config = function(opts)
          opts.autohide = opts.autohide == nil and vim.fn.mode(true):find("no") and vim.v.operator == "y"

          opts.jump_labels = opts.jump_labels
            and vim.v.count == 0
            and vim.fn.reg_executing() == ""
            and vim.fn.reg_recording() == ""

          if opts.jump_labels then
            opts.label.exclude = "hjkliardc"
          end
        end,
        -- Show jump labels for enhanced f/F/t/T
        jump_labels = true,
        multi_line = true,
        label = { exclude = "hjkliardc" },
        keys = { "f", "F", "t", "T", ";" },
        char_actions = function(motion)
          return {
            [";"] = "next",
            [","] = "prev",
            [motion:lower()] = "next",
            [motion:upper()] = "prev",
          }
        end,
        search = { wrap = false },
        highlight = { backdrop = true },
        jump = { register = false },
      },
      treesitter = {
        labels = "abcdefghijklmnopqrstuvwxyz",
        jump = { pos = "range" },
        search = { incremental = false },
        label = {
          before = true,
          after = true,
          style = "inline",
        },
        highlight = {
          backdrop = false,
          matches = false,
        },
      },
      treesitter_search = {
        jump = { pos = "range" },
        search = {
          multi_window = true,
          wrap = true,
          incremental = false,
        },
        remote_op = {
          restore = true,
          motion = true,
        },
      },
      remote = {
        remote_op = {
          restore = true,
          motion = true,
        },
      },
    },
    -- Prompt configuration
    prompt = {
      enabled = true,
      prefix = { { "⚡", "FlashPrompt" } },
      win_config = {
        relative = "editor",
        width = 1,
        height = 1,
        row = -1,
        col = 0,
        zindex = 1000,
      },
    },
    -- Remote Flash configuration
    remote_op = {
      restore = false,
      motion = false,
    },
  },
  config = function(_, opts)
    require("flash").setup(opts)

    -- -- Custom highlight groups
    -- vim.api.nvim_set_hl(0, "FlashBackdrop", {
    --   fg = "#545c7e",
    --   bg = "NONE",
    -- })
    -- vim.api.nvim_set_hl(0, "FlashMatch", {
    --   fg = "#c0caf5",
    --   bg = "#3d59a1",
    --   bold = true,
    -- })
    -- vim.api.nvim_set_hl(0, "FlashCurrent", {
    --   fg = "#16161e",
    --   bg = "#e0af68",
    --   bold = true,
    -- })
    -- vim.api.nvim_set_hl(0, "FlashLabel", {
    --   fg = "#16161e",
    --   bg = "#f7768e",
    --   bold = true,
    --   underline = true,
    -- })
    -- vim.api.nvim_set_hl(0, "FlashPrompt", {
    --   fg = "#7dcfff",
    --   bold = true,
    -- })
  end,
}
