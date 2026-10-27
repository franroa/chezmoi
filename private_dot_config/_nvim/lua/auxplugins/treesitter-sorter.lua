return {
  "mtrajano/tssorter.nvim",
  config = function()
    require("tssorter").setup({
      sortables = {
        markdown = { -- filetype
          list = { -- sortable name
            node = "list_item", -- treesitter node to capture

            ordinal = "inline", -- OPTIONAL: nested node to do the sorting by. If this is not specified it will just sort based on
            -- node's text contents.

            -- It's possible that for the ordinal config above the node name could be one of multiple values. For example in markdown
            -- if you would like to sort by the task status this value could be `task_list_marker_unchecked` or `task_list_marker_checked`
            -- depending on that task status. In this case you could pass a table to ordinal and it would match based on the first one found.
            -- ordinal = {'task_list_marker_unchecked', 'task_list_marker_checked'}

            -- OPTIONAL: function that takes in two nodes and returns true when first node should come first
            -- these are just tsnodes so you have all that functionality available to you
            -- if ordinals are specified in the config above they will be included at the end
            order_by = function(node1, node2, ordinal1, ordinal2)
              if ordinal1 and ordinal2 then
                return ordinal1 < ordinal2
              end

              -- TODO: add more helpers to make it easier to interact with these
              local line1 = require("tssorter.tshelper").get_text(node1)
              local line2 = require("tssorter.tshelper").get_text(node2)

              return line1 < line2
            end,
          },
          header = {
            node = "pipe_table_header",
            ordinal = "inline", -- OPTIONAL: nested node to do the sorting by. If this is not specified it will just sort based on
            -- node's text contents.

            -- It's possible that for the ordinal config above the node name could be one of multiple values. For example in markdown
            -- if you would like to sort by the task status this value could be `task_list_marker_unchecked` or `task_list_marker_checked`
            -- depending on that task status. In this case you could pass a table to ordinal and it would match based on the first one found.
            -- ordinal = {'task_list_marker_unchecked', 'task_list_marker_checked'}

            -- OPTIONAL: function that takes in two nodes and returns true when first node should come first
            -- these are just tsnodes so you have all that functionality available to you
            -- if ordinals are specified in the config above they will be included at the end
            order_by = function(node1, node2, ordinal1, ordinal2)
              if ordinal1 and ordinal2 then
                return ordinal1 < ordinal2
              end

              -- TODO: add more helpers to make it easier to interact with these
              local line1 = require("tssorter.tshelper").get_text(node1)
              local line2 = require("tssorter.tshelper").get_text(node2)

              return line1 < line2
            end,
          },
        },
      },
      logger = {
        level = vim.log.levels.WARN, -- log on warn level and above
        outfile = nil, -- nil prints to messages, or add a path to a file to output logs there
      },
    })
  end, -- latest stable version, use `main` to keep up with the latest changes
  version = "*",
  keys = {
    {
      "<leader>uS",
      function()
        require("tssorter").sort()
      end,
      desc = "Treesitter Sort",
    },
  },
}
