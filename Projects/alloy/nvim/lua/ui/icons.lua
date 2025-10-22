local M = {}

M.futuristic_process_icons = {
  source = "",
  process = "",
  write = "󰒍",
  relabel = "",
  scrape = "󰥟",
  remote_write = "󰛶",
  file_match = "󰈞",
  file = "󰈞",
  default = "",
}

M.arrow_chars = {
  h = "─",
  v = "│",
  bl = "└",
  br = "┘",
  tr = "┐",
  arrow = "►",
  up = "▲",
  down = "▼"
}

function M.get_process_icon(process_name)
  return M.futuristic_process_icons[process_name] or M.futuristic_process_icons.default
end

return M
