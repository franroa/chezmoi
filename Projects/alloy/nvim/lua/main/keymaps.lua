local keymap_utils = require("core.keymap_utils")
local common_actions = require("features.common.actions")

local scroll_source_up = require("features.common.actions.scroll_source_up")
local scroll_source_down = require("features.common.actions.scroll_source_down")
local go_to_definition = require("features.common.actions.go_to_definition")
local show_help_popup = require("features.common.actions.show_help_popup")
local run_pipeline_test_from_diagram = require("features.common.actions.run_pipeline_test_from_diagram")
local show_component_code = require("features.common.actions.show_component_code")
local edit_override_file = require("features.common.actions.edit_override_file")

local M = {}

-- Global actions that work everywhere in alloy files
local ACTIONS = {
	["create-pipeline-diagram"] = {
		func = function()
			local focus_key = require("core.parser").get_key_under_cursor()
			require("features.diagram.init").CreatePipelineDiagram({ focus_key = focus_key })
		end,
		desc = "Show/Focus Pipeline Diagram (Horizontal)",
		default = { "n", "<leader>ap" },
	},
	["create-pipeline-vertical-diagram"] = {
		func = function()
			local focus_key = require("core.parser").get_key_under_cursor()
			require("features.outline.init").CreatePipelineDiagram(focus_key)
		end,
		desc = "Show/Focus Pipeline Diagram (Vertical)",
		default = { "n", "<leader>av" },
	},
	["jump-to-next-component"] = {
		func = common_actions.JumpToNextComponent,
		desc = "Jump to Next Component",
		default = { "n", "<leader>aj" },
	},
	["jump-to-previous-component"] = {
		func = common_actions.JumpToPreviousComponent,
		desc = "Jump to Previous Pipeline Component",
		default = { "n", "<leader>ak" },
	},
	["show-help"] = {
		func = require("features.common.ui").create_help_popup,
		desc = "Show help",
		default = { "n", "<leader>ah" },
	},
	["show-numbers"] = {
		func = require("main.actions.show_pipeline_numbers").handle,
		desc = "Show Pipeline Numbers",
		default = { "n", "<leader>an" },
	},
	["scroll-source-up"] = {
		func = scroll_source_up.scroll_source_up,
		desc = "Scroll Source Up",
		default = { "n", "<C-u>" },
	},
	["scroll-source-down"] = {
		func = scroll_source_down.scroll_source_down,
		desc = "Scroll Source Down",
		default = { "n", "<C-d>" },
	},
	["go-to-definition"] = {
		func = go_to_definition.go_to_definition,
		desc = "Go to Definition / Show Test Summary",
		default = { "n", "<CR>" },
	},
	["show-help-popup"] = {
		func = show_help_popup.show_help_popup,
		desc = "Show Help",
		default = { "n", "g?" },
	},
	["run-pipeline-test-from-diagram"] = {
		func = run_pipeline_test_from_diagram.run_pipeline_test_from_diagram,
		desc = "Run Pipeline Test",
		default = { "n", "<leader>r" },
	},
	["edit-override-file"] = {
		func = edit_override_file.edit_override_file,
		desc = "Edit Test Override File",
		default = { "n", "<leader>ae" },
	},
	["show-component-code"] = {
		func = show_component_code.show_component_code,
		desc = "Show Component Code",
		default = { "n", "<leader>s" },
	},
}

function M.setup_default_keymaps()
	keymap_utils.setup_default_keymaps(ACTIONS)
end

function M.setup_keymaps()
	local state = require("features.common.state")
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
