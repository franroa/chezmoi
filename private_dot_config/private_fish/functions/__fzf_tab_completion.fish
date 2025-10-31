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
        # No completions found
        return 1
    else if test (count $completions) -eq 1
        # Single completion - apply immediately
        set -l comp $completions[1]
        set -l comp_text (echo "$comp" | cut -f1)
        set -l tokens (string split ' ' "$current_line")
        set -l last_token $tokens[-1]
        
        # Replace the last token with the completion
        set -l before (string join ' ' $tokens[1..-2])
        if test -n "$before"
            commandline -c "$before $comp_text"
        else
            commandline -c "$comp_text"
        end
        return 0
    else
        # Multiple completions available - use FZF for selection
        set -l completion_items (printf '%s\n' $completions | cut -f1 | sort -u)
        set -l count (count $completion_items)
        
        set -l selected (printf '%s\n' $completion_items | \
            _fzf_wrapper \
                --multi=0 \
                --no-multi \
                --height='40%' \
                --header="$count completions available" \
                --preview-window=hidden \
                --bind='ctrl-c:abort' \
                2>/dev/null | string trim)
        
        if test -n "$selected"
            set -l tokens (string split ' ' "$current_line")
            set -l before (string join ' ' $tokens[1..-2])
            
            if test -n "$before"
                commandline -c "$before $selected"
            else
                commandline -c "$selected"
            end
        end
        return 0
    end
end
