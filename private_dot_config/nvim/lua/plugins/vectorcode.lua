return {
  "Davidyz/VectorCode",
  version = "*", -- optional, depending on whether you're on nightly or release
  build = "pipx upgrade vectorcode", -- optional but recommended if you set `version = "*"`
  lazy = false,
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("vectorcode").setup({
      -- number of retrieved documents
      n_query = 1,
    })
    local has_vc, vectorcode_config = pcall(require, "vectorcode.config")
    local vectorcode_cacher = nil
    if has_vc then
      vectorcode_cacher = vectorcode_config.get_cacher_backend()
    end

    -- -- roughly equate to 2000 tokens for LLM
    -- local RAG_Context_Window_Size = 8000

    -- local gemini = {
    --   model = "gemini-2.5-pro",
    --   system = {
    --     template = "{{{prompt}}}\n{{{guidelines}}}\n{{{n_completion_template}}}\n{{{repo_context}}}",
    --     repo_context = [[9. Additional context from other files in the repository will be enclosed in <repo_context> tags. Each file will be separated by <file_separator> tags, containing its relative path and content.]],
    --   },
    --   chat_input = {
    --     template = "{{{repo_context}}}\n{{{language}}}\n{{{tab}}}\n<contextBeforeCursor>\n{{{context_before_cursor}}}<cursorPosition>\n<contextAfterCursor>\n{{{context_after_cursor}}}",
    --     repo_context = function(_, _, _)
    --       local prompt_message = ""
    --       if has_vc then
    --         local cache_result = vectorcode_cacher.query_from_cache(0)
    --         for _, file in ipairs(cache_result) do
    --           prompt_message = prompt_message .. "<file_separator>" .. file.path .. "\n" .. file.document
    --         end
    --       end
    --
    --       prompt_message = vim.fn.strcharpart(prompt_message, 0, RAG_Context_Window_Size)
    --
    --       if prompt_message ~= "" then
    --         prompt_message = "<repo_context>\n" .. prompt_message .. "\n</repo_context>"
    --       end
    --       return prompt_message
    --     end,
    --   },
    -- }
    --
    -- require("minuet").setup({
    --   provider = "gemini",
    --   provider_options = {
    --     gemini = gemini,
    --   },
    -- })
  end,
}
