#!/usr/bin/env fish
# Inject 1Password secrets into every fish/tmux session, app-free, with ONE
# masked master-password prompt per login.
#
# Load sources (op-load, cheap, NEVER prompts):
#   1. Shell sentinel (OP_SECRETS_LOADED) -- already done, skip.
#   2. tmux global env  -- set once any pane has fetched; no file, no op call.
#   3. Cache file       -- tmpfs, 0600, written after the first fetch.
#
# Fetch (__op_fetch, INTERACTIVE, prompts): masked password read in fish, piped
# to `op signin` (no desktop app), then `op read` for each secret -> cache.
# Only op-login (the Hyprland floating terminal) and op-reload call it, so a
# normal shell never blocks on a prompt.
#
# Lazy pickup: panes that start before the fetch (tmux-resurrect at boot)
# register fish_prompt/fish_preexec hooks that op-load (no prompt) on the next
# event, inheriting the vars the instant the login window populates them.
#
# Edit only the two maps below.

function __op_secrets_vars
    # One name per line so `for v in (__op_secrets_vars)` iterates correctly.
    printf '%s\n' CLOCKWORK_API JIRA_API_TOKEN JIRA_TOKEN GITLAB_TOKEN TF_TOKEN_gitlab_com GRAFANA_TOKEN GRAFANA_CLOUD_API_TOKEN GITLAB_MANAGEMENT_TOKEN VAULT_PASSWORD OPEN_VPN_PASSWORD
end

function __op_secrets_refs
    # NAME<TAB>op://ref, one per line. Vault froa-shell-secrets is a user-created
    # (non-Personal) vault, readable via a master-password signin with no app.
    printf 'CLOCKWORK_API\top://froa-shell-secrets/CLOCKWORK_API/credential\n'
    printf 'JIRA_API_TOKEN\top://froa-shell-secrets/JIRA_API_TOKEN/credential\n'
    printf 'JIRA_TOKEN\top://froa-shell-secrets/JIRA_TOKEN/credential\n'
    printf 'GITLAB_TOKEN\top://froa-shell-secrets/GITLAB_TOKEN/credential\n'
    printf 'TF_TOKEN_gitlab_com\top://froa-shell-secrets/TF_TOKEN_gitlab_com/credential\n'
    printf 'GRAFANA_TOKEN\top://froa-shell-secrets/GRAFANA_TOKEN/credential\n'
    # Item was created via a Spanish-locale 1Password client: field label is
    # "credencial" not "credential", and `op` can't yet resolve it by name
    # (stale local name-cache for a new item) -- pinned to its UUID instead.
    printf 'GRAFANA_CLOUD_API_TOKEN\top://froa-shell-secrets/f5e3tzqh7n7rkyckupnq3axufq/credencial\n'
    printf 'GITLAB_MANAGEMENT_TOKEN\top://froa-shell-secrets/GITLAB_MANAGEMENT_TOKEN/credential\n'
    printf 'VAULT_PASSWORD\top://froa-shell-secrets/VAULT_PASSWORD/credential\n'
    printf 'OPEN_VPN_PASSWORD\top://froa-shell-secrets/OPEN_VPN_PASSWORD/credential\n'
end

# 1Password account to sign in to (added via `op account add`; no desktop app).
function __op_account
    echo technosylva
end

function __op_cache_path
    set -l rt $XDG_RUNTIME_DIR
    test -n "$rt"; or set rt /tmp/op-(id -u)
    test -d $rt; or mkdir -p -m 700 $rt 2>/dev/null
    echo $rt/op-secrets.cache.fish
end

# Pull vars already stored in tmux's server-global env (zero op calls).
# Returns 0 if at least one var was found.
function __op_load_from_tmux
    set -q TMUX; or return 1
    type -q tmux; or return 1
    set -l found 0
    for v in (__op_secrets_vars)
        set -l line (tmux show-environment -g $v 2>/dev/null)
        if string match -q "$v=*" -- $line
            set -gx $v (string replace "$v=" '' -- $line)
            set found 1
        end
    end
    return (math 1 - $found)
end

# Source the cache file. Returns 0 on success.
function __op_load_from_cache
    set -l cache (__op_cache_path)
    test -s $cache; or return 1
    source $cache
    return 0
end

# Push all loaded vars into tmux global env so other panes can inherit.
function __op_sync_tmux
    set -q TMUX; or return 0
    type -q tmux; or return 0
    for v in (__op_secrets_vars)
        set -q $v; and tmux set-environment -g $v $$v 2>/dev/null
    end
