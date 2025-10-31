# Enhanced git branch/commit completion with preview
# This function is autoloaded from the functions/ directory, ensuring all dependencies
# like _fzf_wrapper are available when it's called.

function __fzf_git_completion --description "Enhanced git completion"
    set -l cmd (commandline -c)
    set -l tokens (string split ' ' "$cmd")
    
    if test (count $tokens) -lt 2 || test "$tokens[1]" != "git"
        return 1
    end
    
    set -l git_cmd $tokens[2]
    
    switch "$git_cmd"
        case "checkout" "switch" "branch"
            set -l branches (git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null)
            if test -n "$branches"
                set -l selected (printf '%s\n' $branches | \
                    _fzf_wrapper \
                        --multi=0 \
                        --preview='git log -1 --oneline --color {}' \
                        --preview-window='right:40%' 2>/dev/null)
                test -n "$selected" && commandline -c "$cmd" && commandline -i " $selected"
                return 0
            end
        case "merge" "rebase" "diff"
            set -l branches (git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null)
            if test -n "$branches"
                set -l selected (printf '%s\n' $branches | \
                    _fzf_wrapper \
                        --multi=0 \
                        --preview='git log -1 --oneline {}' 2>/dev/null)
                test -n "$selected" && commandline -c "$cmd" && commandline -i " $selected"
                return 0
            end
    end
    return 1
end
