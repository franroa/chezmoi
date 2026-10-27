return {
  "cousine/opencode-context.nvim",
  opts = {
    tmux_target = nil, -- Manual override: "session:window.pane"
    auto_detect_pane = true, -- Auto-detect opencode pane in current window
  },
  keys = {
    { "<leader>Oc", "<cmd>OpencodeSend<cr>", desc = "Send prompt to opencode" },
    { "<leader>Oc", "<cmd>OpencodeSend<cr>", mode = "v", desc = "Send prompt to opencode" },
    { "<leader>Ot", "<cmd>OpencodeSwitchMode<cr>", desc = "Toggle opencode mode" },
    { "<leader>Op", "<cmd>OpencodePrompt<cr>", desc = "Open opencode persistent prompt" },
  },
  cmd = { "OpencodeSend", "OpencodeSwitchMode" },
}
