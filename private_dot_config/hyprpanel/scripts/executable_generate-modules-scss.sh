#!/bin/bash
# Generates modules.scss combining wallust colors + dynamic states

SCSS_FILE="$HOME/.config/hyprpanel/modules.scss"
WALLUST_BASE="$HOME/.cache/wallust/hyprpanel-modules.scss"
BATTERY_LOW_FILE="/tmp/.battery_low_$USER"
SLACK_UNREAD_FILE="/tmp/.slack_unread_$USER"
TEMP_HIGH_FILE="/tmp/.temp_high_$USER"

# Load wallust colors from JSON cache
COLORS_JSON="$HOME/.cache/wallust/hyprpanel-colors.json"
if [[ -f "$COLORS_JSON" ]]; then
    blink1=$(jq -r '."blink.color1" // "#f38ba8"' "$COLORS_JSON")
    blink2=$(jq -r '."blink.color2" // "#89b4fa"' "$COLORS_JSON")
    background=$(jq -r '."theme.bar.background" // "#1e1e2e"' "$COLORS_JSON")
else
    blink1="#f38ba8"
    blink2="#89b4fa"
    background="#1e1e2e"
fi

# Start with wallust-generated base (written by wallust to modules.scss)
# We read it first, then append dynamic styles
if [[ -f "$WALLUST_BASE" ]]; then
    BASE_SCSS=$(cat "$WALLUST_BASE")
else
    # Fallback: read current modules.scss if no cached base
    # Strip any previously appended dynamic styles (after marker)
    BASE_SCSS=$(sed '/\/\* DYNAMIC STYLES \*\//,$d' "$SCSS_FILE" 2>/dev/null || echo "")
fi

SLACK_CSS=""
slack_count=0
[[ -f "$SLACK_UNREAD_FILE" ]] && slack_count=$(cat "$SLACK_UNREAD_FILE")

if [[ "$slack_count" -gt 0 ]]; then
    SLACK_CSS="
.bar_item_box_visible.cmodule-slack {
    background: ${blink1};
    animation: slack-blink 0.5s ease-in-out infinite alternate;
}
.bar_item_box_visible.cmodule-slack .icon {
    color: ${background};
}
@keyframes slack-blink {
    0% { background: ${blink1}; }
    100% { background: ${blink2}; }
}"
else
    SLACK_CSS='
.bar_item_box_visible.cmodule-slack {
    background: transparent;
}'
fi

BATTERY_CSS=""
if [[ -f "$BATTERY_LOW_FILE" ]]; then
    BATTERY_CSS="
.bar_item_box_visible.battery,
.bar_item_box_visible.battery-container {
    animation: battery-blink 0.5s ease-in-out infinite alternate;
}
.bar_item_box_visible.battery .bar-button-icon,
.bar_item_box_visible.battery-container .bar-button-icon {
    animation: battery-blink 0.5s ease-in-out infinite alternate;
}
@keyframes battery-blink {
    0% { background: #ff0000; }
    100% { background: ${background}; }
}"
fi

TEMP_CSS=""
if [[ -f "$TEMP_HIGH_FILE" ]]; then
    TEMP_CSS='
.bar_item_box_visible.cmodule-temp {
    animation: temp-blink 0.5s ease-in-out infinite alternate;
}
@keyframes temp-blink {
    0% { background: #ff6600; }
    100% { background: #ff0000; }
}'
fi

echo "$BASE_SCSS
/* DYNAMIC STYLES */
$SLACK_CSS
$BATTERY_CSS
$TEMP_CSS" > "$SCSS_FILE"
