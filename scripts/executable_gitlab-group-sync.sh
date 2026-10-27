#!/usr/bin/env bash
#
# Clone or update every repo in one or more GitLab groups (subgroups included)
# under $DEV_ROOT (default ~/dev), mirroring the GitLab path:
#   technosylva/platform/foo  ->  ~/dev/technosylva/platform/foo
#
# Pass 1: clone missing repos. Existing repos with uncommitted or untracked
#         changes are left alone. Everything else is checked out on main and
#         fast-forwarded to origin/main.
# Pass 2: for repos that are on an up-to-date main, delete your branches
#         (local and origin). Every deletion asks first.
# Summary: repos that could not be cloned or pulled on main are listed last.
#
# Usage: gitlab-group-sync.sh <group-path> [<group-path>...]
#        gitlab-group-sync.sh technosylva/platform

set -uo pipefail

DEV_ROOT="${DEV_ROOT:-$HOME/dev}"
BASE_BRANCH=main
PROTECTED_BRANCHES=(main master develop develop_new_structure)

SYNC_FAILURES=()
CLEANUP_FAILURES=()

log() { printf '\n==> %s\n' "$*"; }
info() { printf '    %s\n' "$*"; }
fail() { SYNC_FAILURES+=("$1: $2"); info "FAILED: $2"; }

# Asks on the terminal; anything other than y/Y (including no tty) is a no.
confirm() {
  local reply
  read -r -p "    $1 [y/N] " reply </dev/tty || return 1
  [[ $reply =~ ^[Yy]$ ]]
}

is_protected() {
  local name=$1 p
  for p in "${PROTECTED_BRANCHES[@]}"; do
    [[ $name == "$p" ]] && return 0
  done
  return 1
}

# Prints path_with_namespace of every project in a group, subgroups included.
list_projects() {
  local encoded json
  encoded=$(printf '%s' "$1" | jq -sRr @uri) || return 1
  json=$(glab api --paginate "groups/$encoded/projects?include_subgroups=true&per_page=100") || return 1
  printf '%s' "$json" | jq -r -s 'add // [] | .[].path_with_namespace'
}

# Returns 0 when the repo ends up on an up-to-date main, 1 otherwise.
sync_repo() {
  local path=$1 dest="$DEV_ROOT/$1" out

  if [[ ! -e $dest ]]; then
    info "cloning"
    mkdir -p "$(dirname "$dest")"
    if ! out=$(glab repo clone "$path" "$dest" 2>&1); then
      fail "$path" "clone failed: $out"
      return 1
    fi
  fi

  if [[ $(git -C "$dest" rev-parse --show-toplevel 2>/dev/null) != "$(realpath "$dest")" ]]; then
    fail "$path" "$dest exists but is not a git repo"
    return 1
  fi

  if [[ -n $(git -C "$dest" status --porcelain) ]]; then
    fail "$path" "uncommitted or untracked changes, left alone"
    return 1
  fi

  if ! out=$(git -C "$dest" checkout -q "$BASE_BRANCH" 2>&1); then
    fail "$path" "checkout $BASE_BRANCH failed: $out"
    return 1
  fi

  if ! out=$(git -C "$dest" pull -q --ff-only origin "$BASE_BRANCH" 2>&1); then
    fail "$path" "pull of $BASE_BRANCH failed (not a fast-forward?): $out"
    return 1
  fi

  info "$BASE_BRANCH is up to date"
  return 0
}

# A branch is yours when its tip was authored with your git email, or when it
# has commits of yours that are not on the base branch.
is_mine() {
  local dest=$1 ref=$2 base=$3 email=$4
  [[ $(git -C "$dest" log -1 --format=%ae "$ref") == "$email" ]] && return 0
  [[ -n $(git -C "$dest" log -n 1 -F --author="$email" --format=%H "$base..$ref" 2>/dev/null) ]]
}

delete_local() {
  local path=$1 dest=$2 name=$3 out
  if confirm "delete local branch '$name'?"; then
    if out=$(git -C "$dest" branch -d "$name" 2>&1); then
      info "deleted local '$name'"
      return
    fi
    info "$out"
    if confirm "'$name' is not merged into $BASE_BRANCH. force delete?"; then
      if out=$(git -C "$dest" branch -D "$name" 2>&1); then
        info "force deleted local '$name'"
      else
        CLEANUP_FAILURES+=("$path: local $name: $out")
        info "FAILED: $out"
      fi
    fi
  fi
}

