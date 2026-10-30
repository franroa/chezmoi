local Layout = require("nui.layout")
local Popup = require("nui.popup")

local TSLayout = require("telescope.pickers.layout")
local transform_mod = require("telescope.actions.mt").transform_mod
local nvb_actions = transform_mod({
  -- VisiData
  visidata = function(prompt_bufnr)
    -- Get the full path
    local content = require("telescope.actions.state").get_selected_entry()
    local full_path = content.cwd .. require("plenary.path").path.sep .. content.value

    -- Close the Telescope window
    require("telescope.actions").close(prompt_bufnr)

    -- Open the file with VisiData
    OpenOrCreateTerminal({ instruction = "vd", name = "visidata" })
  end,
})
local trouble = require("trouble.sources.telescope")
return {
  {
    "nvim-telescope/telescope.nvim",
    keys = {
     -- add a keymap to browse plugin files
      -- stylua: ignore
      {
        "<leader>fP",
        function() require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root }) end,
        desc = "Find Plugin File",
      },
    },
    -- change some options
    opts = {
      extensions = {
        file_browser = {
          mappings = {
            ["i"] = {
              ["<C-t>"] = require("telescope.actions").select_tab,
            },
          },
        },
        ast_grep = {
          command = {
            "sg",
            "--json=stream",
          }, -- must have --json=stream
          grep_open_files = false, -- search in opened files
          lang = nil, -- string value, specify language for ast-grep `nil` for default
        },
      },
      pickers = {
        find_files = {
          theme = "ivy",
          mappings = {
            n = {
              ["s"] = nvb_actions.visidata,
            },
            i = {
              ["<C-s>"] = nvb_actions.visidata,
            },
          },
        },
        git_files = {
          theme = "dropdown",
          mappings = {
            n = {
              ["s"] = nvb_actions.visidata,
            },
            i = {
              ["<C-s>"] = nvb_actions.visidata,
            },
          },
        },
      },
      defaults = {
        mappings = {
          i = { ["<c-t>"] = trouble.open },
          n = { ["<c-t>"] = trouble.open },
        },
        create_layout = function(picker)
          local border = {
            results = {
              top_left = "┌",
              top = "─",
              top_right = "┬",
              right = "│",
              bottom_right = "",
              bottom = "",
              bottom_left = "",
              left = "│",
            },
            results_patch = {
              minimal = {
                top_left = "┌",
                top_right = "┐",
              },
              horizontal = {
                top_left = "┌",
                top_right = "┬",
              },
              vertical = {
                top_left = "├",
                top_right = "┤",
              },
            },
            prompt = {
              top_left = "├",
              top = "─",
              top_right = "┤",
              right = "│",
              bottom_right = "┘",
              bottom = "─",
              bottom_left = "└",
              left = "│",
            },
            prompt_patch = {
              minimal = {
                bottom_right = "┘",
              },
              horizontal = {
                bottom_right = "┴",
              },
              vertical = {
                bottom_right = "┘",
              },
            },
            preview = {
              top_left = "┌",
              top = "─",
              top_right = "┐",
              right = "│",
              bottom_right = "┘",
              bottom = "─",
              bottom_left = "└",
              left = "│",
            },
            preview_patch = {
              minimal = {},
              horizontal = {
                bottom = "─",
                bottom_left = "",
                bottom_right = "┘",
                left = "",
                top_left = "",
              },
              vertical = {
                bottom = "",
                bottom_left = "",
                bottom_right = "",
                left = "│",
                top_left = "┌",
              },
            },
          }

          local results = Popup({
            focusable = false,
            border = {
              style = border.results,
              text = {
                top = picker.results_title,
                top_align = "center",
              },
            },
            win_options = {
              winhighlight = "Normal:Normal",
            },
          })

          local prompt = Popup({
            enter = true,
            border = {
              style = border.prompt,
              text = {
                top = picker.prompt_title,
                top_align = "center",
              },
            },
            win_options = {
              winhighlight = "Normal:Normal",
            },
          })

          local preview = Popup({
            focusable = false,
            border = {
              style = border.preview,
              text = {
                top = picker.preview_title,
                top_align = "center",
              },
            },
          })

          local box_by_kind = {

            vertical = Layout.Box({
              Layout.Box(preview, { grow = 1 }),
              Layout.Box(results, { grow = 1 }),
              Layout.Box(prompt, { size = 3 }),
            }, { dir = "col" }),
            horizontal = Layout.Box({
              Layout.Box({
                Layout.Box(results, { grow = 1 }),
                Layout.Box(prompt, { size = 3 }),
              }, { dir = "col", size = "50%" }),
              Layout.Box(preview, { size = "50%" }),
            }, { dir = "row" }),
            minimal = Layout.Box({
              Layout.Box(results, { grow = 1 }),
              Layout.Box(prompt, { size = 3 }),
            }, { dir = "col" }),
          }

          local function get_box()
            local height, width = vim.o.lines, vim.o.columns
            local box_kind = "horizontal"

            if width < 100 then
              box_kind = "vertical"
              if height < 40 then
                box_kind = "minimal"
              end
            elseif width < 120 then
              box_kind = "minimal"
            end
            return box_by_kind[box_kind], box_kind
          end

          local function prepare_layout_parts(layout, box_type)
            layout.results = TSLayout.Window(results)
            results.border:set_style(border.results_patch[box_type])

            layout.prompt = TSLayout.Window(prompt)
            prompt.border:set_style(border.prompt_patch[box_type])

            if box_type == "minimal" then
              layout.preview = nil
            else
              layout.preview = TSLayout.Window(preview)
              preview.border:set_style(border.preview_patch[box_type])
            end
          end

          local box, box_kind = get_box()
          local layout = Layout({
            relative = "editor",
            position = "50%",
            size = {
              height = "60%",
              width = "90%",
            },
          }, box)

          layout.picker = picker
          prepare_layout_parts(layout, box_kind)

          local layout_update = layout.update
          function layout:update()
            local box, box_kind = get_box()
            prepare_layout_parts(layout, box_kind)
            layout_update(self, box)
          end

          return TSLayout(layout)
        end,
        -- layout_strategy = "horizontal",
        -- layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
      },
    },
  },

  -- -- add telescope-fzf-native
  -- {
  --   "telescope.nvim",
  --   dependencies = {
  --     "nvim-telescope/telescope-fzf-native.nvim",
  --     build = "make",
  --     config = function()
  --       require("telescope").load_extension("fzf")
  --     end,
  --   },
  -- },

  -- add pyright to lspconfig
  --

  {
    "telescope.nvim",
    dependencies = {
      "catgoose/telescope-helpgrep.nvim",
      config = function()
        require("telescope").load_extension("helpgrep")
      end,
    },
  },
  {
    "telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope-live-grep-args.nvim",
      config = function()
        require("telescope").load_extension("live_grep_args")
      end,
    },
  },
  -- { -- TODO: copare with arena.nvim and mini.visits
  --   "telescope.nvim",
  --   dependencies = {
  --     "nvim-telescope/telescope-frecency.nvim",
  --     config = function()
  --       require("telescope").load_extension("frecency")
  --     end,
  --   },
  -- },
  { -- TODO: compare with other plugins like projects, https://github.com/coffebar/neovim-project, https://github.com/GnikDroy/projections.nvim
    "telescope.nvim",
    dependencies = {
      "jvgrootveld/telescope-zoxide",
      config = function()
        require("telescope").load_extension("zoxide")
      end,
    },
  },
  {
    "telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope-dap.nvim",
      config = function()
        require("telescope").load_extension("dap")
      end,
    },
  },
  {
    "telescope.nvim",
    dependencies = {
      { "polirritmico/telescope-lazy-plugins.nvim" },
    },
    opts = {
      name_only = true, -- Match only the `repo_name`, false to match the full `account/repo_name`
      show_disabled = true, -- Also show disabled plugins from the Lazy spec.
      lazy_config = vim.fn.stdpath("config") .. "/lua/config/lazy.lua", -- Optional. Path to the lua file containing the lazy `setup()` call. So e.g. you could search `lazy` and open your `lazy.lua` file.
    },
    keys = {
      { "<leader>cp", "<Cmd>Telescope lazy_plugins<CR>", desc = "Telescope: Plugins configurations" },
    },
    -- etc.
  },

  {
    "telescope.nvim",
    dependencies = {
      "ecthelionvi/NeoComposer.nvim",
      config = function()
        require("telescope").load_extension("macros")
      end,
    },
  },
  {
    "telescope.nvim",
    event = "TermOpen",
    dependencies = {
      "tknightz/telescope-termfinder.nvim",
      config = function()
        require("telescope").load_extension("termfinder")
      end,
    },
  },
  { -- TODO:
    "dharmx/telescope-media.nvim",
    config = function()
      require("telescope").load_extension("media")
    end,
  },
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
  },
  {
    "telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope-media-files.nvim",
      -- opts = {
      --   media_files = {
      --     -- filetypes whitelist
      --     -- defaults to {"png", "jpg", "mp4", "webm", "pdf"}
      --     filetypes = { "png", "webp", "jpg", "jpeg" },
      --     -- find command (defaults to `fd`)
      --     find_cmd = "rg",
      --   },
      -- },
      config = function()
        require("telescope").load_extension("media_files")
      end,
    },
  },
}
