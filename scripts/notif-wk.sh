#!/bin/bash
# Generate a temporary wlr-which-key config with notification keys

CONFIG_FILE="/tmp/notif-wk-$USER.yaml"

# Header
cat > "$CONFIG_FILE" << 'EOF'
font: JetBrainsMono Nerd Font 13
background: "#090300e0"
color: "#A5A2A2"
border: "#807D7C"
separator: "  "
border_width: 2
corner_r: 10
padding: 20
rows_per_column: 10
column_padding: 20
anchor: bottom-right
margin_right: 20
margin_bottom: 20
inhibit_compositor_keyboard_shortcuts: false
menu:
EOF

# Add keys for each notification
NOTIF_MAP="/tmp/.opencode_letter_map"
if [[ -f "$NOTIF_MAP" ]]; then
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        letter=$(echo "$line" | cut -d: -f1)
        content=$(echo "$line" | cut -d: -f2 | cut -d'|' -f1)
        cat >> "$CONFIG_FILE" << EOF
  - key: "$letter"
    desc: "🤖 $content"
    cmd: ~/.config/hypr/scripts/notif-trigger-direct.sh opencode $letter
EOF
    done < "$NOTIF_MAP"
fi

NOTIF_MAP="/tmp/.slack_letter_map"
if [[ -f "$NOTIF_MAP" ]]; then
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        letter=$(echo "$line" | cut -d: -f1)
        cat >> "$CONFIG_FILE" << EOF
  - key: "$letter"
    desc: "💬 Slack"
    cmd: ~/.config/hypr/scripts/notif-trigger-direct.sh slack $letter
EOF
    done < "$NOTIF_MAP"
fi

# Spawn wlr-which-key with this config
wlr-which-key "$(basename $CONFIG_FILE)" &
