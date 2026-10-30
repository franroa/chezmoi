#!/usr/bin/env bash
# Make the patched HyprPanel bundle work with a Lua Hyprland config (>= 0.55).
#
# Since 0.55 the Hyprland socket treats `dispatch <...>` as a Lua expression, so AstalHyprland's
# `hyprland.dispatch("workspace", "3")` (used by the workspace buttons, scroll and the app-focus helper)
# fails with: `hl.dispatch(workspace 3)` -> ')' expected. Upstream fix: Aylur/astal#446 (not merged, HyprPanel is archived).
# This rewrites those calls in the bundle to `hyprctl dispatch 'hl.dsp...'`.
#
# Usage: patch-lua-dispatch.sh [bundle]   (default: ~/.local/share/hyprpanel-hacks/hyprpanel-wrapped.patched)
# Idempotent; keeps the previous bundle as <bundle>.bak-prelua. Restart afterwards: systemctl --user restart hyprpanel.service
set -euo pipefail

bundle="${1:-$HOME/.local/share/hyprpanel-hacks/hyprpanel-wrapped.patched}"
[[ -f "$bundle" ]] || { echo "bundle not found: $bundle" >&2; exit 1; }

if ! grep -aqE '\.dispatch\("(workspace|focuswindow)"|opt\("hyprctl dispatch exit"\)' "$bundle"; then
    echo "already patched (nothing to do): $bundle"
    exit 0
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

python3 -I - "$bundle" "$tmp" <<'PY'
import sys
src, dst = sys.argv[1:3]
s = open(src, encoding="utf-8", errors="surrogateescape").read()
IDENT = set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_$")


def rewrite(s, head, end, build):
    """Replace `<ident>.dispatch(<head>...<end>` calls. Plain string search: the bundle has huge lines, so no regex."""
    out, pos, n = [], 0, 0
    while True:
        i = s.find(head, pos)
        if i < 0:
            out.append(s[pos:])
            break
        j = s.find(end, i)
        k = i
        while k > pos and s[k - 1] in IDENT:  # the service variable in front of `.dispatch(`
            k -= 1
        out.append(s[pos:k])
        out.append(build(s[i + len(head):j]))
        pos = j + len(end)
        n += 1
    return "".join(out), n


s, n_ws = rewrite(
    s, '.dispatch("workspace", ', ");",
    lambda arg: 'execAsync(["hyprctl", "dispatch", `hl.dsp.focus({ workspace = ${%s} })`]).catch(console.error);' % arg)
s, n_win = rewrite(
    s, '.dispatch("focuswindow", `class:${target.class}`', ");",
    lambda arg: 'execAsync(["hyprctl", "dispatch", `hl.dsp.focus({ window = "class:${target.class}" })`]).catch(console.error);')
n_exit = s.count('opt("hyprctl dispatch exit")')
s = s.replace('opt("hyprctl dispatch exit")', 'opt("hyprctl dispatch \'hl.dsp.exit()\'")')

assert '.dispatch("workspace"' not in s and '.dispatch("focuswindow"' not in s, "unpatched dispatch call left"
open(dst, "w", encoding="utf-8", errors="surrogateescape").write(s)
print(f"patched: {n_ws} workspace, {n_win} focuswindow, {n_exit} logout")
PY

cp -p "$bundle" "$bundle.bak-prelua"
chmod u+w "$bundle" 2>/dev/null || true
install -m 555 "$tmp" "$bundle"
echo "done: $bundle (backup: $bundle.bak-prelua)"
