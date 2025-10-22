return {
  "psaia/prompt-ai.vim",
  config = function()
    require("prompt_ai").setup({
      model = "o4-mini", -- or "o4-mini" (default)
      temperature = 1, -- controls creativity (default: 1)
      max_history = 8, -- max prompt/response pairs remembered (default: 8)
    })
  end,
  cmd = { "P", "PClearHistory", "PClearCache" },
}
