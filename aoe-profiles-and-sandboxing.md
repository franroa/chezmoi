# AOE profiles, Claude accounts & sandboxing

How "profiles" and Docker sandboxing actually work in this setup, and how a
session ends up on a given Claude account. Written 2026-06-20.

---

## TL;DR

- **Two unrelated things are both called "profile."** AOE profiles = session-list
  workspaces (no credentials). claude-profile dirs = the things that hold
  credentials.
- **Host `claude`** picks its account from `CLAUDE_CONFIG_DIR`.
- **AOE sandbox `claude`** picks its account from **`HOME`** (it mounts
  `$HOME/.claude/sandbox` into the container) — `CLAUDE_CONFIG_DIR` is *ignored*
  for sandboxes.
- To make an AOE profile run a specific account, point `HOME` at a per-context
  home: `~/.aoe-homes/<ctx>` (built by `~/.config/aoe/build-aoe-homes.sh`).

---

## 1. The two "profile" systems

### A. claude-profile directories — hold credentials + config

`~/.local/share/claude-profiles/{personal,work}/`

Each is a Claude **config directory**. **ALL config** is **symlinked back to the
canonical `~/.claude`** (shared); only credentials + runtime state are **real and
isolated**. Shared set (maintained by `run_after_link-claude-shared.sh`):
`settings.json, settings.local.json, CLAUDE.md, agents, commands, plugins, skills,
projects, history.jsonl, hooks, rules`. Isolated: `.credentials.json`,
`.claude.json` (the account), `sessions`, `session-env`, `sandbox` (per-context
staging), caches/daemon/logs/backups. Example layout:

```
~/.local/share/claude-profiles/personal/
├── .credentials.json   REAL  ← OAuth tokens = the account
├── .claude.json        REAL  ← oauthAccount identity + per-project state
├── sessions/           REAL
├── agents    → ~/.claude/agents      ┐
├── commands  → ~/.claude/commands    │  SHARED
├── settings.json → ~/.claude/...     │  (symlinks to the hub)
├── skills/plugins/projects → ...     │
└── history.jsonl → ~/.claude/...     ┘
```

Goal: **same config & tooling everywhere, different account per profile.**

Accounts currently:
- `personal` → `franciscoroaprieto@gmail.com` (Claude Pro) — logged in
- `work`     → **not logged in yet** (stub `.claude.json`, no `.credentials.json`)
- hub `~/.claude` → `froa@tecnosylva.com` (Enterprise)

There is **no `claude-profile` CLI** — just these dirs + a chezmoi `run_after`
script that maintains the symlinks.

### B. AOE profiles — hold session lists only

`~/.config/agent-of-empires/profiles/{default,main,personal,work}/sessions.json`

`aoe -p work` / `AGENT_OF_EMPIRES_PROFILE=work` only selects **which session list**
you see. **No credentials, no account.** `config.toml` has
`default_profile = "work"`.

> ⚠️ The two namespaces share the names `personal`/`work` but are otherwise
> unrelated. Choosing AOE profile `personal` does NOT select the personal account.

---

## 2. How host Claude picks an account

```
CLAUDE_HOME = ${CLAUDE_CONFIG_DIR:-$HOME/.claude}
```

- `claude` → `~/.claude` → work/Technosylva (the hub)
- `CLAUDE_CONFIG_DIR=~/.local/share/claude-profiles/personal claude` → personal

Convenience (fish, since fish has no inline `VAR=val cmd`):

```fish
function claude-personal
    env CLAUDE_CONFIG_DIR=$HOME/.local/share/claude-profiles/personal claude $argv
end
```

`CLAUDE_CONFIG_DIR` is the lever for **host** Claude. It does **not** work for
sandboxes (next section).

---

## 3. How AOE sandboxing works

One **Docker container per session**. No central daemon brokers accounts — each
session is a tmux session whose pane runs:

```
docker exec -it aoe-sandbox-<id> claude --dangerously-skip-permissions ...
```

It does **not** mount `~/.claude` directly. It mounts a **staging dir**:

```
$HOME/.claude/sandbox             → /root/.claude          (RW)  ← account lives here
$HOME/.claude/sandbox/.claude.json → /root/.claude.json    (RW)
$HOME/.claude/agents              → /root/.claude/agents   (ro)
$HOME/.claude/commands            → /root/.claude/commands (ro)
$HOME/.config/agent-of-empires/profiles → /root/.config/... (ro)
$HOME/.gitconfig                  → /root/.gitconfig       (ro)
```

Flow:

```
$HOME/.claude/.credentials.json
        │  (AOE seeds on first session)
        ▼
$HOME/.claude/sandbox/.credentials.json ──bind-mount──▶ /root/.claude
                                                              │
                                                      claude runs as this account
```

