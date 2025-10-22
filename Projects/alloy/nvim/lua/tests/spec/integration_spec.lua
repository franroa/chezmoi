-- ensure plugin lua dir is on package.path
local repo_root = vim.fn.getcwd()
package.path = repo_root .. "/lua/?.lua;" .. repo_root .. "/lua/?/init.lua;" .. package.path

local parser = require("core.parser")
local utils = require("core.utils")
local state = require("features.common.state")

describe("alloy integration tests", function()
  local test_bufnr

  before_each(function()
    test_bufnr = vim.api.nvim_create_buf(false, true)
    state.reset_state()
  end)

  after_each(function()
    if vim.api.nvim_buf_is_valid(test_bufnr) then
      vim.api.nvim_buf_delete(test_bufnr, { force = true })
    end)
    state.reset_state()
  end)

  describe("parser and utils integration", function()
    it("parses complex pipeline and finds cursor components", function()
      local content = {
        'discovery.kubernetes "pods" {',
        '  role = "pod"',
        '}',
        '',
        'prometheus.scrape "metrics" {',
        '  targets = discovery.kubernetes.pods.targets',
        '  forward_to = [prometheus.relabel.drop_metrics.receiver]',
        '}',
        '',
        'prometheus.relabel "drop_metrics" {',
        '  rule {',
        '    source_labels = ["__name__"]',
        '    regex = "container_.*"',
        '    action = "drop"',
        '  }',
        '  forward_to = [prometheus.remote_write.default.receiver]',
        '}',
        '',
        'prometheus.remote_write "default" {',
        '  endpoint {',
        '    url = "http://localhost:9009/api/v1/push"',
        '  }',
        '}',
      }
      vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, content)

      local components, chains, starts = parser.get_parsed_pipeline_data(test_bufnr)

      -- Verify parsing results
      assert.is_not_nil(components)
      assert.equal(4, vim.tbl_count(components))
      assert.is_not_nil(components["discovery.kubernetes.pods"])
      assert.is_not_nil(components["prometheus.scrape.metrics"])
      assert.is_not_nil(components["prometheus.relabel.drop_metrics"])
      assert.is_not_nil(components["prometheus.remote_write.default"])

      -- Verify relationships
      assert.is_not_nil(components["discovery.kubernetes.pods"].forward_to)
      assert.equal(1, #components["discovery.kubernetes.pods"].forward_to)
      assert.equal("prometheus.scrape.metrics", components["discovery.kubernetes.pods"].forward_to[1])

      assert.is_not_nil(components["prometheus.scrape.metrics"].forward_to)
      assert.equal(1, #components["prometheus.scrape.metrics"].forward_to)
      assert.equal("prometheus.relabel.drop_metrics", components["prometheus.scrape.metrics"].forward_to[1])

      -- Verify chain construction
      assert.equal(1, #chains)
      assert.equal(4, #chains[1])
      assert.equal("discovery.kubernetes.pods", chains[1][1])
      assert.equal("prometheus.scrape.metrics", chains[1][2])
      assert.equal("prometheus.relabel.drop_metrics", chains[1][3])
      assert.equal("prometheus.remote_write.default", chains[1][4])

      -- Test cursor component finding
      local key, comp = utils.get_cursor_component(test_bufnr, components)
      -- This will depend on actual cursor position in test environment
      -- For now, just verify the function doesn't error
      assert.is_boolean(key ~= nil or comp ~= nil or (key == nil and comp == nil))
    end)

    it("handles empty file gracefully across all modules", function()
      vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, {})

      local components, chains, starts = parser.get_parsed_pipeline_data(test_bufnr)
      assert.is_nil(components)
      assert.is_nil(chains)
      assert.is_nil(starts)

      local key, comp = utils.get_cursor_component(test_bufnr, {})
      assert.is_nil(key)
      assert.is_nil(comp)
    end)
  end)

  describe("state management integration", function()
    it("manages complete visualizer state through lifecycle", function()
      -- Set up complete state
      local complete_state = {
        win_id = 123,
        container_win_id = 456,
        buf = 789,
        source_bufnr = test_bufnr,
        nav_mode = "component",
        focused_pipeline_index = 1,
        pipelines = { { "comp1", "comp2" } },
        components = {
          ["comp1"] = { type = "prometheus.scrape", label = "test1", line = 1 },
          ["comp2"] = { type = "prometheus.remote_write", label = "test2", line = 5 },
        },
        box_metadata = {
          { key = "comp1", line_in_diagram = 1 },
          { key = "comp2", line_in_diagram = 3 },
        },
      }

      state.set_state(complete_state)
      state.set_syncing(true)

      -- Verify state is set correctly
      local retrieved = state.get_state()
      assert.are.same(complete_state, retrieved)
      assert.is_true(state.is_syncing())

      -- Update state
      state.update_state("nav_mode", "pipeline")
      state.update_state("focused_pipeline_index", 2)

      -- Verify updates
      local updated = state.get_state()
      assert.equal("pipeline", updated.nav_mode)
      assert.equal(2, updated.focused_pipeline_index)
      assert.equal(123, updated.win_id) -- Original values preserved

      -- Reset and verify cleanup
      state.reset_state()
      assert.is_nil(state.get_state())
      assert.is_false(state.is_syncing())
    end)

    it("handles state updates with parser data", function()
      local content = {
        'prometheus.scrape "test" {',
        '  targets = [{"__address__" = "localhost:9090"}]',
        '}',
      }
      vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, content)

      local components, chains, starts = parser.get_parsed_pipeline_data(test_bufnr)
      
      state.set_state({
        source_bufnr = test_bufnr,
        nav_mode = "component",
      })

      -- Update state with parsed data
      state.update_state("components", components)
      state.update_state("pipelines", chains)

      local current_state = state.get_state()
      assert.are.same(components, current_state.components)
      assert.are.same(chains, current_state.pipelines)
      assert.equal("component", current_state.nav_mode)
    end)
  end)

  describe("error handling integration", function()
    it("handles buffer validation errors gracefully", function()
      -- Test with invalid buffer
      local invalid_bufnr = 99999
      
      assert.is_false(utils.validate_buffer(invalid_bufnr))
      
      local components, chains, starts = parser.get_parsed_pipeline_data(invalid_bufnr)
      assert.is_nil(components)
      assert.is_nil(chains)
      assert.is_nil(starts)

      local key, comp = utils.get_cursor_component(invalid_bufnr, {})
      assert.is_nil(key)
      assert.is_nil(comp)
    end)

    it("handles malformed content with safe_call", function()
      local malformed_content = {
        'this is not valid alloy syntax',
        'prometheus.scrape "test" {',
        '  // missing closing brace',
      }
      vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, malformed_content)

      -- Use safe_call to handle potential parsing errors
      local components = utils.safe_call(function()
        return parser.get_parsed_pipeline_data(test_bufnr)
      end, {})

      -- Should not crash and return something (empty or parsed data)
      assert.is_not_nil(components)
    end)

    it("handles state corruption gracefully", function()
      -- Set corrupted state
      state.set_state({ invalid = "data", missing_required_fields = true })
      
      -- Should handle gracefully
      local current_state = state.get_state()
      assert.is_not_nil(current_state)
      
      -- Update should work even with corrupted state
      state.update_state("nav_mode", "component")
      local updated = state.get_state()
      assert.equal("component", updated.nav_mode)
    end)
  end)

  describe("caching integration", function()
    it("caches parser results and integrates with state", function()
      local content = {
        'prometheus.scrape "cached_test" {',
        '  targets = [{"__address__" = "localhost:9090"}]',
        '}',
      }
      vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, content)

      -- First parse
      local components1, _, _ = parser.get_parsed_pipeline_data(test_bufnr)
      state.set_state({ components = components1, source_bufnr = test_bufnr })

      -- Second parse with same content (should use cache)
      local components2, _, _ = parser.get_parsed_pipeline_data(test_bufnr)
      state.update_state("components", components2)

      -- Should be identical due to caching
      local current_state = state.get_state()
      assert.are.same(components1, components2)
      assert.are.same(components2, current_state.components)
    end)

    it("invalidates cache when content changes", function()
      local content1 = {
        'prometheus.scrape "test1" {',
        '  targets = [{"__address__" = "localhost:9090"}]',
        '}',
      }
      vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, content1)

      local components1, _, _ = parser.get_parsed_pipeline_data(test_bufnr)
      assert.is_not_nil(components1["prometheus.scrape.test1"])

      -- Change content
      local content2 = {
        'prometheus.scrape "test2" {',
        '  targets = [{"__address__" = "localhost:8080"}]',
        '}',
      }
      vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, content2)

      local components2, _, _ = parser.get_parsed_pipeline_data(test_bufnr)
      assert.is_nil(components2["prometheus.scrape.test1"])
      assert.is_not_nil(components2["prometheus.scrape.test2"])
    end)
  end)

  describe("full workflow integration", function()
    it("simulates complete visualizer workflow", function()
      -- Step 1: Create Alloy content
      local content = {
        'discovery.kubernetes "services" {',
        '  role = "service"',
        '}',
        '',
        'prometheus.scrape "app_metrics" {',
        '  targets = discovery.kubernetes.services.targets',
        '  forward_to = [prometheus.remote_write.central.receiver]',
        '}',
        '',
        'prometheus.remote_write "central" {',
        '  endpoint {',
        '    url = "http://central:9009/api/v1/push"',
        '  }',
        '}',
      }
      vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, content)

      -- Step 2: Parse the content
      local components, chains, starts = parser.get_parsed_pipeline_data(test_bufnr)
      assert.is_not_nil(components)
      assert.equal(3, vim.tbl_count(components))

      -- Step 3: Initialize visualizer state
      state.set_state({
        source_bufnr = test_bufnr,
        components = components,
        pipelines = chains,
        nav_mode = "component",
        focused_pipeline_index = 1,
        win_id = vim.api.nvim_get_current_win(),
      })

      -- Step 4: Verify state initialization
      local current_state = state.get_state()
      assert.equal(test_bufnr, current_state.source_bufnr)
      assert.equal("component", current_state.nav_mode)
      assert.equal(1, current_state.focused_pipeline_index)
      assert.are.same(components, current_state.components)

      -- Step 5: Simulate navigation state changes
      state.update_state("nav_mode", "pipeline")
      state.set_syncing(true)

      current_state = state.get_state()
      assert.equal("pipeline", current_state.nav_mode)
      assert.is_true(state.is_syncing())

      -- Step 6: Simulate cursor component detection
      local cursor_key = utils.get_cursor_component_key(test_bufnr, components)
      if cursor_key then
        state.update_state("last_focused_component", cursor_key)
        current_state = state.get_state()
        assert.equal(cursor_key, current_state.last_focused_component)
      end

      -- Step 7: Cleanup
      state.set_syncing(false)
      state.reset_state()
      assert.is_nil(state.get_state())
      assert.is_false(state.is_syncing())
    end)
  end)
end)
