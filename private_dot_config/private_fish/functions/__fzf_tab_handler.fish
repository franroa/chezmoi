# Tab key handler with FZF support
# This function is autoloaded from the functions/ directory and is called
# when Tab is pressed. It ensures all dependencies are available when needed.

function __fzf_tab_handler --description "Tab key handler with FZF support"
    # Get the current state
    set -l cmd (commandline -c)
    
    # Special handling for specific commands that benefit from FZF completion
    if string match -q "git *" "$cmd"
        if __fzf_git_completion
            return 0
        end
    end
    
    # Default FZF-enhanced tab completion
    __fzf_tab_completion
end
