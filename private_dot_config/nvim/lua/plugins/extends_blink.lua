-- return {
--   "saghen/blink.cmp",
--   config = function()
--     require("blink-cmp").setup({
--       keymap = {
--         -- Manually invoke minuet completion.
--         ["<A-y>"] = require("minuet").make_blink_map(),
--       },
--       sources = {
--         -- Enable minuet for autocomplete
--         default = { "minuet" },
--         -- For manual completion only, remove 'minuet' from default
--         providers = {
--           minuet = {
--             name = "minuet",
--             module = "minuet.blink",
--             async = true,
--             -- Should match minuet.config.request_timeout * 1000,
--             -- since minuet.config.request_timeout is in seconds
--             timeout_ms = 3000,
--             score_offset = 50, -- Gives minuet higher priority among suggestions
--           },
--         },
--       },
--       -- Recommended to avoid unnecessary request
--       completion = { trigger = { prefetch_on_insert = false } },
--     })
--   end,
-- }
--
local kind_icons = {
  -- LLM Provider icons
  claude = "󰋦",
  openai = "󱢆",
  codestral = "󱎥",
  gemini = "",
  Groq = "",
  Openrouter = "󱂇",
  Ollama = "",
  ["Llama.cpp"] = "",
  Deepseek = "",
  -- Iconos de fuentes de autocompletado
  Text = "󰦨",
  Method = "m",
  Function = "󰊕",
  Constructor = "",
  Field = "",
  Variable = "󰀫",
  Class = "󰠱",
  Interface = "",
  Module = "",
  Property = "",
  Unit = "",
  Value = "󰎠",
  Enum = "",
  Keyword = "󰌋",
  Snippet = "",
  Color = "󰏘",
  File = "󰈙",
  Reference = "",
  Folder = "󰉋",
  EnumMember = "",
  Constant = "󰏿",
  Struct = "",
  Event = "",
  Operator = "󰆕",
  TypeParameter = "󰅲",
}

vim.g.lazyvim_blink_main = true

