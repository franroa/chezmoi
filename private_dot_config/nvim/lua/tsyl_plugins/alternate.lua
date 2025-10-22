return {
  "otavioschwanck/telescope-alternate",
  lazy = false,
  config = function()
    require("telescope-alternate").setup({
      mappings = {
        {
          "src/Gims/Gims.API/Controllers/(.*)/(.*)CommandController.cs",
          {
            -- {
            --   "src/Gims/Gims.API/Controllers/[1]/[2]CommandController.cs",
            -- },
            -- { "src/Gims/Gims.API.Application/Rules/Commands/Insert/Insert[1]Command.cs", "Insert Command" },
            { "test/Gims/Gims.API.Test/Controllers/[1]/[2]CommandControllerTest.cs", "Controller Test" },
            { "test/Gims/Gims.API.Test/Controllers/[1]/[2]CommandControllerTest.cs", "Controller Test 2" },
            { "../../requests/[1].http", "Request" },
          },
        },
        -- {
        --   "src/Gims/Gims.API.Application/**/Commands/Insert/Insert(.*)Command.cs",
        --   {
        --     { "test/Gims/Gims.API.Test/Controllers/[1]CommandControllerTest.cs", "Controller Test" },
        --   },
        -- },
        -- {
        --   "test/Gims/Gims.API.Test/Controllers/(.*)CommandControllerTest.cs",
        --   {
        --     { "src/Gims/Gims.API/Controllers/[1]CommandController.cs", "Controller" },
        --   },
        -- },
        -- {
        --   "../../requests/(.*).http",
        --   {
        --     { "src/Gims/Gims.API/Controllers/[1]CommandController.cs", "Controller" },
        --   },
        -- },
      },
      presets = { "rails", "rspec", "nestjs", "angular" }, -- Telescope pre-defined mapping presets
      open_only_one_with = "current_pane", -- when just have only possible file, open it with.  Can also be horizontal_split and vertical_split
      transformers = { -- custom transformers
        change_to_uppercase = function(w)
          return my_uppercase_method(w)
        end,
      },
      -- telescope_mappings = { -- Change the telescope mappings
      --   i = {
      --     open_current = '<CR>',
      --     open_horizontal = '<C-s>',
      --     open_vertical = '<C-v>',
      --     open_tab = '<C-t>',
      --   },
      --   n = {
      --     open_current = '<CR>',
      --     open_horizontal = '<C-s>',
      --     open_vertical = '<C-v>',
      --     open_tab = '<C-t>',
      --   }
      -- }
    })
    require("telescope").load_extension("telescope-alternate")
  end,
}
