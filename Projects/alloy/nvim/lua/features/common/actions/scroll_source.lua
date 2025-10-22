local M = {}

local state = require("features.common.state")

local function _scroll_source_buffer(direction)
	local current_state = state.get_state()
	if not current_state or not current_state.source_bufnr then
		return
	end
	local source_win_id = vim.fn.bufwinid(current_state.source_bufnr)
	if source_win_id == -1 then
		return
	end
	local command = (direction == "up") and "normal! \x15" or "normal! \x04"
	vim.fn.win_execute(source_win_id, command)
end

function M.scroll_source_up()
	_scroll_source_buffer("up")
end

function M.scroll_source_down()
	_scroll_source_buffer("down")
end

return M