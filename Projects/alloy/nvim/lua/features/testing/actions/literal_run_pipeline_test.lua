local utils = require("core.utils")
local e2e_runner = require("features.testing.utils.e2e_runner")

local M = {}

-- Need to be set from init.lua
M.run_function = nil

function M.run_pipeline_test(opts)
	opts = opts or {}
	local source_bufnr = opts.source_bufnr or vim.api.nvim_get_current_buf()
	local logger = e2e_runner.create_logger()

	if not utils.validate_buffer(source_bufnr) then
		logger.error("Invalid buffer provided for pipeline test run.")
		return false
	end

	local parser = require("core.parser")
	local components, all_chains_by_key, _ = parser.get_parsed_pipeline_data(source_bufnr)
	if not components or not all_chains_by_key or #all_chains_by_key == 0 then
		logger.error("No pipelines found in the current buffer.")
		return
	end

	local cursor_component_key = utils.get_cursor_component_key(source_bufnr, components)
	local chains_to_consider = all_chains_by_key
	local prompt = "Select a pipeline to test:"

	if cursor_component_key then
		local relevant_chains = vim.tbl_filter(function(chain)
			return vim.tbl_contains(chain, cursor_component_key)
		end, all_chains_by_key)
		if #relevant_chains > 0 then
			chains_to_consider = relevant_chains
			prompt = "Component is in multiple pipelines. Select one to test:"
		end
	end

	if #chains_to_consider == 1 then
		local a_chain = chains_to_consider[1]
		local pipeline_components = {}
		for _, component_key in ipairs(a_chain) do
			table.insert(pipeline_components, components[component_key])
		end
		vim.api.nvim_buf_clear_namespace(source_bufnr, e2e_runner.ns_id_pipeline_test_hl, 0, -1)
		for _, component in ipairs(pipeline_components) do
			for i = component.line - 1, component.end_line - 1 do
				vim.api.nvim_buf_add_highlight(
					source_bufnr,
					e2e_runner.ns_id_pipeline_test_hl,
					"AlloyTestedPipelineHighlight",
					i,
					0,
					-1
				)
			end
		end
		if M.run_function then
			M.run_function({
				source_bufnr = source_bufnr,
				pipeline_components = pipeline_components,
			})
		else
			logger.error("Run function not properly initialized.")
		end
		return
	end

	local pipeline_choices = {}
	local choice_to_chain_map = {}
	for i, chain in ipairs(chains_to_consider) do
		local start_node_key = chain[1]
		local start_node = components[start_node_key]
		local end_node_key = chain[#chain]
		local end_node = components[end_node_key]
		local choice_text = string.format(
			"Pipeline %d: %s.%s -> %s.%s",
			i,
			start_node.type,
			start_node.label,
			end_node.type,
			end_node.label
		)
		table.insert(pipeline_choices, choice_text)
		choice_to_chain_map[choice_text] = chain
	end

	vim.ui.select(pipeline_choices, { prompt = prompt }, function(choice)
		if not choice then
			logger.info("Test cancelled.")
			return
		end
		local selected_pipeline_chain = choice_to_chain_map[choice]
		local pipeline_components = {}
		for _, component_key in ipairs(selected_pipeline_chain) do
			table.insert(pipeline_components, components[component_key])
		end
		vim.api.nvim_buf_clear_namespace(source_bufnr, e2e_runner.ns_id_pipeline_test_hl, 0, -1)
		for _, component in ipairs(pipeline_components) do
			for i = component.line - 1, component.end_line - 1 do
				vim.api.nvim_buf_add_highlight(
					source_bufnr,
					e2e_runner.ns_id_pipeline_test_hl,
					"AlloyTestedPipelineHighlight",
					i,
					0,
					-1
				)
			end
		end
		if M.run_function then
			M.run_function({
				source_bufnr = source_bufnr,
				pipeline_components = pipeline_components,
			})
		else
			logger.error("Run function not properly initialized.")
		end
	end)
end

return M