return {
  "saghen/blink.cmp",
  enabled = true,
  dependencies = {
    -- FIX: Añadidas dependencias necesarias para snippets
    "L3MON4D3/LuaSnip",
    "rafamadriz/friendly-snippets",

    -- Dependencias originales del usuario
    "mikavilpas/blink-ripgrep.nvim",
    "jc-doyle/cmp-pandoc-references",
    { "samiulsami/cmp-go-deep" },
    { "moyiz/blink-emoji.nvim" },
    { "saghen/blink.compat" },
    { "ray-x/cmp-treesitter" },
    "moyiz/blink-emoji.nvim",
    "Kaiser-Yang/blink-cmp-dictionary",
  },
  opts = function(_, opts)
    opts.appearance = vim.tbl_deep_extend("force", opts.appearance or {}, {
      use_nvim_cmp_as_default = true,
      nerd_font_variant = "normal",
      kind_icons = kind_icons,
    })

    opts.fuzzy = vim.tbl_deep_extend("force", opts.fuzzy or {}, {
      sorts = {
        -- Always prioritize exact matches, case-sensitive.
        "exact",

        -- Sort by Fuzzy matching score.
        "score",

        -- Sort by `sortText` field from LSP server, defaults to `label`.
        -- `sortText` often differs from `label`.
        "sort_text",

        -- Sort by `label` field from LSP server, i.e. name in completion menu.
        -- Needed to sort results from LSP server by `label`,
        -- even though protocol specifies default value of `sortText` is `label`.
        "label",
      },

      implementation = "prefer_rust_with_warning",
    })
    --
    -- opts.enabled = function()
    --   local filetype = vim.bo[0].filetype
    --   if
    --     filetype == "alloy_horizontal_diagram"
    --     or filetype == "TelescopePrompt"
    --     or filetype == "minifiles"
    --     or filetype == "snacks_picker_input"
    --   then
    --     return false
    --   end
    --   return true
    -- end

    -- Initial keymap extension for ripgrep
    opts.keymap = vim.tbl_deep_extend("force", opts.keymap or {}, {
      ["<c-g>"] = {
        function()
          require("blink-cmp").show({ providers = { "ripgrep" } })
        end,
      },
      -- ["<c-y>"] = require("minuet").make_blink_map(),
    })

    -- Extend the existing sources instead of overriding
    opts.sources = opts.sources or {}

    -- Merge default sources with existing ones
    local existing_default = opts.sources.default or {}
    local new_sources = {
      "dynamic_filter",
      "omni",
      "lsp",
      "path",
      "snippets",
      "ripgrep",
      "buffer",
      "dadbod",
      "emoji",
      "dictionary",
    }

    -- Create a set of existing sources to avoid duplicates
    local source_set = {}
    for _, source in ipairs(existing_default) do
      source_set[source] = true
    end

    -- Add new sources that don't already exist
    for _, source in ipairs(new_sources) do
      if not source_set[source] then
        table.insert(existing_default, source)
      end
    end

    opts.sources.default = existing_default

    -- Extend providers instead of overriding
    opts.sources.providers = vim.tbl_deep_extend("force", opts.sources.providers or {}, {

      cmdline = {
        min_keyword_length = function(ctx)
          -- when typing a command, only show when the keyword is 3 characters or longer
          if ctx.mode == "cmdline" and string.find(ctx.line, " ") == nil then
            return 1
          end
          return 0
        end,
      },

      dynamic_filter = {
        enabled = function()
          if vim.bo[0].filetype == "dynamic_filter" then
            return true
          end
          return false
        end,
        name = "dynamic_filter",
        module = "blink_sources.dynamic_filter",
      },

      -- FIX: Configuración de snippets simplificada a la versión estándar y funcional.
      -- Se ha eliminado la lógica personalizada con `should_show_items` y `transform_items` que causaba problemas.
      snippets = {
        name = "snippets",
        enabled = function()
          if vim.bo[0].filetype == "dynamic_filter" then
            return false
          end
          return true
        end,
        max_items = 15,
        min_keyword_length = 2,
        module = "blink.cmp.sources.snippets",
        score_offset = 85, -- Prioridad alta para los snippets
        -- should_show_items = function(ctx)
        --   return ctx.trigger.initial_kind ~= "trigger_character"
        -- end,
      },

      -- El resto de tus proveedores se mantienen intactos
      references = {
        enabled = function()
          if vim.bo[0].filetype == "dynamic_filter" then
            return false
          end
          return true
        end,
        name = "pandoc_references",
        module = "cmp-pandoc-references.blink",
        score_offset = 2,
      },
      symbols = { name = "symbols", module = "blink.compat.source" },
      path = {
        name = "Path",
        module = "blink.cmp.sources.path",
        score_offset = 25,
        fallbacks = { "snippets", "buffer" },
        enabled = function()
          if vim.bo[0].filetype == "dynamic_filter" then
            return false
          end
          return true
        end,
        opts = {
          trailing_slash = false,
          label_trailing_slash = true,
          get_cwd = function(context)
            return vim.fn.expand(("#%d:p:h"):format(context.bufnr))
          end,
          show_hidden_files_by_default = true,
        },
      },
      buffer = {
        name = "Buffer",
        max_items = 3,
        module = "blink.cmp.sources.buffer",
        min_keyword_length = 2,
        score_offset = 15,
        enabled = function()
          if vim.bo[0].filetype == "dynamic_filter" then
            return false
          end
          return true
        end,
      },
      -- minuet = {
      --   name = "minuet",
      --   module = "minuet.blink",
      --   async = true,
      --   -- Should match minuet.config.request_timeout * 1000,
      --   -- since minuet.config.request_timeout is in seconds
      --   timeout_ms = 3000,
      --   score_offset = 101, -- Gives minuet higher priority among suggestions
      -- },
      ["easy-dotnet"] = {
        name = "easy-dotnet",
        enabled = function()
          if vim.bo[0].filetype == "dynamic_filter" then
            return false
          end
          return true
        end,
        module = "easy-dotnet.completion.blink",
        score_offset = 10000,
        async = true,
      },
      go_deep = {
        enabled = function()
          if vim.bo[0].filetype == "dynamic_filter" then
            return false
          end
          return true
        end,
        name = "go_deep",
        module = "blink.compat.source",
      },
      treesitter = {
        name = "treesitter",
        module = "blink.compat.source",
        enabled = function()
          if vim.bo[0].filetype == "dynamic_filter" then
            return false
          end
          return true
        end,
      },
      ripgrep = {
        module = "blink-ripgrep",
        enabled = function()
          if vim.bo[0].filetype == "dynamic_filter" then
            return false
          end
          return true
        end,
        name = "Ripgrep",
        opts = {
          prefix_min_len = 3,
          project_root_marker = ".git",
          fallback_to_regex_highlighting = true,
          toggles = {
            on_off = nil,
          },
          backend = {
            use = "ripgrep",
            context_size = 5,
            ripgrep = {
              max_filesize = "1M",
              project_root_fallback = true,
              search_casing = "--ignore-case",
              additional_rg_options = {},
              ignore_paths = {},
              additional_paths = {},
            },
          },
          debug = false,
        },
      },
      lsp = { -- ROSLYN
        transform_items = function(_, items)
          if vim.bo.filetype == "cs" then
            for _, item in ipairs(items) do
              local cmp_item_kind = require("blink.cmp.types").CompletionItemKind

              if item.kind == cmp_item_kind.Property or item.kind == cmp_item_kind.Field then
                item.score_offset = item.score_offset + 1
              end

              -- print(vim.inspect(item))

              if item.kind == cmp_item_kind.Operator then
                item.score_offset = item.score_offset - 1
              end
            end
          end

          return vim.tbl_filter(function(item)
            return item.kind ~= require("blink.cmp.types").CompletionItemKind.Text
          end, items)
        end,
        module = "blink.cmp.sources.lsp",
        score_offset = 100,
        name = "LSP",
        opts = {},
        enabled = function()
          if vim.bo[0].filetype == "dynamic_filter" then
            return false
          end
          return true
        end,
      },

      -- lsp = {
      --   module = "blink.cmp.sources.lsp",
      --   name = "LSP",
      --   opts = {},
      --   enabled = true,
      -- },
      dadbod = {
        name = "Dadbod",
        module = "vim_dadbod_completion.blink",
        min_keyword_length = 2,
        score_offset = 85,
        enabled = function()
          if vim.bo[0].filetype == "dynamic_filter" then
            return false
          end
          return true
        end,
      },
      emoji = {
        module = "blink-emoji",
        enabled = function()
          if vim.bo[0].filetype == "dynamic_filter" then
            return false
          end
          return true
        end,
        name = "Emoji",
        score_offset = 93,
        min_keyword_length = 2,
        opts = { insert = true },
      },
      dictionary = {
        module = "blink-cmp-dictionary",
        name = "Dict",
        score_offset = 20,
        enabled = function()
          if vim.bo[0].filetype == "dynamic_filter" then
            return false
          end
          return true
        end,
        max_items = 8,
        min_keyword_length = 3,
        opts = {
          dictionary_directories = { vim.fn.expand("~/github/dotfiles-latest/dictionaries") },
          dictionary_files = {
            vim.fn.expand("~/github/dotfiles-latest/neovim/neobean/spell/en.utf-8.add"),
            vim.fn.expand("~/github/dotfiles-latest/neovim/neobean/spell/es.utf-8.add"),
          },
        },
      },
      copilot = {
        score_offset = 500,
      },
    })

    -- opts.cmdline = {
    --   enabled = true,
    --   keymap = {
    --     ["<CR>"] = { "accept_and_enter", "fallback" },
    --   },
    --   -- (optionally) automatically show the menu
    --   completion = { menu = { auto_show = true } },
    -- }

    opts.completion = vim.tbl_deep_extend("force", opts.completion or {}, {
      trigger = { prefetch_on_insert = false },
      ghost_text = { enabled = true },
      menu = {
        direction_priority = function()
          return { "n", "s" }
        end,
        draw = {
          columns = {
            { "label", "label_description", gap = 1 },
            { "kind_icon", "kind" },
            { "source_icon" },
          },
          components = {
            source_icon = {
              -- don't truncate source_icon
              ellipsis = false,
              text = function(ctx)
                return kind_icons[ctx.source_name:lower()] or kind_icons.fallback
              end,
              highlight = "BlinkCmpSource",
            },
          },
        },
      },
      documentation = {
        auto_show = true,
        window = {
          border = "single",
        },
      },
    })

    -- -- FIX: Asegurarse de que LuaSnip es el motor de snippets
    -- opts.snippets = {
    --   preset = "luasnip",
    -- }

    -- FIX: Mapeos de teclado mejorados para una mejor experiencia con snippets y autocompletado.
    opts.keymap = vim.tbl_deep_extend("force", opts.keymap, {
      preset = "default",
      ["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
      ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
      ["<CR>"] = { "accept", "fallback" },

      ["<Up>"] = { "select_prev", "fallback" },
      ["<Down>"] = { "select_next", "fallback" },
      ["<C-p>"] = { "select_prev", "fallback" },
      ["<C-n>"] = { "select_next", "fallback" },

      ["<S-k>"] = { "scroll_documentation_up", "fallback" },
      ["<S-j>"] = { "scroll_documentation_down", "fallback" },

      ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
      ["<C-e>"] = { "hide", "fallback" },
    })

    return opts
  end,
}

-- -- https://github.com/jmbuhr/nvim-config/blob/main/lua/plugins/completion.lua
-- --
-- -- https://cmp.saghen.dev/configuration/completion.html
-- local kind_icons = {
--   -- LLM Provider icons
--   claude = "󰋦",
--   openai = "󱢆",
--   codestral = "󱎥",
--   gemini = "",
--   Groq = "",
--   Openrouter = "󱂇",
--   Ollama = "",
--   ["Llama.cpp"] = "",
--   Deepseek = "",
-- }
--
-- vim.g.lazyvim_blink_main = true
-- --
--
-- -- Filename: ~/github/dotfiles-latest/neovim/neobean/lua/plugins/blink-cmp.lua
-- -- ~/github/dotfiles-latest/neovim/neobean/lua/plugins/blink-cmp.lua
--
-- -- HACK: blink.cmp updates | Remove LuaSnip | Emoji and Dictionary Sources | Fix Jump Autosave Issue
-- -- https://youtu.be/JrgfpWap_Pg
-- --
-- -- completion plugin with support for LSPs and external sources that updates
-- -- on every keystroke with minimal overhead
--
-- -- https://www.lazyvim.org/extras/coding/blink
-- -- https://github.com/saghen/blink.cmp
-- -- Documentation site: https://cmp.saghen.dev/
--
-- -- NOTE: Specify the trigger character(s) used for luasnip
-- local trigger_text = ";"
--
-- return {
--   "saghen/blink.cmp",
--   enabled = true,
--   -- In case there are breaking changes and you want to go back to the last
--   -- working release
--   -- https://github.com/Saghen/blink.cmp/releases
--   -- version = "v0.13.1",
--   dependencies = {
--     "mikavilpas/blink-ripgrep.nvim",
--     { "samiulsami/cmp-go-deep" },
--     { "moyiz/blink-emoji.nvim" },
--     { "saghen/blink.compat" },
--     { "ray-x/cmp-treesitter" },
--     "moyiz/blink-emoji.nvim",
--     "Kaiser-Yang/blink-cmp-dictionary",
--   },
--   opts = function(_, opts)
--     opts.appearance = {
--       use_nvim_cmp_as_default = true,
--       nerd_font_variant = "normal",
--       kind_icons = kind_icons,
--     }
--
--     -- I noticed that telescope was extremeley slow and taking too long to open,
--     -- assumed related to blink, so disabled blink and in fact it was related
--     -- :lua print(vim.bo[0].filetype)
--     -- So I'm disabling blink.cmp for Telescope
--     opts.enabled = function()
--       -- Get the current buffer's filetype
--       local filetype = vim.bo[0].filetype
--       -- Disable for Telescope buffers
--       if filetype == "TelescopePrompt" or filetype == "minifiles" or filetype == "snacks_picker_input" then
--         return false
--       end
--       return true
--     end
--
--     opts.keymap = vim.tbl_deep_extend("force", opts.keymap or {}, {
--       keymap = {
--         ["<c-g>"] = {
--           function()
--             -- invoke manually, requires blink >v0.8.0
--             require("blink-cmp").show({ providers = { "ripgrep" } })
--           end,
--         },
--         ["<A-y>"] = {
--           function(cmp)
--             cmp.show({ providers = { "minuet" } })
--           end,
--         },
--       },
--     })
--
--     -- NOTE: The new way to enable LuaSnip
--     -- Merge custom sources with the existing ones from lazyvim
--     -- NOTE: by default lazyvim already includes the lazydev source, so not adding it here again
--     opts.sources = vim.tbl_deep_extend("force", opts.sources or {}, {
--       -- default = { "lsp", "path", "snippets", "ripgrep", "buffer", "dadbod", "emoji", "dictionary" },
--       -- default = { "lsp", "obsidian", "obsidian_new", "obsidian_tags", "omni" },
--       -- default = { "snippets" },
--       -- default = { "lazydev", "lsp", "omni", "snippets" },
--       default = { "snippets" },
--       providers = {
--         -- lsp = {
--         --   name = "lsp",
--         --   enabled = true,
--         --   module = "blink.cmp.sources.lsp",
--         --   kind = "LSP",
--         --   min_keyword_length = 2,
--         --   -- When linking markdown notes, I would get snippets and text in the
--         --   -- suggestions, I want those to show only if there are no LSP
--         --   -- suggestions
--         --   --
--         --   -- Enabled fallbacks as this seems to be working now
--         --   -- Disabling fallbacks as my snippets wouldn't show up when editing
--         --   -- lua files
--         --   -- fallbacks = { "snippets", "buffer" },
--         --   score_offset = 90, -- the higher the number, the higher the priority
--         -- },
--         references = {
--           name = "pandoc_references",
--           module = "cmp-pandoc-references.blink",
--           score_offset = 2,
--         },
--         symbols = { name = "symbols", module = "blink.compat.source" },
--         path = {
--           name = "Path",
--           module = "blink.cmp.sources.path",
--           score_offset = 25,
--           -- When typing a path, I would get snippets and text in the
--           -- suggestions, I want those to show only if there are no path
--           -- suggestions
--           fallbacks = { "snippets", "buffer" },
--           -- min_keyword_length = 2,
--           opts = {
--             trailing_slash = false,
--             label_trailing_slash = true,
--             get_cwd = function(context)
--               return vim.fn.expand(("#%d:p:h"):format(context.bufnr))
--             end,
--             show_hidden_files_by_default = true,
--           },
--         },
--         buffer = {
--           name = "Buffer",
--           enabled = true,
--           max_items = 3,
--           module = "blink.cmp.sources.buffer",
--           min_keyword_length = 2,
--           score_offset = 15, -- the higher the number, the higher the priority
--         },
--         snippets = {
--           name = "snippets",
--           enabled = true,
--           max_items = 15,
--           min_keyword_length = 2,
--           module = "blink.cmp.sources.snippets",
--           score_offset = 85, -- the higher the number, the higher the priority
--           -- Only show snippets if I type the trigger_text characters, so
--           -- to expand the "bash" snippet, if the trigger_text is ";" I have to
--           should_show_items = function()
--             local col = vim.api.nvim_win_get_cursor(0)[2]
--             local before_cursor = vim.api.nvim_get_current_line():sub(1, col)
--             -- NOTE: remember that `trigger_text` is modified at the top of the file
--             return before_cursor:match(trigger_text .. "%w*$") ~= nil
--           end,
--           -- After accepting the completion, delete the trigger_text characters
--           -- from the final inserted text
--           -- Modified transform_items function based on suggestion by `synic` so
--           -- that the luasnip source is not reloaded after each transformation
--           -- https://github.com/linkarzu/dotfiles-latest/discussions/7#discussion-7849902
--           -- NOTE: I also tried to add the ";" prefix to all of the snippets loaded from
--           -- friendly-snippets in the luasnip.lua file, but I was unable to do
--           -- so, so I still have to use the transform_items here
--           -- This removes the ";" only for the friendly-snippets snippets
--           transform_items = function(_, items)
--             local line = vim.api.nvim_get_current_line()
--             local col = vim.api.nvim_win_get_cursor(0)[2]
--             local before_cursor = line:sub(1, col)
--             local start_pos, end_pos = before_cursor:find(trigger_text .. "[^" .. trigger_text .. "]*$")
--             if start_pos then
--               for _, item in ipairs(items) do
--                 if not item.trigger_text_modified then
--                   ---@diagnostic disable-next-line: inject-field
--                   item.trigger_text_modified = true
--                   item.textEdit = {
--                     newText = item.insertText or item.label,
--                     range = {
--                       start = { line = vim.fn.line(".") - 1, character = start_pos - 1 },
--                       ["end"] = { line = vim.fn.line(".") - 1, character = end_pos },
--                     },
--                   }
--                 end
--               end
--             end
--             return items
--           end,
--         },
--
--         minuet = {
--           name = "minuet",
--           module = "minuet.blink",
--           score_offset = 100,
--         },
--
--         ["easy-dotnet"] = {
--           name = "easy-dotnet",
--           enabled = true,
--           module = "easy-dotnet.completion.blink",
--           score_offset = 10000,
--           async = true,
--         },
--
--         go_deep = {
--           name = "go_deep",
--           module = "blink.compat.source",
--           opts = {
--             -- See below for configuration options
--           },
--         },
--
--         treesitter = {
--           name = "treesitter",
--           module = "blink.compat.source",
--         },
--
--         ripgrep = {
--           module = "blink-ripgrep",
--           name = "Ripgrep",
--           -- the options below are optional, some default values are shown
--           ---@module "blink-ripgrep"
--           ---@type blink-ripgrep.Options
--           opts = {
--             -- For many options, see `rg --help` for an exact description of
--             -- the values that ripgrep expects.
--
--             -- the minimum length of the current word to start searching
--             -- (if the word is shorter than this, the search will not start)
--             prefix_min_len = 3,
--
--             -- The number of lines to show around each match in the preview
--             -- (documentation) window. For example, 5 means to show 5 lines
--             -- before, then the match, and another 5 lines after the match.
--             context_size = 5,
--
--             -- The maximum file size of a file that ripgrep should include in
--             -- its search. Useful when your project contains large files that
--             -- might cause performance issues.
--             -- Examples:
--             -- "1024" (bytes by default), "200K", "1M", "1G", which will
--             -- exclude files larger than that size.
--             max_filesize = "1M",
--
--             -- Specifies how to find the root of the project where the ripgrep
--             -- search will start from. Accepts the same options as the marker
--             -- given to `:h vim.fs.root()` which offers many possibilities for
--             -- configuration. If none can be found, defaults to Neovim's cwd.
--             --
--             -- Examples:
--             -- - ".git" (default)
--             -- - { ".git", "package.json", ".root" }
--             project_root_marker = ".git",
--
--             -- Enable fallback to neovim cwd if project_root_marker is not
--             -- found. Default: `true`, which means to use the cwd.
--             project_root_fallback = true,
--
--             -- The casing to use for the search in a format that ripgrep
--             -- accepts. Defaults to "--ignore-case". See `rg --help` for all the
--             -- available options ripgrep supports, but you can try
--             -- "--case-sensitive" or "--smart-case".
--             search_casing = "--ignore-case",
--
--             -- (advanced) Any additional options you want to give to ripgrep.
--             -- See `rg -h` for a list of all available options. Might be
--             -- helpful in adjusting performance in specific situations.
--             -- If you have an idea for a default, please open an issue!
--             --
--             -- Not everything will work (obviously).
--             additional_rg_options = {},
--
--             -- When a result is found for a file whose filetype does not have a
--             -- treesitter parser installed, fall back to regex based highlighting
--             -- that is bundled in Neovim.
--             fallback_to_regex_highlighting = true,
--
--             -- Absolute root paths where the rg command will not be executed.
--             -- Usually you want to exclude paths using gitignore files or
--             -- ripgrep specific ignore files, but this can be used to only
--             -- ignore the paths in blink-ripgrep.nvim, maintaining the ability
--             -- to use ripgrep for those paths on the command line. If you need
--             -- to find out where the searches are executed, enable `debug` and
--             -- look at `:messages`.
--             ignore_paths = {},
--
--             -- Any additional paths to search in, in addition to the project
--             -- root. This can be useful if you want to include dictionary files
--             -- (/usr/share/dict/words), framework documentation, or any other
--             -- reference material that is not available within the project
--             -- root.
--             additional_paths = {},
--
--             -- Keymaps to toggle features on/off. This can be used to alter
--             -- the behavior of the plugin without restarting Neovim. Nothing
--             -- is enabled by default. Requires folke/snacks.nvim.
--             toggles = {
--               -- The keymap to toggle the plugin on and off from blink
--               -- completion results. Example: "<leader>tg"
--               on_off = nil,
--             },
--
--             -- Features that are not yet stable and might change in the future.
--             -- You can enable these to try them out beforehand, but be aware
--             -- that they might change. Nothing is enabled by default.
--             future_features = {
--               backend = {
--                 -- The backend to use for searching. Defaults to "ripgrep".
--                 -- Available options:
--                 -- - "ripgrep", always use ripgrep
--                 -- - "gitgrep", always use git grep
--                 -- - "gitgrep-or-ripgrep", use git grep if possible, otherwise
--                 --   ripgrep
--                 use = "ripgrep",
--               },
--             },
--
--             -- Show debug information in `:messages` that can help in
--             -- diagnosing issues with the plugin.
--             debug = false,
--           },
--           -- (optional) customize how the results are displayed. Many options
--           -- are available - make sure your lua LSP is set up so you get
--           -- autocompletion help
--           transform_items = function(_, items)
--             for _, item in ipairs(items) do
--               -- example: append a description to easily distinguish rg results
--               item.labelDetails = {
--                 description = "(rg)",
--               }
--             end
--             return items
--           end,
--         },
--         lsp = {
--           module = "blink.cmp.sources.lsp",
--           name = "LSP",
--           opts = {},
--           enabled = true,
--         },
--         -- lsp = { -- ROSLYN
--         --   transform_items = function(_, items)
--         --     for _, item in ipairs(items) do
--         --       local cmp_item_kind = require("blink.cmp.types").CompletionItemKind
--         --
--         --       if item.kind == cmp_item_kind.Property or item.kind == cmp_item_kind.Field then
--         --         item.score_offset = item.score_offset + 1
--         --       end
--         --
--         --       -- print(vim.inspect(item))
--         --
--         --       if item.kind == cmp_item_kind.Operator then
--         --         item.score_offset = item.score_offset - 1
--         --       end
--         --     end
--         --
--         --     return vim.tbl_filter(function(item)
--         --       return item.kind ~= require("blink.cmp.types").CompletionItemKind.Text
--         --     end, items)
--         --   end,
--         -- },
--
--         -- Example on how to configure dadbod found in the main repo
--         -- https://github.com/kristijanhusak/vim-dadbod-completion
--         dadbod = {
--           name = "Dadbod",
--           module = "vim_dadbod_completion.blink",
--           min_keyword_length = 2,
--           score_offset = 85, -- the higher the number, the higher the priority
--         },
--         -- https://github.com/moyiz/blink-emoji.nvim
--         emoji = {
--           module = "blink-emoji",
--           name = "Emoji",
--           score_offset = 93, -- the higher the number, the higher the priority
--           min_keyword_length = 2,
--           opts = { insert = true }, -- Insert emoji (default) or complete its name
--         },
--         -- https://github.com/Kaiser-Yang/blink-cmp-dictionary
--         -- In macOS to get started with a dictionary:
--         -- cp /usr/share/dict/words ~/github/dotfiles-latest/dictionaries/words.txt
--         --
--         -- NOTE: For the word definitions make sure "wn" is installed
--         -- brew install wordnet
--         dictionary = {
--           module = "blink-cmp-dictionary",
--           name = "Dict",
--           score_offset = 20, -- the higher the number, the higher the priority
--           -- https://github.com/Kaiser-Yang/blink-cmp-dictionary/issues/2
--           enabled = true,
--           max_items = 8,
--           min_keyword_length = 3,
--           opts = {
--             -- -- The dictionary by default now uses fzf, make sure to have it
--             -- -- installed
--             -- -- https://github.com/Kaiser-Yang/blink-cmp-dictionary/issues/2
--             --
--             -- Do not specify a file, just the path, and in the path you need to
--             -- have your .txt files
--             dictionary_directories = { vim.fn.expand("~/github/dotfiles-latest/dictionaries") },
--             -- Notice I'm also adding the words I add to the spell dictionary
--             dictionary_files = {
--               vim.fn.expand("~/github/dotfiles-latest/neovim/neobean/spell/en.utf-8.add"),
--               vim.fn.expand("~/github/dotfiles-latest/neovim/neobean/spell/es.utf-8.add"),
--             },
--             -- --  NOTE: To disable the definitions uncomment this section below
--             --
--             -- separate_output = function(output)
--             --   local items = {}
--             --   for line in output:gmatch("[^\r\n]+") do
--             --     table.insert(items, {
--             --       label = line,
--             --       insert_text = line,
--             --       documentation = nil,
--             --     })
--             --   end
--             --   return items
--             -- end,
--           },
--         },
--         -- -- Third class citizen mf always talking shit
--         -- copilot = {
--         --   name = "copilot",
--         --   enabled = true,
--         --   module = "blink-cmp-copilot",
--         --   kind = "Copilot",
--         --   min_keyword_length = 6,
--         --   score_offset = -100, -- the higher the number, the higher the priority
--         --   async = true,
--         -- },
--       },
--     })
--
--     opts.cmdline = {
--       enabled = true,
--     }
--
--     opts.completion = {
--       -- accept = {
--       --   auto_brackets = {
--       --     enabled = true,
--       --     default_brackets = { ";", "" },
--       --     override_brackets_for_filetypes = {
--       --       markdown = { ";", "" },
--       --     },
--       --   },
--       -- },
--       --   keyword = {
--       --     -- 'prefix' will fuzzy match on the text before the cursor
--       --     -- 'full' will fuzzy match on the text before *and* after the cursor
--       --     -- example: 'foo_|_bar' will match 'foo_' for 'prefix' and 'foo__bar' for 'full'
--       --     range = "full",
--       --   },
--       menu = {
--         border = "single",
--       },
--       documentation = {
--         auto_show = true,
--         window = {
--           border = "single",
--         },
--       },
--     }
--
--     -- opts.fuzzy = {
--     --   -- Disabling this matches the behavior of fzf
--     --   use_typo_resistance = false,
--     --   -- Frecency tracks the most recently/frequently used items and boosts the score of the item
--     --   use_frecency = true,
--     --   -- Proximity bonus boosts the score of items matching nearby words
--     --   use_proximity = false,
--     -- }
--
--     opts.snippets = {
--       preset = "luasnip", -- Choose LuaSnip as the snippet engine
--     }
--
--     -- -- To specify the options for snippets
--     -- opts.sources.providers.snippets.opts = {
--     --   use_show_condition = true, -- Enable filtering of snippets dynamically
--     --   show_autosnippets = true, -- Display autosnippets in the completion menu
--     -- }
--
--     -- The default preset used by lazyvim accepts completions with enter
--     -- I don't like using enter because if on markdown and typing
--     -- something, but you want to go to the line below, if you press enter,
--     -- the completion will be accepted
--     -- https://cmp.saghen.dev/configuration/keymap.html#default
--     opts.keymap = {
--       preset = "default",
--       ["<Tab>"] = { "snippet_forward", "fallback" },
--       ["<S-Tab>"] = { "snippet_backward", "fallback" },
--
--       ["<Up>"] = { "select_prev", "fallback" },
--       ["<Down>"] = { "select_next", "fallback" },
--       ["<C-p>"] = { "select_prev", "fallback" },
--       ["<C-n>"] = { "select_next", "fallback" },
--
--       ["<S-k>"] = { "scroll_documentation_up", "fallback" },
--       ["<S-j>"] = { "scroll_documentation_down", "fallback" },
--
--       ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
--       ["<C-e>"] = { "hide", "fallback" },
--     }
--
--     return opts
--   end,
-- }
--
-- --
-- -- return {
-- --   {
-- --     "saghen/blink.cmp",
-- --     optional = true,
-- --     dependencies = {
-- --       { "samiulsami/cmp-go-deep" },
-- --       { "moyiz/blink-emoji.nvim" },
-- --       { "saghen/blink.compat" },
-- --       { "ray-x/cmp-treesitter" },
-- --       { "Kaiser-Yang/blink-cmp-dictionary" },
-- --     },
-- --     build = "cargo build --release",
-- --     version = "1.*",
-- --     opts = {
-- --       keymap = {
-- --         ["<A-y>"] = {
-- --           function(cmp)
-- --             cmp.show({ providers = { "minuet" } })
-- --           end,
-- --         },
-- --       },
-- --       appearance = {
-- --         use_nvim_cmp_as_default = true,
-- --         nerd_font_variant = "normal",
-- --         kind_icons = kind_icons,
-- --       },
-- --
-- --       completion = {
-- --         list = { selection = { preselect = false }, cycle = { from_top = false } },
-- --       },
-- --       sources = {
-- --         -- if you want to use auto-complete
-- --         default = { "lsp", "emoji", "dictionary", "easy-dotnet", "path", "buffer", "snippets", "go_deep" },
-- --         -- default = { "minuet", "codecompanion", "lsp", "path", "buffer", "snippets" },
-- --         -- default = { "codecompanion" },
-- --         providers = {
-- --           emoji = {
-- --             module = "blink-emoji",
-- --             name = "Emoji",
-- --             score_offset = 15, -- Tune by preference
-- --             opts = {
-- --               insert = true, -- Insert emoji (default) or complete its name
-- --               ---@type string|table|fun():table
-- --               trigger = function()
-- --                 return { ":" }
-- --               end,
-- --             },
-- --             should_show_items = function()
-- --               return vim.tbl_contains(
-- --                 -- Enable emoji completion only for git commits and markdown.
-- --                 -- By default, enabled for all file-types.
-- --                 { "gitcommit", "markdown" },
-- --                 vim.o.filetype
-- --               )
-- --             end,
-- --           },
-- --           dictionary = {
-- --             module = "blink-cmp-dictionary",
-- --             name = "Dict",
-- --             score_offset = 20, -- the higher the number, the higher the priority
-- --             -- https://github.com/Kaiser-Yang/blink-cmp-dictionary/issues/2
-- --             enabled = true,
-- --             max_items = 8,
-- --             min_keyword_length = 3,
-- --             opts = {
-- --               -- -- The dictionary by default now uses fzf, make sure to have it
-- --               -- -- installed
-- --               -- -- https://github.com/Kaiser-Yang/blink-cmp-dictionary/issues/2
-- --               --
-- --               -- Do not specify a file, just the path, and in the path you need to
-- --               -- have your .txt files
-- --               dictionary_directories = { vim.fn.expand("~/github/dotfiles-latest/dictionaries") },
-- --               -- Notice I'm also adding the words I add to the spell dictionary
-- --               dictionary_files = {
-- --                 vim.fn.expand("~/github/dotfiles-latest/neovim/neobean/spell/en.utf-8.add"),
-- --                 vim.fn.expand("~/github/dotfiles-latest/neovim/neobean/spell/es.utf-8.add"),
-- --               },
-- --               -- --  NOTE: To disable the definitions uncomment this section below
-- --               --
-- --               -- separate_output = function(output)
-- --               --   local items = {}
-- --               --   for line in output:gmatch("[^\r\n]+") do
-- --               --     table.insert(items, {
-- --               --       label = line,
-- --               --       insert_text = line,
-- --               --       documentation = nil,
-- --               --     })
-- --               --   end
-- --               --   return items
-- --               -- end,
-- --             },
-- --           },
-- --           minuet = {
-- --             name = "minuet",
-- --             module = "minuet.blink",
-- --             score_offset = 100,
-- --           },
-- --
-- --           ["easy-dotnet"] = {
-- --             name = "easy-dotnet",
-- --             enabled = true,
-- --             module = "easy-dotnet.completion.blink",
-- --             score_offset = 10000,
-- --             async = true,
-- --           },
-- --
-- --           go_deep = {
-- --             name = "go_deep",
-- --             module = "blink.compat.source",
-- --             opts = {
-- --               -- See below for configuration options
-- --             },
-- --           },
-- --
-- --           treesitter = {
-- --             name = "treesitter",
-- --             module = "blink.compat.source",
-- --           },
-- --
-- --           lsp = { -- ROSLYN
-- --             transform_items = function(_, items)
-- --               for _, item in ipairs(items) do
-- --                 local cmp_item_kind = require("blink.cmp.types").CompletionItemKind
-- --
-- --                 if item.kind == cmp_item_kind.Property or item.kind == cmp_item_kind.Field then
-- --                   item.score_offset = item.score_offset + 1
-- --                 end
-- --
-- --                 -- print(vim.inspect(item))
-- --
-- --                 if item.kind == cmp_item_kind.Operator then
-- --                   item.score_offset = item.score_offset - 1
-- --                 end
-- --               end
-- --
-- --               return vim.tbl_filter(function(item)
-- --                 return item.kind ~= require("blink.cmp.types").CompletionItemKind.Text
-- --               end, items)
-- --             end,
-- --           },
-- --         },
-- --       },
-- --     },
-- --   },
-- -- }
-- --
-- -- -- -- NOTE: you can leave out the type annotations if you don't want to use them
-- -- --
-- -- -- ---@module "lazy"
-- -- -- ---@type LazySpec
-- -- -- return {
-- -- --   "saghen/blink.cmp",
-- -- --   dependencies = {
-- -- --     "mikavilpas/blink-ripgrep.nvim",
-- -- --     -- 👆🏻👆🏻 add the dependency here
-- -- --
-- -- --     -- optional dependency used for toggling features on/off
-- -- --     -- https://github.com/folke/snacks.nvim
-- -- --     "folke/snacks.nvim",
-- -- --   },
-- -- --   ---@module 'blink.cmp'
-- -- --   ---@type blink.cmp.Config
-- -- --   opts = {
-- -- --     sources = {
-- -- --       default = {
-- -- --         "buffer",
-- -- --         "ripgrep", -- 👈🏻 add "ripgrep" here
-- -- --       },
-- -- --       providers = {
-- -- --         -- 👇🏻👇🏻 add the ripgrep provider config below
-- -- --         ripgrep = {
-- -- --           module = "blink-ripgrep",
-- -- --           name = "Ripgrep",
-- -- --           -- the options below are optional, some default values are shown
-- -- --           ---@module "blink-ripgrep"
-- -- --           ---@type blink-ripgrep.Options
-- -- --           opts = {
-- -- --             -- For many options, see `rg --help` for an exact description of
-- -- --             -- the values that ripgrep expects.
-- -- --
-- -- --             -- the minimum length of the current word to start searching
-- -- --             -- (if the word is shorter than this, the search will not start)
-- -- --             prefix_min_len = 3,
-- -- --
-- -- --             -- The number of lines to show around each match in the preview
-- -- --             -- (documentation) window. For example, 5 means to show 5 lines
-- -- --             -- before, then the match, and another 5 lines after the match.
-- -- --             context_size = 5,
-- -- --
-- -- --             -- The maximum file size of a file that ripgrep should include in
-- -- --             -- its search. Useful when your project contains large files that
-- -- --             -- might cause performance issues.
-- -- --             -- Examples:
-- -- --             -- "1024" (bytes by default), "200K", "1M", "1G", which will
-- -- --             -- exclude files larger than that size.
-- -- --             max_filesize = "1M",
-- -- --
-- -- --             -- Specifies how to find the root of the project where the ripgrep
-- -- --             -- search will start from. Accepts the same options as the marker
-- -- --             -- given to `:h vim.fs.root()` which offers many possibilities for
-- -- --             -- configuration. If none can be found, defaults to Neovim's cwd.
-- -- --             --
-- -- --             -- Examples:
-- -- --             -- - ".git" (default)
-- -- --             -- - { ".git", "package.json", ".root" }
-- -- --             project_root_marker = ".git",
-- -- --
-- -- --             -- Enable fallback to neovim cwd if project_root_marker is not
-- -- --             -- found. Default: `true`, which means to use the cwd.
-- -- --             project_root_fallback = true,
-- -- --
-- -- --             -- The casing to use for the search in a format that ripgrep
-- -- --             -- accepts. Defaults to "--ignore-case". See `rg --help` for all the
-- -- --             -- available options ripgrep supports, but you can try
-- -- --             -- "--case-sensitive" or "--smart-case".
-- -- --             search_casing = "--ignore-case",
-- -- --
-- -- --             -- (advanced) Any additional options you want to give to ripgrep.
-- -- --             -- See `rg -h` for a list of all available options. Might be
-- -- --             -- helpful in adjusting performance in specific situations.
-- -- --             -- If you have an idea for a default, please open an issue!
-- -- --             --
-- -- --             -- Not everything will work (obviously).
-- -- --             additional_rg_options = {},
-- -- --
-- -- --             -- When a result is found for a file whose filetype does not have a
-- -- --             -- treesitter parser installed, fall back to regex based highlighting
-- -- --             -- that is bundled in Neovim.
-- -- --             fallback_to_regex_highlighting = true,
-- -- --
-- -- --             -- Absolute root paths where the rg command will not be executed.
-- -- --             -- Usually you want to exclude paths using gitignore files or
-- -- --             -- ripgrep specific ignore files, but this can be used to only
-- -- --             -- ignore the paths in blink-ripgrep.nvim, maintaining the ability
-- -- --             -- to use ripgrep for those paths on the command line. If you need
-- -- --             -- to find out where the searches are executed, enable `debug` and
-- -- --             -- look at `:messages`.
-- -- --             ignore_paths = {},
-- -- --
-- -- --             -- Any additional paths to search in, in addition to the project
-- -- --             -- root. This can be useful if you want to include dictionary files
-- -- --             -- (/usr/share/dict/words), framework documentation, or any other
-- -- --             -- reference material that is not available within the project
-- -- --             -- root.
-- -- --             additional_paths = {},
-- -- --
-- -- --             -- Keymaps to toggle features on/off. This can be used to alter
-- -- --             -- the behavior of the plugin without restarting Neovim. Nothing
-- -- --             -- is enabled by default. Requires folke/snacks.nvim.
-- -- --             toggles = {
-- -- --               -- The keymap to toggle the plugin on and off from blink
-- -- --               -- completion results. Example: "<leader>tg"
-- -- --               on_off = nil,
-- -- --             },
-- -- --
-- -- --             -- Features that are not yet stable and might change in the future.
-- -- --             -- You can enable these to try them out beforehand, but be aware
-- -- --             -- that they might change. Nothing is enabled by default.
-- -- --             future_features = {
-- -- --               backend = {
-- -- --                 -- The backend to use for searching. Defaults to "ripgrep".
-- -- --                 -- Available options:
-- -- --                 -- - "ripgrep", always use ripgrep
-- -- --                 -- - "gitgrep", always use git grep
-- -- --                 -- - "gitgrep-or-ripgrep", use git grep if possible, otherwise
-- -- --                 --   ripgrep
-- -- --                 use = "ripgrep",
-- -- --               },
-- -- --             },
-- -- --
-- -- --             -- Show debug information in `:messages` that can help in
-- -- --             -- diagnosing issues with the plugin.
-- -- --             debug = false,
-- -- --           },
-- -- --           -- (optional) customize how the results are displayed. Many options
-- -- --           -- are available - make sure your lua LSP is set up so you get
-- -- --           -- autocompletion help
-- -- --           transform_items = function(_, items)
-- -- --             for _, item in ipairs(items) do
-- -- --               -- example: append a description to easily distinguish rg results
-- -- --               item.labelDetails = {
-- -- --                 description = "(rg)",
-- -- --               }
-- -- --             end
-- -- --             return items
-- -- --           end,
-- -- --         },
-- -- --       },
-- -- --       keymap = {
-- -- --         -- 👇🏻👇🏻 (optional) add a keymap to invoke the search manually
-- -- --         ["<c-g>"] = {
-- -- --           function()
-- -- --             -- invoke manually, requires blink >v0.8.0
-- -- --             require("blink-cmp").show({ providers = { "ripgrep" } })
-- -- --           end,
-- -- --         },
-- -- --       },
-- -- --     },
-- -- --   },
-- -- -- }
