# which-key.fish - A fish shell implementation of which-key
# Displays available keybindings when space is pressed in normal mode

# Initialize global state
set -g __which_key_state ""

# Define keybinding categories and their descriptions
function __which_key_init_bindings
    # Main leader key bindings
    set -g __which_key_bindings_main \
        "g|Git commands" \
        "f|FZF commands"
    
    # Git bindings (g + key)
    set -g __which_key_bindings_git \
        "b|Branches" \
        "e|Each ref" \
        "f|Files" \
        "h|Hashes" \
        "l|Reflogs" \
        "r|Remotes" \
        "s|Stashes" \
        "t|Tags" \
        "w|Worktrees"
    
    # FZF bindings (f + key)
    set -g __which_key_bindings_fzf \
        "c|CD directory" \
        "f|File" \
        "h|History" \
        "p|Processes" \
        "s|Git status" \
        "l|Git log"
end

# Display menu
function __which_key_show_menu --description "Show which-key menu"
    set -l menu_type $argv[1]
    set -l bindings ""
    set -l title ""
    
    switch $menu_type
        case "main"
            set title "Available Keys"
            set bindings $__which_key_bindings_main
        case "git"
            set title "Git Commands"
            set bindings $__which_key_bindings_git
        case "fzf"
            set title "FZF Commands"
            set bindings $__which_key_bindings_fzf
    end
    
    # Draw menu
    set_color cyan
    echo "┌─ $title ─┐"
    set_color normal
    
    for binding in $bindings
        set -l parts (string split '|' $binding)
        set -l key $parts[1]
        set -l desc $parts[2]
        printf "│ $(set_color yellow)%s$(set_color normal)  %s\n" $key "$desc"
    end
    
    set_color cyan
    echo "└────────────────────────────────────┘"
    set_color normal
end

# Handler when space is pressed
function __which_key_space
    __which_key_show_menu main
    set -g __which_key_state "main"
end

# Handler for 'g' key
function __which_key_handler_g
    if test "$__which_key_state" = "main"
        __which_key_show_menu git
        set -g __which_key_state "git"
    else if test "$__which_key_state" = "git"
        set -g __which_key_state ""
        __fzf_git_sh branches
    else
        commandline -f self-insert
    end
end

# Handler for 'f' key
function __which_key_handler_f
    if test "$__which_key_state" = "main"
        __which_key_show_menu fzf
        set -g __which_key_state "fzf"
    else if test "$__which_key_state" = "git"
        set -g __which_key_state ""
        __fzf_git_sh files
    else if test "$__which_key_state" = "fzf"
        set -g __which_key_state ""
        fzf-file-widget
    else
        commandline -f self-insert
    end
end

# Handler for other git commands
function __which_key_handler_git_cmd
    set -l cmd $argv[1]
    if test "$__which_key_state" = "git"
        set -g __which_key_state ""
        switch $cmd
            case "b"
                __fzf_git_sh branches
            case "e"
                __fzf_git_sh each_ref
            case "h"
                __fzf_git_sh hashes
            case "l"
                __fzf_git_sh lreflogs
            case "r"
                __fzf_git_sh remotes
            case "s"
                __fzf_git_sh stashes
            case "t"
                __fzf_git_sh tags
            case "w"
                __fzf_git_sh worktrees
        end
    else
        commandline -f self-insert
    end
end

# Handler for fzf commands
function __which_key_handler_fzf_cmd
    set -l cmd $argv[1]
    if test "$__which_key_state" = "fzf"
        set -g __which_key_state ""
        switch $cmd
            case "c"
                fzf-cd-widget
            case "h"
                fzf-history-widget
            case "p"
                fzf-processes-widget
            case "s"
                fzf-git-status-widget
            case "l"
                fzf-git-log-widget
        end
    else
        commandline -f self-insert
    end
end

# Cancel which-key
function __which_key_escape
    set -g __which_key_state ""
    commandline -f repaint
end

# Initialize bindings on startup
__which_key_init_bindings

# Main keybindings
bind -M default ' ' __which_key_space
bind -M default 'g' __which_key_handler_g
bind -M default 'f' __which_key_handler_f

# Git command bindings
bind -M default 'b' '__which_key_handler_git_cmd b'
bind -M default 'e' '__which_key_handler_git_cmd e'
bind -M default 'h' '__which_key_handler_git_cmd h'
bind -M default 'l' '__which_key_handler_git_cmd l'
bind -M default 'r' '__which_key_handler_git_cmd r'
bind -M default 's' '__which_key_handler_git_cmd s'
bind -M default 't' '__which_key_handler_git_cmd t'
bind -M default 'w' '__which_key_handler_git_cmd w'

# FZF command bindings
bind -M default 'c' '__which_key_handler_fzf_cmd c'
bind -M default 'p' '__which_key_handler_fzf_cmd p'

# Escape to cancel
bind -M default escape __which_key_escape
