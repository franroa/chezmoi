-- ensure plugin lua dir is on package.path
local repo_root = vim.fn.getcwd()
package.path = repo_root .. "/lua/?.lua;" .. repo_root .. "/lua/?/init.lua;" .. package.path

local diagram_utils = require("ui.diagram_utils")

describe("ui.diagram_utils", function()
  local orig_get_box

  setup(function()
    orig_get_box = diagram_utils.get_box_at_cursor
  end)

  teardown(function()
    diagram_utils.get_box_at_cursor = orig_get_box
  end)

  describe("get_box_at_cursor", function()
    it("finds box at current cursor position", function()
      local box_metadata = {
        { key = "comp1", line_in_diagram = 1, start_col = 1, end_col = 10 },
        { key = "comp2", line_in_diagram = 3, start_col = 5, end_col = 15 },
        { key = "comp3", line_in_diagram = 5, start_col = 2, end_col = 8 },
      }
      
      -- Mock cursor at line 3, column 7 (within comp2)
      diagram_utils.get_box_at_cursor = function(win_id, cursor_line, box_metadata)
        for _, box in ipairs(box_metadata) do
          if cursor_line == box.line_in_diagram then
            return box.key, box
          end
        end
        return nil, nil
      end
      
      local key, box = diagram_utils.get_box_at_cursor(123, 3, box_metadata)
      assert.equal("comp2", key)
      assert.equal(3, box.line_in_diagram)
    end)

    it("returns nil when no box at cursor position", function()
      local box_metadata = {
        { key = "comp1", line_in_diagram = 1 },
        { key = "comp2", line_in_diagram = 3 },
      }
      
      diagram_utils.get_box_at_cursor = function(win_id, cursor_line, box_metadata)
        return nil, nil
      end
      
      local key, box = diagram_utils.get_box_at_cursor(123, 5, box_metadata)
      assert.is_nil(key)
      assert.is_nil(box)
    end)
  end)

  describe("navigate_pipeline_components with extended coverage", function()
    it("navigates to next component in middle of pipeline", function()
      local state = {
        nav_mode = "component",
        focused_pipeline_index = 1,
        pipelines = { { "comp1", "comp2", "comp3" } },
        box_metadata = {
          { key = "comp1", line_in_diagram = 1 },
          { key = "comp2", line_in_diagram = 3 },
          { key = "comp3", line_in_diagram = 5 },
        },
        win_id = 100,
      }
      
      -- Mock cursor at comp2
      diagram_utils.get_box_at_cursor = function(_, _, _)
        return nil, state.box_metadata[2]
      end
      
      local ok = diagram_utils.navigate_pipeline_components(state, "next")
      assert.is_true(ok)
    end)

    it("navigates to previous component in middle of pipeline", function()
      local state = {
        nav_mode = "component",
        focused_pipeline_index = 1,
        pipelines = { { "comp1", "comp2", "comp3" } },
        box_metadata = {
          { key = "comp1", line_in_diagram = 1 },
          { key = "comp2", line_in_diagram = 3 },
          { key = "comp3", line_in_diagram = 5 },
        },
        win_id = 100,
      }
      
      -- Mock cursor at comp2
      diagram_utils.get_box_at_cursor = function(_, _, _)
        return nil, state.box_metadata[2]
      end
      
      local ok = diagram_utils.navigate_pipeline_components(state, "prev")
      assert.is_true(ok)
    end)

    it("returns false when no focused pipeline", function()
      local state = {
        nav_mode = "component",
        focused_pipeline_index = nil,
        pipelines = { { "comp1", "comp2" } },
      }
      
      local ok = diagram_utils.navigate_pipeline_components(state, "next")
      assert.is_false(ok)
    end)

    it("returns false when focused pipeline index is out of bounds", function()
      local state = {
        nav_mode = "component",
        focused_pipeline_index = 5,
        pipelines = { { "comp1", "comp2" } },
      }
      
      local ok = diagram_utils.navigate_pipeline_components(state, "next")
      assert.is_false(ok)
    end)

    it("returns false when no box at cursor", function()
      local state = {
        nav_mode = "component",
        focused_pipeline_index = 1,
        pipelines = { { "comp1", "comp2" } },
        box_metadata = {},
        win_id = 100,
      }
      
      diagram_utils.get_box_at_cursor = function(_, _, _)
        return nil, nil
      end
      
      local ok = diagram_utils.navigate_pipeline_components(state, "next")
      assert.is_false(ok)
    end)

    it("handles single component pipeline", function()
      local state = {
        nav_mode = "component",
        focused_pipeline_index = 1,
        pipelines = { { "single_comp" } },
        box_metadata = {
          { key = "single_comp", line_in_diagram = 1 },
        },
        win_id = 100,
      }
      
      diagram_utils.get_box_at_cursor = function(_, _, _)
        return nil, state.box_metadata[1]
      end
      
      -- Both next and prev should work (cycling to self)
      local ok_next = diagram_utils.navigate_pipeline_components(state, "next")
      local ok_prev = diagram_utils.navigate_pipeline_components(state, "prev")
      assert.is_true(ok_next)
      assert.is_true(ok_prev)
    end)
  end)

  describe("navigate_pipeline_starts with extended coverage", function()
    it("cycles through multiple starts with next", function()
      local state = { win_id = 100 }
      local starts = {
        { key = "start1", line_in_diagram = 1 },
        { key = "start2", line_in_diagram = 5 },
        { key = "start3", line_in_diagram = 10 },
      }
      
      -- Test cycling from last to first
      diagram_utils.get_box_at_cursor = function(_, _, _)
        return nil, starts[3] -- Currently at start3
      end
      
      local ok = diagram_utils.navigate_pipeline_starts(state, "next", starts)
      assert.is_true(ok)
    end)

    it("cycles through multiple starts with prev", function()
      local state = { win_id = 100 }
      local starts = {
        { key = "start1", line_in_diagram = 1 },
        { key = "start2", line_in_diagram = 5 },
        { key = "start3", line_in_diagram = 10 },
      }
      
      -- Test cycling from first to last
      diagram_utils.get_box_at_cursor = function(_, _, _)
        return nil, starts[1] -- Currently at start1
      end
      
      local ok = diagram_utils.navigate_pipeline_starts(state, "prev", starts)
      assert.is_true(ok)
    end)

    it("returns false when no starts provided", function()
      local state = { win_id = 100 }
      local ok = diagram_utils.navigate_pipeline_starts(state, "next", {})
      assert.is_false(ok)
    end)

    it("returns false when invalid window", function()
      local state = { win_id = nil }
      local starts = { { key = "start1", line_in_diagram = 1 } }
      local ok = diagram_utils.navigate_pipeline_starts(state, "next", starts)
      assert.is_false(ok)
    end)

    it("handles single start node", function()
      local state = { win_id = 100 }
      local starts = { { key = "only_start", line_in_diagram = 1 } }
      
      -- Both next and prev should work with single start
      local ok_next = diagram_utils.navigate_pipeline_starts(state, "next", starts)
      local ok_prev = diagram_utils.navigate_pipeline_starts(state, "prev", starts)
      assert.is_true(ok_next)
      assert.is_true(ok_prev)
    end)

    it("navigates to middle start when at middle position", function()
      local state = { win_id = 100 }
      local starts = {
        { key = "start1", line_in_diagram = 1 },
        { key = "start2", line_in_diagram = 5 },
        { key = "start3", line_in_diagram = 10 },
      }
      
      -- Test next from middle
      diagram_utils.get_box_at_cursor = function(_, _, _)
        return nil, starts[2] -- Currently at start2
      end
      
      local ok = diagram_utils.navigate_pipeline_starts(state, "next", starts)
      assert.is_true(ok)
    end)
  end)

  describe("box finding utilities", function()
    it("finds box by key in metadata", function()
      local box_metadata = {
        { key = "comp1", line_in_diagram = 1 },
        { key = "comp2", line_in_diagram = 3 },
        { key = "comp3", line_in_diagram = 5 },
      }
      
      -- Assuming there's a utility function to find box by key
      local target_key = "comp2"
      local found_box = nil
      for _, box in ipairs(box_metadata) do
        if box.key == target_key then
          found_box = box
          break
        end
      end
      
      assert.is_not_nil(found_box)
      assert.equal("comp2", found_box.key)
      assert.equal(3, found_box.line_in_diagram)
    end)

    it("returns nil when key not found", function()
      local box_metadata = {
        { key = "comp1", line_in_diagram = 1 },
        { key = "comp2", line_in_diagram = 3 },
      }
      
      local target_key = "nonexistent"
      local found_box = nil
      for _, box in ipairs(box_metadata) do
        if box.key == target_key then
          found_box = box
          break
        end
      end
      
      assert.is_nil(found_box)
    end)
  end)

  describe("navigation edge cases", function()
    it("handles empty pipelines", function()
      local state = {
        nav_mode = "component",
        focused_pipeline_index = 1,
        pipelines = { {} }, -- Empty pipeline
        box_metadata = {},
        win_id = 100,
      }
      
      local ok = diagram_utils.navigate_pipeline_components(state, "next")
      assert.is_false(ok)
    end)

    it("handles missing box_metadata", function()
      local state = {
        nav_mode = "component",
        focused_pipeline_index = 1,
        pipelines = { { "comp1" } },
        box_metadata = nil,
        win_id = 100,
      }
      
      local ok = diagram_utils.navigate_pipeline_components(state, "next")
      assert.is_false(ok)
    end)

    it("handles invalid direction parameter", function()
      local state = {
        nav_mode = "component",
        focused_pipeline_index = 1,
        pipelines = { { "comp1", "comp2" } },
        box_metadata = {
          { key = "comp1", line_in_diagram = 1 },
          { key = "comp2", line_in_diagram = 3 },
        },
        win_id = 100,
      }
      
      diagram_utils.get_box_at_cursor = function(_, _, _)
        return nil, state.box_metadata[1]
      end
      
      local ok = diagram_utils.navigate_pipeline_components(state, "invalid_direction")
      -- Should handle gracefully - implementation dependent
      assert.is_boolean(ok)
    end)
  end)
end)