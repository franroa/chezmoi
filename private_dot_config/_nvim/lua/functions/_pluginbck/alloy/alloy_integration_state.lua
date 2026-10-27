-- ==============================================================================
-- Alloy Tooling Integration State
--
-- This module acts as a simple, shared state bridge between the E2E test
-- runner and the pipeline visualizer.
-- ==============================================================================

local M = {
  --- DEBUG: Set this to true to enable detailed notifications for debugging.
  debug = false,

  visualizer_module = nil,
  overridden_components = {},
  last_summary_data = nil,
}

--- DEBUG: Shared notification function.
-- It checks the debug flag before sending a notification.
-- @param msg string The message to display.
-- @param level integer|nil vim.log.levels value (e.g., INFO, WARN, ERROR).
function M.notify_debug(msg, level)
  if M.debug then
    vim.notify("[Alloy Tools] " .. msg, level or vim.log.levels.INFO)
  end
end

return M
