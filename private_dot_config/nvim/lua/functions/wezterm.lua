local M = {}
-- changes the wezterm font size
function M.wezterm()
  local background = "#222436"

  if string.find(vim.g.kubernetes_cluster, "fran") or string.find(vim.g.kubernetes_cluster, "kind") then
    background = "#303b33"
  end

  if string.find(vim.g.kubernetes_cluster, "dev") then
    background = "#182f6d"
  end

  if string.find(vim.g.kubernetes_cluster, "stg") or string.find(vim.g.kubernetes_cluster, "prd") then
    background = "#ff0000"
  end

  local stdout = vim.loop.new_tty(1, false)
  stdout:write("\x1bPtmux;\x1b\x1b]11;" .. background .. "\b\x1b\\")
  -- stdout:write(
  --   ("\x1bPtmux;\x1b\x1b]1337;SetUserVar=%s=%s\b\x1b\\"):format(
  --     "K8S_CLUSTER",
  --     vim.fn.system({ "base64" }, tostring("kind-kind"))
  --   )
  -- )
  -- vim.cmd([[redraw]])
end

return M
