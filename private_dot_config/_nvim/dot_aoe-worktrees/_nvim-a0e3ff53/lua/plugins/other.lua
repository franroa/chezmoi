return {
  "rgroli/other.nvim",
  lazy = false,
  config = function()
    vim.api.nvim_set_keymap("n", "gat", "<cmd>:Other test<CR>", { desc = "Tests", noremap = true, silent = true })
    vim.api.nvim_set_keymap(
      "n",
      "gah",
      "<cmd>:Other requests<CR>",
      { desc = "Handle requests", noremap = true, silent = true }
    )
    vim.api.nvim_set_keymap(
      "n",
      "gaor",
      "<cmd>:Other requests_dto<CR>",
      { desc = "Request Dtos", noremap = true, silent = true }
    )
    vim.api.nvim_set_keymap(
      "n",
      "gaoR",
      "<cmd>:Other responses_dto<CR>",
      { desc = "Response Dtos", noremap = true, silent = true }
    )
    vim.api.nvim_set_keymap(
      "n",
      "gag",
      "<cmd>:Other by_id<CR>",
      { desc = "Get by Id Handler", noremap = true, silent = true }
    )
    vim.api.nvim_set_keymap(
      "n",
      "gas",
      "<cmd>:Other search<CR>",
      { desc = "Search handler", noremap = true, silent = true }
    )
    vim.api.nvim_set_keymap(
      "n",
      "gaS",
      "<cmd>:Other domain_search<CR>",
      { desc = "Domain search Entity", noremap = true, silent = true }
    )
    vim.api.nvim_set_keymap(
      "n",
      "gar",
      "<cmd>:Other repository_implementation<CR>",
      { desc = "Repository implementation", noremap = true, silent = true }
    )
    vim.api.nvim_set_keymap(
      "n",
      "gaR",
      "<cmd>:Other repository_interface<CR>",
      { desc = "Repository interface", noremap = true, silent = true }
    )
    vim.api.nvim_set_keymap(
      "n",
      "gac",
      "<cmd>:Other controller_command<CR>",
      { desc = "Command controller", noremap = true, silent = true }
    )
    vim.api.nvim_set_keymap(
      "n",
      "gaC",
      "<cmd>:Other controller_query<CR>",
      { desc = "Query controller", noremap = true, silent = true }
    )
    vim.api.nvim_set_keymap(
      "n",
      "gaTcc",
      "<cmd>:Other test_controller_command<CR>",
      { desc = "Test controller command", noremap = true, silent = true }
    )
    vim.api.nvim_set_keymap(
      "n",
      "gaTcq",
      "<cmd>:Other test_controller_query<CR>",
      { desc = "Test controller query", noremap = true, silent = true }
    )
    vim.api.nvim_set_keymap(
      "n",
      "gaThq",
      "<cmd>:Other test_handler_query<CR>",
      { desc = "Test handler query", noremap = true, silent = true }
    )
    vim.api.nvim_set_keymap(
      "n",
      "gaThc",
      "<cmd>:Other test_handler_command<CR>",
      { desc = "Test handler command", noremap = true, silent = true }
    )
    vim.api.nvim_set_keymap(
      "n",
      "gad",
      "<cmd>:Other delete_handler<CR>",
      { desc = "Delete handler", noremap = true, silent = true }
    )
    vim.api.nvim_set_keymap(
      "n",
      "gaD",
      "<cmd>:Other delete_validator<CR>",
      { desc = "Delete validator", noremap = true, silent = true }
    )
    vim.api.nvim_set_keymap(
      "n",
      "gau",
      "<cmd>:Other update_handler<CR>",
      { desc = "Update handler", noremap = true, silent = true }
    )
    vim.api.nvim_set_keymap(
      "n",
      "gaU",
      "<cmd>:Other update_validator<CR>",
      { desc = "Update validator", noremap = true, silent = true }
    )
    vim.api.nvim_set_keymap(
      "n",
      "gai",
      "<cmd>:Other insert_handler<CR>",
      { desc = "Insert handler", noremap = true, silent = true }
    )
    vim.api.nvim_set_keymap(
      "n",
      "gaI",
      "<cmd>:Other insert_validator<CR>",
      { desc = "Insert validator", noremap = true, silent = true }
    )
    vim.g.other_nvim_command = "src/Gims/Gims.API.Application/(.*)s/Commands/.*/.*.cs$"
    vim.g.other_nvim_query = "src/Gims/Gims.API.Application/(.*)s/Queries/.*.cs$"
    vim.g.other_nvim_controller = "src/Gims/Gims.API/Controllers/(.*)s/(.*).cs$"
    vim.g.other_nvim_controller_test = "test/Gims/Gims.API.Test/Controllers/(.*)s/(.*)ControllerTest.cs$"
    vim.g.other_nvim_test_general = "test/.*/(.*).cs$"
    vim.g.other_nvim_general = "src/.*/(.*).cs$"
    require("other-nvim").setup({
      hooks = {
        -- This hook which is executed when the file-picker is shown.
        -- It could be used to filter or reorder the files in the filepicker.
        -- The function must return a lua table with the same structure as the input parameter.
        --
        -- The input parameter "files" is a lua table with each entry containing:
        -- @param table (filename (string), context (string), exists (boolean))
        -- @return table | boolean When an empty table or false is returned the filepicker is not openend.
        filePickerBeforeShow = function(files)
          return files
        end,

        -- This hook is called whenever a file is about to be opened.
        -- One example how this can be used: a non existing file needs to be opened by another plugin, which provides a template.
        --
        -- @param filename (string) the full-path of the file
        -- @param exists (boolean) doess the file already exist
        -- @return (boolean) When true (default) the plugin takes care of opening the file, when the function returns false this indicated that opening of the file is done in the hook.
        onOpenFile = function(filename, exists)
          -- vim.cmd("Template InsertCommand")
          return true
        end,

        -- This hook is called whenever the plugin tries to find other files.
        -- It returns the matches found by the plugin. It can be used to filter or reorder the files or use the matches with another plugin.
        --
        -- @param matches (table) lua table with each entry containing: (filename (string), context (string), exists (boolean))
        -- @return (matches) Make sure to return the matches, otherwise the plugin will not work as expected.
        onFindOtherFiles = function(matches)
          return matches
        end,
      },
      transformers = {
        clean = function(inputString)
          local wordsToRemove = {
            "Insert",
            "Update",
            "Delete",
            "Get",
            "Command",
            "Controller",
            "Handler",
            "Validator",
            "Repository",
            "Search",
            "Test",
            "ByIdQuery",
            "ByCenterIdQuery",
            "Query",
            "Request",
            "PagedResponse",
            "Reponse",
          }
          if inputString:match("Repository$") then
            -- Remove "I" if it is followed by a capital letter
            inputString = inputString:gsub("I(%u)", "%1")
          end
          for _, word in ipairs(wordsToRemove) do
            inputString = inputString:gsub(word, "")
          end
          return inputString
        end,
      },

      mappings = {
        "livewire",
        "angular",
        "laravel",
        "rails",
        "golang",
        -- specifics
        {
          pattern = vim.g.other_nvim_controller_test,
          target = "src/Gims/Gims.API/Controllers/%1s/%2Controller.cs",
          context = "test",
        },
        {
          pattern = vim.g.other_nvim_controller,
          target = "test/Gims/Gims.API.Test/Controllers/%1s/%2Test.cs",
          context = "test",
        },
        {
          pattern = vim.g.other_nvim_command,
          target = "test/Gims/Gims.API.Test/Handlers/%1s/%1CommandHandlerTest.cs",
          context = "test",
        },
        {
          pattern = vim.g.other_nvim_query,
          target = "test/Gims/Gims.API.Test/Handlers/%1s/%1QueryHandlerTest.cs",
          context = "test",
        },

        {
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/Gims.API/Program.cs",
          context = "program",
        },
        {
          pattern = vim.g.other_nvim_general,
          target = "build/dependencies.props",
          context = "properties",
        },

        -- other
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/Gims.API/Controllers/%1s/*.cs",
          transformer = "clean",
          context = "other_controllers",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/**/Interfaces/*.cs",
          transformer = "clean",
          context = "other_interfaces",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/**/Extensions/*.cs",
          transformer = "clean",
          context = "other_extensions",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "**/ApplicationMapping.cs",
          transformer = "clean",
          context = "other_automapper",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/**/Services/*.cs",
          transformer = "clean",
          context = "other_services",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/**/Constants/*.cs",
          transformer = "clean",
          context = "other_constants",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/Gims.API.Application/Requests/%1s/*.cs",
          transformer = "clean",
          context = "other_requests_dto",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/Gims.API.Application/Responses/%1s/*.cs",
          transformer = "clean",
          context = "other_responses_dto",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/Gims.API.Application/Rules/Commands/%1s/*.cs",
          transformer = "clean",
          context = "other_commands_handlers",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/Gims.API.Application/Rules/Queries/%1s/*.cs",
          transformer = "clean",
          context = "other_queries_handlers",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          transformer = "clean",
          context = "other_queries_handlers",
        },

        -- General
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/Gims.API.Application/%1s/Queries/Get%1ByIdQueryHandler.cs",
          transformer = "clean",
          context = "by_id",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/Gims.API.Application/%1s/Queries/Get%1SearchQueryHandler.cs",
          transformer = "clean",
          context = "search",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/Gims.API.Domain/Repositories/%1s/I%1Repository.cs",
          transformer = "clean",
          context = "repository_interface",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/Gims.API.Infrastructure/Data/Repositories/%1s/%1Repository.cs",
          transformer = "clean",
          context = "repository_implementation",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/Gims.API.Domain/Data/Search/%1s/%1Search.cs",
          transformer = "clean",
          context = "domain_search",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "test/Gims/Gims.API.Test/Handlers/%1s/%1QueryHandlerTest.cs",
          transformer = "clean",
          context = "test_handler_query",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "test/Gims/Gims.API.Test/Handlers/%1s/%1CommandHandlerTest.cs",
          transformer = "clean",
          context = "test_handler_command",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/Gims.API.Application/%1s/Commands/Delete/Delete%1Command.cs",
          transformer = "clean",
          context = "delete_command",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/Gims.API.Application/%1s/Commands/Delete/Delete%1CommandHandler.cs",
          transformer = "clean",
          context = "delete_handler",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/Gims.API.Application/%1s/Commands/Delete/Delete%1CommandValidator.cs",
          transformer = "clean",
          context = "delete_validator",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/Gims.API.Application/%1s/Commands/Insert/Insert%1Command.cs",
          transformer = "clean",
          context = "insert_command",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/Gims.API.Application/%1s/Commands/Insert/Insert%1CommandHandler.cs",
          transformer = "clean",
          context = "insert_handler",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/Gims.API.Application/%1s/Commands/Insert/Insert%1CommandValidator.cs",
          transformer = "clean",
          context = "insert_validator",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/Gims.API.Application/%1s/Commands/Update/Update%1Command.cs",
          transformer = "clean",
          context = "update_command",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/Gims.API.Application/%1s/Commands/Update/Update%1CommandHandler.cs",
          transformer = "clean",
          context = "update_handler",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/Gims.API.Application/%1s/Commands/Update/Update%1CommandValidator.cs",
          transformer = "clean",
          context = "update_validator",
        },
        {
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/Gims.API/Controllers/%1s/%1CommandController.cs",
          transformer = "clean",
          context = "controller_command",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_general,
          target = "test/Gims/Gims.API.Test/Controllers/%1s/%1CommandControllerTest.cs",
          transformer = "clean",
          context = "test_controller_command",
        },
        {
          pattern = vim.g.other_nvim_general,
          target = "src/Gims/Gims.API/Controllers/%1s/%1QueryController.cs",
          context = "controller_query",
          transformer = "clean",
        },
        {
          pattern = vim.g.other_nvim_general,
          target = "test/Gims/Gims.API.Test/Controllers/%1s/%1QueryControllerTest.cs",
          context = "test_controller_query",
          transformer = "clean",
        },
        {
          pattern = vim.g.other_nvim_general,
          target = "../../requests/%1.http",
          transformer = "clean",
          context = "requests",
        },

        -- TESTS
        -- TESTS
        -- TESTS
        -- TESTS
        -- TESTS
        -- TESTS
        -- TESTS
        -- TESTS
        -- TESTS
        -- TESTS
        -- TESTS
        -- TESTS
        { -- Command Handler
          pattern = vim.g.other_nvim_test_general,
          target = "src/Gims/Gims.API.Application/%1s/Queries/Get%1ByIdQueryHandler.cs",
          transformer = "clean",
          context = "by_id",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_test_general,
          target = "src/Gims/Gims.API.Application/%1s/Queries/Get%1SearchQueryHandler.cs",
          transformer = "clean",
          context = "search",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_test_general,
          target = "src/Gims/Gims.API.Domain/Repositories/%1s/I%1Repository.cs",
          transformer = "clean",
          context = "repository_interface",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_test_general,
          target = "src/Gims/Gims.API.Infrastructure/Data/Repositories/%1s/%1Repository.cs",
          transformer = "clean",
          context = "repository_implementation",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_test_general,
          target = "src/Gims/Gims.API.Domain/Data/Search/%1s/%1Search.cs",
          transformer = "clean",
          context = "domain_search",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_test_general,
          target = "test/Gims/Gims.API.Test/Handlers/%1s/%1QueryHandlerTest.cs",
          transformer = "clean",
          context = "test_handler_query",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_test_general,
          target = "test/Gims/Gims.API.Test/Handlers/%1s/%1CommandHandlerTest.cs",
          transformer = "clean",
          context = "test_handler_command",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_test_general,
          target = "src/Gims/Gims.API.Application/%1s/Commands/Delete/Delete%1Command.cs",
          transformer = "clean",
          context = "delete_command",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_test_general,
          target = "src/Gims/Gims.API.Application/%1s/Commands/Delete/Delete%1CommandHandler.cs",
          transformer = "clean",
          context = "delete_handler",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_test_general,
          target = "src/Gims/Gims.API.Application/%1s/Commands/Delete/Delete%1CommandValidator.cs",
          transformer = "clean",
          context = "delete_validator",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_test_general,
          target = "src/Gims/Gims.API.Application/%1s/Commands/Insert/Insert%1Command.cs",
          transformer = "clean",
          context = "insert_command",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_test_general,
          target = "src/Gims/Gims.API.Application/%1s/Commands/Insert/Insert%1CommandHandler.cs",
          transformer = "clean",
          context = "insert_handler",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_test_general,
          target = "src/Gims/Gims.API.Application/%1s/Commands/Insert/Insert%1CommandValidator.cs",
          transformer = "clean",
          context = "insert_validator",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_test_general,
          target = "src/Gims/Gims.API.Application/%1s/Commands/Update/Update%1Command.cs",
          transformer = "clean",
          context = "update_command",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_test_general,
          target = "src/Gims/Gims.API.Application/%1s/Commands/Update/Update%1CommandHandler.cs",
          transformer = "clean",
          context = "update_handler",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_test_general,
          target = "src/Gims/Gims.API.Application/%1s/Commands/Update/Update%1CommandValidator.cs",
          transformer = "clean",
          context = "update_validator",
        },
        {
          pattern = vim.g.other_nvim_test_general,
          target = "src/Gims/Gims.API/Controllers/%1s/%1CommandController.cs",
          transformer = "clean",
          context = "controller_command",
        },
        { -- Command Handler
          pattern = vim.g.other_nvim_test_general,
          target = "test/Gims/Gims.API.Test/Controllers/%1s/%1CommandControllerTest.cs",
          transformer = "clean",
          context = "test_controller_command",
        },
        {
          pattern = vim.g.other_nvim_test_general,
          target = "src/Gims/Gims.API/Controllers/%1s/%1QueryController.cs",
          context = "controller_query",
          transformer = "clean",
        },
        {
          pattern = vim.g.other_nvim_test_general,
          target = "test/Gims/Gims.API.Test/Controllers/%1s/%1QueryControllerTest.cs",
          context = "test_controller_query",
          transformer = "clean",
        },
        {
          pattern = vim.g.other_nvim_test_general,
          target = "../../requests/%1.http",
          transformer = "clean",
          context = "requests",
        },
      },
      style = {
        -- How the plugin paints its window borders
        -- Allowed values are none, single, double, rounded, solid and shadow
        border = "solid",

        -- Column seperator for the window
        seperator = "|",

        -- width of the window in percent. e.g. 0.5 is 50%, 1.0 is 100%
        width = 0.7,

        -- min height in rows.
        -- when more columns are needed this value is extended automatically
        minHeight = 2,
      },
    })
  end,
}