Verified properties:
- The `/root/.claude` mount path is **hardcoded** — can't double-mount over it
  (Docker rejects duplicate mount points), so per-profile `extra_volumes`
  credential injection is impossible.
- Staging is auto-created and **seeded from `$HOME/.claude/.credentials.json`**.
- Mounted **RW**, so token refresh writes back into the staging dir — and the
  container (running as root) leaves **root-owned files** there (a Stop-hook
  chowns them back).
- `agents`/`commands` are **ro**; plugins/marketplaces are NOT mounted (they'd
  EROFS-fail when Claude re-clones) — they reach the sandbox via `enabledPlugins`.
- Inside the container `/.dockerenv` exists → statusline shows 🐳.

---

## 4. Where the two systems collide (the key gotcha)

The sandbox account is decided entirely by `$HOME/.claude/sandbox`, i.e. by
**`HOME`** — NOT `CLAUDE_CONFIG_DIR`, NOT the AOE profile. Tested:

| You set… | Host `claude` | Sandbox container |
|---|---|---|
| `CLAUDE_CONFIG_DIR=…/personal` | ✅ personal | ❌ still work (ignored) |
| `HOME=/tmp/fake` | ✅ from fake | ✅ `/tmp/fake/.claude/sandbox` |

This explains everything:
- `aoe -p personal` doesn't change the account → AOE profile ≠ account.
- prefix-T "didn't apply the profile" → it set `AGENT_OF_EMPIRES_PROFILE`
  (workspace) but not `HOME` (account), so every sandbox ran the hub's work
  account.
- Side-by-side different accounts needs **per-context `HOME`** (two sessions
  otherwise share the single `$HOME/.claude/sandbox`).

---

## 5. The solution: per-context HOMEs

`~/.config/aoe/build-aoe-homes.sh` builds `~/.aoe-homes/{personal,work}`, each a
**symlink mirror of the real `$HOME`** EXCEPT the account-specific files:

```
~/.aoe-homes/personal/
├── .claude       → ~/.local/share/claude-profiles/personal        (account)
├── .claude.json  → ~/.local/share/claude-profiles/personal/.claude.json
├── .config       → ~/.config        ┐
├── .gitconfig    → ~/.gitconfig      │  everything else mirrored
└── … (all other ~ entries symlinked)┘
```

Re-run the builder any time (idempotent), e.g. after new dotfiles appear:

```bash
bash ~/.config/aoe/build-aoe-homes.sh            # personal + work
bash ~/.config/aoe/build-aoe-homes.sh personal   # one context
```

Launching `HOME=~/.aoe-homes/personal aoe -p personal …` → the sandbox mounts
`…/claude-profiles/personal/sandbox` and runs the personal account. **Verified:
two contexts run concurrently as two containers on two accounts.**

### Wired into prefix-T

`~/.config/tmux/scripts/aoe-profile-session.sh` now, after the fzf profile pick,
also sets `HOME` when a matching context home exists:

```bash
[ -n "$profile" ] && export AGENT_OF_EMPIRES_PROFILE="$profile"
if [ -n "$profile" ] && [ -d "$HOME/.aoe-homes/$profile" ]; then
    export HOME="$HOME/.aoe-homes/$profile"
fi
```

Profiles with no context home (default/main) keep the real `$HOME`.

> TODO (not yet wired): the same `HOME` selection in `aoen` (fish, use `set -lx`
> so it doesn't pollute the interactive shell) and prefix-a
> (`aoen-session.sh`, export before `fish -c 'aoen'`). And widen the auth-chown
> Stop-hook to cover `~/.local/share/claude-profiles/{personal,work}/sandbox`.

---

## 6. Prerequisite: log `work` in

`work` has no credentials yet. Until then, a `work` pick seeds an empty staging
dir and Claude prompts for login inside the first work sandbox. Log it in once:

```fish
env HOME=$HOME/.aoe-homes/work claude   # then /login → Technosylva account → exit
```

`personal` already works with no extra steps.

---

## 7. Statusline badge

`~/.claude/yas-docker-wrapper.py` (and its `~/.claude/sandbox/` copy) shows an
AOE-profile badge: 🧑‍💻 work / 🌳 personal, plus 🐳 in a sandbox. Resolution order:
session_id match in `sessions.json` → container-hostname match →
`$AGENT_OF_EMPIRES_PROFILE` → `CLAUDE_CONFIG_DIR` basename when under
`claude-profiles/` (so host `claude-personal` shows 🌳) → `default_profile`.
Not chezmoi-managed — edit both copies and keep them in sync.
