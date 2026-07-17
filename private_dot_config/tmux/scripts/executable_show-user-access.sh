#!/usr/bin/env bash
#
# show-user-access.sh
#
# Show every Azure subscription a user can see and the role(s) granting that access
# (direct, inherited from a management group, or via group membership).
#
# Usage:
#   ./show-user-access.sh <user>
#
#   <user> can be:
#     - a UPN              (e.g. jdoe@technosylva.com)
#     - an email / mail    (e.g. ggarner@technosylva.com  — works for guest #EXT# users)
#     - an object ID (GUID)
#
# Requires: az CLI (logged in) and jq.

set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  grep '^#' "$0" | sed 's/^# \{0,1\}//'
  exit 1
fi

# Accept the user as an argument, or prompt for it (e.g. when launched from the
# tmux which-key popup with no args).
if [[ $# -ge 1 && -n "$1" ]]; then
  INPUT="$1"
else
  read -rp "User (UPN/email/objectId): " INPUT
fi

if [[ -z "${INPUT// /}" ]]; then
  echo "ERROR: no user provided." >&2
  exit 1
fi

command -v az >/dev/null || { echo "ERROR: az CLI not found." >&2; exit 1; }
command -v jq >/dev/null || { echo "ERROR: jq not found." >&2; exit 1; }

# --- Resolve the input to an object ID -------------------------------------
resolve_object_id() {
  local input="$1"

  # Already a GUID?
  if [[ "$input" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; then
    echo "$input"
    return 0
  fi

  # Try direct UPN lookup.
  local id
  id=$(az ad user show --id "$input" --query id -o tsv 2>/dev/null || true)
  if [[ -n "$id" ]]; then echo "$id"; return 0; fi

  # Fall back to a directory search by mail or UPN prefix (covers guest #EXT# users).
  id=$(az ad user list \
        --query "[?mail=='${input}' || userPrincipalName=='${input}' || starts_with(userPrincipalName,'${input%%@*}')].id | [0]" \
        -o tsv 2>/dev/null || true)
  if [[ -n "$id" && "$id" != "null" ]]; then echo "$id"; return 0; fi

  return 1
}

OBJECT_ID=$(resolve_object_id "$INPUT") || {
  echo "ERROR: could not resolve a user from '$INPUT'." >&2
  exit 1
}

# Show who we resolved.
USER_INFO=$(az ad user show --id "$OBJECT_ID" \
  --query "{displayName:displayName, upn:userPrincipalName, mail:mail, id:id}" -o json 2>/dev/null || echo '{}')
echo "User:"
echo "$USER_INFO" | jq -r 'to_entries[] | "  \(.key): \(.value // "-")"'
echo

# --- Iterate subscriptions --------------------------------------------------
printf "%-22s %-38s %s\n" "SUBSCRIPTION" "SUBSCRIPTION ID" "ACCESS"
printf "%-22s %-38s %s\n" "----------------------" "--------------------------------------" "------"

az account list --all --query "sort_by([?state=='Enabled'], &name)[].{name:name, id:id}" -o json \
| jq -c '.[]' \
| while read -r row; do
    name=$(echo "$row" | jq -r '.name')
    sub=$(echo "$row" | jq -r '.id')

    roles=$(az role assignment list \
              --assignee "$OBJECT_ID" \
              --scope "/subscriptions/$sub" \
              --include-inherited --include-groups \
              --query "[].{role:roleDefinitionName, via:principalName, type:principalType}" \
              -o json 2>/dev/null || echo '[]')

    count=$(echo "$roles" | jq 'length')
    if [[ "$count" -eq 0 ]]; then
      printf "%-22s %-38s %s\n" "$name" "$sub" "(no access)"
    else
      # First role on the subscription line, the rest indented underneath.
      echo "$roles" | jq -r '
        to_entries[] |
        (if .key == 0 then "" else "FIRST" end) as $marker |
        "\(.value.role) [via \(.value.via)]"' \
      | { first=1
          while IFS= read -r line; do
            if [[ $first -eq 1 ]]; then
              printf "%-22s %-38s %s\n" "$name" "$sub" "$line"
              first=0
            else
              printf "%-22s %-38s %s\n" "" "" "$line"
            fi
          done; }
    fi
  done

# When attached to a terminal (e.g. the tmux which-key popup), keep the window
# open until the user presses "q".
if [[ -t 0 && -t 1 ]]; then
  echo
  printf 'Press q to close... '
  while IFS= read -rsn1 key; do
    [[ "$key" == "q" ]] && break
  done
  echo
fi
