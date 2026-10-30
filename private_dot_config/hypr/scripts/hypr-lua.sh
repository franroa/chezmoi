#!/usr/bin/env bash
# Thin wrappers around `hyprctl dispatch` / `hyprctl eval` for the Lua config (Hyprland >= 0.55).
# Since 0.55 `hyprctl dispatch` takes a Lua expression, e.g. hyprctl dispatch 'hl.dsp.focus({ workspace = 3 })',
# and `hyprctl keyword` is gone (use `hyprctl eval 'hl.config({ ... })'`).
#
# Usage: source "$HOME/.config/hypr/scripts/hypr-lua.sh"
# A <window> argument is any window selector, e.g. "address:0x55d..." or "class:Slack". Omitted = active window.

# Lua string literal from arbitrary text
hl_str() {
    local s=${1//\\/\\\\}
    s=${s//\"/\\\"}
    s=${s//$'\n'/\\n}
    printf '"%s"' "$s"
}

# Workspace argument: bare integer stays a number, anything else (e+1, special:x, name:y) becomes a string
hl_ws() {
    if [[ $1 =~ ^[0-9]+$ ]]; then printf '%s' "$1"; else hl_str "$1"; fi
}

# Optional ", window = ..." table field
_hl_win() { [[ -n ${1:-} ]] && printf ', window = %s' "$(hl_str "$1")"; }

hl_eval()     { hyprctl eval "$1"; }
hl_dispatch() { hyprctl dispatch "$1"; }

hl_workspace()      { hyprctl dispatch "hl.dsp.focus({ workspace = $(hl_ws "$1") })"; }
hl_focus_window()   { hyprctl dispatch "hl.dsp.focus({ window = $(hl_str "$1") })"; }
hl_close_window()   { hyprctl dispatch "hl.dsp.window.close({ window = $(hl_str "$1") })"; }
hl_pin_window()     { hyprctl dispatch "hl.dsp.window.pin({ window = $(hl_str "$1") })"; }
hl_toggle_special() { hyprctl dispatch "hl.dsp.workspace.toggle_special($(hl_str "$1"))"; }

# hl_move_window <workspace> [window]        move and follow
# hl_move_window_silent <workspace> [window]  move without changing focus
hl_move_window()        { hyprctl dispatch "hl.dsp.window.move({ workspace = $(hl_ws "$1")$(_hl_win "${2:-}") })"; }
hl_move_window_silent() { hyprctl dispatch "hl.dsp.window.move({ workspace = $(hl_ws "$1"), follow = false$(_hl_win "${2:-}") })"; }

# Absolute move / resize in pixels (old movewindowpixel / resizewindowpixel "exact ...")
hl_move_px()   { hyprctl dispatch "hl.dsp.window.move({ x = $1, y = $2$(_hl_win "${3:-}") })"; }
hl_resize_px() { hyprctl dispatch "hl.dsp.window.resize({ x = $1, y = $2$(_hl_win "${3:-}") })"; }

# hl_exec_rules <command> <lua rules table>, e.g. hl_exec_rules "foot" '{ float = true, size = {800, 600} }'
hl_exec_rules() { hyprctl dispatch "hl.dsp.exec_cmd($(hl_str "$1"), $2)"; }

# hl_config '<lua table>'   e.g. hl_config '{ general = { layout = "master" } }'
hl_config() { hyprctl eval "hl.config($1)"; }

# Current workspace id (stable replacement for the old `e+0` selector)
hl_current_ws() { hyprctl -j activeworkspace | jq -r '.id'; }
