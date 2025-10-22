-- https://www.youtube.com/watch?v=rerTvidyz-0
local tmpl = {
  name = "GitLab CI Job",
  strategy = "snacks",
  params = {
    job = { type = "string" },
  },
  builder = function(params)
    return {
      name = "gitlab job",
      cmd = " gitlab-ci-local  "
        .. params.job
        .. ' --volume /var/run/docker.sock:/var/run/docker.sock  --variable CI_DEPLOY_USER="$CI_DEPLOY_USER" --variable CI_DEPLOY_PASSWORD="$GITLAB_TOKEN"  ',
      cwd = LazyVim.root.git(),
    }
  end,
}
return tmpl
