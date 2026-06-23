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
        0.0 C s "Pipeline TUI — Remote (gctui)" \
            "display-popup -d '#{pane_current_path}' -w 95% -h 90% -E \
            '~/.local/bin/gctui --remote \"#{pane_current_path}\"'" \
        0.0 C ? "Pipeline TUI — usage / flags" \
            "display-popup -d '#{pane_current_path}' -w 70% -h 65% -E \
            'bash -c \"~/.local/bin/gctui --help 2>&1; read -p \\\"Press enter to close\\\" _\"'" \
        0.0 S \
        0.0 C o "Open repo in browser" \
            "run-shell '$glab repo view --web'" \
        0.0 C v "View current MR in browser" \
            "run-shell '$glab mr view --web'" \
        0.0 C l "List MRs" \
            "display-popup -d '#{pane_current_path}' -w 80% -h 50% -E \
            'bash -c \"$glab mr list 2>&1; echo; read -p \\\"Press enter to close\\\" _\"'" \
        0.0 C r "Review MR (pick \xE2\x86\x92 tuicr)" \
            "display-popup -d '#{pane_current_path}' -w 95% -h 90% -E \
            'bash -c \"~/.config/tmux/scripts/glab-mr-review.sh \\\"#{pane_current_path}\\\" || read -p \\\"Press enter to close\\\" _\"'" \
        0.0 C p "Create MR" \
            "display-popup -d '#{pane_current_path}' -w 80% -h 80% -E '$glab mr create'" \
        0.0 S \
        0.0 T "-#[nodim]Pipeline TUI  (gctui — Local + Remote)" \
        0.0 S \
        0.0 C V "Open — Local view" \
            "display-popup -d '#{pane_current_path}' -w 95% -h 90% -E \
            '~/.local/bin/gctui \"#{pane_current_path}\"'" \
        0.0 C y "Open — Config view (expanded YAML)" \
            "display-popup -d '#{pane_current_path}' -w 95% -h 90% -E \
            '~/.local/bin/gctui --config \"#{pane_current_path}\"'" \
        0.0 C a "Assemble pipeline from components/jobs" \
            "display-popup -d '#{pane_current_path}' -w 90% -h 70% -E \
            'bash -c \"~/.local/bin/gctui assemble \\\"#{pane_current_path}\\\"; read -p \\\"Press enter to close\\\" _\"'" \
        0.0 C u "Setup: init submodules + verify vars" \
            "display-popup -d '#{pane_current_path}' -w 90% -h 75% -E \
            'bash ~/.config/tmux/scripts/gcl-setup.sh \"#{pane_current_path}\"'"

    menu_generate_part 1 "$@"
}

menu_name="GitLab"

menu_key="G"

D_TM_BASE_PATH=$(cd -- "$(dirname -- "$0")/.." && pwd)

. "$D_TM_BASE_PATH"/scripts/menu_handling.sh
