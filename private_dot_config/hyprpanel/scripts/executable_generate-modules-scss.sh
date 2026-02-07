#!/bin/bash
# Generates modules.scss combining all dynamic styles

SCSS_FILE="$HOME/.config/hyprpanel/modules.scss"
BATTERY_LOW_FILE="/tmp/.battery_low_$USER"
SLACK_UNREAD_FILE="/tmp/.slack_unread_$USER"
TEMP_HIGH_FILE="/tmp/.temp_high_$USER"

BASE_SCSS='@include styleModule(
    '\''cmodule-pomodoro'\'',
    (
        '\''text-color'\'': #f5c2e7,
        '\''icon-color'\'': #1e1e2e,
        '\''icon-background'\'': #f5c2e7,
        '\''label-background'\'': #1e1e2e,
        '\''inner-spacing'\'': 0.5em,
        '\''border-enabled'\'': false,
        '\''icon-size'\'': 1.2em
    )
);'

SLACK_CSS=""
slack_count=0
[[ -f "$SLACK_UNREAD_FILE" ]] && slack_count=$(cat "$SLACK_UNREAD_FILE")

if [[ "$slack_count" -gt 0 ]]; then
    SLACK_CSS='
.bar_item_box_visible.cmodule-slack {
    background: #f38ba8;
    animation: slack-blink 0.5s ease-in-out infinite alternate;
}
.bar_item_box_visible.cmodule-slack .icon {
    color: #1e1e2e;
}
@keyframes slack-blink {
    0% { background: #f38ba8; }
    100% { background: #89b4fa; }
}'
else
    SLACK_CSS='
.bar_item_box_visible.cmodule-slack {
    background: transparent;
}'
fi

BATTERY_CSS=""
if [[ -f "$BATTERY_LOW_FILE" ]]; then
    BATTERY_CSS='
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
    100% { background: #1E1E20; }
}'
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
$SLACK_CSS
$BATTERY_CSS
$TEMP_CSS" > "$SCSS_FILE"
