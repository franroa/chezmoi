# Global Claude Code Instructions

## Rules

- Never send Slack messages on the user's behalf. Draft the message in conversation and let the user send it.
- Never post GitLab comments/replies/threads on the user's behalf without explicit approval. Draft the text first and wait for confirmation. Read-only `glab` calls and non-comment MR edits (retargeting, labels, etc.) are fine when authorized.
- Never push directly to base branches (main, master, develop, develop_new_structure, or any branch that serves as a merge target). Always create a feature branch and open an MR instead.
- Never delete or truncate data in production systems (databases, Tinybird workspaces, object storage, etc.). Any destructive data operation must target staging/dev environments only. If in doubt, ask.
- Before deleting or truncating data in staging, always ask for explicit confirmation twice before proceeding.
- Never commit or push tokens, secrets, or credentials. If a file needs an auth token to work locally (e.g. project `.npmrc` for a private registry), set up the auth globally (e.g. `~/.npmrc`) — never inline it into a project file that could be committed. Before any `git add`/`git commit`/`git push`, scan staged content for `_authToken`, `Bearer `, `ghp_`, `glpat-`, `xoxb-`, AWS keys, or any "<redacted>"-style placeholder; if found, abort and report to the user.

## Environment

- OS: Linux. Default shell: **fish** — `$(...)`, `export`, and bash-only syntax do not work in an interactive fish shell (fish uses `(...)` and `set -x`). Non-interactive tool calls run under bash, so bash syntax is fine there; just don't hand the user fish-incompatible one-liners.
- GNU coreutils (not BSD): use `date -u -d '-1 hour' +%s`, not `date -u -v-1H`.

## Local Repository Layout

All GitLab repos are cloned locally under `~/dev/technosylva/`, mirroring the GitLab group hierarchy:

```
gitlab.com/technosylva/<group>/<repo>  →  ~/dev/technosylva/<group>/<repo>
```

Examples:
- `technosylva/ai/synapse`          → `~/dev/technosylva/ai/synapse`
- `technosylva/platform/platform-api` → `~/dev/technosylva/platform/platform-api`
- `technosylva/data/data-platform`  → `~/dev/technosylva/data/data-platform`
- `technosylva/ansible-playbooks`   → `~/dev/technosylva/ansible-playbooks`

Some groups nest subgroups (e.g. `platform/development`, `platform/ai`, `platform/modules`, `platform/tools`, `platform/observability`, `platform/legacy`). Layout mirrors full path depth:
- `technosylva/platform/development/cicd-tools` → `~/dev/technosylva/platform/development/cicd-tools`
- `technosylva/platform/ai/ai-gateway`          → `~/dev/technosylva/platform/ai/ai-gateway`

To clone all repos in a group (including subgroups), use `glab repo clone -g <group> <dir> -p --paginate` — pass the parent dir (e.g. `~/dev`) so `-p` (preserve-namespace) reconstructs full path depth automatically.

Worktrees are managed by `aoe` and live inside the repo at `.aoe-worktrees/<branch>` (multi-repo workspaces at `.aoe-workspaces/<branch>-<session-id>`).

Before fetching a file via `glab api`, always check if the repo exists locally and read it directly.
Before starting any work in a repo, run `git pull` on the main branch to ensure it is up to date.

## Available Tools

- **glab**: GitLab CLI, authenticated as `froa-tsyl` on `gitlab.com` (token from `$GITLAB_TOKEN`). Use for MRs, issues, pipelines, API.
  - **Always use the `/gitlab-mr` skill** when creating MRs — never call `glab mr create` directly. The skill handles branch naming, Conventional Commits format, AI labels (`ai::generated`, `ai-agent::claude`), and the Technosylva MR description template.

- **aoe (Agent of Empires)**: tmux-based session manager for AI coding agents; use it instead of raw `git worktree` for parallel work.
  ```
  aoe                                    # TUI dashboard
  aoe add <path> -w <branch> -b -l       # new branch + worktree session, launched
  aoe add <path> -w <branch> -l          # session on an existing branch
  aoe add <path> -w <branch> -b --base-branch <ref>   # stack on top of another branch
  aoe list | aoe status                  # sessions + state
  aoe session attach <id|title>          # attach interactively
  aoe send <id|title> "<message>"        # send a prompt to a running agent
  aoe worktree list | aoe worktree cleanup
  aoe remove <id|title> [--delete-worktree] [--delete-branch]
  ```
  After creating a worktree, copy gitignored local config from the main checkout before running any dev task:
  ```bash
  cp <repo-main-checkout>/.env <new-worktree>/.env
  ```
  `.env` is gitignored and not shared between worktrees. Without it, `docker compose` uses wrong defaults (e.g. port 5432 instead of 5434) and the backend fails to connect.

- **GitLab container registry**: token in `$GITLAB_REGISTRY_TOKEN` (`read_registry` scope, already exported in the shell environment). To log in:
  ```bash
  echo "$GITLAB_REGISTRY_TOKEN" | docker login registry.gitlab.com -u froa-tsyl --password-stdin
  ```

- **grafana** (`https://grafana.technosylva.io`): API with service token when MCP unavailable.
  - Token header: `Authorization: Bearer $GRAFANA_TOKEN`
  - Grafana Cloud stacks use `$GRAFANA_CLOUD_API_TOKEN_US` / `_EU` / `_CA`
  - Loki: `us01` (540), `eu01` (546), `ca01` (543), `Legacy` (586)
  - Mimir: `us01` (544), `eu01` (542), `ca01` (541)
  - LogQL example:
    ```bash
    curl -sG "https://grafana.technosylva.io/api/datasources/proxy/uid/<uid>/loki/api/v1/query_range" \
      -H "Authorization: Bearer $GRAFANA_TOKEN" \
      --data-urlencode 'query={namespace="firerisk"}' \
      --data-urlencode "start=$(date -u -d '-1 hour' +%s)000000000" \
      --data-urlencode "end=$(date -u +%s)000000000"
    ```
    (or `/api/datasources/proxy/<id>/...`)

- **Jira**: Atlassian MCP is the primary interface. For raw REST, `$JIRA_TOKEN` / `$JIRA_API_TOKEN` and `$JIRA_ENCODED_CREDENTIALS` (basic-auth base64 of `$JIRA_EMAIL:$JIRA_TOKEN`) are exported in the shell environment.
