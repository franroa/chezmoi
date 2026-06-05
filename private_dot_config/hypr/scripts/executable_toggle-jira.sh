#!/usr/bin/env bash
# Toggle a jira issue-list scratchpad (show/hide), modeled on toggle-scratch.sh
SCRATCH_CLASS="jira-scratch"

JQL='project in (SDI2402, P0004) AND assignee = currentUser() AND status not in ("Done", "Closed", "Resolved")'
JIRA_CMD="docker exec -it 70d jira issue list --jql '$JQL'"

WINDOW=$(hyprctl clients -j 2>/dev/null | jq -r ".[] | select(.class == \"$SCRATCH_CLASS\")" 2>/dev/null)

if [ -z "$WINDOW" ] || [ "$WINDOW" = "null" ]; then
    # Not running - launch it, run the jira command once (window closes when it exits)
    foot --app-id="$SCRATCH_CLASS" fish -c "$JIRA_CMD" &>/dev/null &
    exit 0
fi

ADDR=$(echo "$WINDOW" | jq -r '.address')
WS=$(echo "$WINDOW" | jq -r '.workspace.id')

if [ "$WS" = "99" ]; then
    hyprctl dispatch movetoworkspacesilent "e+0,address:$ADDR"
    hyprctl dispatch focuswindow "address:$ADDR"
else
    hyprctl dispatch movetoworkspacesilent "99,address:$ADDR"
fi
