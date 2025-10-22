local M = {}

local visualizer = require("features.init")

function M.show_numbers()
	return visualizer.show_pipeline_numbers()
end

function M.create_diagram()
	return visualizer.create_pipeline_diagram()
end

function M.create_vertical_diagram(filter_word)
	return visualizer.create_vertical_pipeline_diagram(filter_word)
end

function M.jump_next()
	return visualizer.jump_to_next_component()
end

function M.jump_prev()
	return visualizer.jump_to_previous_component()
end

function M.jump_next_block()
	return visualizer.jump_to_next_block_in_file()
end

function M.jump_prev_block()
	return visualizer.jump_to_previous_block_in_file()
end

function M.edit_override()
	return visualizer.edit_override_file()
end

function M.show_override_icons()
	return visualizer.show_override_icons_in_buffer()
end

function M.clear_override_icons()
	return visualizer.clear_override_icons_in_buffer()
end

function M.show_diff()
	return visualizer.show_diff_popup_from_buffer()
end

return M
