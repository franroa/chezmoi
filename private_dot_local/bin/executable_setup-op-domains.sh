#!/bin/sh
# One-time setup: create a 1Password item per Active Directory domain so that
# ft.sh / oil-ssh.sh can fetch passwords by domain.
#
# Source of the passwords: the per-domain fields of your existing "BBDD" item
# (field label == domain name, e.g. a field labelled "TSYLHA"). Override the
# source item with SRC_ITEM=... and the vault with OP_VAULT=...
#
# Run this once, interactively, in your own terminal:
#   ./setup-op-domains.sh

. /home/froa/.local/bin/ssh-op-lib.sh

SRC_ITEM="${SRC_ITEM:-BBDD}"

if ! op_ensure_signin; then
  echo "Error: 1Password sign-in failed" >&2
  exit 1
fi

# Distinct domains derived from the SSH config Users.
domains=$(grep -E '^[[:space:]]*User\b' "$HOME/.ssh/config" \
  | sed -E 's/^[[:space:]]*User[[:space:]]+//' \
  | sort -u \
  | while IFS= read -r u; do ssh_user_domain "$u"; done \
  | sort -u)

echo "Source item: '$SRC_ITEM' (vault '$OP_VAULT')" >&2
echo "Domains: $(echo "$domains" | tr '\n' ' ')" >&2

for d in $domains; do
  pass=$(op item get "$SRC_ITEM" --vault "$OP_VAULT" --fields "label=$d" --reveal 2>/dev/null)
  if [ -z "$pass" ]; then
    echo "SKIP $d: no field labelled '$d' in item '$SRC_ITEM'" >&2
    continue
  fi
  if op item get "$d" --vault "$OP_VAULT" >/dev/null 2>&1; then
    if op item edit "$d" --vault "$OP_VAULT" "password=$pass" >/dev/null 2>&1; then
      echo "UPDATED $d" >&2
    else
      echo "FAILED to update $d" >&2
    fi
  else
    if op item create --category password --title "$d" --vault "$OP_VAULT" "password=$pass" >/dev/null 2>&1; then
      echo "CREATED $d" >&2
    else
      echo "FAILED to create $d" >&2
    fi
  fi
done

echo "Done." >&2
