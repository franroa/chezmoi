# Tab key handler with FZF support
# This function is autoloaded from the functions/ directory and is called
# when Tab is pressed. It ensures all dependencies are available when needed.

function __fzf_tab_handler --description "Tab key handler with FZF support"
    # Check if we already showed completions for this command line
    set -l current_line (commandline -c)
    
    # Initialize global state if needed
    if not set -q __last_tab_completion_line
        set -g __last_tab_completion_line ""
        set -g __tab_press_count 0
    end
    
    # If the command line changed, reset counter
    if test "$current_line" != "$__last_tab_completion_line"
        set -g __last_tab_completion_line "$current_line"
        set -g __tab_press_count 0
    end
    
    # Increment tab press counter
    set -g __tab_press_count (math $__tab_press_count + 1)
    
    # First tab: use default Fish completion
    if test $__tab_press_count -eq 1
        commandline -f complete
        return 0
    end
    
    # Second and subsequent tabs: use FZF completion
    if test $__tab_press_count -ge 2
        set -g __tab_press_count 0  # Reset for next cycle
        __fzf_tab_completion
        return 0
    end
end
