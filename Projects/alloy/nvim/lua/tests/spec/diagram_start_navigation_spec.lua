-- ensure plugin lua dir is on package.path
local repo_root = vim.fn.getcwd()
package.path = repo_root .. "/lua/?.lua;" .. repo_root .. "/lua/?/init.lua;" .. package.path

local diagram_utils = require("ui.diagram_utils")

describe("diagram_utils.navigate_pipeline_starts", function()
  it("jumps to first pipeline start when no box at cursor and direction next", function()
    local state = { win_id = 100 }
    local starts = {
      { key = "s1", line_in_diagram = 1 },
      { key = "s2", line_in_diagram = 5 },
    }
    -- When no current box, function should jump to first for 'next'.
    local ok = diagram_utils.navigate_pipeline_starts(state, "next", starts)
    assert.is_true(ok)
  end)

  it("jumps to last pipeline start when no box at cursor and direction prev", function()
    local state = { win_id = 100 }
    local starts = {
      { key = "s1", line_in_diagram = 1 },
      { key = "s2", line_in_diagram = 5 },
    }
    local ok = diagram_utils.navigate_pipeline_starts(state, "prev", starts)
    assert.is_true(ok)
  end)
end)
