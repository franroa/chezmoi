local M = {}
function M.UpdateColors()
  local background = "#6c7414"

  if vim.g.kubernetes_cluster == "kind-kind" then
    vim.g.kubernetes_cluster_fg = "#2f601b"
    vim.g.kubernetes_namespace_fg = "#182f6d"
    vim.g.kubernetes_cluster_bg = background
    vim.g.kubernetes_namespace_bg = background
  end

  if string.find(vim.g.kubernetes_cluster, "dev") then
    vim.g.kubernetes_cluster_fg = "#922e20"
    vim.g.kubernetes_namespace_fg = "#182f6d"
    vim.g.kubernetes_cluster_bg = background
    vim.g.kubernetes_namespace_bg = background
  end

  if string.find(vim.g.kubernetes_cluster, "prd") or string.find(vim.g.kubernetes_cluster, "stg") then
    vim.g.kubernetes_cluster_fg = "Green"
    vim.g.kubernetes_namespace_fg = "Blue"
    vim.g.kubernetes_cluster_bg = background
    vim.g.kubernetes_namespace_bg = background
  end
end

function M.UpdateGlobalValuesForTheFirstTime()
  local cluster = os.getenv("K8S_CLUSTER")
  if cluster == "__None__" then
    vim.g.kubernetes_namespace = ""
    vim.g.kubernetes_cluster = ""
    return
  end
  vim.g.kubernetes_cluster = cluster
  vim.g.kubernetes_namespace = os.getenv("K8S_NAMESPACE")
  M.UpdateColors()
end

function M.UpdateGlobalValues()
  local cluster = vim.fn.system('echo -n "$(kubectl config current-context 2>/dev/null)"')
  if cluster == "__None__" then
    vim.g.kubernetes_namespace = ""
    vim.g.kubernetes_cluster = ""
    return
  end

  local namespace = vim.fn.system("kubectl config view --minify -o jsonpath='{..namespace}'")
  if namespace == "" then
    namespace = "default"
  end

  vim.g.kubernetes_namespace = namespace
  vim.g.kubernetes_cluster = cluster
  M.UpdateColors()
end

return M
