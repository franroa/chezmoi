# Auto-assemble a modular component pipeline when entering a GitLab repo.
#
# Fires on directory change. Guards heavily so it is cheap and non-intrusive:
#   - only inside a git repo whose origin points at gitlab
#   - only once per repo per shell session (in-memory set)
#   - skips if .gitlab-ci.dynamic.yml is newer than HEAD already
#   - runs `gctui assemble --quiet` in the background; never blocks the prompt
#
# Disable entirely:  set -U CI_INJECT_AUTO 0   (default: on)
# Force a re-run:     gctui assemble   (or the gitlab leader: prefix G j)

set -q CI_INJECT_AUTO; or set -g CI_INJECT_AUTO 1

function __ci_inject_on_pwd --on-variable PWD
    test "$CI_INJECT_AUTO" = 1; or return
    status is-interactive; or return

    # Inside a git work tree?
    set -l root (git rev-parse --show-toplevel 2>/dev/null); or return
    # GitLab remote?
    set -l url (git -C $root remote get-url origin 2>/dev/null); or return
    string match -qr 'gitlab' -- $url; or return

    # Once per repo per session.
    set -q __ci_inject_seen; or set -g __ci_inject_seen
    contains -- $root $__ci_inject_seen; and return
    set -a __ci_inject_seen $root

    # Already have a fresh overlay? skip.
    if test -f "$root/.gitlab-ci.dynamic.yml"
        test "$root/.gitlab-ci.dynamic.yml" -nt "$root/.git/HEAD"; and return
    end

    set -l gctui "$HOME/.local/bin/gctui"
    test -x "$gctui"; or return
    # Background, quiet; surface a one-line hint if it produced a file.
    fish -c "$gctui assemble --quiet $root >/dev/null 2>&1; and echo '↯ gctui: pipeline ready ($root/.gitlab-ci.dynamic.yml) — prefix G v to view'" &
    disown 2>/dev/null
end
