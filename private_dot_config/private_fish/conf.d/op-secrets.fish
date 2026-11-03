#!/usr/bin/env fish
# Inject all 1Password secrets from a vault into every fish/tmux session,
# app-free, with ONE masked master-password prompt per login.
#
# No hardcoded secret lists: discovers all vault items dynamically, using
# each item's title as the environment variable name.
#
# Load sources (op-load, cheap, NEVER prompts):
#   1. Shell sentinel (OP_SECRETS_LOADED) -- already done, skip.
#   2. tmux global env  -- set once any pane has fetched; no file, no op call.
#   3. Cache file       -- tmpfs, 0600, written after the first fetch.
#
# Fetch (__op_fetch, INTERACTIVE, prompts):
#   - Reads masked master password in fish.
#   - Signs in (1 call).
#   - Lists and extracts all items in the vault in one batch (op item list | op item get -).
#   - Writes 0600 cache in tmpfs and syncs to tmux.

# 1Password account to sign in to (added via `op account add`; no desktop app).
function __op_account
    echo technosylva
end

# Vault containing your shell secrets
function __op_vault
    echo froa-shell-secrets
end

function __op_cache_path
    set -l rt $XDG_RUNTIME_DIR
    test -n "$rt"; or set rt /tmp/op-(id -u)
    test -d $rt; or mkdir -p -m 700 $rt 2>/dev/null
    echo $rt/op-secrets.cache.fish
end

# Dynamically resolve variable names from the cache or tmux (no hardcoded array).
function __op_secrets_vars
    set -l cache (__op_cache_path)
    if test -s $cache
        string replace -r '^set -gx ([A-Za-z0-9_]+) .*' '$1' <$cache
        return 0
    end
    if set -q TMUX; and type -q tmux
        set -l line (tmux show-environment -g OP_SECRET_NAMES 2>/dev/null)
        if string match -q 'OP_SECRET_NAMES=*' -- $line
            string split ' ' -- (string replace 'OP_SECRET_NAMES=' '' -- $line)
            return 0
        end
    end
end

# Pull vars already stored in tmux's server-global env (zero op calls).
function __op_load_from_tmux
    set -q TMUX; or return 1
    type -q tmux; or return 1
    set -l vars (__op_secrets_vars)
    test (count $vars) -gt 0; or return 1

    set -l found 0
    for v in $vars
        set -l line (tmux show-environment -g $v 2>/dev/null)
        if string match -q "$v=*" -- $line
            set -gx $v (string replace "$v=" '' -- $line)
            set found 1
        end
    end
    return (math 1 - $found)
end

# Source the cache file.
function __op_load_from_cache
    set -l cache (__op_cache_path)
    test -s $cache; or return 1
    source $cache
    return 0
end

# Push all loaded vars into tmux global env so other panes inherit instantly.
function __op_sync_tmux
    set -q TMUX; or return 0
    type -q tmux; or return 0
    set -l vars (__op_secrets_vars)
    test (count $vars) -gt 0; or return 0

    for v in $vars
        set -q $v; and tmux set-environment -g $v $$v 2>/dev/null
    end
    # Record the list of secret variable names in tmux
    tmux set-environment -g OP_SECRET_NAMES (string join ' ' $vars) 2>/dev/null
end

# Cheap, non-interactive load. NEVER prompts.
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

# Interactive fetch from 1Password. Prompts once, pulls the entire vault dynamically.
function __op_fetch
    status is-interactive; or return 1
    type -q op; or return 1
    type -q jq; or begin
        echo "Error: 'jq' is required to parse 1Password vault secrets." >&2
        return 1
    end

    read --silent --local --prompt-str 'Enter 1Password master password: ' pw
    echo
    test -n "$pw"; or return 1

    # Sign in and grab the session token
    set -l out (printf '%s' "$pw" | op signin --account (__op_account) 2>/dev/null)
    set -e pw
    test -n "$out"; or return 1

    set -l kv (string replace 'export ' '' -- $out)
    set -l name (string split -m1 '=' -- $kv)[1]
    set -l val (string split -m1 '=' -- $kv)[2]
    set -gx $name (string trim -c '"' -- $val)

    # 1. List all items in the vault
    # 2. Bulk-fetch full item JSON via stdin (`op item get -`)
    # 3. Extract item title as the var name, picking the password/credential/concealed field
    set -l resolved (
        op item list --vault (__op_vault) --format json 2>/dev/null \
        | op item get - --reveal --format json 2>/dev/null \
        | jq -r '
            (if type == "array" then . else [.] end)[]
            | .title as $title
            | ([.fields[]? | select(.value != null and .value != "" and (
                .purpose == "PASSWORD" or 
                .type == "CONCEALED" or 
                (.label? | test("credential|credencial|password|token"; "i"))
              ))] | .[0].value) as $val
            | select($val != null)
            | "\($title)\t\($val)"
        '
    )
    set -e $name # drop session token immediately

    test -n "$resolved"; or return 1

    # Atomically write cache
    set -l cache (__op_cache_path)
    set -l tmp $cache.tmp.$fish_pid
    rm -f $tmp
    set -l ok 0

    for line in $resolved
        set -l parts (string split -m1 \t -- $line)
        test (count $parts) -ge 2; or continue
        printf 'set -gx %s %s\n' $parts[1] (string escape -- $parts[2]) >>$tmp
        set ok 1
    end

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

