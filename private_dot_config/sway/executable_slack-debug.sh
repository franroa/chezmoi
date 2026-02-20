#!/bin/bash
source ~/.config/slack-credentials

echo "Testing channel: C07K1J8HA59 (tm-platform-dev)"
response=$(curl -s --connect-timeout 5 --max-time 10 \
     -H "Authorization: Bearer $SLACK_TOKEN" \
     "https://slack.com/api/conversations.history?channel=C07K1J8HA59&limit=5")

echo "API ok: $(echo "$response" | jq -r '.ok')"
echo "Error: $(echo "$response" | jq -r '.error // "none"')"
echo "Messages count: $(echo "$response" | jq -r '.messages | length')"
echo ""
echo "Recent messages:"
echo "$response" | jq -r '.messages[]? | "[\(.ts)] \(.user // .bot_id): \(.text | .[0:80])"'
