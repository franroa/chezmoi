return {
  'yelog/i18n.nvim',
  dependencies = {
    'ibhagwan/fzf-lua',
    'nvim-treesitter/nvim-treesitter'
  },
  keys = {
    { "<leader>ik", function() require('i18n').i18n_keys() end,          desc = "Show i18n keys" },
    { "<leader>il", function() require('i18n').next_locale() end,        desc = "Switch to next locale" },
    { "<leader>io", function() require('i18n').toggle_origin() end,      desc = "Toggle origin overlay" },
    { "<leader>it", function() require('i18n').toggle_translation() end, desc = "Toggle translation" },
    {
      "gd",
      function()
        if require('i18n').i18n_definition() then
          return
        end
        vim.lsp.buf.definition()
      end,
      desc = "i18n or LSP definition"
    },
    {
      "gu",
      function()
        if require('i18n').i18n_key_usages() then
          return
        end
        vim.lsp.buf.references()
      end,
      desc = "i18n usages or LSP references"
    },
  },
  config = function()
    -- Get the project root by finding package.json
    local function find_project_root()
      local current_file = vim.api.nvim_buf_get_name(0)
      local current_dir = vim.fn.fnamemodify(current_file, ':h')

      -- Search up for package.json
      local root = vim.fs.find('package.json', {
        upward = true,
        path = current_dir,
      })[1]

      if root then
        return vim.fn.fnamemodify(root, ':h')
      end

      return vim.fn.getcwd()
    end

    local root = find_project_root()

    require('i18n').setup({
      locales = { 'en', 'es' },
      sources = {
        root .. '/src/i18n/locales/{locales}.json'
      },
      func_pattern = { '$t', 't' },
      func_type = { 'vue', 'typescript', 'javascript' },
      show_mode = 'translation_conceal',
      diagnostic = true,
    })

    print("i18n.nvim loaded with root:", root)
  end
}
