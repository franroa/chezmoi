-- ensure plugin lua dir is on package.path
local repo_root = vim.fn.getcwd()
package.path = repo_root .. "/lua/?.lua;" .. repo_root .. "/lua/?/init.lua;" .. package.path

local diagram_utils = require("ui.diagram_utils")

describe("diagram_utils.navigate_pipeline_components", function()
  local orig_get_box

  setup(function()
    -- preserve original
    orig_get_box = diagram_utils.get_box_at_cursor
  end)

  teardown(function()
    diagram_utils.get_box_at_cursor = orig_get_box
  end)

  it("cycles next from last to first in focused pipeline", function()
    local state = {
      nav_mode = "component",
      focused_pipeline_index = 1,
      pipelines = { { "a", "b", "c" } },
      box_metadata = {
        { key = "a", line_in_diagram = 1 },
        { key = "b", line_in_diagram = 2 },
        { key = "c", line_in_diagram = 3 },
      },
      win_id = 100,
    }

    -- stub get_box_at_cursor to return the last component as the current box
    diagram_utils.get_box_at_cursor = function(_, _, _)
      return nil, state.box_metadata[3]
    end

    -- Call navigate; it should return truthy (jump succeeded)
    local ok = diagram_utils.navigate_pipeline_components(state, "next")
    assert.is_true(ok)
  end)

  it("cycles prev from first to last in focused pipeline", function()
    local state = {
      nav_mode = "component",
      focused_pipeline_index = 1,
      pipelines = { { "a", "b", "c" } },
      box_metadata = {
        { key = "a", line_in_diagram = 1 },
        { key = "b", line_in_diagram = 2 },
        { key = "c", line_in_diagram = 3 },
      },
      win_id = 100,
    }

    -- stub get_box_at_cursor to return the first component as the current box
    diagram_utils.get_box_at_cursor = function(_, _, _)
      return nil, state.box_metadata[1]
    end

    local ok = diagram_utils.navigate_pipeline_components(state, "prev")
    assert.is_true(ok)
  end)

  it("returns false when not in component nav_mode", function()
    local state = { nav_mode = "pipeline" }
    local ok = diagram_utils.navigate_pipeline_components(state, "next")
    assert.is_false(ok)
  end)

  it("returns false when cursor component not in focused pipeline", function()
    local state = {
      nav_mode = "component",
      focused_pipeline_index = 1,
      pipelines = { { "a", "b" } },
      box_metadata = { { key = "x", line_in_diagram = 1 } },
      win_id = 100,
    }
    diagram_utils.get_box_at_cursor = function(_, _, _)
      return nil, state.box_metadata[1]
    end
    local ok = diagram_utils.navigate_pipeline_components(state, "next")
    assert.is_false(ok)
  end)
end)
