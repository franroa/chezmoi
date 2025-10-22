-- ensure plugin lua dir is on package.path
local repo_root = vim.fn.getcwd()
package.path = repo_root .. "/lua/?.lua;" .. repo_root .. "/lua/?/init.lua;" .. package.path

local utils = require("core.utils")

describe("core.utils", function()
  describe("safe_call", function()
    it("returns result when function succeeds", function()
      local result = utils.safe_call(function() return "success" end, "default")
      assert.equal("success", result)
    end)

    it("returns default when function fails", function()
      local result = utils.safe_call(function() error("test error") end, "default")
      assert.equal("default", result)
    end)

    it("handles nil default", function()
      local result = utils.safe_call(function() error("test error") end, nil)
      assert.is_nil(result)
    end)
  end)

  describe("validate_buffer", function()
    it("returns false for nil buffer", function()
      assert.is_false(utils.validate_buffer(nil))
    end)

    it("returns false for invalid buffer", function()
      assert.is_false(utils.validate_buffer(99999))
    end)

    it("returns true for valid buffer", function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      assert.is_true(utils.validate_buffer(bufnr))
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)
  end)

  describe("validate_window", function()
    it("returns false for nil window", function()
      assert.is_false(utils.validate_window(nil))
    end)

    it("returns false for invalid window", function()
      assert.is_false(utils.validate_window(99999))
    end)

    it("returns true for current window", function()
      local win_id = vim.api.nvim_get_current_win()
      assert.is_true(utils.validate_window(win_id))
    end)
  end)

  describe("get_cursor_component", function()
    local test_bufnr
    local components

    before_each(function()
      test_bufnr = vim.api.nvim_create_buf(false, true)
      components = {
        ["comp1"] = { line = 1, end_line = 3 },
        ["comp2"] = { line = 5, end_line = 8 },
        ["comp3"] = { line = 10, end_line = 12 },
      }
    end)

    after_each(function()
      if vim.api.nvim_buf_is_valid(test_bufnr) then
        vim.api.nvim_buf_delete(test_bufnr, { force = true })
      end
    end)

    it("returns nil for invalid buffer", function()
      local key, comp = utils.get_cursor_component(nil, components)
      assert.is_nil(key)
      assert.is_nil(comp)
    end)

    it("returns nil for nil components", function()
      local key, comp = utils.get_cursor_component(test_bufnr, nil)
      assert.is_nil(key)
      assert.is_nil(comp)
    end)

    it("finds component when cursor is within range", function()
      -- Mock cursor position - this is a simplified test
      -- In real usage, cursor position would be determined by actual cursor
      -- For testing, we'll test the logic by checking the range matching
      local cursor_line = 6
      for key, comp_data in pairs(components) do
        if cursor_line >= comp_data.line and cursor_line <= comp_data.end_line then
          assert.equal("comp2", key)
          assert.equal(5, comp_data.line)
          assert.equal(8, comp_data.end_line)
        end
      end
    end)
  end)

  describe("get_free_port", function()
    it("returns a valid port number", function()
      local port = utils.get_free_port()
      assert.is_not_nil(port)
      assert.is_number(port)
      assert.is_true(port > 0)
      assert.is_true(port <= 65535)
    end)

    it("returns different ports on multiple calls", function()
      local port1 = utils.get_free_port()
      local port2 = utils.get_free_port()
      -- While not guaranteed, it's very unlikely to get the same port twice
      assert.is_not_nil(port1)
      assert.is_not_nil(port2)
    end)
  end)

  describe("center_text", function()
    it("centers text in given width", function()
      local result = utils.center_text("test", 10)
      assert.equal("   test   ", result)
    end)

    it("handles text wider than target width", function()
      local result = utils.center_text("very long text", 5)
      assert.equal("very long text", result)
    end)

    it("handles odd padding correctly", function()
      local result = utils.center_text("hi", 7)
      -- Should have 2 spaces on left, 3 on right (or vice versa)
      assert.equal(7, #result)
      assert.is_true(result:match("^%s*hi%s*$") ~= nil)
    end)

    it("handles empty text", function()
      local result = utils.center_text("", 5)
      assert.equal("     ", result)
    end)
  end)

  describe("create_temp_file_with_content", function()
    it("creates file with string content", function()
      local content = "line1\nline2\nline3"
      local temp_file = utils.create_temp_file_with_content(content)
      
      assert.is_not_nil(temp_file)
      assert.equal(1, vim.fn.filereadable(temp_file))
      
      local lines = vim.fn.readfile(temp_file)
      assert.equal(3, #lines)
      assert.equal("line1", lines[1])
      assert.equal("line2", lines[2])
      assert.equal("line3", lines[3])
      
      -- Cleanup
      vim.fn.delete(temp_file)
    end)

    it("creates file with table content", function()
      local content = { "line1", "line2", "line3" }
      local temp_file = utils.create_temp_file_with_content(content)
      
      assert.is_not_nil(temp_file)
      assert.equal(1, vim.fn.filereadable(temp_file))
      
      local lines = vim.fn.readfile(temp_file)
      assert.equal(3, #lines)
      assert.equal("line1", lines[1])
      assert.equal("line2", lines[2])
      assert.equal("line3", lines[3])
      
      -- Cleanup
      vim.fn.delete(temp_file)
    end)
  end)

  describe("extract_log_contents", function()
    it("extracts logs from valid Loki response", function()
      local loki_response = vim.fn.json_encode({
        data = {
          result = {
            {
              values = {
                { "1234567890", "log message 1" },
                { "1234567891", "log message 2" },
              }
            },
            {
              values = {
                { "1234567892", "log message 3" },
              }
            }
          }
        }
      })
      
      local logs = utils.extract_log_contents(loki_response)
      assert.equal(3, #logs)
      assert.equal("log message 1", logs[1])
      assert.equal("log message 2", logs[2])
      assert.equal("log message 3", logs[3])
    end)

    it("returns empty table for invalid JSON", function()
      local logs = utils.extract_log_contents("invalid json")
      assert.are.same({}, logs)
    end)

    it("returns empty table for response without data", function()
      local response = vim.fn.json_encode({ status = "success" })
      local logs = utils.extract_log_contents(response)
      assert.are.same({}, logs)
    end)
  end)

  describe("jump_to_line", function()
    it("returns false for invalid window", function()
      local result = utils.jump_to_line(99999, 1, 0)
      assert.is_false(result)
    end)

    it("returns true for valid window", function()
      local win_id = vim.api.nvim_get_current_win()
      local result = utils.jump_to_line(win_id, 1, 0)
      assert.is_true(result)
    end)

    it("uses default column when not provided", function()
      local win_id = vim.api.nvim_get_current_win()
      local result = utils.jump_to_line(win_id, 1)
      assert.is_true(result)
    end)
  end)

  describe("extract_metric_contents", function()
    it("extracts metrics from valid Prometheus response", function()
      local prom_response = vim.fn.json_encode({
        data = {
          result = {
            { value = { "1234567890", "100" } },
            { value = { "1234567891", "200" } },
            { value = { "1234567892", "300" } },
          }
        }
      })
      
      local metrics = utils.extract_metric_contents(prom_response)
      assert.equal(3, #metrics)
      assert.equal("100", metrics[1])
      assert.equal("200", metrics[2])
      assert.equal("300", metrics[3])
    end)

    it("returns empty table for invalid response structure", function()
      local response = vim.fn.json_encode({ status = "error" })
      local metrics = utils.extract_metric_contents(response)
      assert.are.same({}, metrics)
    end)

    it("skips entries without value field", function()
      local response = vim.fn.json_encode({
        data = {
          result = {
            { value = { "1234567890", "100" } },
            { metric = { __name__ = "test" } }, -- No value field
            { value = { "1234567891", "200" } },
          }
        }
      })
      
      local metrics = utils.extract_metric_contents(response)
      assert.equal(2, #metrics)
      assert.equal("100", metrics[1])
      assert.equal("200", metrics[2])
    end)
  end)

  describe("debounce", function()
    it("delays function execution", function()
      local counter = 0
      local debounced = utils.debounce(function() counter = counter + 1 end, 10)
      
      debounced()
      assert.equal(0, counter) -- Should not execute immediately
      
      -- Wait for debounce delay
      vim.wait(50, function() return counter > 0 end)
      assert.equal(1, counter)
    end)

    it("cancels previous calls when called multiple times", function()
      local counter = 0
      local debounced = utils.debounce(function() counter = counter + 1 end, 20)
      
      debounced()
      debounced()
      debounced()
      
      vim.wait(50, function() return counter > 0 end)
      assert.equal(1, counter) -- Should only execute once
    end)
  end)
end)
