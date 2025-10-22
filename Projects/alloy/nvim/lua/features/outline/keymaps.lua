local M = {}

--- Outline (vertical diagram) specific keymaps
--- Default keybindings are defined in the ACTIONS object below
--- and can be overridden in user configuration
--- Also includes common diagram keymaps via common_keymaps.setup_keymaps()

local state = require("features.common.state")
local keymap_utils = require("core.keymap_utils")
local main_keymaps = require("main.keymaps")
local actions = require("features.outline.actions")

local ACTIONS = {
	["diagram-sync-save"] = {
		func = actions.diagram_sync_save,
		desc = "Save block to .alloy",
		default = { "n", "<C-s>" },
	},
	["diagram-filter"] = { func = actions.diagram_filter, desc = "Filter diagram", default = { "n", "f" } },
	["filter-by-cursor"] = {
		func = actions.filter_by_cursor,
		desc = "Filter by component under cursor",
		default = { "n", "F" },
	},
	["filter-current-component"] = {
		func = actions.filter_current_component,
		desc = "Filter by current component",
		default = { "n", "<S-f>" },
	},
	["clear-filter"] = { func = actions.clear_filter, desc = "Clear filter", default = { "n", "c" } },
}

function M.setup_keymaps()
	main_keymaps.setup_keymaps()
	local current_state = state.get_state()
	if not current_state then
		return
	end
	local buf = current_state.buf
	keymap_utils.setup_default_keymaps(ACTIONS, { buffer = buf, silent = true })
end

function M.get_actions()
	return ACTIONS
end

-- Make the register function available through this module as well
M.register = keymap_utils.register

return M
