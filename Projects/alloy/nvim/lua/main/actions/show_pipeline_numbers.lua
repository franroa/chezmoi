local M = {}

local parser = require("core.parser")

local ns_id_pipeline_numbers = vim.api.nvim_create_namespace("AlloyPipelineNumbers")

function M.handle()
	vim.g.are_alloy_pipeline_number_shown = true
	local highlights = require("ui.highlights")
	highlights.setup_highlights()
	local current_buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_clear_namespace(current_buf, ns_id_pipeline_numbers, 0, -1)
	local components, all_chains_by_key, _ = parser.get_parsed_pipeline_data(current_buf)
	if not components or not all_chains_by_key then
		vim.notify("Could not analyze pipelines to show numbers.", vim.log.levels.WARN)
		return
	end
	local cursor_line = vim.fn.getpos(".")[2]
	local current_component_key = nil
	for key, comp_data in pairs(components) do
		if cursor_line >= comp_data.line and cursor_line <= comp_data.end_line then
			current_component_key = key
			break
		end
	end
	if not current_component_key then
		vim.notify("Cursor is not inside a recognized component block.", vim.log.levels.INFO)
		return
	end
	local chains_to_number = vim.tbl_filter(function(chain)
		return vim.tbl_contains(chain, current_component_key)
	end, all_chains_by_key)

	if #chains_to_number > 0 then
		local numbered_count, already_numbered = 0, {}
		for _, chain in ipairs(chains_to_number) do
			for i, key in ipairs(chain) do
				if not already_numbered[key] then
					local comp_data = components[key]
					if comp_data and comp_data.line then
						local icon_text = "  "
							.. i
							.. (
								(comp_data.forward_to and #comp_data.forward_to > 1)
									and ("  " .. #comp_data.forward_to)
								or ""
							)
						vim.api.nvim_buf_set_extmark(
							current_buf,
							ns_id_pipeline_numbers,
							comp_data.line - 1,
							0,
							{ virt_text = { { icon_text .. " ", "AlloyPipelineNumber" } }, virt_text_pos = "eol" }
						)
						already_numbered[key], numbered_count = true, numbered_count + 1
					end
				end
			end
		end
		vim.notify(
			string.format("Numbered %d component(s) across %d pipeline(s).", numbered_count, #chains_to_number),
			vim.log.levels.INFO
		)
	else
		vim.notify("Could not determine a pipeline for the current component.", vim.log.levels.WARN)
	end
end

return M
