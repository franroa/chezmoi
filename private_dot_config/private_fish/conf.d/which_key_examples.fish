#!/usr/bin/env fish
# which-key-example.fish - Example extensions for the which-key plugin
# Copy functions from this file to customize your which-key experience

# Example 1: Show only git-related bindings
function which_key_git --description "Show git-related keybindings"
    set -gx __which_key_active 1
    set -gx __which_key_prefix "git"
    
    printf '\033[?1049h'  # Alternate screen
    printf '\033[H\033[2J'  # Clear
    
    printf '\n'
    printf '╔════════════════════════════════════════════════════════════════════════╗\n'
    printf '║                    GIT RELATED KEY BINDINGS                            ║\n'
    printf '╠════════════════════════════════════════════════════════════════════════╣\n'
    
    # Show only bindings containing "git"
    bind -a 2>/dev/null | sort | grep -i "git" | head -18 | while read -l line
        printf '║ %-68s ║\n' (string sub -l 65 "$line")
    end
    
    printf '╠════════════════════════════════════════════════════════════════════════╣\n'
    printf '║ Press any key to close                                                 ║\n'
    printf '╚════════════════════════════════════════════════════════════════════════╝\n'
    
    read -z -n 1 _key
    printf '\033[?1049l'
    set -gx __which_key_active 0
    commandline -f repaint
end

# Example 2: Show only navigation bindings
function which_key_nav --description "Show navigation keybindings"
    set -gx __which_key_active 1
    
    printf '\033[?1049h'  # Alternate screen
    printf '\033[H\033[2J'  # Clear
    
    printf '\n'
    printf '╔════════════════════════════════════════════════════════════════════════╗\n'
    printf '║                    NAVIGATION KEY BINDINGS                             ║\n'
    printf '╠════════════════════════════════════════════════════════════════════════╣\n'
    
    printf '║ up-line, down-line, forward-char, backward-char, etc.                 ║\n'
    printf '║                                                                        ║\n'
    
    # Show arrow keys and movement
    bind -a 2>/dev/null | sort | grep -E "(line|char|word|history)" | head -15 | while read -l line
        printf '║ %-68s ║\n' (string sub -l 65 "$line")
    end
    
    printf '╠════════════════════════════════════════════════════════════════════════╣\n'
    printf '║ Press any key to close                                                 ║\n'
    printf '╚════════════════════════════════════════════════════════════════════════╝\n'
    
    read -z -n 1 _key
    printf '\033[?1049l'
    set -gx __which_key_active 0
    commandline -f repaint
end

# Example 3: Interactive navigation - drill down into categories
function which_key_interactive --description "Interactively navigate keybindings by category"
    set -gx __which_key_active 1
    
    printf '\033[?1049h'
    printf '\033[H\033[2J'
    
    printf '\n'
    printf '╔════════════════════════════════════════════════════════════════════════╗\n'
    printf '║                         KEY BINDING CATEGORIES                          ║\n'
    printf '╠════════════════════════════════════════════════════════════════════════╣\n'
    printf '║                                                                        ║\n'
    printf '║ Type a key combination:                                                ║\n'
    printf '║   [g] - Git commands                                                   ║\n'
    printf '║   [n] - Navigation                                                     ║\n'
    printf '║   [e] - Editing                                                        ║\n'
    printf '║   [a] - All bindings                                                   ║\n'
    printf '║   [q] - Quit                                                           ║\n'
    printf '║                                                                        ║\n'
    printf '╚════════════════════════════════════════════════════════════════════════╝\n'
    
    read -z -n 1 choice
    
    printf '\033[?1049l'
    set -gx __which_key_active 0
    commandline -f repaint
    
    switch $choice
        case 'g'
            which_key_git
        case 'n'
            which_key_nav
        case 'a'
            which_key
        case '*'
            # Do nothing for other keys
    end
end

# Example: Bind the interactive version to Ctrl+Shift+W
# Uncomment below to use:
# bind \ec\cw which_key_interactive
