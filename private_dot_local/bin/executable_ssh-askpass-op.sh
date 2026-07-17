#!/bin/sh
# SSH_ASKPASS helper: prints the password that ssh asks for.
# The password is provided out-of-band via the SSH_PASSWORD environment
# variable (set on the tmux session by ft.sh / oil-ssh.sh). This lets ssh
# authenticate non-interactively without sshpass.
printf '%s\n' "$SSH_PASSWORD"
