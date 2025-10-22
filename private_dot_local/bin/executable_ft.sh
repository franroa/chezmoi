#!/bin/sh

echo "Starting host selection..." >&2

# Select a host via fzf
host=$(grep 'Host\>' ~/.ssh/config | sed 's/^Host //' | grep -v '\*' | fzf --cycle --layout=reverse)

if [ -z "$host" ]; then
  echo "No host selected, exiting." >&2
  exit 0
fi

echo "Selected host: $host" >&2

# Get user from host name
user=$(ssh -G "$host" | grep '^user\>' | sed 's/^user //')
echo "User for $host: $user" >&2

# Get password using tpass.sh script (copies to clipboard)
echo "Retrieving password for $host..." >&2
/home/froa/.local/bin/tpass.sh "$host"

echo "Connecting to $user@$host..." >&2

# Test if sshpass is available
if ! command -v sshpass >/dev/null 2>&1; then
  echo "Error: sshpass is not installed" >&2
  exit 1
fi

# Use password from clipboard
export SSHPASS="$(xclip -selection clipboard -o)"
echo "About to run: sshpass -e ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no $user@$host" >&2
sshpass -e ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$user@$host"
