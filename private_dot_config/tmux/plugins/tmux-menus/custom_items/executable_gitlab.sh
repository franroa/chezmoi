static_content() {
    glab="/home/linuxbrew/.linuxbrew/bin/glab"

    set -- \
        0.0 M Left "Back to Custom items  $nav_prev" "$f_custom_items_index" \
        0.0 M Home "Back to Main menu     $nav_home" main.sh \
        0.0 S \
        0.0 T "-#[nodim]GitLab" \
        0.0 S \
        0.0 C c "CI Run (current branch)" \
            "display-popup -d '#{pane_current_path}' -w 80% -h 50% -E \
            'bash -c \"$glab ci run -b \$(git branch --show-current) 2>&1; echo; read -p \\\"Press enter to close\\\" _\"'" \
        0.0 C s "CI Viewer (tree · children · logs)" \
            "display-popup -d '#{pane_current_path}' -w 95% -h 90% -E \
            'bash -c \"~/.config/tmux/scripts/glab-ci.sh || read -n 1\"'" \
        0.0 C ? "CI Viewer — keybindings" \
            "display-popup -d '#{pane_current_path}' -w 70% -h 55% -E \
            'bash -c \"~/.config/tmux/scripts/glab-ci.sh help; read -p \\\"Press enter to close\\\" _\"'" \
        0.0 S \
        0.0 C o "Open repo in browser" \
            "run-shell '$glab repo view --web'" \
        0.0 C v "View current MR in browser" \
            "run-shell '$glab mr view --web'" \
        0.0 C l "List MRs" \
            "display-popup -d '#{pane_current_path}' -w 80% -h 50% -E \
            'bash -c \"$glab mr list 2>&1; echo; read -p \\\"Press enter to close\\\" _\"'" \
        0.0 C p "Create MR" \
            "display-popup -d '#{pane_current_path}' -w 80% -h 80% -E '$glab mr create'"

    menu_generate_part 1 "$@"
}

menu_name="GitLab"

menu_key="G"

D_TM_BASE_PATH=$(cd -- "$(dirname -- "$0")/.." && pwd)

. "$D_TM_BASE_PATH"/scripts/menu_handling.sh
