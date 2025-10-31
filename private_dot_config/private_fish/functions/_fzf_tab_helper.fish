#!/usr/bin/env fish
# _fzf_tab_helper.fish - Helper function for FZF-enhanced tab completion
# Provides fuzzy selection from Fish completion candidates

function _fzf_tab_helper --description "Select from completions using FZF"
    # Read completions from stdin (one per line)
    set -l completions (cat)
    
    if test -z "$completions"
        return 1
    end
    
    # If only one completion, return it immediately
    if test (count $completions) -eq 1
        echo $completions[1]
        return 0
    end
    
    # Multiple completions - use FZF for selection
    printf '%s\n' $completions | _fzf_wrapper \
        --multi=0 \
        --no-multi \
        --preview-window=hidden \
        --height='15' \
        --bind='ctrl-c:abort' 2>/dev/null
    
    if test $status -eq 0
        return 0
    else
        return 1
    end
end
