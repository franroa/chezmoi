-- return {
--   "nvim-neotest/neotest",
--   event = { "BufReadPost", "BufNewFile" },
--   dependencies = {
--     "nvim-neotest/nvim-nio",
--     "nvim-lua/plenary.nvim",
--     "antoinemadec/FixCursorHold.nvim",
--     "nvim-treesitter/nvim-treesitter",
--     "nvim-neotest/neotest-jest",
--   },
--   config = function()
--     local status_ok, neotest = pcall(require, "neotest")
--     if not status_ok then
--       return
--     end
--
--     local jest = require("neotest-jest")
--
--     neotest.setup({
--       summary = {
--         open = "botright vsplit | vertical resize 80",
--       },
--       adapters = {
--         jest({
--           jestCommand = "npm test --",
--           cwd = function(path)
--             return vim.fn.getcwd()
--           end,
--         }),
--       },
--     })
--   end,
-- }

return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/neotest-jest",
    "marilari88/neotest-vitest",
    "nvim-neotest/neotest-jest",
    {
      "Nsidorenco/neotest-vstest",
      -- dir = vim.fn.expand("~/.config/nvim/lua/local_plugins/neotest-vstest"),
      -- dev = true,
    },
  },
  config = function(_, opts)
    opts.consumers = opts.consumers or {}
    opts.consumers.overseer = require("neotest.consumers.overseer")
    opts.overseer = {
      enabled = true,
      force_default = false,
    }
    if opts.adapters then
      local adapters = {}
      for name, config in pairs(opts.adapters or {}) do
        if type(name) == "number" then
          if type(config) == "string" then
            config = require(config)
          end
          adapters[#adapters + 1] = config
        elseif config ~= false then
          local adapter = require(name)
          if type(config) == "table" and not vim.tbl_isempty(config) then
            local meta = getmetatable(adapter)
            if adapter.setup then
              adapter.setup(config)
            elseif meta and meta.__call then
              adapter(config)
            else
              error("Adapter " .. name .. " does not support setup")
            end
          end
          adapters[#adapters + 1] = adapter
        end
      end
      opts.adapters = adapters
    end

    require("neotest").setup({
      log_level = vim.log.levels.TRACE,
      adapters = {
        require("neotest-jest")({}),
        require("neotest-vstest")({}),
        require("neotest-vitest")({
          vitestCommand = "npm test --",
          ignoreVitestDependency = true, -- Skip vitest dependency check
        }),
      },
    })
  end,
  -- stylua: ignore
}
