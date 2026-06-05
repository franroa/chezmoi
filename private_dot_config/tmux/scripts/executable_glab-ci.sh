#!/usr/bin/env bash
# GitLab CI viewer (Option B): a navigable TREE of the current branch's pipeline
# and ALL downstream child/grandchild pipelines + their jobs, with a live log
# preview pane on the right. Child job logs come straight from the trace API,
# so they always work — unlike `glab ci view`.
#
#   COMMAND mode (default) — single keys act on the selected job:
#     l / Enter  full log (running job follows live)
#     r retry · c cancel · p play · o open in browser
#     j/k ↑/↓ navigate · Ctrl-R refresh · f or / filter · q/Esc quit
#   FILTER mode (f or /): type to fuzzy-search; Esc returns to COMMAND mode.
#
# Subcommands (internal / help):
#   --list | --log <proj> <jobid> | --action <retry|cancel|play> <proj> <jobid> | help
set -uo pipefail

self="$(readlink -f "$0")"
GLAB="$(command -v glab || echo /home/linuxbrew/.linuxbrew/bin/glab)"
B=$'\033[1m'; D=$'\033[2m'; Rst=$'\033[0m'   # bold / dim / reset

if [ "${1:-}" = "help" ]; then
  cat <<EOF

  GitLab CI viewer — keys

    COMMAND mode (default)
      j / k · ↑ / ↓       navigate the tree
      l  or  Enter        full log of the selected job (running follows live)
      r                   retry / rerun the job
      c                   cancel the job
      p                   play a manual job
      o                   open the job in the browser
      Ctrl-R              refresh
      f  or  /            enter FILTER mode
      q  or  Esc          quit

    FILTER mode
      type                fuzzy-search the tree
      Esc                 back to COMMAND mode

  The right pane shows the selected job's log (child/grandchild jobs included).

EOF
  exit 0
fi

glyph() {
  case "$1" in
    success)            printf '\033[32m✓\033[0m' ;;
    failed)             printf '\033[31m✗\033[0m' ;;
    running)            printf '\033[36m⠿\033[0m' ;;
    pending|waiting_for_resource|preparing) printf '\033[33m◌\033[0m' ;;
    canceled|canceling) printf '\033[90m⊘\033[0m' ;;
    skipped)            printf '\033[90m⤳\033[0m' ;;
    manual)             printf '\033[35m⚙\033[0m' ;;
    created|scheduled)  printf '\033[90m·\033[0m' ;;
    *)                  printf '?' ;;
  esac
}

