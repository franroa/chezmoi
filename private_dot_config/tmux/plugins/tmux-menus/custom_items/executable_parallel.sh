static_content() {
    scr="$HOME/.config/tmux/scripts"

    set -- \
        0.0 M Left "Back to Custom items  $nav_prev" "$f_custom_items_index" \
        0.0 M Home "Back to Main menu     $nav_home" main.sh \
        0.0 S \
        0.0 T "-#[nodim]Parallel agents" \
        0.0 S \
        0.0 C s "Spawn swarm (prompts for tickets)" \
            "display-popup -d '#{pane_current_path}' -w 80% -h 60% -E \
            'bash -c \"$scr/swarm.sh interactive\"'" \
        0.0 C S "Swarm control session (dashboard)" \
            "run-shell \"tmuxinator start swarm root='#{pane_current_path}'\"" \
        0.0 C d "Dashboard — all worker sessions" \
            "display-popup -d '#{pane_current_path}' -w 90% -h 60% -E \
            'bash -c \"$scr/swarm-dashboard.sh watch\"'" \
        0.0 S \
        0.0 C r "Review layout (multi-perspective)" \
            "run-shell \"tmuxinator start review root='#{pane_current_path}' id=rev\"" \
        0.0 C p "Pipeline layout (staged)" \
            "run-shell \"tmuxinator start pipeline root='#{pane_current_path}' id=p\"" \
        0.0 C m "Monitor layout" \
            "run-shell \"tmuxinator start monitor root='#{pane_current_path}'\"" \
        0.0 C o "Workflow (orchestrator-Claude)" \
            "run-shell \"tmuxinator start workflow root='#{pane_current_path}' id=wf\"" \
        0.0 S \
        0.0 C a "Autopilot status (scheduled jobs)" \
            "display-popup -d '#{pane_current_path}' -w 80% -h 50% -E \
            'bash -c \"$scr/autopilot.sh list; echo; read -p \\\"Press enter to close\\\" _\"'" \
        0.0 S \
        0.0 C P "Peek a worker's output (no attach)" \
            "display-popup -d '#{pane_current_path}' -w 90% -h 70% -E \
            'bash -c \"$scr/swarm.sh peek-i\"'" \
        0.0 C R "Reap finished (done) workers only" \
            "display-popup -d '#{pane_current_path}' -w 80% -h 50% -E \
            'bash -c \"$scr/swarm.sh reap-done; echo; read -p \\\"Press enter to close\\\" _\"'" \
        0.0 C x "Teardown swarm (remove ALL worktrees)" \
            "display-popup -d '#{pane_current_path}' -w 80% -h 50% -E \
            'bash -c \"$scr/swarm.sh teardown; echo; read -p \\\"Press enter to close\\\" _\"'"

    menu_generate_part 1 "$@"
}

menu_name="Parallel"

menu_key="A"

D_TM_BASE_PATH=$(cd -- "$(dirname -- "$0")/.." && pwd)

. "$D_TM_BASE_PATH"/scripts/menu_handling.sh