# Force a fresh fetch (e.g. after adding/rotating tokens in 1Password).
function op-reload
    set -e OP_SECRETS_LOADED
    set -l old_vars (__op_secrets_vars)
    rm -f (__op_cache_path)
    if set -q TMUX; and type -q tmux
        for v in $old_vars
            tmux set-environment -gu $v 2>/dev/null
        end
        tmux set-environment -gu OP_SECRET_NAMES 2>/dev/null
    end
    __op_fetch
end

# Interactive login helper for the floating startup terminal (Hyprland exec-once).
function op-login
    op-load; or __op_fetch
    set -l vars (__op_secrets_vars)
    if test (count $vars) -gt 0
        set_color green
        echo "✓ 1Password secrets loaded ("(count $vars)" tokens from "(__op_vault)"). Closing…"
        set_color normal
        sleep 1.5
        return 0
    end
    set_color red
    echo "✗ Sign-in failed or no secrets found in vault '"(__op_vault)"'."
    set_color normal
    echo "Press Enter to retry, Ctrl-C to close."
    read
    op-login
end

# Lazy pickup hooks for panes started before login window finishes
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

# Erase hooks if already loaded
if set -q OP_SECRETS_LOADED
    functions -e __op_lazy_prompt __op_lazy_preexec
end
##!/usr/bin/env fish
## Inject 1Password secrets into every fish/tmux session, app-free, with ONE
## masked master-password prompt per login.
##
## Load sources (op-load, cheap, NEVER prompts):
##   1. Shell sentinel (OP_SECRETS_LOADED) -- already done, skip.
##   2. tmux global env  -- set once any pane has fetched; no file, no op call.
##   3. Cache file       -- tmpfs, 0600, written after the first fetch.
##
## Fetch (__op_fetch, INTERACTIVE, prompts): masked password read in fish, piped
## to `op signin` (no desktop app), then `op read` for each secret -> cache.
## Only op-login (the Hyprland floating terminal) and op-reload call it, so a
## normal shell never blocks on a prompt.
##
## Lazy pickup: panes that start before the fetch (tmux-resurrect at boot)
## register fish_prompt/fish_preexec hooks that op-load (no prompt) on the next
## event, inheriting the vars the instant the login window populates them.
##
## Edit only the two maps below.
#
#function __op_secrets_vars
#    # One name per line so `for v in (__op_secrets_vars)` iterates correctly.
#    printf '%s\n' CLOCKWORK_API JIRA_API_TOKEN JIRA_TOKEN GITLAB_TOKEN TF_TOKEN_gitlab_com GRAFANA_TOKEN GRAFANA_CLOUD_API_TOKEN GITLAB_MANAGEMENT_TOKEN VAULT_PASSWORD OPEN_VPN_PASSWORD GITLAB_REGISTRY_TOKEN GRAFANA_CLOUD_API_TOKEN_CA GRAFANA_CLOUD_API_TOKEN_EU ARM_CLIENT_ID ARM_CLIENT_SECRET ARM_TENANT_ID ARM_SUBSCRIPTION_ID TINYBIRD_TOKEN TINYBIRD_TOKEN_AWS
#end
#
#function __op_secrets_refs
#    # NAME<TAB>op://ref, one per line. Vault froa-shell-secrets is a user-created
#    # (non-Personal) vault, readable via a master-password signin with no app.
#    printf 'CLOCKWORK_API\top://froa-shell-secrets/CLOCKWORK_API/credential\n'
#    printf 'JIRA_API_TOKEN\top://froa-shell-secrets/JIRA_API_TOKEN/credential\n'
#    printf 'JIRA_TOKEN\top://froa-shell-secrets/JIRA_TOKEN/credential\n'
#    printf 'GITLAB_TOKEN\top://froa-shell-secrets/GITLAB_TOKEN/credential\n'
#    printf 'TF_TOKEN_gitlab_com\top://froa-shell-secrets/TF_TOKEN_gitlab_com/credential\n'
#    printf 'GRAFANA_TOKEN\top://froa-shell-secrets/GRAFANA_TOKEN/credential\n'
#    printf 'CI_PLATFORM_USERNAME\top://froa-shell-secrets/CI_PLATFORM_USERNAME/credential\n'
#    printf 'CI_PLATFORM_PASSWORD\top://froa-shell-secrets/CI_PLATFORM_PASSWORD/credential\n'
#    printf 'TF_VAR_ci_platform_password\top://froa-shell-secrets/TF_VAR_ci_platform_password/credential\n'
#    printf 'TF_VAR_ci_platform_username\top://froa-shell-secrets/TF_VAR_ci_platform_username/credential\n'
#    # Item was created via a Spanish-locale 1Password client: field label is
#    # "credencial" not "credential", and `op` can't yet resolve it by name
#    # (stale local name-cache for a new item) -- pinned to its UUID instead.
#    printf 'GRAFANA_CLOUD_API_TOKEN\top://froa-shell-secrets/f5e3tzqh7n7rkyckupnq3axufq/credencial\n'
#    printf 'GITLAB_MANAGEMENT_TOKEN\top://froa-shell-secrets/GITLAB_MANAGEMENT_TOKEN/credential\n'
#    printf 'VAULT_PASSWORD\top://froa-shell-secrets/VAULT_PASSWORD/credential\n'
#    printf 'OPEN_VPN_PASSWORD\top://froa-shell-secrets/OPEN_VPN_PASSWORD/credential\n'
#    printf 'GITLAB_REGISTRY_TOKEN\top://froa-shell-secrets/GITLAB_REGISTRY_TOKEN/credential\n'
#    printf 'GRAFANA_CLOUD_API_TOKEN_CA\top://froa-shell-secrets/GRAFANA_CLOUD_API_TOKEN_CA/credential\n'
#    printf 'GRAFANA_CLOUD_API_TOKEN_EU\top://froa-shell-secrets/GRAFANA_CLOUD_API_TOKEN_EU/credential\n'
#    printf 'GRAFANA_CLOUD_API_TOKEN_US\top://froa-shell-secrets/GRAFANA_CLOUD_API_TOKEN_US/credential\n'
#    printf 'ARM_CLIENT_ID\top://froa-shell-secrets/ARM_CLIENT_ID/credential\n'
#    printf 'ARM_CLIENT_SECRET\top://froa-shell-secrets/ARM_CLIENT_SECRET/credential\n'
#    printf 'ARM_TENANT_ID\top://froa-shell-secrets/ARM_TENANT_ID/credential\n'
#    printf 'ARM_SUBSCRIPTION_ID\top://froa-shell-secrets/ARM_SUBSCRIPTION_ID/credential\n'
#    printf 'TINYBIRD_TOKEN\top://froa-shell-secrets/TINYBIRD_TOKEN/credential\n'
#    printf 'TINYBIRD_TOKEN_AWS\top://froa-shell-secrets/TINYBIRD_TOKEN_AWS/credential\n'
#end
#
## 1Password account to sign in to (added via `op account add`; no desktop app).
#function __op_account
#    echo technosylva
#end
#
#function __op_cache_path
#    set -l rt $XDG_RUNTIME_DIR
#    test -n "$rt"; or set rt /tmp/op-(id -u)
#    test -d $rt; or mkdir -p -m 700 $rt 2>/dev/null
#    echo $rt/op-secrets.cache.fish
#end
#
## Pull vars already stored in tmux's server-global env (zero op calls).
## Returns 0 if at least one var was found.
#function __op_load_from_tmux
#    set -q TMUX; or return 1
#    type -q tmux; or return 1
#    set -l found 0
#    for v in (__op_secrets_vars)
#        set -l line (tmux show-environment -g $v 2>/dev/null)
#        if string match -q "$v=*" -- $line
#            set -gx $v (string replace "$v=" '' -- $line)
#            set found 1
#        end
#    end
#    return (math 1 - $found)
#end
#
## Source the cache file. Returns 0 on success.
#function __op_load_from_cache
#    set -l cache (__op_cache_path)
#    test -s $cache; or return 1
#    source $cache
#    return 0
#end
#
## Push all loaded vars into tmux global env so other panes can inherit.
#function __op_sync_tmux
#    set -q TMUX; or return 0
#    type -q tmux; or return 0
#    for v in (__op_secrets_vars)
#        set -q $v; and tmux set-environment -g $v $$v 2>/dev/null
#    end
#end
#
## Cheap, non-interactive load. NEVER prompts. Returns 0 if all sources gave vars.
#function op-load
#    set -q OP_SECRETS_LOADED; and return 0
#    if __op_load_from_tmux
#        set -gx OP_SECRETS_LOADED 1
#        return 0
#    end
#    if __op_load_from_cache
#        __op_sync_tmux
#        set -gx OP_SECRETS_LOADED 1
#        return 0
#    end
#    return 1
#end
#
## Interactive fetch from 1Password (no desktop app). One MASKED master-password
## prompt, sign in, read each secret, write the 0600 tmpfs cache, sync to tmux.
## Returns 0 on success. Only call from op-login / op-reload.
#function __op_fetch
#    status is-interactive; or return 1
#    type -q op; or return 1
#
#    # Masked read in fish itself -- reliable, unlike op's own prompt in this
#    # nested context (op fails to disable echo here).
#    read --silent --local --prompt-str 'Enter 1Password master password: ' pw
#    echo
#    test -n "$pw"; or return 1
#
#    # Pipe the password to `op signin`; capture its `export OP_SESSION_x=...`.
#    set -l out (printf '%s' "$pw" | op signin --account (__op_account) 2>/dev/null)
#    set -e pw
#    test -n "$out"; or return 1
#
#    # Apply the session to THIS shell so the reads below are authenticated.
#    # Split on the FIRST '=' only -- the token can contain '=' padding.
#    set -l kv (string replace 'export ' '' -- $out)
#    set -l name (string split -m1 '=' -- $kv)[1]
#    set -l val (string split -m1 '=' -- $kv)[2]
#    set -gx $name (string trim -c '"' -- $val)
#
#    # Read each secret; build the cache atomically.
#    set -l cache (__op_cache_path)
#    set -l tmp $cache.tmp.$fish_pid
#    rm -f $tmp
#    set -l ok 0
#    for line in (__op_secrets_refs)
#        set -l parts (string split \t -- $line)
#        set -l v (op read $parts[2] 2>/dev/null)
#        test -n "$v"; or continue
#        printf 'set -gx %s %s\n' $parts[1] (string escape -- $v) >>$tmp
#        set ok 1
#    end
#    set -e $name # drop the session token from env; the cache holds the secrets
#
#    if test $ok -eq 0
#        rm -f $tmp
#        return 1
#    end
#    mv -f $tmp $cache
#    chmod 600 $cache
#
#    __op_load_from_cache
#    __op_sync_tmux
#    set -gx OP_SECRETS_LOADED 1
#    return 0
#end
#
## Force a fresh fetch (e.g. after rotating a token).
#function op-reload
#    set -e OP_SECRETS_LOADED
#    rm -f (__op_cache_path)
#    if set -q TMUX; and type -q tmux
#        for v in (__op_secrets_vars)
#            tmux set-environment -gu $v 2>/dev/null
#        end
#    end
#    __op_fetch
#end
#
## Interactive login helper for the floating startup terminal (Hyprland exec-once).
## Loads from cache/tmux if available, else prompts (masked) once. Prints clear
## success/failure feedback; on failure waits and offers a retry.
#function op-login
#    op-load; or __op_fetch
#    set -l missing
#    for v in (__op_secrets_vars)
#        set -q $v; or set -a missing $v
#    end
#    if test (count $missing) -eq 0
#        set_color green
#        echo "✓ 1Password secrets loaded ("(count (__op_secrets_vars))" tokens). Closing…"
#        set_color normal
#        sleep 1.5
#        return 0
#    end
#    set_color red
#    echo "✗ Sign-in failed (wrong password or no network). Missing: $missing"
#    set_color normal
#    echo "Press Enter to retry, Ctrl-C to close."
#    read
#    op-login
#end
#
## Lazy pickup hooks: panes started before the login fetch inherit the vars on
## their next prompt/command -- op-load only (no prompt), self-erase once loaded.
#function __op_lazy_pickup
#    set -q OP_SECRETS_LOADED; and begin
#        functions -e __op_lazy_prompt __op_lazy_preexec
#        return 0
#    end
#    if op-load
#        functions -e __op_lazy_prompt __op_lazy_preexec
#    end
#end
#
#function __op_lazy_prompt --on-event fish_prompt
#    __op_lazy_pickup
#end
#
#function __op_lazy_preexec --on-event fish_preexec
#    __op_lazy_pickup
#end
#
## Run at shell startup (cache/tmux only -- never prompts here).
#op-load
#
## If loaded: erase both lazy hooks (zero per-prompt cost for normal shells).
## If not:    keep both hooks so the pane self-heals on the next event.
#if set -q OP_SECRETS_LOADED
#    functions -e __op_lazy_prompt __op_lazy_preexec
#end
