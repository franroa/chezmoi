#!/bin/bash
source "$HOME/.config/hypr/scripts/hypr-lua.sh"

MAP_FILE="/tmp/hypr_notif_map"
CHEAT_SHEET_TEXT=""

# SAFETY CHECK: Does the file exist AND is it not empty?
if [ ! -s "$MAP_FILE" ]; then
  notify-send -t 2000 "Vimium Binds" "No active notifications to bind."
  exit 0
fi

# Loop through the map file and bind the keys
while IFS=':' read -r letter app summary; do
  if [ -n "$letter" ]; then
    # Build the cheat sheet string (converts letter to uppercase visually)
    CHEAT_SHEET_TEXT+="[${letter^^}] $app: $summary\n"

    # Tell Hyprland to bind the letter!
    hyprctl eval "hl.bind($(hl_str "$letter"), hl.dsp.exec_cmd($(hl_str "notify-send 'Action Triggered' 'You pressed ${letter^^} for $app'")))"
  fi
done <"$MAP_FILE"

# # Show the Cheat Sheet
# if [ -n "$CHEAT_SHEET_TEXT" ]; then
#   notify-send -t 6000 -u critical "Vimium Binds Active" "$CHEAT_SHEET_TEXT"
# fi
