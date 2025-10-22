return {
  {
    "aznhe21/actions-preview.nvim",
    config = function()
      local hl = require("actions-preview.highlight")
      require("actions-preview").setup({
        -- options for vim.diff(): https://neovim.io/doc/user/lua.html#vim.diff()
        diff = {
          ctxlen = 3,
        },

        -- priority list of external command to highlight diff
        -- disabled by defalt, must be set by yourself
        highlight_command = {
          require("actions-preview.highlight").delta("delta"),
          -- require("actions-preview.highlight").diff_so_fancy(),
          -- require("actions-preview.highlight").diff_highlight(),
        },

        -- priority list of preferred backend
        backend = { "snacks", "telescope", "nui" },
        --- options for snacks picker
        ---@type snacks.picker.Config
        ---
        snacks = {
          layout = {
            layout = {
              box = "vertical",
              {
                height = 0.2,
                box = "vertical",
                { win = "list", title = " Results ", title_pos = "center", border = "rounded" },
                {
                  win = "input",
                  height = 1,
                  border = "rounded",
                  title = "{title} {live} {flags}",
                  title_pos = "center",
                },
              },
              {
                win = "preview",
                title = "{preview:Preview}",
                height = 0.8,
                width = 0,
                border = "rounded",
                title_pos = "center",
              },
            },
            fullscreen = true,
          },
        },
        -- options related to telescope.nvim
        -- telescope = {
        --   sorting_strategy = "ascending",
        --   layout_strategy = "horizontal",
        --   layout_config = {
        --     width = 0.5,
        --     height = 0.6,
        --     prompt_position = "top",
        --     preview_cutoff = 20,
        --     preview_height = function(_, _, max_lines)
        --       return max_lines - 15
        --     end,
        --   },
        -- },
        -- telescope = vim.tbl_extend(
        --   "force",
        --   -- telescope theme: https://github.com/nvim-telescope/telescope.nvim#themes
        --   require("telescope.themes").get_dropdown(),
        --   -- a table for customizing content
        --   {
        --     -- a function to make a table containing the values to be displayed.
        --     -- fun(action: Action): { title: string, client_name: string|nil }
        --     make_value = nil,
        --
        --     -- a function to make a function to be used in `display` of a entry.
        --     -- see also `:h telescope.make_entry` and `:h telescope.pickers.entry_display`.
        --     -- fun(values: { index: integer, action: Action, title: string, client_name: string }[]): function
        --     make_make_display = nil,
        --   }
        -- ),

        -- options for nui.nvim components
        nui = {
          -- component direction. "col" or "row"
          dir = "col",
          -- keymap for selection component: https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/menu#keymap
          keymap = nil,
          -- options for nui Layout component: https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/layout
          layout = {
            position = "50%",
            size = {
              width = "60%",
              height = "90%",
            },
            min_width = 40,
            min_height = 10,
            relative = "editor",
          },
          -- options for preview area: https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/popup
          preview = {
            size = "60%",
            border = {
              style = "rounded",
              padding = { 0, 1 },
            },
          },
          -- options for selection area: https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/menu
          select = {
            size = "40%",
            border = {
              style = "rounded",
              padding = { 0, 1 },
            },
          },
        },

        highlight_command = {
          -- Highlight diff using delta: https://github.com/dandavison/delta
          -- The argument is optional, in which case "delta" is assumed to be
          -- specified.
          -- hl.delta("path/to/delta --option1 --option2"),
          -- You may need to specify "--no-gitconfig" since it is dependent on
          -- the gitconfig of the project by default.
          hl.delta("delta --side-by-side"),

          -- Highlight diff using diff-so-fancy: https://github.com/so-fancy/diff-so-fancy
          -- The arguments are optional, in which case ("diff-so-fancy", "less -R")
          -- is assumed to be specified. The existence of less is optional.
          hl.diff_so_fancy("path/to/diff-so-fancy --option1 --option2"),

          -- Highlight diff using diff-highlight included in git-contrib.
          -- The arguments are optional; the first argument is assumed to be
          -- "diff-highlight" and the second argument is assumed to be
          -- `{ colordiff = "colordiff", pager = "less -R" }`. The existence of
          -- colordiff and less is optional.
          hl.diff_highlight("path/to/diff-highlight", { colordiff = "path/to/colordiff" }),

          -- And, you can use any command to highlight diff.
          -- Define the pipeline by `hl.commands`.
          hl.commands({
            { cmd = "command-to-diff-highlight" },
            -- `optional` can be used to define that the command is optional.
            { cmd = "less -R", optional = true },
          }),
          -- If you use optional `less -R` (or similar command), you can also use `hl.with_pager`.
          hl.with_pager("command-to-diff-highlight"),
          -- hl.with_pager("command-to-diff-highlight", "custom-pager"),

          -- Functions can also be specified for items. Functions are executed during setup.
          -- This is useful for `require(...)` at definition time, such as in lazy.nvim.
          function()
            return require("actions-preview.highlight").delta()
          end,
        },
      })
    end,
  },
}
