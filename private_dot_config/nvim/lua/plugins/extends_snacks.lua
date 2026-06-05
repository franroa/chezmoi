-- https://github.com/SwayKh/dotfiles/blob/main/nvim/lua/plugins/snacks.lua
-- https://linkarzu.com/posts/neovim/snacks-picker/
--#region

return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    config = function(_, opts)
      require("snacks").setup(opts)
    end,
    keys = {

      {
        "<leader>j",
        function()
          require("toolbox").show_toolbox()
        end,
        desc = "@ms Toolbox",
      },
      {
        "<leader>J",
        function()
          require("snacks").zen.zen()
        end,
        desc = "@ms Toolbox",
      },
      {
        "ö",
        function()
          require("snacks").words.jump(1, true)
        end,
        desc = "󰉚 Next reference",
      },
      -- {
      --   "<leader>e",
      --   function()
      --     require("snacks").explorer.open()
      --   end,
      --   desc = "󰉚 Next reference",
      -- },
      {
        "Ö",
        function()
          require("snacks").words.jump(-1, true)
        end,
        desc = "󰉚 Prev reference",
      },
      {
        "<leader>g?",
        function()
          require("snacks").git.blame_line()
        end,
        desc = " Blame line",
      },
      {
        "<D-9>",
        function()
          openNotif("last")
        end,
        mode = { "n", "v", "i" },
        desc = "󰎟 Last notification",
      },
      {
        "<leader>om",
        function()
          local enabled = require("snacks").dim.enabled
          require("snacks").dim[enabled and "disable" or "enable"]()
        end,
        desc = "󰝟 Mute code",
      },
      -- {
      --   "<leader>olt",
      --   require("functions.snacks_pickers").find_cmake_targets,
      --   desc = "Tasks in Taskfile",
      -- },
    },
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      dim = {
        scope = { min_size = 5, max_size = 20 },
      },

      scroll = {
        enabled = true,
        animate = {
          duration = { step = 10, total = 150 },
          easing = "linear",
        },
        spamming = 10, -- threshold for spamming detection
      },
      zen = {
        toggles = {
          dim = false,
          git_signs = true,
          mini_diff_signs = false,
        },
        show = { statusline = false, tabline = false },
        win = { backdrop = { transparent = false, blend = 10 } },
      },

      notify = {
        enabled = true,
      },

      terminal = {
        enabled = true,
        win = {
          style = "terminal",
          border = vim.g.border_style,
          -- position = "float",
          position = "bottom",
          height = 0.8,
          width = 0.8,
        },
      },

      explorer = {
        enabled = false,
        hidden = true,
        auto_close = false,
        win = {
          list = {
            keys = {
              ["-"] = "edit_split",
              ["|"] = "edit_vsplit",
              ["<CR>"] = "confirm",
              ["o"] = "confirm",
              ["O"] = { { "pick_win", "jump" }, mode = { "n", "i" } },
              ["<BS>"] = "explorer_up",
              ["a"] = "explorer_add",
              ["d"] = "explorer_del",
              ["r"] = "explorer_rename",
              ["c"] = "explorer_copy",
              ["p"] = "explorer_paste",
              ["u"] = "explorer_update",
              ["<C-t>"] = "terminal",
              ["x"] = "explorer_move",
              ["y"] = "explorer_yank",
              ["<c-c>"] = "explorer_cd",
              ["."] = "explorer_focus",
              ["I"] = "toggle_ignored",
              ["H"] = "toggle_hidden",
              ["Z"] = "explorer_close_all",
            },
          },
        },
      },
      picker = {
        sources = {
          lsp_workspace_symbols = {
            -- Custom icons for Alloy components
            icons = {
              symbols = {
                Class = "󰌗", -- Components
                Function = "󰊕", -- Functions
                Variable = "󰀫", -- Variables
                Property = "󰜢", -- Properties
                Field = "󰜢", -- Fields
                Method = "󰆧", -- Methods
                Object = "󰅩", -- Objects
                File = "󰈙", -- Files
                Module = "󰆧", -- Modules
              },
            },
            -- Enhanced fuzzy matching
            matcher = {
              fuzzy = true,
              smartcase = true,
              ignorecase = true,
              -- Boost scores for Alloy-specific patterns
              boost = {
                ["prometheus"] = 2,
                ["loki"] = 2,
                ["otelcol"] = 2,
                ["scrape"] = 1.5,
                ["receiver"] = 1.5,
                ["exporter"] = 1.5,
              },
            },
            -- Better layout for symbols
            layout = {
              preset = "vscode",
              preview = true,
              -- Show file path in preview
              preview_title = true,
            },
          },
          projects = {
            confirm = function(picker, item)
              picker:close()
              if item and item.file then
                local tabpages = vim.api.nvim_list_tabpages()
                for _, tabpage in ipairs(tabpages) do
                  local tab_cwd = vim.fn.getcwd(-1, tabpage)
                  if tab_cwd == item.file then
                    -- Change to the tab
                    vim.api.nvim_set_current_tabpage(tabpage)
                    return
                  end
                end

                for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                  if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_get_name(bufnr) ~= "" then
                    vim.cmd("tabnew")
                    break
                  end
                end
              end
              -- Change cwd to the selected project, only for this tab
              vim.cmd("tcd " .. vim.fn.fnameescape(item.file))
              Snacks.picker.smart()
            end,
          },
          explorer = {
            layout = { layout = { position = "right" } },
            jump = { close = false },
            supports_live = false,
          },
        },
      },
      animate = {
        enabled = true,
        duration = 20, -- ms per step
        easing = "linear",
        fps = 60, -- frames per second. Global setting for all animations
      },
      -- indent = {
      --   enabled = true,
      --   only_scope = true,
      --   only_current = true,
      --   indent = {
      --     hl = {
      --       -- "SnacksIndent1",
      --       -- "SnacksIndent2",
      --       -- "SnacksIndent3",
      --       -- "SnacksIndent4",
      --       -- "SnacksIndent5",
      --       -- "SnacksIndent6",
      --       -- "SnacksIndent7",
      --       -- "SnacksIndent8",
      --       "Comment",
      --     },
      --   },
      --   scope = {
      --     enabled = false,
      --     underline = true,
      --   },
      -- },
      indent = {
        char = "│",
        scope = { hl = "Comment" },
        chunk = {
          enabled = false,
          hl = "Comment",
        },
      },
      words = {
        notify_jump = true,
        modes = { "n" },
        debounce = 300,
      },
      win = {
        border = vim.g.borderStyle,
        keys = { q = "close", ["<Esc>"] = "close" },
      },
      notifier = {
        timeout = 7500,
        sort = { "added" }, -- sort only by time
        width = { min = 12, max = 0.5 },
        height = { min = 1, max = 0.5 },
        icons = { error = "󰅚", warn = "", info = "󰋽", debug = "󰃤", trace = "󰓗" },
        top_down = false,
      },
      input = {
        icon = "",
      },
      styles = {
        input = {
          backdrop = true,
          border = vim.g.borderStyle,
          title_pos = "left",
          width = 50,
          row = math.ceil(vim.o.lines / 2) - 3,
          keys = {
            i_esc = { "<Esc>", { "cmp_close", "stopinsert" }, mode = "i" },
            BS = { "<BS>", "<Nop>", mode = "n" }, -- prevent accidental closing (<BS> -> :bprev)
            CR = { "<CR>", "confirm", mode = "n" },
          },
        },
        notification = {
          border = vim.g.borderStyle,
          wo = { winblend = 0, wrap = true },
        },
        blame_line = {
          width = 0.6,
          height = 0.6,
          border = vim.g.borderStyle,
          title = " 󰉚 Git blame ",
        },
      },
      bigfile = { enabled = true },
      -- notifier = { enabled = true },
      quickfile = { enabled = true },
      toggle = { enabled = true },
      -- words = { enabled = true },
      dashboard = {

        config = function(opts, defaults)
          --           opts.preset.header = [[
          -- ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
          -- ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
          -- ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
          -- ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
          -- ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
          -- ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]]
          --
          --           opts.preset.header = {
          --             "                                                                                                                                                            ",
          --             "                                                                                                                                                            ",
          --             "                                                                     #                          *(                                                          ",
          --             "                                                                    &(                          (&                                                          ",
          --             "                                                                   &&                            &&                                                         ",
          --             "                                                                  &&                             &&(                                                        ",
          --             "                                                                 @&                              %&&                                                        ",
          --             "                                                               .&&,                              &&&               &                                        ",
          --             "                             #%                               &@&&&&&&&&&&&&&&&&#        ,/###&@&&&&&           #&/                                         ",
          --             "                                 &&,                      /&&&&&&@&@&&%#%&&&@&@@@%. /&&&&&@&&&&&@&&&&&&&/    #&&#                ,                          ",
          --             "                                  ,&&%                 /&&&&&#.               %&&&&&&&#. (&#,       #&&&&&&&&&                  //                          ",
          --             "                                    &@&@.            &&&&&             .(&&&&&@#         *&&&&&&&       *%&&&&&&               ,&                           ",
          --             "                                      &@@&&&&&&&&% &&&& #&&&&&&&@&&&&&&@&#*.                  &@&&&, *,.     ,&&&&*            &&                           ",
          --             "                                      %&&&@&&&&# &&&%      .##(/,  ,%&&&&&&&&&&&&&&&&&&&&&&&&&@,.&&&&& (&&&&&&&&&&%/          &&&                           ",
          --             "                    */             .&&&&,      &&&&    /&&&&&&&&&#               .,/#&&@&&&&#.     *&&&&#     ,(%&&&&&&&&&.  (&&(                           ",
          --             "                        ,@&&&*   &&&&&       .&&&  (&&&&&&&&%                          #&&&          ,&&&&&/       @&* (@&&&&&&&/                           ",
          --             "                             *.&&&@&        ./&&&&&&&&&&&&%                              ,&*           #&&&&&&#     &&&%  .&&&&&&,                          ",
          --             "                             &&&&&,#&&&&&&&&&&&(      ,&&&,                  (&            &&             #&&&&&&&  ,&&&&&. ./(###        ,(                ",
          --             "                            %&&&&,&&&&&&%. (*           &&#                  (&              &            .&&&&&&&&@//&&&&&&&&&&&&&#,.                      ",
          --             "                           .&&&& &&&   #&&&              &&            (&&&&&&&&&&&&&         ,          *&&#     .&& &&&&&.   &&&&/                        ",
          --             "                        #&.&&&&//    /&&&.                %(                 (&                         #&#          . &&&(    ,&&&&                        ",
          --             "                     &&&&& &&&&    *&&&%                   *       &#        (&         *&             #%              &&&& &&  &&&&.                       ",
          --             "                   &&&&&&& &&&&  ,&&&&/                            %&        (&         %&            *.               &&&&%,&&&(.&@(                       ",
          --             "                  /&&&&&,  &&&./&&&&@.                        &&&&&&@/*.     (&   *&&&&&&&&&&&&                        .&&&&* &&&&@ /                       ",
          --             "                  &&&&(    * &&&&&@*                               .&        (&         &,                               &&&&   /&@@&.                      ",
          --             "                 *&&&.    /&&&&&                                    &/       (&        ,&                                 &&&#  (#.&&&&                     ",
          --             "               , @&&&    &@&&*,                                     &#       (&        (&                                  &&&& #&&,(&&&*                   ",
          --             "             %&&&&&&&   &&@%.&&                                     #&       (&        &%                                ,%&&&& &&&   @&&(    *#&#.         ",
          --             "                 &&&&  @&&* &&&&&%*..,(&&&&%#/*                     ,&       (&        &/                         .(@&&&&&&&&&@ &&&..* &&&#,                ",
          --             "                 /&&& &&&/  &&&&&&&%*                                &. #&&&&&&&&&&&&&%&.                                    & &&&&&&&,(&&&/                ",
          --             "                  &&&%.&,  &&&&                                    ,&&&&&&&&&&&&&&&&&&&&&&&@#                                 &&&&*    .&&&&,               ",
          --             "                  ,&&&(    &&&&                                 %&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&.                          ,&&@& @    .&&&&&(              ",
          --             "                  #,&&&%   &&&&&&&*                          &&&&&&&&&&&&&&&&&@&&&&&&&&&&&&&&&&&&&&@&                      %&&&& @@&,  (&&&&&&&&&.          ",
          --             "                *&@& &&&@, ,&&&.     .                   #@&&&&&&&&&&&&&&&&&&&&&&%%&&&%%&&&%&&&&&&&&&&&&#                 ,&&&&  (&&&# &&#        ,%&(      ",
          --             "              .&&&&.   &&&& &&                     ,&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&(&&&&(&@&&(&&&%&&&%&&&&&#,.         *&&&,   .&&&#%%              /&#  ",
          --             "            #&&&&&&,    ,&& &&.            ,  &&&&&&&&&&&&&@@&&&&&&&&&&&&&&&@&&&&%@&&&#@&&&*&&&&/&&@&*@&&(&&&#&&&&&&&     /&&(     (&&&                     ",
          --             "         (&&&&&(&&&&      .(&&..       &%   &  .*/      .&&&&*      #&&&&&&&&/   .&&&%#&&&%#&&&%/&&&%*&&&#/&@&/&&%(&&&&, ,&&&       &&&*                    ",
          --             "       %&&&.     &&&&      &&#/&&   &&/   (&.   &&&&&&&&&&&&&&&&,        %&&# .&&#   .&&&&#%&&&##&&&#*&&&#*&@&((&&&*&@& %&&&&     ,&,@&&.                   ",
          --             "     *&(          &&&&    &&& &&&@ %&/  %&&  (    /&@&&        ,&% (  / *%&&@     .#             &&&(#&&&/*&@&(*@&&*( &&&@&&&*  .&&& &&&&/                  ",
          --             "    &              &&&&,  &&&  %&&&*  /&&,/   &/   &&&*/(#%&&.     ,&%   .&&&&*     ,&&&&&&&      ##.%&&&*#&&&,/@&& &&&...&&&**&&&&,  &&&&                  ",
          --             "  ,                 &&&&% &&&   *&&&&@&&    .&&&* ,/&&####((/ *&%      #      @&%/,     ,%&&&&&&(      /%,&@&&.%&%*&**&%..& %&@&&&@&&&*                     ",
          --             "                     &&&&&(.&    .&&&&&,(&&&&&&/&%.*&&&&&&&@&&&.  *&/      #/%&%%%.          .(&&&&&#    .* *#.&/#  &&&# ,&&&&&&/,.                         ",
          --             "                      .&&&&@&.    *&&&&,&&&&&&&&&&&&&&&&&&&&&&&&* #/  #&/%  ,#&&&&&&&&.     *      .&(. &.  (#   &*,&(.&&&&&#*&     (&&&*                   ",
          --             "                          %&&&@&(  %&&&#(&&&&&&@&&@&&(.     /&&&@&# #(#&&&&&@%      /&&&&&&#           &&&&@&&#.   .@&&&&&(*&&&.  *&&@&                     ",
          --             "                          @&.,&&&&& &&&& &&&&&&&@&%(*,*%&(. ,#%/  ./%@&&&&&&&&&&&@&&%,     .(&&(%      &&&&&%    ,*&&&&&(  %&&&*#&&&&                       ",
          --             "                          &&&@  (&&& @&&#*@&&&&&&&&&&&&&&&#(#&#* &&&&&(. (&(.(*&&@@/  (&&&%,    *& @&&&&&%&#  .&& &&&&#    %&&&*#&&&&#                      ",
          --             "                            *@@&&@@&& &&&,%& /@&&&&&&&&&&&&&&@  @&&&&&@& . (%(  .&%&&&#   *#(    #@ &&&&&&&&&&& *&&&&    / &&&@     @&&&                    ",
          --             "                       *&&&&&( .       &&& &&&&&* #&&&&&&@/ %%.&@&@( #&.(&&&&&&&&&&&(  .  .       %&/   *&&&&&.%&&& .%&&& &&&&         %&%                  ",
          --           }

          opts.preset.header = [[


                              .:+*+.                      
                            .==+*+*+                      
                            .==+*+*+                      
                            .==****+                      
                            .==****+                      
                            .==****+                      
                            .==##*#+                      
                            .==##**+              .-=:-*-.
                            :==##**+       ..-+---=====*#*
                            :==##**+...:-:-=====++##******
                            :==#***=::-=::-*###*++*##****+
                           .:+====+=::=-:-=+++*****######+
                     .:+#=*++++++*+-:-=::-*#########=..   
                  .-=-:=%=+****+**+:-==::=@%%*:.          
            .:=+++++++::=#-+######==+=---*#+*-            
         .+++++*+*****=::-*=+*+*--=++=-=***++-            
         .*******##%##+=::.....::=**+-=**+*++:            
         .*######***+:=*+-:...:=*#+==..+*+*+=:            
         .****+-.     .+#**+*##*--=+  .+*++==:            
                       .----::--+**+  .+*++==.            
                       .=+++-++****+   =*+===.            
                       .-=+=-++****+  .+*===-.            
                       .-=+==++****+  .**===-.            
                       .-==-=++*+**+    :--:.             
                       .-==-=++*+**+                      
                            =++*+***                      
                            =++*+***                      
                           .=++=+***                      
          :.               .=++=+***                      
         .=:               .+++++***      .=.             
        .--.        ...=-.-:+++*+***      .--:            
        .:=-:--   +*===+*++#*++++***.     :-=:            
        .-=-.:*=.+++*+:.   .++==+***.     ---:            
        ..-=:.-*:-==:-.    .+++++***    .--:.             
         .==:*+++++=:=.    .+++=+***:    .-==:  ..  .+:   
         .---=+**=+=+-.    .+++=+++==.  .==-.  :-.:*+:    
        .::=-=*+.-:=++..   .++=+=*+=-:..+=-=-- .:+.       
        .::-.:-==-+*--:::.:.=++++***====-====:=:==-.      
        ...==:--:.:::-+-:.:-:==+*+=======-==:=--:-:.      
          ]]

          -- local chezmoi_entry = {
          --   icon = " ",
          --   key = "c",
          --   desc = "Config",
          --   action = Snacks.picker.chez,
          -- }

          opts.sections = {
            {
              section = "terminal",
              cmd = "colorscript -e square",
              height = 5,
              padding = 1,
            },
            { section = "keys", gap = 1, padding = 1 },
            { pane = 1, icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
            { pane = 1, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
            {
              pane = 1,
              icon = " ",
              title = "Git Status",
              section = "terminal",
              enabled = function()
                return Snacks.git.get_root() ~= nil
              end,
              cmd = "git status --short --branch --renames",
              height = 5,
              padding = 1,
              ttl = 5 * 60,
              indent = 3,
            },
            { section = "startup" },
            {
              section = "header",
              pane = 2,
              align = "center",
              key = "h",
            },
          }
        end,
      },
    },
  },
}
