-- https://github.com/SwayKh/dotfiles/blob/main/nvim/lua/plugins/snacks.lua
-- https://linkarzu.com/posts/neovim/snacks-picker/
--#region

vim.keymap.set("n", "<leader>ap", function()
  local filename = vim.fn.expand("%:t")
  if filename == "inventory.yaml" then
    require("functions.snacks_pickers").pick_playbook_with_current_host()
  else
    require("functions.snacks_pickers").pick_server()
  end
end)
vim.keymap.set("n", "<leader>aP", function()
  require("functions.snacks_pickers").pick_server()
end)
vim.keymap.set("n", "<leader>aVd", function()
  require("functions.ansible").decrypt_value_with_vault()
end)
vim.keymap.set("n", "<leader>aVe", function()
  require("functions.ansible").encrypt_value_with_vault()
end)
--
vim.keymap.set("n", "<leader>Ff", function()
  require("snacks").picker.lsp_workspace_symbols({
    live = true,
    title = "Fuzzy Search",
  })
end, { desc = "Live fuzzy search" })

-- Dynamic keymaps for Taskfile targets
local function create_taskfile_keymaps()
  -- Get the current working directory for task command
  local cwd = LazyVim and LazyVim.root.git() or vim.fn.getcwd()

  -- Execute task --list-all to get available targets with descriptions
  local handle = io.popen("cd " .. vim.fn.shellescape(cwd) .. " && task --list-all 2>/dev/null")
  if not handle then
    return
  end

  local result = handle:read("*a")
  handle:close()

  if not result or result == "" then
    return
  end

  -- Parse the task output to extract target names and descriptions
  local targets = {}
  for line in result:gmatch("[^\n]+") do
    if line:sub(1, 1) == "*" then
      local full_line = line:sub(2):gsub("^%s+", "") -- remove leading * and whitespace
      local target, description = full_line:match("^([^:]+):?%s*(.*)")

      if target and target ~= "" then
        target = target:gsub("%s+$", "") -- trim trailing whitespace from target
        description = description and description:gsub("^%s+", ""):gsub("%s+$", "") or "" -- trim description

        -- If no description, use a default one
        if description == "" then
          description = "Run " .. target .. " task"
        end

        table.insert(targets, {
          name = target,
          description = description,
        })
      end
    end
  end

  -- Create keymaps using the first letter of each task name
  local keymap_base = "<leader>ol"
  local used_keys = {} -- Track used keys to avoid conflicts

  for _, target_info in ipairs(targets) do
    local task_name = target_info.name
    local first_char = task_name:sub(1, 1):lower()

    -- Skip if this key is already used
    if not used_keys[first_char] then
      used_keys[first_char] = true

      local key = keymap_base .. first_char
      local desc = "󰚌 " .. target_info.name .. ": " .. target_info.description

      vim.keymap.set("n", key, function()
        require("overseer").run_template({
          name = "Taskfile Task",
          params = {
            region = vim.env.TSYL_REGION,
            tier = vim.env.TSYL_TIER,
            domain = vim.env.TSYL_DOMAIN,
            module = vim.env.TSYL_MODULE,
            action = target_info.name,
          },
        }, function(task)
          if task then
            require("overseer").run_action(task, "open float")
          end
        end)
      end, { desc = desc })
    end

    -- Create a keymap with the uppercase letter
    local first_char_upper = task_name:sub(1, 1):upper() -- Get the uppercase version
    if not used_keys[first_char_upper] then
      used_keys[first_char_upper] = true

      local key_upper = keymap_base .. first_char_upper
      local desc_upper = "󰚌 " .. target_info.name .. ": " .. target_info.description

      vim.keymap.set("n", key_upper, function()
        require("functions.terraform").apply_action(target_info.name, true)
        -- require("overseer").run_template({
        --   name = "Taskfile Task",
        --   params = {
        --     region = vim.env.REGION_ENV_VAR,
        --     tier = vim.env.TIER_ENV_VAR,
        --     domain = vim.env.DOMAIN_ENV_VAR,
        --     action = target_info.name,
        --   },
        -- }, function(task)
        --   if task then
        --     require("overseer").run_action(task, "open float")
        --   end
        -- end)
      end, { desc = desc_upper })
    end
  end
end

return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    config = function(_, opts)
      require("snacks").setup(opts)
      -- Create dynamic taskfile keymaps after plugin loads
      vim.schedule(function()
        create_taskfile_keymaps()
      end)
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
      {
        "<leader>olt",
        require("functions.snacks_pickers").find_cmake_targets,
        desc = "Tasks in Taskfile",
      },
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
            actions = {
              explorer_del = function(picker) --[[Override]]
                local actions = require("snacks.explorer.actions")
                local Tree = require("snacks.explorer.tree")
                local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected({ fallback = true }))
                if #paths == 0 then
                  return
                end
                local what = #paths == 1 and vim.fn.fnamemodify(paths[1], ":p:~:.") or #paths .. " files"
                actions.confirm("Put to the trash " .. what .. "?", function()
                  local jobs = #paths
                  local after_job = function()
                    jobs = jobs - 1
                    if jobs == 0 then
                      picker.list:set_selected()
                      actions.update(picker)
                    end
                  end
                  for _, path in ipairs(paths) do
                    local err_data = {}
                    local cmd = "trash " .. path --[[Actual command to run]]
                    local job_id = vim.fn.jobstart(cmd, {
                      detach = true,
                      on_stderr = function(_, data)
                        err_data[#err_data + 1] = table.concat(data, "\n")
                      end,
                      on_exit = function(_, code)
                        pcall(function()
                          if code == 0 then
                            Snacks.bufdelete({ file = path, force = true })
                          else
                            local err_msg = vim.trim(table.concat(err_data, ""))
                            Snacks.notify.error("Failed to delete `" .. path .. "`:\n- " .. err_msg)
                          end
                          Tree:refresh(vim.fs.dirname(path))
                        end)
                        after_job()
                      end,
                    })
                    if job_id == 0 then
                      after_job()
                      Snacks.notify.error("Failed to start the job for: " .. path)
                    end
                  end
                end)
              end,
            },
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
      statuscolumn = { enabled = true },
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

          local bible = require("dailybible")
          local verse = bible.get_verse().text
          -- Split the text into words
          local words = {}
          for word in verse:gmatch("%S+") do
            table.insert(words, word)
          end

          -- Reconstruct the text with newlines after every 5 words
          local formatted_text = ""
          for i, word in ipairs(words) do
            formatted_text = formatted_text .. word
            if i % 13 == 0 then
              formatted_text = formatted_text .. "\n"
            else
              formatted_text = formatted_text .. " "
            end
          end

          -- Optionally trim any trailing whitespace or newline
          formatted_text = formatted_text:match("^(.-)%s*$")

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
              cmd = "hub status --short --branch --renames",
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
            {
              pane = 2,
              padding = 1,
              hl = "special",
              width = 1,
              title = formatted_text .. "\n\n------ " .. require("dailybible").get_verse().verse .. " -------",
              align = "center",
            },
          }
        end,
      },
    },
  },
}
