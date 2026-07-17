#!/bin/sh
# Pick a host, fetch its domain password from 1Password, and open a new tmux
# session running Neovim's Oil file manager over SSH. The SSH calls Oil makes
# authenticate automatically (no sshpass, no pasting) via SSH_ASKPASS.
# Usage: `oil-ssh.sh` (or `oil` via an alias).

. /home/froa/.local/bin/ssh-op-lib.sh

host=$(ssh_select_host)
if [ -z "$host" ]; then
  exit 0
fi

user=$(ssh_host_user "$host")
domain=$(ssh_user_domain "$user")

if ! op_ensure_signin; then
  echo "Error: 1Password sign-in failed" >&2
  exit 1
fi

pass=$(op_domain_password "$domain")
if [ -z "$pass" ]; then
  echo "Error: no password found in vault '$OP_VAULT' for domain '$domain'" >&2
  exit 1
fi

session="oil-$host"
cmd="nvim 'oil-ssh://$user@$host/' || { ec=\$?; printf '\n[oil] nvim exited (%s). Press Enter to close...' \"\$ec\"; read _; }"

ssh_tmux_launch "$session" "$pass" "$cmd"
