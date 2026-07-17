#!/bin/sh
# Diagnostic for ft.sh / oil-ssh.sh: runs the op fetch + ssh auth for one host
# (default CCDEVDBS1), no tmux, no fzf, logging everything to a file.
# Usage: ./ssh-diag.sh [HOST]

. /home/froa/.local/bin/ssh-op-lib.sh

LOG=/tmp/claude-1001/-home-froa--local/a48623b3-c501-4a13-bfec-0c9d64ca02e4/scratchpad/ssh-diag.log
host="${1:-CCDEVDBS1}"

{
  echo "===== ssh-diag $(date) ====="
  echo "host=$host  OP_VAULT=$OP_VAULT  TMUX=${TMUX:-<none>}"
  echo "-- op whoami --"
  op whoami 2>&1
  user=$(ssh_host_user "$host"); echo "user=$user"
  domain=$(ssh_user_domain "$user"); echo "domain=$domain"
  echo "-- op_ensure_signin --"
  if op_ensure_signin; then echo "signin: OK"; else echo "signin: FAILED"; fi
  pass=$(op_domain_password "$domain")
  echo "pass_len=${#pass}"
  echo "-- direct ssh -v (askpass, no tmux) --"
  SSH_ASKPASS="$SSH_ASKPASS_HELPER" SSH_ASKPASS_REQUIRE=force SSH_PASSWORD="$pass" \
    ssh -v -o ConnectTimeout=12 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o NumberOfPasswordPrompts=1 "$user@$host" 'echo REMOTE_OK; hostname' 2>&1
  echo "ssh_exit=$?"
  echo "===== end ====="
} >"$LOG" 2>&1

echo "Diagnostic written to: $LOG"
echo "(If op asked for your password, that's normal.)"
