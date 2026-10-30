local tmpl = {
  name = "Port-Forward DB Port",
  builder = function(params)
    return {
      name = "Port-Forward DB in " .. LazyVim.root.git():match("([^/]+)$"),
      cmd = "kubie exec EMAZWEGEDGEDAKS01-aks default kubectl port-forward svc/nginx-proxy-service 3307:3306",
      cwd = "/",
      components = {
        "default",
        { "unique", replace = true },
      },
    }
  end,
}
return tmpl
