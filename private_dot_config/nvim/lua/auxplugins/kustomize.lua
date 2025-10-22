return {
  "allaman/kustomize.nvim",
  -- dev = true,
  ft = "yaml",
  opts = {
    enable_lua_snip = true,
    kinds = {
      auto_close = true,
      show_filepath = true,
      show_line = true,
    },
    run = {
      deprecations29 = {
        args = { "-t", "1.29", "-c=false", "--helm3=false", "-l=error", "-e", "-f" },
        cmd = "kubent",
      },
      deprecations30 = {
        args = { "-t", "1.30", "-c=false", "--helm3=false", "-l=error", "-e", "-f" },
        cmd = "kubent",
      },
      trivy = {
        args = { "-q", "fs" },
        cmd = "trivy",
      },
    },
  },
  config = function(_, opts)
    require("which-key").add({
      { "<leader>k", group = "Kustomize" },
    })
    require("kustomize").setup(opts)
  end,
}
