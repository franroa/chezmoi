-- ensure plugin lua dir is on package.path
local repo_root = vim.fn.getcwd()
package.path = repo_root .. "/lua/?.lua;" .. repo_root .. "/lua/?/init.lua;" .. package.path

local state = require("features.common.state")

describe("visualizer state management", function()
	before_each(function()
		state.reset_state()
	end)

	after_each(function()
		state.reset_state()
	end)

	describe("state.reset_state", function()
		it("resets state to nil", function()
			state.set_state({ win_id = 123 })
			assert.is_not_nil(state.get_state())

			state.reset_state()

			assert.is_nil(state.get_state())
			assert.is_false(state.is_syncing())
		end)
	end)

	describe("state.get_state and state.set_state", function()
		it("stores and retrieves state correctly", function()
			local test_state = {
				win_id = 123,
				buf = 456,
				nav_mode = "component",
				focused_pipeline_index = 1,
			}

			state.set_state(test_state)
			local retrieved = state.get_state()

			assert.are.same(test_state, retrieved)
		end)

		it("returns nil when no state is set", function()
			assert.is_nil(state.get_state())
		end)
	end)

	describe("state.update_state", function()
		it("updates existing state fields", function()
			local initial_state = {
				win_id = 123,
				nav_mode = "pipeline",
			}

			state.set_state(initial_state)
			state.update_state("nav_mode", "component")
			state.update_state("focused_pipeline_index", 2)

			local updated = state.get_state()
			assert.equal("component", updated.nav_mode)
			assert.equal(2, updated.focused_pipeline_index)
			assert.equal(123, updated.win_id) -- Original field preserved
		end)

		it("does nothing when state is nil", function()
			state.update_state("win_id", 123)
			assert.is_nil(state.get_state())
		end)

		it("can add new fields to existing state", function()
			state.set_state({ win_id = 123 })
			state.update_state("new_field", "new_value")

			local updated = state.get_state()
			assert.equal("new_value", updated.new_field)
			assert.equal(123, updated.win_id)
		end)
	end)

	describe("syncing status", function()
		it("starts with syncing false", function()
			assert.is_false(state.is_syncing())
		end)

		it("can set and get syncing status", function()
			state.set_syncing(true)
			assert.is_true(state.is_syncing())

			state.set_syncing(false)
			assert.is_false(state.is_syncing())
		end)

		it("resets syncing status when resetting state", function()
			state.set_syncing(true)
			assert.is_true(state.is_syncing())

			state.reset_state()
			assert.is_false(state.is_syncing())
		end)
	end)

	describe("complete state object", function()
		it("handles all expected state fields", function()
			local complete_state = {
				win_id = 123,
				container_win_id = 456,
				original_container_height = 40,
				buf = 789,
				box_metadata = { { key = "test", line_in_diagram = 1 } },
				source_bufnr = 111,
				type = "visualizer",
				popup_win_id = 222,
				help_popup_win_id = 333,
				pipelines = { { "comp1", "comp2" } },
				components = { comp1 = { type = "test", label = "test" } },
				nav_mode = "component",
				focused_pipeline_index = 1,
				total_content_width = 100,
				last_focused_component = "comp1",
				last_source_component = "comp2",
			}

			state.set_state(complete_state)
			local retrieved = state.get_state()

			assert.are.same(complete_state, retrieved)
		end)
	end)
end)
