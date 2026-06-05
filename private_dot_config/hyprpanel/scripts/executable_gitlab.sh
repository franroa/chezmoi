#!/bin/bash
# GitLab notifications for HyprPanel

SCRIPT="$HOME/.config/hypr/scripts/gitlab-monitor.sh"

case "${1:-}" in
    open)
        $SCRIPT open
        ;;
    show)
        $SCRIPT show
        ;;
    mark-read)
        $SCRIPT mark-read
        ;;
    *)
        result=$(timeout 2 $SCRIPT status 2>/dev/null)
        if [[ -z "$result" ]]; then
            echo '{"text": "", "alt": "none", "tooltip": "GitLab"}'
            exit 0
        fi
        echo "$result"
        ;;
esac