end

# Cheap, non-interactive load. NEVER prompts. Returns 0 if all sources gave vars.
function op-load
    set -q OP_SECRETS_LOADED; and return 0
    if __op_load_from_tmux
        set -gx OP_SECRETS_LOADED 1
        return 0
    end
    if __op_load_from_cache
        __op_sync_tmux
        set -gx OP_SECRETS_LOADED 1
        return 0
    end
    return 1
end

# Interactive fetch from 1Password (no desktop app). One MASKED master-password
# prompt, sign in, read each secret, write the 0600 tmpfs cache, sync to tmux.
# Returns 0 on success. Only call from op-login / op-reload.
function __op_fetch
    status is-interactive; or return 1
    type -q op; or return 1

    # Masked read in fish itself -- reliable, unlike op's own prompt in this
    # nested context (op fails to disable echo here).
    read --silent --local --prompt-str 'Enter 1Password master password: ' pw
    echo
    test -n "$pw"; or return 1

    # Pipe the password to `op signin`; capture its `export OP_SESSION_x=...`.
    set -l out (printf '%s' "$pw" | op signin --account (__op_account) 2>/dev/null)
    set -e pw
    test -n "$out"; or return 1

    # Apply the session to THIS shell so the reads below are authenticated.
    # Split on the FIRST '=' only -- the token can contain '=' padding.
    set -l kv (string replace 'export ' '' -- $out)
    set -l name (string split -m1 '=' -- $kv)[1]
    set -l val (string split -m1 '=' -- $kv)[2]
    set -gx $name (string trim -c '"' -- $val)

    # Read each secret; build the cache atomically.
    set -l cache (__op_cache_path)
    set -l tmp $cache.tmp.$fish_pid
    rm -f $tmp
    set -l ok 0
    for line in (__op_secrets_refs)
        set -l parts (string split \t -- $line)
        set -l v (op read $parts[2] 2>/dev/null)
        test -n "$v"; or continue
        printf 'set -gx %s %s\n' $parts[1] (string escape -- $v) >> $tmp
        set ok 1
    end
    set -e $name  # drop the session token from env; the cache holds the secrets

    if test $ok -eq 0
        rm -f $tmp
        return 1
    end
    mv -f $tmp $cache
    chmod 600 $cache

    __op_load_from_cache
    __op_sync_tmux
    set -gx OP_SECRETS_LOADED 1
    return 0
end

# Force a fresh fetch (e.g. after rotating a token).
function op-reload
    set -e OP_SECRETS_LOADED
    rm -f (__op_cache_path)
    if set -q TMUX; and type -q tmux
        for v in (__op_secrets_vars)
            tmux set-environment -gu $v 2>/dev/null
        end
    end
    __op_fetch
end

# Interactive login helper for the floating startup terminal (Hyprland exec-once).
# Loads from cache/tmux if available, else prompts (masked) once. Prints clear
# success/failure feedback; on failure waits and offers a retry.
function op-login
    op-load; or __op_fetch
    set -l missing
    for v in (__op_secrets_vars)
        set -q $v; or set -a missing $v
    end
    if test (count $missing) -eq 0
        set_color green
        echo "✓ 1Password secrets loaded ("(count (__op_secrets_vars))" tokens). Closing…"
        set_color normal
        sleep 1.5
        return 0
    end
    set_color red
    echo "✗ Sign-in failed (wrong password or no network). Missing: $missing"
    set_color normal
    echo "Press Enter to retry, Ctrl-C to close."
    read
    op-login
end

# Lazy pickup hooks: panes started before the login fetch inherit the vars on
# their next prompt/command -- op-load only (no prompt), self-erase once loaded.
function __op_lazy_pickup
    set -q OP_SECRETS_LOADED; and begin
        functions -e __op_lazy_prompt __op_lazy_preexec
        return 0
    end
    if op-load
        functions -e __op_lazy_prompt __op_lazy_preexec
    end
end

function __op_lazy_prompt --on-event fish_prompt
    __op_lazy_pickup
end

function __op_lazy_preexec --on-event fish_preexec
    __op_lazy_pickup
end

# Run at shell startup (cache/tmux only -- never prompts here).
op-load

# If loaded: erase both lazy hooks (zero per-prompt cost for normal shells).
# If not:    keep both hooks so the pane self-heals on the next event.
if set -q OP_SECRETS_LOADED
    functions -e __op_lazy_prompt __op_lazy_preexec
end
