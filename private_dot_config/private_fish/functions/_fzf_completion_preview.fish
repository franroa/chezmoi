#!/usr/bin/env fish
# _fzf_completion_preview.fish - Preview helper for FZF completions
# Provides smart preview based on completion type

function _fzf_completion_preview --description "Generate preview for FZF completion item"
    set -l item $argv[1]
    set -l context $argv[2]
    
    switch "$context"
        case "git_branch"
            # Show recent commits for a git branch
            git log -1 --oneline --format="%h %s" "$item" 2>/dev/null
            git log --oneline -5 "$item" 2>/dev/null | tail -4
            
        case "git_commit"
            # Show commit details
            git show --stat "$item" 2>/dev/null | head -20
            
        case "kubectl_pod"
            # Show pod info
            set -l ns (commandline | string match -oE -- '--namespace=\S+|-n\s+\S+' | head -1 | string replace -r '.*=' '')
            if test -n "$ns"
                kubectl describe pod "$item" -n "$ns" 2>/dev/null | head -20
            else
                kubectl describe pod "$item" 2>/dev/null | head -20
            end
            
        case "docker_container"
            # Show container info
            docker ps -a --filter="name=$item" --format='table {{.ID}}\t{{.Image}}\t{{.Status}}' 2>/dev/null
            
        case "directory"
            # Show directory contents
            ls -lah "$item" 2>/dev/null | head -15
            
        case "file"
            # Show file preview
            if file "$item" | string match -q "*text*"
                head -20 "$item" 2>/dev/null
            else if file "$item" | string match -q "*image*"
                echo "Image: $item"
            else
                file "$item"
            end
            
        case "*"
            echo "Preview not available for: $item"
    end
end
