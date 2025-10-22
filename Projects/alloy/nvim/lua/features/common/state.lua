local M = {}

--@class AlloyDiagramState
--@field win_id integer | nil
--@field container_win_id integer | nil
--@field original_container_height integer | nil
--@field buf integer | nil
--@field box_metadata table | nil
--@field source_bufnr integer | nil
--@field type string | nil
--@field popup_win_id integer | nil
--@field help_popup_win_id integer | nil
--@field pipelines table | nil
--@field components table | nil
--@field nav_mode string | nil
--@field focused_pipeline_index integer | nil
--@field total_content_width integer | nil
--@field last_focused_component string | nil
--@field last_source_component string | nil

--@type AlloyDiagramState | nil
M.diagram_state = nil
M._is_syncing = false

--- Resets the diagram state.
function M.reset_state()
  M.diagram_state = nil
  M._is_syncing = false
end

--- Gets the current diagram state.
--@return AlloyDiagramState | nil
function M.get_state()
  return M.diagram_state
end

--- Sets the diagram state.
--@param state AlloyDiagramState
function M.set_state(state)
  M.diagram_state = state
end

--- Updates a specific field in the diagram state.
--@param key string
--@param value any
function M.update_state(key, value)
  if M.diagram_state then
    M.diagram_state[key] = value
  end
end

--- Checks if the visualizer is currently syncing.
--@return boolean
function M.is_syncing()
  return M._is_syncing
end

--- Sets the syncing status.
--@param syncing boolean
function M.set_syncing(syncing)
  M._is_syncing = syncing
end

return M
