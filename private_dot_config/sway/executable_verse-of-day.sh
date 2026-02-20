#!/bin/bash
# Verse of the Day fetcher
# Fetches from verseoftheday.com and displays via notification or wofi

set -euo pipefail

CACHE_FILE="/tmp/.verse_of_day_$USER"
CACHE_TTL=3600  # 1 hour

fetch_verse() {
    local html
    html=$(curl -sL -A "Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0" "https://www.verseoftheday.com/" 2>/dev/null)
    
    # Extract verse text
    local verse
    verse=$(echo "$html" | grep -oP '(?<=<div class="bilingual-left">)[^<]+' | head -1 | sed 's/&mdash;/—/g; s/&quot;/"/g; s/&#39;/'"'"'/g; s/&amp;/\&/g')
    
    # Extract reference
    local reference
    reference=$(echo "$html" | grep -oP '(?<=<meta property="og:title" content="Verse of the Day: )[^"]+' | head -1)
    
    if [[ -n "$verse" && -n "$reference" ]]; then
        echo "$reference"
        echo "$verse"
    else
        echo "Error"
        echo "Could not fetch verse"
    fi
}

get_verse() {
    # Check cache
    if [[ -f "$CACHE_FILE" ]]; then
        local age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE")))
        if [[ $age -lt $CACHE_TTL ]]; then
            cat "$CACHE_FILE"
            return
        fi
    fi
    
    # Fetch and cache
    fetch_verse | tee "$CACHE_FILE"
}

show_notification() {
    local data
    data=$(get_verse)
    local reference
    reference=$(echo "$data" | head -1)
    local verse
    verse=$(echo "$data" | tail -n +2)
    
    notify-send -t 15000 -i dialog-information "✝ $reference" "$verse"
}

show_wofi() {
    local data
    data=$(get_verse)
    local reference
    reference=$(echo "$data" | head -1)
    local verse
    verse=$(echo "$data" | tail -n +2)
    
    # Format for wofi display
    local display="✝ $reference\n\n$verse\n\n─────────────────\n󰆏 Copy verse\n󰖟 Open website\n󰑓 Refresh"
    
    local selected
    selected=$(echo -e "$display" | wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "Verse of the Day" --cache-file=/dev/null)
    
    case "$selected" in
        *"Copy"*)
            echo "$reference: $verse" | wl-copy
            notify-send -t 3000 "✝ Verse" "Copied to clipboard"
            ;;
        *"Open"*)
            xdg-open "https://www.verseoftheday.com/" &
            ;;
        *"Refresh"*)
            rm -f "$CACHE_FILE"
            show_wofi
            ;;
    esac
}

show_waybar() {
    local data
    data=$(get_verse)
    local reference
    reference=$(echo "$data" | head -1)
    local verse
    verse=$(echo "$data" | tail -n +2 | head -c 100)
    
    # JSON output for waybar
    echo "{\"text\": \"✝\", \"tooltip\": \"$reference\\n$verse...\", \"class\": \"verse\"}"
}

case "${1:-}" in
    notify) show_notification ;;
    waybar) show_waybar ;;
    fetch) get_verse ;;
    *) show_wofi ;;
esac
