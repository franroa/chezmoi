#!/usr/bin/env bash
# Screenshot chooser for hyprpanel dashboard: capture, then prompt for a file name

PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
dir="$PICTURES_DIR/Screenshots"
sDIR="$HOME/.config/hypr/scripts"
iDIR="$HOME/.config/swaync/icons"

if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
fi

choice=$(printf "Full Screen\nRegion / Area" | rofi -dmenu -p "Screenshot" -mesg "Choose screenshot type" -theme-str 'listview {lines: 2;}')

# let rofi/panel layers finish closing before capturing
sleep 0.3

tmpfile=$(mktemp --suffix=.png)

# Unfocused windows are translucent and dimmed (opacity rules + dim_inactive),
# which lets the wallpaper tint the capture. Force visible windows opaque and
# undimmed just for the grab, then restore them.
visible_windows() {
    hyprctl -j clients | jq -r --argjson ws "$(hyprctl -j monitors | jq '[.[].activeWorkspace.id]')" \
        '.[] | select(.mapped and (.hidden | not) and (.workspace.id as $w | $ws | index($w))) | .address'
}
set_capture_props() {
    local value=$1 addrs=""
    for addr in $(visible_windows); do
        addrs+="\"$addr\", "
    done
    [[ -n "$addrs" ]] && hyprctl eval "for _, a in ipairs({ $addrs }) do for _, p in ipairs({ \"opaque\", \"no_dim\" }) do hl.dispatch(hl.dsp.window.set_prop({ prop = p, value = \"$value\", window = \"address:\" .. a })) end end" >/dev/null
}
capture() {
    set_capture_props 1
    sleep 0.05
    grim "$@" "$tmpfile"
    local rc=$?
    set_capture_props unset
    return $rc
}
trap 'set_capture_props unset; rm -f "$tmpfile"' EXIT

case "$choice" in
    "Full Screen")
        capture || exit 1
        ;;
    "Region / Area")
        geometry=$(slurp) || exit 0
        capture -g "$geometry" || exit 1
        ;;
    *)
        exit 0
        ;;
esac

[[ -s "$tmpfile" ]] || exit 1
wl-copy <"$tmpfile"

# Ask for a name (pre-filled with the default); Esc keeps the default
default_name="Screenshot_$(date "+%d-%b_%H-%M-%S")"
name=$(rofi -dmenu -p "Save as" -mesg "Enter: save with this name · Esc: keep default" \
    -filter "$default_name" -theme-str 'listview {lines: 0;}' </dev/null)
name="${name//\//-}"
name="${name#"${name%%[![:space:]]*}"}"
name="${name%"${name##*[![:space:]]}"}"
[[ -n "$name" ]] || name="$default_name"
name="${name%.png}"

# Don't overwrite an existing file
path="$dir/$name.png"
n=1
while [[ -e "$path" ]]; do
    path="$dir/${name}_$n.png"
    ((n++))
done

mv "$tmpfile" "$path"

"$sDIR/Sounds.sh" --screenshot
resp=$(timeout 10 notify-send -t 10000 -A action1=Open -A action2=Delete \
    -h string:x-canonical-private-synchronous:shot-notify \
    -i "$iDIR/picture.png" " Screenshot saved" " $(basename "$path")")
case "$resp" in
    action1) xdg-open "$path" & ;;
    action2) rm "$path" ;;
esac