# Render one pipeline node: header line, then its jobs and child pipelines with
# ├─/└─ connectors; recurses into downstream pipelines.
# Row:  proj \t jobid \t weburl \t <visible tree text>
# (header/child rows carry an empty jobid -> actions are no-ops there.)
render_pipeline() {
  local proj="$1" plid="$2" header="$3" prefix="$4"
  printf '%s\t\t\t%s\n' "$proj" "$header"

  # Fetch this pipeline's jobs and bridges concurrently (cuts round-trips).
  local tj tk jobs kids
  tj="$(mktemp)"; tk="$(mktemp)"
  "$GLAB" api "projects/${proj}/pipelines/${plid}/jobs?per_page=100"    >"$tj" 2>/dev/null &
  local pj=$!
  "$GLAB" api "projects/${proj}/pipelines/${plid}/bridges?per_page=100" >"$tk" 2>/dev/null &
  local pk=$!
  wait "$pj" "$pk"
  mapfile -t jobs < <(jq -r '.[] | [(.id|tostring), (.web_url//""), .stage, .name, .status] | @tsv' "$tj" 2>/dev/null)
  mapfile -t kids < <(jq -r '.[] | select(.downstream_pipeline != null)
             | [(.downstream_pipeline.project_id|tostring),
                (.downstream_pipeline.id|tostring), .name,
                (.downstream_pipeline.status // "")] | @tsv' "$tk" 2>/dev/null)
  rm -f "$tj" "$tk"

  local total=$(( ${#jobs[@]} + ${#kids[@]} )) idx=0 conn cont
  local jid url stage name status

  for line in "${jobs[@]}"; do
    [ -z "$line" ] && continue
    IFS=$'\t' read -r jid url stage name status <<< "$line"
    idx=$((idx + 1))
    if [ "$idx" -eq "$total" ]; then conn="└─"; else conn="├─"; fi
    printf '%s\t%s\t%s\t%s%s %s  %s%s·%s%s  %s%s%s\n' \
      "$proj" "$jid" "$url" "$prefix" "$conn" "$(glyph "$status")" \
      "$D" "$stage" "$name" "$Rst" "$D" "$status" "$Rst"
  done

  local kproj kid kname kstatus
  for line in "${kids[@]}"; do
    [ -z "$line" ] && continue
    IFS=$'\t' read -r kproj kid kname kstatus <<< "$line"
    idx=$((idx + 1))
    if [ "$idx" -eq "$total" ]; then conn="└─"; cont="   "; else conn="├─"; cont="│  "; fi
    render_pipeline "$kproj" "$kid" \
      "${prefix}${conn} $(glyph "$kstatus") ${B}${kname}»${Rst} ${D}→ #${kid} ${kstatus}${Rst}" \
      "${prefix}${cont}"
  done
}

list_rows() {
  : "${TOP_PROJECT:?}" "${TOP_PIPELINE:?}"
  local st
  st="$("$GLAB" api "projects/${TOP_PROJECT}/pipelines/${TOP_PIPELINE}" 2>/dev/null | jq -r '.status // "?"')"
  render_pipeline "$TOP_PROJECT" "$TOP_PIPELINE" \
    "$(glyph "$st") ${B}${TOP_REF:-pipeline}${Rst} ${D}#${TOP_PIPELINE} ${st}${Rst}" ""
}

show_log() {
  [ -z "${2:-}" ] && { echo "— pipeline node — move to a job and press l"; return 0; }
  "$GLAB" api "projects/${1}/jobs/${2}/trace" 2>/dev/null | tail -n 2000
}

do_action() {  # verb proj jobid
  [ -z "${3:-}" ] && return 0
  "$GLAB" api --method POST "projects/${2}/jobs/${3}/${1}" >/dev/null 2>&1
}

case "${1:-}" in
  --list)   list_rows; exit 0 ;;
  --log)    show_log "$2" "${3:-}"; exit 0 ;;
  --action) do_action "$2" "$3" "${4:-}"; exit 0 ;;
esac

# ── interactive entry ────────────────────────────────────────────────────────
path="${1:-$PWD}"
cd "$path" 2>/dev/null || { echo "❌ Path not accessible: $path"; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "❌ Not a git repository"; exit 1; }
for bin in glab jq fzf; do
  command -v "$bin" >/dev/null 2>&1 || { echo "❌ Missing dependency: $bin"; exit 1; }
done

remote="$(git remote get-url origin 2>/dev/null)"
fullpath="$(printf '%s' "$remote" | sed -E 's|^ssh://git@[^/]+/||; s|^git@[^:]+:||; s|^https?://[^/]+/||; s|\.git$||')"
encoded="${fullpath//\//%2F}"
TOP_PROJECT="$("$GLAB" api "projects/${encoded}" 2>/dev/null | jq -r '.id // empty')"
[ -z "$TOP_PROJECT" ] && { echo "❌ Could not resolve project id for: $fullpath"; exit 1; }

TOP_REF="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
enc_ref="${TOP_REF//\//%2F}"
TOP_PIPELINE="$("$GLAB" api "projects/${TOP_PROJECT}/pipelines?ref=${enc_ref}&per_page=1" 2>/dev/null | jq -r '.[0].id // empty')"
[ -z "$TOP_PIPELINE" ] && { echo "ℹ️  No pipeline found for branch: $TOP_REF"; exit 0; }

export TOP_PROJECT TOP_PIPELINE TOP_REF GLAB

# Modal design (fzf's `transform` action is unreliable in this build, so we use
# direct binds + unbind/rebind):
#   COMMAND mode — letter keys act on the selected job.
#   FILTER mode (f or /) — enable-search + unbind the action letters so they type
#     into the query; Esc disables search and rebinds the letters.
LOG="execute(bash $self --log {1} {2} | less -R +G)"
RETRY="execute-silent(bash $self --action retry {1} {2})+reload(bash $self --list)+refresh-preview"
CANCEL="execute-silent(bash $self --action cancel {1} {2})+reload(bash $self --list)+refresh-preview"
PLAY="execute-silent(bash $self --action play {1} {2})+reload(bash $self --list)+refresh-preview"
OPEN="execute-silent(xdg-open {3} >/dev/null 2>&1)"

ACT_KEYS='l r c p o j k q f /'
ENTER_FILTER='enable-search+change-prompt(filter> )'
EXIT_FILTER="clear-query+disable-search+change-prompt(CI> )+reload-sync(bash $self --list)+first"
for k in $ACT_KEYS; do ENTER_FILTER="${ENTER_FILTER}+unbind($k)"; done
for k in $ACT_KEYS; do EXIT_FILTER="${EXIT_FILTER}+rebind($k)"; done

# Build the whole tree up front so fzf renders it complete and correctly
# ordered (streaming the slow API calls makes the tree reshuffle as it loads).
printf 'Loading pipeline tree #%s …\n' "$TOP_PIPELINE" >&2
rows="$(list_rows)"

fzf --ansi --delimiter '\t' --with-nth '4..' \
      --layout=reverse \
      --disabled --prompt 'CI> ' --info inline --no-multi --cycle --header-first \
      --header "branch ${TOP_REF}  #${TOP_PIPELINE}   l/↵ log · r retry · c cancel · p play · o open · f filter · q quit" \
      --preview "bash $self --log {1} {2}" \
      --preview-window 'right,58%,wrap,follow' \
      --bind "enter:$LOG" \
      --bind "l:$LOG" \
      --bind "r:$RETRY" \
      --bind "c:$CANCEL" \
      --bind "p:$PLAY" \
      --bind "o:$OPEN" \
      --bind "j:down" \
      --bind "k:up" \
      --bind "q:abort" \
      --bind "ctrl-r:reload-sync(bash $self --list)+refresh-preview" \
      --bind "f:$ENTER_FILTER" \
      --bind "/:$ENTER_FILTER" \
      --bind "esc:$EXIT_FILTER" \
      <<< "$rows" >/dev/null
