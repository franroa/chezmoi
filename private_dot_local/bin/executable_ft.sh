#!/bin/sh
# Pick a host, fetch its domain password from 1Password, and open a new tmux
# session that SSHes into the host, authenticating automatically (no sshpass,
# no pasting) via SSH_ASKPASS.

. /home/froa/.local/bin/ssh-op-lib.sh

echo "Starting host selection..." >&2
host=$(ssh_select_host)
if [ -z "$host" ]; then
  echo "No host selected, exiting." >&2
  exit 0
fi
echo "Selected host: $host" >&2

user=$(ssh_host_user "$host")
domain=$(ssh_user_domain "$user")
echo "User for $host: $user (domain: $domain)" >&2

echo "Signing in to 1Password..." >&2
if ! op_ensure_signin; then
  echo "Error: 1Password sign-in failed" >&2
  exit 1
fi

pass=$(op_domain_password "$domain")
if [ -z "$pass" ]; then
  echo "Error: no password found in vault '$OP_VAULT' for domain '$domain'" >&2
  exit 1
fi

session="ssh-$host"
# On ssh failure keep the tmux pane open so the error is visible instead of the
# session vanishing instantly.
cmd="ssh -tt -o ConnectTimeout=10 -o StrictHostKeyChecking=no '$user@$host' || { ec=\$?; printf '\n[ft] ssh to %s failed (exit %s). Press Enter to close...' '$host' \"\$ec\"; read _; }"

echo "Connecting to $user@$host in tmux session '$session'..." >&2
ssh_tmux_launch "$session" "$pass" "$cmd"
