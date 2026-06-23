# gitlab-ci — modular pipeline assembler

Author a GitLab pipeline **from scratch, locally**, using **reusable CI/CD
components**, validate it with `gitlab-ci-local`, then commit it and have it run
**unchanged on the remote**.

## Layout

```
~/.config/gitlab-ci/
  components/<name>.yml   include: component: fragments (real catalog units).
                          Resolved locally by gitlab-ci-local + GITLAB_TOKEN and
                          natively on the remote. PREFERRED.
  jobs/<name>.yml         self-contained mini-jobs. Offline fallback (no token).
```

Each `components/*.yml` may carry `# ci-stage: <stage>` so the assembler can
declare `stages:` correctly. Each `jobs/*.yml` declares its own `stage:`.

## The assembler — `ci-inject.sh`

```
ci-inject.sh [repo] [--mode auto|reuse|remote|skill|both]
                    [--prefer auto|components|jobs] [--semver] [--root] [--quiet]
```

Selection (under `--mode auto`, first non-empty wins):

1. **reuse**  — `component:`/`local:` includes already in this repo's `.gitlab-ci.yml`.
2. **remote** — components/jobs the remote ran recently on this branch (`glab`).
3. **skill**  — static analysis: `go.mod`→Go, `package.json`→Node, `Dockerfile`→docker,
   `Cargo.toml`→Rust, `*.py`→Python, `*.tf`→Terraform. Adds org `base` + `sast`.

`--prefer`:
- `auto` (default) — a reusable component where one exists, else a mini-job.
- `components` — force component fragments (needs token for local runs).
- `jobs` — force offline mini-jobs (fully offline `gitlab-ci-local`).

Output (one file that works locally **and** remotely):
- no existing `.gitlab-ci.yml` → writes `.gitlab-ci.yml` (scaffold).
- existing `.gitlab-ci.yml`    → writes `.gitlab-ci.dynamic.yml` (safe overlay;
  run with `gitlab-ci-local --file .gitlab-ci.dynamic.yml`). `--root` overwrites
  `.gitlab-ci.yml` and keeps a `.bak`.

Generated `local:` job files are **intent-to-add staged** automatically, because
`gitlab-ci-local` reads local includes from the git tree (untracked files report
"cannot be found").

## Local ⇄ remote parity

- `components/*` are the same `include: component:` lines the remote uses, so a
  scaffolded pipeline runs identically in both places.
- Local component resolution needs a valid `GITLAB_TOKEN` (wired via the repo's
  `.gitlab-ci-local-variables.yml`; see `gcl-setup.sh`, `prefix G → u`). Without
  a token, use `--prefer jobs` for an offline-equivalent pipeline.

## tmux integration (gitlab leader, `prefix G`)

- `j` — run the assembler on the current repo.
- `r/l/v/n` — context-aware run / logs / view / list; routed to local
  (`gitlab-ci-local`) or remote (`glab`) by the focused pane's `@ci-context`.
- `w` — dual view (remote left, local right), each pane tagged with its context.

## fish auto-trigger

`conf.d/ci-inject-hook.fish` assembles the pipeline once per repo per session on
`cd` into a GitLab repo. Disable: `set -U CI_INJECT_AUTO 0`.

## Adding a component / job

Drop a file in `components/` or `jobs/`, then map its stack in `ci-inject.sh`
(`stack_tokens`). Re-run `ci-inject.sh` in any repo to pick it up.
