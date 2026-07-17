#!/usr/bin/env bash
# AOE scratchpad — quick-create a named AOE *scratch* session (project-
# independent, lives under .../agent-of-empires/scratch/).
#
# Bound to a tmux popup (prefix-A -> O). The popup is a small dialog: pick the
# AOE profile (workspace), enter a name, and it ensures the scratch session
# titled "SP-<name>" exists and is running in that profile (creating it on first
# use), then switches the client that opened the popup into that session and
# exits (so the popup closes onto the now-focused session). The parent client is
# handed in via TMUX_PARENT_CLIENT (-e in the binding); without it we just leave
# the session running and print a notice.
#
# Sessions are never removed here -- this only creates/starts them. Removal is
# only ever explicit via `aoe rm`; the docs default to wiping the scratch dir
# then, so use `aoe rm --keep-scratch` if you ever want to delete the session
# but keep its files. See https://www.agent-of-empires.com/guides/scratch-sessions/
set -u

AOE=/home/linuxbrew/.linuxbrew/bin/aoe
command -v aoe >/dev/null 2>&1 && AOE=aoe

PREFIX="SP-"

die() { echo "aoe-scratchpad: $*" >&2; sleep 1.5; exit 1; }

# Pick the AOE profile (workspace). The default profile is listed first so it's
# the pre-selected fzf row. With a single profile we skip the picker. Scoping
# everything below to the chosen profile is just a matter of exporting the env
# var that every `aoe` subcommand reads.
mapfile -t PROFILES < <("$AOE" profile list 2>/dev/null \
    | grep -E '^[[:space:]]+' \
    | sed -E 's/^[[:space:]]*\*?[[:space:]]*//; s/ \(default\)//; s/[[:space:]]+$//' \
    | sed '/^$/d')

PROFILE=""
if [[ ${#PROFILES[@]} -gt 1 ]]; then
    if command -v fzf >/dev/null 2>&1; then
        PROFILE=$(printf '%s\n' "${PROFILES[@]}" \
            | fzf --reverse --height=100% --prompt="profile: " \
                  --header="AOE scratchpad — pick a profile") || exit 0
    else
        i=1; for p in "${PROFILES[@]}"; do printf '  %d) %s\n' "$i" "$p"; i=$((i+1)); done
        read -r -p "  profile [1]: " n; n=${n:-1}
        PROFILE="${PROFILES[$((n-1))]:-}"
    fi
    [[ -z "$PROFILE" ]] && exit 0
elif [[ ${#PROFILES[@]} -eq 1 ]]; then
    PROFILE="${PROFILES[0]}"
fi
[[ -n "$PROFILE" ]] && export AGENT_OF_EMPIRES_PROFILE="$PROFILE"

# Prompt for the suffix; the popup gives us an interactive TTY. The "SP-" prefix
# is shown inline so you only type the rest. Empty input (or Ctrl-C) cancels.
printf '\n  AOE scratchpad%s\n\n' "${PROFILE:+ [$PROFILE]}"
read -e -r -p "  session name: ${PREFIX}" NAME || exit 0

# Normalise to the characters aoe keeps verbatim in the tmux session name
# (aoe turns e.g. spaces into underscores). Doing it up front means the aoe
# title and the cleaned tmux name can't drift apart — so the session shows the
# same name in the dashboard as you see in tmux — and reusing a name finds the
# same session instead of spawning a duplicate. Runs of other chars collapse to
# a single underscore; leading/trailing underscores are trimmed.
NAME=$(printf '%s' "$NAME" | sed -E 's/[^A-Za-z0-9_-]+/_/g; s/^_+//; s/_+$//')
[[ -z "$NAME" ]] && exit 0

TITLE="${PREFIX}${NAME}"

# Exact-title match among AOE scratch sessions.
find_id() {
    "$AOE" list --json 2>/dev/null | jq -r --arg t "$TITLE" '
        [ .[] | select(.title == $t and (.path | contains("/agent-of-empires/scratch/"))) ]
        | sort_by(.created_at) | last | .id // empty'
}

ID=$(find_id)

# Not there yet -- create the named scratch session.
if [[ -z "$ID" ]]; then
    echo "  creating ${TITLE} ..."
    "$AOE" add --scratch -t "$TITLE" >/dev/null || die "failed to create ${TITLE}"
    ID=$(find_id)
    [[ -z "$ID" ]] && die "scratch session ${TITLE} created but not found"
fi

# Make sure its tmux process is up (harmless if already running).
"$AOE" session start "$ID" >/dev/null 2>&1 || true

# Resolve the real tmux session name. We match on the "_<hash>" suffix (first 8
# of the id), which is stable across renames, so this keeps working below.
ID8=${ID:0:8}
find_ts() {
    env -u TMUX tmux list-sessions -F '#{session_name}' 2>/dev/null \
        | grep -E "_${ID8}\$" | head -1
}
TS=""
for _ in 1 2 3 4 5; do
    TS=$(find_ts)
    [[ -n "$TS" ]] && break
    sleep 0.3
done

# Authoritative pass: name the aoe session after its real tmux session, with the
# "aoe_" prefix and "_<hash>" suffix stripped — i.e. exactly the name you see in
# tmux. With the normalisation above this is already the case, so the rename
# only fires in the rare event aoe altered the name further (re-resolve TS after,
# since renaming the title also renames the tmux session).
if [[ -n "$TS" ]]; then
    CLEAN="${TS#aoe_}"; CLEAN="${CLEAN%_*}"
    if [[ -n "$CLEAN" && "$CLEAN" != "$TITLE" ]]; then
        "$AOE" session rename "$ID" -t "$CLEAN" >/dev/null 2>&1 || true
        TITLE="$CLEAN"
        TS=$(find_ts)
    fi
fi

# Focus it: switch the client that opened this popup into the session, then exit
# so the -E popup closes onto it. If we couldn't resolve the tmux name or the
# parent client wasn't handed in, fall back to leaving it running with a notice.
if [[ -n "$TS" && -n "${TMUX_PARENT_CLIENT:-}" ]] \
    && tmux switch-client -c "$TMUX_PARENT_CLIENT" -t "$TS" 2>/dev/null; then
    exit 0
fi
echo "  ${TITLE} ready${PROFILE:+ [$PROFILE]}."
exit 0
