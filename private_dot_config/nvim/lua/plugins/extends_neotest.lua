return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/neotest-jest",
    "marilari88/neotest-vitest",
    "Nsidorenco/neotest-vstest",
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
        require("neotest-vstest")({
          build_opts = {
            additional_args = {
              "/p:CollectCoverage=true",
              "/p:CoverletOutputFormat=lcov",
              "/p:CoverletOutput=" .. LazyVim.root.git() .. "/coverage/lcov.info",
            },
          },
        }),
        require("neotest-vitest")({
          vitestCommand = "npm test --",
          ignoreVitestDependency = true, -- Skip vitest dependency check
        }),
      },
    })
  end,
  -- stylua: ignore
}
