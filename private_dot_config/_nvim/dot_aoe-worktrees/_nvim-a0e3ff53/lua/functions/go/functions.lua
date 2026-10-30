vim.api.nvim_set_hl(0, 'TEST_PASSED', { fg = "#00FF00" })

local test_function_query_string = [[
(
 (function_declaration
  name: (identifier) @name
  parameters:
    (parameter_list
     (parameter_declaration
      name: (identifier)
      type: (pointer_type
          (qualified_type
           package: (package_identifier) @_package_name
           name: (type_identifier) @_type_name)))))

 (#eq? @_package_name "testing")
 (#eq? @_type_name "T")
 (#eq? @name "%s")
)
]]

local find_test_line = function(go_bufnr, name)
  local formatted = string.format(test_function_query_string, name)
  local query = vim.treesitter.query.parse("go", formatted)
  local parser = vim.treesitter.get_parser(go_bufnr, "go", {})
  local tree = parser:parse()[1]
  local root = tree:root()

  for id, node in query:iter_captures(root, go_bufnr, 0, -1) do
    if id == 1 then
      local range = { node:range() }
      return range[1]
    end
  end
end

local add_golang_test = function(state, entry, index)
  state.tests[index] = {
    name = entry.Test,
    line = find_test_line(state.bufnr, entry.Test),
    output = {},
    success = "false"
  }
end

local ns = vim.api.nvim_create_namespace "live-tests"



local M = {}
function M.attach_to_buffer(bufnr, command)
  local state = {
    bufnr = bufnr,
    tests = {},
  }

  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  state = {
    bufnr = bufnr,
    tests = {},
  }
  vim.fn.jobstart(command, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if not data then
        return
      end
      local index = 1
      for _, line in ipairs(data) do
        local decoded = vim.json.decode(line)
        if decoded.Action == "run" then
          index = index + 1
          add_golang_test(state, decoded, index)
        elseif decoded.Action == "output" then
          if not decoded.Test then
            return
          end

          if not string.find(decoded.Output, "FAIL") and not string.find(decoded.Output, "RUN") then
            assert(state.tests, vim.inspect(state))
            table.insert(state.tests[index].output, vim.trim(decoded.Output))
          end
        elseif decoded.Action == "pass" or decoded.Action == "fail" then
          if decoded.Action == "pass" then
            state.tests[index].success = "true"
          end
          local test = state.tests[index]
          if test.success == "true" then
            local text = { "    ✓ Passed", "TEST_PASSED" }
            vim.api.nvim_buf_set_extmark(bufnr, ns, test.line, 0, {
              virt_text = { text },
              hl_group = "Error",
            })
          end
        elseif decoded.Action == "pause" or decoded.Action == "cont" or decoded.Action == "start" then
          -- Do nothing
        else
          error("Failed to handle" .. vim.inspect(data))
        end
      end
    end,
    on_exit = function()
      local failed = {}
      for _, test in pairs(state.tests) do
        if test.line then
          if test.success == "false" then
            table.insert(failed, {
              bufnr = bufnr,
              lnum = test.line,
              col = 0,
              severity = vim.diagnostic.severity.ERROR,
              source = "go-test",
              message = "Failed: " .. test.output[1],
              user_data = {},
            })
          end
        end
      end

      vim.diagnostic.set(ns, bufnr, failed, {})
    end,
  })
  --   end,
  -- })
end

return M
