local M = {}

-- Import all action modules
local follow_from_diagram = require("features.common.actions.follow_from_diagram")
local follow_component_in_diagram = require("features.common.actions.follow_component_in_diagram")
local show_override_icons_in_buffer = require("features.common.actions.show_override_icons_in_buffer")
local clear_override_icons_in_buffer = require("features.common.actions.clear_override_icons_in_buffer")
local show_diff_popup_from_buffer = require("features.common.actions.show_diff_popup_from_buffer")
local clear_pipeline_numbers = require("features.common.actions.clear_pipeline_numbers")
local jump_to_next_component = require("features.common.actions.jump_to_next_component")
local jump_to_previous_component = require("features.common.actions.jump_to_previous_component")
local jump_to_next_block_in_file = require("features.common.actions.jump_to_next_block_in_file")
local jump_to_previous_block_in_file = require("features.common.actions.jump_to_previous_block_in_file")
local scroll_source_up = require("features.common.actions.scroll_source_up")
local scroll_source_down = require("features.common.actions.scroll_source_down")
local go_to_definition = require("features.common.actions.go_to_definition")
local show_help_popup = require("features.common.actions.show_help_popup")
local run_pipeline_test_from_diagram = require("features.common.actions.run_pipeline_test_from_diagram")
local show_component_code = require("features.common.actions.show_component_code")
local edit_override_file = require("features.common.actions.edit_override_file")

-- Export all functions from the modules
M.FollowFromDiagram = follow_from_diagram.follow_from_diagram
M.FollowComponentInDiagram = follow_component_in_diagram.follow_component_in_diagram
M.show_override_icons_in_buffer = show_override_icons_in_buffer.show_override_icons_in_buffer
M.clear_override_icons_in_buffer = clear_override_icons_in_buffer.clear_override_icons_in_buffer
M.show_diff_popup_from_buffer = show_diff_popup_from_buffer.show_diff_popup_from_buffer
M.ClearPipelineNumbers = clear_pipeline_numbers.clear_pipeline_numbers
M.JumpToNextComponent = jump_to_next_component.jump_to_next_component
M.JumpToPreviousComponent = jump_to_previous_component.jump_to_previous_component
M.JumpToNextBlockInFile = jump_to_next_block_in_file.jump_to_next_block_in_file
M.JumpToPreviousBlockInFile = jump_to_previous_block_in_file.jump_to_previous_block_in_file
M.scroll_source_up = scroll_source_up.scroll_source_up
M.scroll_source_down = scroll_source_down.scroll_source_down
M.go_to_definition = go_to_definition.go_to_definition
M.show_help_popup = show_help_popup.show_help_popup
M.run_pipeline_test_from_diagram = run_pipeline_test_from_diagram.run_pipeline_test_from_diagram
M.show_component_code = show_component_code.show_component_code
M.edit_override_file = edit_override_file.edit_override_file

return M