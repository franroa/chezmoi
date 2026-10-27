return {
  "yelog/i18n.nvim",
  config = function()
    local cwd = nil
    if os.getenv("GIT_WORK_TREE") == nil then
      cwd = LazyVim and LazyVim.root.git() or vim.fn.getcwd()
    else
      cwd = os.getenv("GIT_WORK_TREE")
    end
    require("i18n").setup({
      locales = { "en", "es" },
      sources = { cwd .. "/src/locales/{locales}.json" },
    })

    vim.keymap.set("n", "<leader>igd", function()
      -- Jump from an i18n key usage to its definition
      if require("i18n").i18n_definition() then
        return
      end
      -- Jump from current i18n definition to the next locale's definition, following the order in locales
      if require("i18n").i18n_definition_next_locale() then
        return
      end
      -- Fall back to LSP definition
      vim.lsp.buf.definition()
    end, { desc = "i18n or LSP definition" })

    vim.keymap.set("n", "<leader>ik", function()
      require("i18n").i18n_keys()
    end, { desc = "Show i18n keys" })

    vim.keymap.set("n", "<leader>it", function()
      require("i18n").toggle_translation()
    end, { desc = "Toggle Translation" })

    vim.keymap.set("n", "<leader>io", function()
      require("i18n").toggle_origin()
    end, { desc = "Toggle Origin" })

    vim.keymap.set("n", "<leader>il", function()
      require("i18n").next_locale()
    end, { desc = "Switch to next locale" })

    vim.keymap.set("n", "<leader>igu", function()
      if require("i18n").i18n_key_usages() then
        return
      end
      vim.lsp.buf.references()
    end, { desc = "i18n usages or LSP references" })
  end,
}
