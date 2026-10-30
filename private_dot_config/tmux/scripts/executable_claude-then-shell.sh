#!/usr/bin/env bash
# aoe agent wrapper, used via `aoe add --cmd-override`: run claude with the args
# aoe appends (--dangerously-skip-permissions --session-id ...), then drop into
# an interactive shell in the same dir instead of letting the pane die (aoe sets
# remain-on-exit, so it would otherwise sit there dead). From that shell, C-b o
# relaunches claude in the pane (workspace-focus.sh sees a bare shell).
claude "$@"
exec "$(tmux show -gv default-shell 2>/dev/null || echo bash)"
