#!/bin/sh
# Shared helpers for ft.sh / oil-ssh.sh.
#
# Passwords live in 1Password: one item per Active Directory domain, titled
# after the domain (e.g. "TSYLHA"), inside the OP_VAULT vault. (As a fallback,
# the password is also looked up in a per-domain field of the "BBDD" item.)
# The domain is derived from the SSH config User (the part before the "\").
#
# Authentication is non-interactive and does NOT use sshpass: the fetched
# password is handed to ssh through the SSH_ASKPASS mechanism, set up on the
# tmux session by ssh_tmux_launch().

# 1Password vault that holds the per-domain password items.
OP_VAULT="${OP_VAULT:-Employee}"

# 1Password item that aggregates all domain passwords as fields (fallback).
OP_SRC_ITEM="${OP_SRC_ITEM:-BBDD}"

# Absolute path to the SSH_ASKPASS helper.
SSH_ASKPASS_HELPER="${SSH_ASKPASS_HELPER:-/home/froa/.local/bin/ssh-askpass-op.sh}"

# Pick a host from ~/.ssh/config via fzf (skips wildcard "Host *" entries).
ssh_select_host() {
  grep -E '^Host\b' "$HOME/.ssh/config" \
    | sed -E 's/^Host[[:space:]]+//' \
    | grep -v '\*' \
    | fzf --cycle --layout=reverse
}

# Resolve the effective SSH user for a host (may be "DOMAIN\user").
ssh_host_user() {
  ssh -G "$1" 2>/dev/null | awk '/^user /{print $2; exit}'
}

# Domain = the part before the backslash in "DOMAIN\user".
# Falls back to the whole value when there is no backslash.
ssh_user_domain() {
  case "$1" in
    *\\*) printf '%s\n' "${1%%\\*}" ;;
    *)    printf '%s\n' "$1" ;;
  esac
}

# Ensure we have a 1Password session, prompting for the account password only
# when needed. Runs in the caller's shell so the session env persists.
op_ensure_signin() {
  if op whoami >/dev/null 2>&1; then
    return 0
  fi
  eval "$(op signin)"
}

# Print the password for a domain: first its own item, then the BBDD fallback.
op_domain_password() {
  d=$1
  v=$(op item get "$d" --vault "$OP_VAULT" --fields label=password --reveal 2>/dev/null)
  if [ -z "$v" ]; then
    v=$(op item get "$OP_SRC_ITEM" --vault "$OP_VAULT" --fields "label=$d" --reveal 2>/dev/null)
  fi
  printf '%s' "$v"
}

# Open a command in a new tmux session, wired so any ssh it runs authenticates
# automatically with the given password (via SSH_ASKPASS, no sshpass).
#   ssh_tmux_launch <session-name> <password> <shell-command>
ssh_tmux_launch() {
  _session=$1
  _password=$2
  _cmd=$3
  # Use a fresh, unique session name so repeated runs never collide with a
  # stale session (which would otherwise error, or switch to a dead pane).
  _base=$_session
  _session="${_base}-$(date +%H%M%S)"
  while tmux has-session -t "$_session" 2>/dev/null; do
    _session="${_base}-$(date +%H%M%S)-$$"
  done
  # Run the command from a tiny throwaway #!/bin/sh script instead of passing it
  # inline. tmux's own argument lexer mangles complex inline commands (single
  # quotes, $?, backslashes, braces) and silently falls back to the default
  # shell (a bare prompt). Exec'ing a file path sidesteps all of that.
  _runner=$(mktemp "${TMPDIR:-/tmp}/ft-ssh.XXXXXX") || return 1
  {
    printf '#!/bin/sh\n'
    printf '%s\n' "$_cmd"
    printf 'rm -f -- "%s"\n' "$_runner"
  } >"$_runner"
  chmod +x "$_runner"

  # Always create the target session detached so it exists no matter how we
  # were invoked (normal pane, nested tmux, or a tmux popup).
  tmux new-session -d -s "$_session" \
    -e "SSH_ASKPASS=$SSH_ASKPASS_HELPER" \
    -e "SSH_ASKPASS_REQUIRE=force" \
    -e "SSH_PASSWORD=$_password" \
    "$_runner"

  if [ -n "$TMUX" ] || [ -n "$TMUX_PARENT_CLIENT" ]; then
    # Inside tmux. From a popup, switch-client must target the *parent* client
    # (the popup's own client disappears when it closes). The binding can hand
    # it in via TMUX_PARENT_CLIENT=#{client_tty}; otherwise fall back to the
    # first attached client.
    _client="${TMUX_PARENT_CLIENT:-$(tmux list-clients -F '#{client_tty}' 2>/dev/null | head -n1)}"
    if [ -n "$_client" ]; then
      tmux switch-client -c "$_client" -t "$_session"
    else
      tmux switch-client -t "$_session"
    fi
  else
    # Not in tmux: attach in the foreground.
    tmux attach-session -t "$_session"
  fi
}
