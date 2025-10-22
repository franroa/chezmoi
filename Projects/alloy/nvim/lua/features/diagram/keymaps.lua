local M = {}

--- Diagram (horizontal) specific keymaps
--- Default keybindings are defined in the ACTIONS object below
--- and can be overridden in user configuration
--- Also includes common diagram keymaps via common_keymaps.setup_keymaps()

local state = require("features.common.state")
local keymap_utils = require("core.keymap_utils")
local main_keymaps = require("main.keymaps")
local actions = require("features.diagram.actions")

local ACTIONS = {
	["toggle-pipeline-focus"] = {
		func = actions.toggle_pipeline_focus,
		desc = "Toggle Pipeline Focus",
		default = { "n", "P" },
	},
	["navigate-next"] = { func = actions.navigate_next, desc = "Navigate Next", default = { "n", "<Tab>" } },
	["navigate-prev"] = { func = actions.navigate_prev, desc = "Navigate Previous", default = { "n", "<S-Tab>" } },
	["close-diagram-buffer"] = { func = actions.close_diagram_buffer, desc = "Close Diagram", default = { "n", "q" } },
	["debug-cursor"] = { func = actions.debug_cursor, desc = "Debug Cursor Position", default = { "n", "<leader>d" } },
}

function M.setup_keymaps()
	main_keymaps.setup_keymaps()
	local current_state = state.get_state()
	if not current_state then
		return
	end
	local buf = current_state.buf

	-- Pass the actions to the utility function to handle registration.
	-- The utility will handle checking the user's config for overrides.
	keymap_utils.setup_default_keymaps(ACTIONS, { buffer = buf, silent = true })
end

function M.get_actions()
	return ACTIONS
end

-- Make the register function available through this module as well
M.register = keymap_utils.register

return M
