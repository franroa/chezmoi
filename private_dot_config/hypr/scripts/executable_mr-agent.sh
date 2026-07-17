#!/usr/bin/env bash
# Spawn an Agent of Empires (aoe) Claude session to work on GitLab merge
# requests, launched from a notification "Agent" button. Runs INSIDE a fresh
# ghostty window (the button does `ghostty -e mr-agent.sh <mode> ...`), so the
# spawned aoe session is visible and we attach to it at the end.
#
# Modes:
#   review <mr_web_url>   One MR: a Claude (sonnet 4.6) session that checks the
#                         MR out locally and runs the /code-review skill on it.
#                         Wired into every gitlab-monitor.sh per-MR notification.
#   digest                All MRs merged the previous working day (read from the
#                         morning-digest state file): a Claude session that
#                         summarises every MR. Wired into the morning digest.
#
# The model is forwarded to the claude binary via aoe's --extra-args; the agent
# itself is the supported "claude" tool that aoe runs in tmux.

set -uo pipefail

# hyprpanel spawns the action command with a minimal PATH; rebuild a usable one
# (linuxbrew for aoe/glab, ~/.local/bin for claude) -- same pattern as
# tuicr-review.sh.
export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

MODEL="claude-sonnet-4-6"          # "sonnet 6" = Sonnet 4.6
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/morning-digest"
MRS_FILE="$STATE_DIR/last_mrs.txt"
GITLAB_CREDS_FILE="$HOME/.config/gitlab-credentials"
SESSION_BOOT_WAIT=5                # let claude reach its prompt before send

die() { echo "❌ $*" >&2; echo "Press Enter to close."; read -r _; exit 1; }

# --- GitLab token (mirror gitlab-monitor resolution) so glab works in-session ---
resolve_gitlab_token() {
    local tok="${GITLAB_TOKEN:-}"
    if [[ -n "$tok" && "$tok" != "your_token" ]]; then printf '%s' "$tok"; return 0; fi
    local cache="${XDG_RUNTIME_DIR:-/tmp/op-$(id -u)}/op-secrets.cache.fish"
    if [[ -r "$cache" ]]; then
        tok="$(awk '$1=="set" && $3=="GITLAB_TOKEN" {print $4; exit}' "$cache")"
        tok="${tok#[\"\']}"; tok="${tok%[\"\']}"
        [[ -n "$tok" ]] && { printf '%s' "$tok"; return 0; }
    fi
    if [[ -f "$GITLAB_CREDS_FILE" ]]; then
        tok="$(grep -v '^#' "$GITLAB_CREDS_FILE" | sed -n 's/^[[:space:]]*GITLAB_TOKEN=//p' | tail -n1)"
        tok="${tok%\"}"; tok="${tok#\"}"
        [[ -n "$tok" && "$tok" != "your_token" ]] && { printf '%s' "$tok"; return 0; }
    fi
    return 1
}

command -v aoe   >/dev/null || die "aoe not found on PATH"
command -v jq    >/dev/null || die "jq not found on PATH"

tok="$(resolve_gitlab_token || true)"
if [[ -n "$tok" ]]; then
    export GITLAB_TOKEN="$tok"
    export GITLAB_HOST="gitlab.com"
fi

# Newest session id (aoe has no --json on `add`; diff by created_at like the
# existing aoen-session.sh helper does).
newest_session_id() {
    aoe list --json 2>/dev/null | jq -r 'sort_by(.created_at) | last | .id // empty'
}

launch_and_drive() {   # <session_id> <message>
    local sid="$1" msg="$2"
    [[ -z "$sid" ]] && die "could not determine the new aoe session id"
    echo "🤖 aoe session $sid starting (claude $MODEL)…"
    sleep "$SESSION_BOOT_WAIT"
    aoe send "$sid" "$msg" || echo "⚠ aoe send failed; the message is queued on next revive."
    exec aoe session attach "$sid"
}

mode="${1:-}"; shift || true

case "$mode" in
  review)
    mr_url="${1:-}"
    [[ -z "$mr_url" ]] && die "usage: mr-agent.sh review <mr_web_url>"
    # Parse "<project/path>/-/merge_requests/<iid>" out of the URL.
    iid="$(printf '%s' "$mr_url"  | grep -oE 'merge_requests/[0-9]+' | grep -oE '[0-9]+' | head -1)"
    proj="$(printf '%s' "$mr_url" | sed -E 's#^https?://[^/]+/##; s#/-/merge_requests/.*$##')"
    [[ -z "$iid" || -z "$proj" ]] && die "could not parse project/iid from: $mr_url"

    title="review ${proj##*/}!${iid}"
    workdir="$HOME/.cache/mr-agent/$(printf '%s' "${proj}_${iid}" | tr '/' '_')"
    mkdir -p "$workdir"

    aoe add "$workdir" -t "$title" -c claude --extra-args "--model $MODEL" -y -l >/dev/null 2>&1 \
        || die "aoe add failed"
    sleep 2
    read -r -d '' msg <<EOF || true
Resume GitLab merge request ${mr_url} (project ${proj}, MR !${iid}).
Step 1 — check it out into the current directory:
  • if this directory is not yet a git repo, run: glab repo clone ${proj} .
  • then check out the MR branch: glab mr checkout ${iid}
    (if the source branch was deleted after merge, fetch the MR ref instead:
     git fetch origin merge-requests/${iid}/head:mr-${iid} && git checkout mr-${iid})
Step 2 — run the /code-review skill on this MR's diff and give me a concise
summary of the findings (correctness bugs first, then cleanups).
EOF
    launch_and_drive "$(newest_session_id)" "$msg"
    ;;

  digest)
    list="$(cat "$MRS_FILE" 2>/dev/null)"
    [[ -z "$list" ]] && list="(no stored MR list — run morning-digest.sh first)"
    aoe add --scratch -t "MR digest summary" -c claude --extra-args "--model $MODEL" -y -l >/dev/null 2>&1 \
        || die "aoe add failed"
    sleep 2
    read -r -d '' msg <<EOF || true
Summarise the GitLab platform merge requests merged in the last working day,
listed below as "web_url — title (project!iid)". For each MR, fetch it with
\`glab mr view <web_url>\` (glab is authenticated) or the GitLab API, then write
a one-line plain-English summary of what changed and why it matters. Group the
summaries by project and flag anything risky (DB migrations, infra/Terraform,
security, breaking changes). End with a 2–3 sentence overall "state of the day".

Merge requests:
${list}
EOF
    launch_and_drive "$(newest_session_id)" "$msg"
    ;;

  *)
    die "usage: mr-agent.sh {review <mr_web_url>|digest}"
    ;;
esac
