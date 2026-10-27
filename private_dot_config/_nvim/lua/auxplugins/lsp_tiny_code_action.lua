return {
  "rachartier/tiny-code-action.nvim",
  dependencies = {
    { "nvim-lua/plenary.nvim" },
  },
  event = "LspAttach",
  opts = {
    --- The backend to use, currently only "vim", "delta" and "difftastic" are supported
    backend = "delta",
    -- The picker to use, "telescope", "snacks", "select" are supported
    -- If you want to use the `fzf-lua` picker, you can simply set it to `select`
    picker = "snacks",
    backend_opts = {
      delta = {
        -- Header from delta can be quite large.
        -- You can remove them by setting this to the number of lines to remove
        header_lines_to_remove = 4,

        -- The arguments to pass to delta
        -- If you have a custom configuration file, you can set the path to it like so:
        args = {
          "--config" .. os.getenv("HOME") .. "/.config/delta/config.yml",
        },
        -- args = {
        --   "--line-numbers",
        -- },
      },
      difftastic = {
        -- Header from delta can be quite large.
        -- You can remove them by setting this to the number of lines to remove
        header_lines_to_remove = 1,

        -- The arguments to pass to difftastic
        args = {
          "--color=always",
          "--display=inline",
          "--syntax-highlight=on",
        },
      },
    },
    -- The icons to use for the code actions
    -- You can add your own icons, you just need to set the exact action's kind of the code action
    -- You can set the highlight like so: { link = "DiagnosticError" } or  like nvim_set_hl ({ fg ..., bg..., bold..., ...})
    signs = {
      quickfix = { "󰁨", { link = "DiagnosticInfo" } },
      others = { "?", { link = "DiagnosticWarning" } },
      refactor = { "", { link = "DiagnosticWarning" } },
      ["refactor.move"] = { "󰪹", { link = "DiagnosticInfo" } },
      ["refactor.extract"] = { "", { link = "DiagnosticError" } },
      ["source.organizeImports"] = { "", { link = "DiagnosticWarning" } },
      ["source.fixAll"] = { "", { link = "DiagnosticError" } },
      ["source"] = { "", { link = "DiagnosticError" } },
      ["rename"] = { "󰑕", { link = "DiagnosticWarning" } },
      ["codeAction"] = { "", { link = "DiagnosticError" } },
    },
  },
}
