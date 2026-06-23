#!/usr/bin/env bash
# Interactive GitLab MR picker → checkout branch → open in tuicr
# Usage: glab-mr-review.sh [repo_path]
set -uo pipefail

GLAB="$(command -v glab || echo /home/linuxbrew/.linuxbrew/bin/glab)"
TUICR="$(command -v tuicr || echo /home/linuxbrew/.linuxbrew/bin/tuicr)"
REPO_PATH="${1:-$PWD}"

cd "$REPO_PATH" || { echo "Cannot cd to $REPO_PATH"; read -r _; exit 1; }

mrs_json=$("$GLAB" mr list --output json 2>/dev/null) || {
  echo "Failed to fetch MR list. Are you in a GitLab repo?"
  read -r _
  exit 1
}

count=$(echo "$mrs_json" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))' 2>/dev/null || echo 0)
if [ "$count" = "0" ]; then
  echo "No open merge requests."
  read -r _
  exit 0
fi

selected=$(echo "$mrs_json" | python3 -c "
import json, sys
mrs = json.load(sys.stdin)
for m in mrs:
    iid   = m['iid']
    title = m.get('title','')
    author = m.get('author',{}).get('username','?')
    src   = m.get('source_branch','')
    tgt   = m.get('target_branch','')
    draft = '[DRAFT] ' if m.get('draft') or m.get('work_in_progress') else ''
    print(f'!{iid:<5} {draft}{title:<58}  \033[2m{author}\033[0m  {src} → {tgt}')
" | fzf \
  --prompt="MR> " \
  --header="Pick MR to review (Enter=checkout+tuicr, Esc=cancel)" \
  --ansi \
  --no-sort \
  --reverse)

[ -z "$selected" ] && exit 0

iid=$(echo "$selected" | sed 's/^!//' | awk '{print $1}')

mr_info=$("$GLAB" mr view "$iid" --output json 2>/dev/null) || {
  echo "Failed to fetch MR !$iid details."
  read -r _
  exit 1
}

src=$(echo "$mr_info" | python3 -c "import json,sys; print(json.load(sys.stdin)['source_branch'])")
tgt=$(echo "$mr_info" | python3 -c "import json,sys; print(json.load(sys.stdin)['target_branch'])")

echo "Checking out MR !$iid: $src → $tgt"
"$GLAB" mr checkout "$iid" 2>&1 || {
  echo "Checkout failed — trying fetch only"
  git fetch origin "$src" 2>&1
}

exec "$TUICR" -r "origin/$tgt..HEAD"
