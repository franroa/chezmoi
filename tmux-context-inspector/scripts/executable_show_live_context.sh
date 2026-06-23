#!/usr/bin/env bash
# LIVE view (opt-in): THIS one does send /context to the REPL and scrapes the
# pane, for the official per-category breakdown. Pollutes the conversation with /context.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_capture.sh"

cap="$(ci_capture_live)"
ci_popup_file "$cap"
