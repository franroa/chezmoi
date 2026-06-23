static_content() {
    scripts="$HOME/.config/tmux/scripts"
    np="$HOME/.config/tmux/plugins/tmux-named-snapshot/scripts"

    set -- \
        0.0 M Left "Back to Custom items  $nav_prev" "$f_custom_items_index" \
        0.0 M Home "Back to Main menu     $nav_home" main.sh \
        0.0 S \
        0.0 T "-#[nodim]Sessions" \
        0.0 S \
        0.0 E a "New AOE session (repo picker + aoen)" \
            "display-popup -d '#{pane_current_path}' -w 80% -h 80% -E \
            -e 'TMUX_PARENT_CLIENT=#{client_tty}' '$scripts/aoen-session.sh'" \
        0.0 E S "Session picker  (enter=switch  D=delete  R=rename)" \
            "display-popup -d '#{pane_current_path}' -w 50% -h 40% -E \
            '$scripts/session-picker.sh'" \
        0.0 E f "Sessionizer  (fzf projects → create/switch session)" \
            "display-popup -d '#{pane_current_path}' -w 60% -h 50% -E \
            '$scripts/sessionizer.sh'" \
        0.0 S \
        0.0 T "-#[nodim]Snapshots  (leader: prefix N \xE2\x86\x92 s/r/p)" \
        0.0 S \
        0.0 E v "Save named snapshot" \
            "command-prompt -p 'Save snapshot as:' \
            'run-shell \"$np/save-snapshot.sh %%\"'" \
        0.0 E b "Restore named snapshot" \
            "command-prompt -p 'Restore snapshot:' \
            'run-shell \"$np/restore-snapshot.sh %%\"'" \
        0.0 E n "Snapshot picker  (restore/delete named snapshots)" \
            "display-popup -d '#{pane_current_path}' -w 50% -h 40% -E \
            '$scripts/snapshot-picker.sh'" \
        0.0 S \
        0.0 T "-#[nodim]Navigation" \
        0.0 S \
        0.0 C p "Previous session" "run-shell '$scripts/switch-client.sh -1'" \
        0.0 C n "Next session"     "run-shell '$scripts/switch-client.sh 1'" \
        0.0 S \
        0.0 T "-#[nodim]Resurrect" \
        0.0 S \
        0.0 C s "Save session" \
            "run-shell '/home/froa/.config/tmux/plugins/tmux-resurrect/scripts/save.sh'" \
        0.0 C r "Restore session" \
            "run-shell '/home/froa/.config/tmux/plugins/tmux-resurrect/scripts/restore.sh'" \
        0.0 S \
        0.0 T "-#[nodim]Tools" \
        0.0 S \
        0.0 C g "Scratch terminal popup" \
            "display-popup -d '#{pane_current_path}' -w 80% -h 80% -E"

    menu_generate_part 1 "$@"
}

menu_name="Sessions & Tools"

menu_key="s"

D_TM_BASE_PATH=$(cd -- "$(dirname -- "$0")/.." && pwd)

. "$D_TM_BASE_PATH"/scripts/menu_handling.sh
