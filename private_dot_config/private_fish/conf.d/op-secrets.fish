#!/usr/bin/env fish
# Load secrets from 1Password ONCE per login into every shell and tmux pane.
#
# Sources (tried in order, cheapest first):
#   1. Shell sentinel (OP_SECRETS_LOADED) -- already done, skip everything.
#   2. tmux global env  -- set when ANY pane in this server has done auth;
#                          no cache file needed, no op call.
#   3. Cache file       -- tmpfs, 0600, written after the first successful fetch.
#   4. 1Password fetch  -- one biometric prompt under a flock; losers wait for
#                          the winner's cache instead of each prompting.
#
# Lazy pickup: shells that start before auth (e.g. tmux-continuum panes at
# boot) register hooks on BOTH fish_prompt AND fish_preexec. The first event
# that fires after any source becomes available loads the vars and self-removes.
#
# op-reload: force a fresh fetch (use after rotating a token).
#
# Edit only the map below.

function __op_secrets_vars
    # One name per line so `for v in (__op_secrets_vars)` iterates correctly.
    printf '%s\n' CLOCKWORK_API JIRA_API_TOKEN JIRA_TOKEN GITLAB_TOKEN
end

function __op_secrets_refs
    # Returns NAME ref pairs, one pair per call to the caller via stdout.
    # Format: NAME<TAB>ref  (one line each)
    printf 'CLOCKWORK_API\top://Employee/CLOCKWORK_API/credential\n'
    printf 'JIRA_API_TOKEN\top://Employee/JIRA_API_TOKEN/credential\n'
    printf 'JIRA_TOKEN\top://Employee/JIRA_TOKEN/credential\n'
    printf 'GITLAB_TOKEN\top://Employee/GITLAB_TOKEN/credential\n'
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

# Main loader: tries all sources, falls back to fetching.
function op-load
    set -q OP_SECRETS_LOADED; and return 0

    # Source 2: tmux global env (fast, no file needed).
    if __op_load_from_tmux
        set -gx OP_SECRETS_LOADED 1
        return 0
    end

    # Source 3: cache file.
    if __op_load_from_cache
        __op_sync_tmux
        set -gx OP_SECRETS_LOADED 1
        return 0
    end

    # Source 4: fetch from 1Password (interactive + has tools only).
    status is-interactive; or return 1
    type -q op; or return 1
    set -l helper $HOME/.config/op/op-fetch.sh
    test -f $helper; or return 1

    set -l cache (__op_cache_path)
    set -l rt (dirname $cache)
    set -l lock $rt/op-secrets.lock
    set -l spec (mktemp $rt/op-spec.XXXXXX)
    __op_secrets_refs > $spec

    if type -q flock
        flock -w 20 $lock sh $helper $cache $spec
    else
        sh $helper $cache $spec
    end
    rm -f $spec

    if __op_load_from_cache
        __op_sync_tmux
        set -gx OP_SECRETS_LOADED 1
        return 0
    end

    return 1
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
    op-load
end

# Lazy pickup hooks: fire on BOTH fish_prompt AND fish_preexec so that idle
# panes that started before auth don't need user interaction to catch up.
# Both hooks check tmux global env first -- no file needed -- so they pick up
# vars the instant another pane finishes its fetch, even without a re-render.
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

# Run at shell startup.
op-load

# If loaded: erase both lazy hooks (zero per-prompt cost for normal shells).
# If not:    keep both hooks so the pane self-heals on the next event.
if set -q OP_SECRETS_LOADED
    functions -e __op_lazy_prompt __op_lazy_preexec
end
