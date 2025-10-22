local popup = require("ui.popup")
local config = require("main._core.configuration")

local M = {}

local function get_diagram_help(diagram_type)
	config.initialize_data_if_needed()
	local keymaps = config.DATA.keymaps

	local function get_key(action_name)
		local keymap_config = keymaps[action_name]
		if keymap_config and type(keymap_config) == "table" and #keymap_config >= 2 then
			return keymap_config[2]
		end
		return "?"
	end

	local content = {
		"Diagram Keymaps:",
		string.format(
			"• %-22s %s",
			get_key("navigate-next") .. " / " .. get_key("navigate-prev"),
			"Cycle through components"
		),
		string.format("• %-22s %s", get_key("go-to-definition"), "Jump to component's definition"),
		string.format(
			"• %-22s %s",
			get_key("scroll-source-up") .. " / " .. get_key("scroll-source-down"),
			"Scroll the source code buffer"
		),
		string.format("• %-22s %s", get_key("show-component-code"), "Show component code/diff"),
		string.format("• %-22s %s", get_key("run-e2e-test-from-diagram"), "Run the E2E test suite"),
		string.format("• %-22s %s", get_key("run-pipeline-test-from-diagram"), "Run test for the current pipeline"),
		string.format("• %-22s %s", get_key("edit-override-file"), "Edit the override file"),
		"",
	}

	if diagram_type == "horizontal" then
		table.insert(
			content,
			2,
			string.format("• %-22s %s", get_key("toggle-pipeline-focus"), 'Toggle "focus mode" on a pipeline')
		)
	else -- vertical
		table.insert(content, 2, string.format("• %-22s %s", get_key("add-new-component"), "Add a new component"))
		table.insert(content, 3, string.format("• %-22s %s", "f", "Set a new filter"))
		table.insert(content, 4, string.format("• %-22s %s", "c", "Clear the current filter"))
	end

	table.insert(content, "")
	table.insert(content, "Shared Keymaps:")
	table.insert(content, string.format("• %-22s %s", get_key("close-diagram-buffer"), "Close the diagram window"))
	table.insert(content, string.format("• %-22s %s", get_key("show-help-popup"), "Show this help popup"))
	table.insert(content, "")
	table.insert(content, "Press 'q' or <Esc> to close this help popup.")

	return content
end

local function get_test_runner_help()
	return {
		"This script runs an E2E test by replacing Alloy blocks",
		"from your buffer with overrides found in the `.alloy_tests`",
		"directory.",
		"",
		"Keymaps in this Log Window:",
		"• q:         Hide this log window.",
		"• <C-k>:     Jump back to the source code window.",
		"• g?:        Show this help popup.",
		"",
		"Global Keymaps (in .alloy files):",
		"• <leader>tar: Run test from current buffer.",
		"• <leader>taR: Rerun the last test exactly.",
		"• <leader>tas: Toggle the last test summary report.",
		"• <leader>tal: Toggle visibility of the test log window.",
		"• <C-j>:     Jump from source code to this window (if visible).",
		"",
		"Press 'q' or <Esc> to close this help popup.",
	}
end

function M.show_help(help_type)
	local content
	local title
	if help_type == "horizontal" or help_type == "vertical_list" then
		content = get_diagram_help(help_type)
		title = "❓ Diagram Help"
	else
		content = get_test_runner_help()
		title = "❓ Test Runner Help"
	end

	popup.create_popup(content, {
		title = title,
		border = "double",
	})
end

return M
