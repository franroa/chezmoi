-- This module wraps neotest-vstest to provide runtime coverage argument support
-- luacheck: globals vim
local M = {}

local runtime_args = {}

--- Set runtime dotnet arguments to be passed to the test runner
--- @param args table|nil Array of arguments (e.g., {"/p:CollectCoverage=true", ...})
function M.set_coverage_args(args)
  runtime_args = args or {}
  vim.notify("neotest-vstest: coverage args set to: " .. vim.inspect(args), vim.log.levels.INFO)
end

--- Get the runtime dotnet arguments
--- @return table
function M.get_coverage_args()
  return runtime_args
end

--- Run tests with coverage collection
--- @param dotnet_args table Array of dotnet arguments
function M.run_with_coverage(dotnet_args)
  M.set_coverage_args(dotnet_args)
  require("neotest").run.run(vim.fn.expand("%"))
end

--- Run all tests in file with coverage
function M.run_file_with_coverage()
  M.run_with_coverage({
    "/p:CollectCoverage=true",
    "/p:CoverletOutputFormat=lcov",
    "/p:CoverletOutput=" .. (vim.fn.getcwd() or ".") .. "/coverage/lcov.info",
  })
end

--- Inject runtime args into neotest-vstest adapter's build_spec
function M.patch_adapter()
  local ok_vstest, vstest_adapter = pcall(require, "neotest-vstest")
  if not ok_vstest then
    vim.notify("neotest-vstest adapter not loaded", vim.log.levels.ERROR)
    return
  end

  -- Store original build_spec
  local original_build_spec = vstest_adapter.build_spec

  -- Wrap build_spec to inject runtime args
  vstest_adapter.build_spec = function(args)
    if #runtime_args > 0 then
      args.dotnet_additional_args = runtime_args
    end
    return original_build_spec(args)
  end

  vim.notify("neotest-vstest: patched with runtime coverage support", vim.log.levels.INFO)
end

return M
