vim.lsp.config("ts_go_ls", {
  cmd = { vim.loop.os_homedir() .. "/dev/typescript-go/built/local/tsgo", "lsp", "-stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
})
vim.lsp.enable("ts_go_ls")
