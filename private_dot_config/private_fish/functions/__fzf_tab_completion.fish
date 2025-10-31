# FZF Tab Completion Enhancement for Fish Shell
# Provides fuzzy completion for commands, arguments, and file paths using FZF
# This function is autoloaded from the functions/ directory, ensuring all dependencies
# like _fzf_wrapper are available when it's called.

function __fzf_tab_completion --description "Tab completion with FZF for multiple options"
    # Get the current command line
    set -l current_line (commandline -c)
    
    # Get all available completions from Fish
    set -l completions (complete -C "$current_line" 2>/dev/null)
    
    if test (count $completions) -eq 0
        # No completions found, use Fish's default behavior
        commandline -f complete
        return 0
    else if test (count $completions) -eq 1
        # Single completion - apply immediately
        commandline -f complete
        return 0
    else
        # Multiple completions available - use FZF for selection
        # Extract just the completion text (first column before tab)
        set -l completion_items (printf '%s\n' $completions | cut -f1 | sort -u)
        set -l count (count $completion_items)
        
        if test $count -le 10
            # Few options - show all with Fish's default
            commandline -f complete
            return 0
        else
            # Many options - use FZF for interactive selection with column layout
            # Format items into columns before passing to fzf
            set -l col_count 4
            set -l formatted_items (printf '%s\n' $completion_items | \
                awk -v cols=$col_count '
                    {
                        printf "%-25s", $0
                        if (NR % cols == 0) print ""
                    }
                    END { if (NR % cols != 0) print "" }
                ')
            
            set -l selected (printf '%s\n' $formatted_items | \
                _fzf_wrapper \
                    --multi=0 \
                    --no-multi \
                    --height='40%' \
                    --header="$count completions available" \
                    --preview-window=hidden \
                    --bind='ctrl-c:abort' \
                    2>/dev/null | string trim)
            
            # Extract the actual completion from the formatted line
            set -l selected (string trim -c '[:space:]' (echo "$selected" | awk '{print $1}'))
            
            if test -n "$selected"
                # Get the word being completed
                set -l tokens (string split ' ' "$current_line")
                set -l last_token $tokens[-1]
                
                # Find common prefix
                set -l prefix (string sub -l (string length "$last_token" | math . - (string length "$selected")) "$last_token")
                
                # Replace with selected completion
                commandline -c (string length (string join ' ' $tokens[1..-2]))
                commandline -i " $selected"
            end
            return 0
        end
    end
end
