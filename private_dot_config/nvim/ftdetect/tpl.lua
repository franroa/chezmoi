-- *.tpl files are ambiguous:
--   * <chart>/templates/*.tpl          -> helm (go templates)
--   * *.alloy.tpl                       -> alloy
--   * anything else (values.tpl, ...)   -> yaml; they are terraform templatefile() inputs
local function in_chart(path)
  return vim.fs.root(path, "Chart.yaml") ~= nil
end

vim.filetype.add({
  pattern = {
    [".*%.alloy%.tpl"] = { "alloy", { priority = 20 } },
    [".*%.tpl"] = {
      function(path)
        return (path:find("/templates/", 1, true) and in_chart(path)) and "helm" or "yaml"
      end,
      { priority = 10 },
    },
    -- helm chart templates
    [".*/templates/.*%.ya?ml"] = {
      function(path)
        return in_chart(path) and "helm" or nil
      end,
      { priority = 10 },
    },
    -- chart values -> helm_ls + yamlls
    ["values.*%.ya?ml"] = {
      function(path)
        return vim.uv.fs_stat(vim.fs.dirname(path) .. "/Chart.yaml") and "yaml.helm-values" or nil
      end,
      { priority = 10 },
    },
    ["helmfile.*%.ya?ml"] = { "helm", { priority = 10 } },
  },
  extension = {
    gotmpl = "helm",
  },
})