delete_remote() {
  local path=$1 dest=$2 name=$3 out
  if confirm "delete remote branch 'origin/$name'?"; then
    if out=$(git -C "$dest" push -q origin --delete "$name" 2>&1); then
      info "deleted origin/$name"
    else
      CLEANUP_FAILURES+=("$path: origin/$name: $out")
      info "FAILED: $out"
    fi
  fi
}

cleanup_branches() {
  local path=$1 dest="$DEV_ROOT/$1" email base name names out

  email=$(git -C "$dest" config user.email)
  if [[ -z $email ]]; then
    info "no user.email configured, skipping branch cleanup"
    return
  fi

  if ! out=$(git -C "$dest" fetch -q --prune origin 2>&1); then
    info "fetch failed, skipping branch cleanup: $out"
    return
  fi
  base="origin/$BASE_BRANCH"

  # Branches checked out in any worktree (e.g. aoe sessions) can't be deleted.
  local checked_out
  checked_out=$(git -C "$dest" worktree list --porcelain | sed -n 's|^branch refs/heads/||p')

  names=$(git -C "$dest" for-each-ref --format='%(refname:strip=2)' refs/heads)
  while IFS= read -r name; do
    [[ -z $name ]] && continue
    is_protected "$name" && continue
    if grep -qxF -- "$name" <<<"$checked_out"; then
      info "local  $name  (checked out in a worktree, skipped)"
      continue
    fi
    is_mine "$dest" "refs/heads/$name" "$base" "$email" || continue
    info "local  $name  ($(git -C "$dest" log -1 --format='%h %ar, %s' "refs/heads/$name"))"
    delete_local "$path" "$dest" "$name"
  done <<<"$names"

  names=$(git -C "$dest" for-each-ref --format='%(refname:strip=3)' refs/remotes/origin)
  while IFS= read -r name; do
    [[ -z $name || $name == HEAD ]] && continue
    is_protected "$name" && continue
    is_mine "$dest" "refs/remotes/origin/$name" "$base" "$email" || continue
    info "origin $name  ($(git -C "$dest" log -1 --format='%h %ar, %s' "refs/remotes/origin/$name"))"
    delete_remote "$path" "$dest" "$name"
  done <<<"$names"
}

main() {
  if (($# == 0)); then
    echo "usage: $(basename "$0") <group-path> [<group-path>...]" >&2
    echo "example: $(basename "$0") technosylva/platform" >&2
    exit 2
  fi

  local tool
  for tool in glab git jq; do
    command -v "$tool" >/dev/null || { echo "error: $tool not found in PATH" >&2; exit 1; }
  done
  mkdir -p "$DEV_ROOT"

  local group path listing
  local -a all_repos repos synced
  for group in "$@"; do
    log "Listing projects in $group"
    if ! listing=$(list_projects "$group"); then
      SYNC_FAILURES+=("$group: could not list projects (is glab authenticated?)")
      info "FAILED: could not list projects for $group"
      continue
    fi
    while IFS= read -r path; do
      [[ -n $path ]] && all_repos+=("$path")
    done <<<"$listing"
  done

  if ((${#all_repos[@]} == 0)); then
    echo "no repos found"
    exit 0
  fi
  mapfile -t repos < <(printf '%s\n' "${all_repos[@]}" | sort -u)

  log "Syncing ${#repos[@]} repos into $DEV_ROOT"
  for path in "${repos[@]}"; do
    printf '\n[%s]\n' "$path"
    if sync_repo "$path"; then
      synced+=("$path")
    fi
  done

  log "Cleaning up your branches (every deletion asks first)"
  for path in "${synced[@]}"; do
    printf '\n[%s]\n' "$path"
    cleanup_branches "$path"
  done

  log "Summary"
  if ((${#SYNC_FAILURES[@]})); then
    echo "Repos that could NOT be cloned or pulled on $BASE_BRANCH:"
    printf '  - %s\n' "${SYNC_FAILURES[@]}"
  else
    echo "All ${#repos[@]} repos are on $BASE_BRANCH and up to date."
  fi
  if ((${#CLEANUP_FAILURES[@]})); then
    echo "Branch deletions that failed:"
    printf '  - %s\n' "${CLEANUP_FAILURES[@]}"
  fi
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
