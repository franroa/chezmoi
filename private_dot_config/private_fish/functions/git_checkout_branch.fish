#!/usr/bin/env fish
# Git checkout branch function with worktree support
# Checks out branches stored under git_root/branches/name-of-branch
# Shows local and remote branches and allows selection with FZF

function git_checkout_branch
    # Check if we're in a git repository
    if not git rev-parse --git-dir > /dev/null 2>&1
        echo (set_color red)"✗ Not a git repository"(set_color normal)
        return 1
    end

    # Get git root directory
    set -l git_root (git rev-parse --show-toplevel)
    
    # Get local branches (from branches directory)
    set -l local_branches
    if test -d "$git_root/branches"
        for dir in "$git_root/branches"/*
            if test -d "$dir"
                set local_branches $local_branches (basename "$dir")
            end
        end
        # Sort the local branches
        set local_branches (printf '%s\n' $local_branches | sort)
    end
    
    # Get remote branches
    set -l remote_branches (git branch -r --format='%(refname:short)' 2>/dev/null | while read branch
        if not string match -q "*HEAD*" "$branch"
            echo "$branch" | string replace "origin/" ""
        end
    end | sort -u)
    
    # Combine branches: local first (with indicator), then remote
    set -l all_branches
    
    if test -n "$local_branches"
        for branch in $local_branches
            set all_branches $all_branches "(local) $branch"
        end
    end
    
    for branch in $remote_branches
        # Only add if not already in local
        if not contains "$branch" $local_branches
            set all_branches $all_branches "(remote) $branch"
        end
    end
    
    if test -z "$all_branches"
        echo (set_color yellow)"⚠ No branches found"(set_color normal)
        return 0
    end

    # Use fzf to select a branch
    set -l selected (printf '%s\n' $all_branches | \
        fzf --ansi \
            --preview "git log --oneline --graph --date=short --color=always --pretty='format:%C(auto)%cd %h%d %s' {2} -- 2>/dev/null || echo 'Branch preview not available'" \
            --header "Select branch to checkout" \
            --border-label "🌲 Branch Checkout" \
            --preview-window right,50% \
            --height 100% \
            --nth 2)
    
    # If nothing selected, return
    if test -z "$selected"
        return 0
    end
    
    # Extract the branch name (remove the (local)/(remote) prefix)
    set -l branch_name (string trim "$selected" | string split " " | tail -1)
    set -l is_local (string match "*local*" "$selected" > /dev/null && echo "true" || echo "false")
    
    if test "$is_local" = "true"
        # Local branch exists in branches directory, checkout worktree
        set -l worktree_path "$git_root/branches/$branch_name"
        if test -d "$worktree_path"
            echo (set_color green)"✓ Checking out worktree: $branch_name"(set_color normal)
            cd "$worktree_path"
            return 0
        else
            echo (set_color red)"✗ Worktree directory not found: $worktree_path"(set_color normal)
            return 1
        end
    else
        # Remote branch, create worktree if needed
        echo (set_color green)"✓ Creating worktree for branch: $branch_name"(set_color normal)
        
        set -l worktree_path "$git_root/branches/$branch_name"
        
        # Create the branches directory if it doesn't exist
        if not test -d "$git_root/branches"
            mkdir -p "$git_root/branches"
        end
        
        # Check if worktree already exists
        if test -d "$worktree_path"
            echo (set_color yellow)"⚠ Worktree already exists, changing to: $branch_name"(set_color normal)
        else
            # Create worktree for remote branch
            git worktree add "$worktree_path" "origin/$branch_name" 2>&1
            if test $status -ne 0
                echo (set_color red)"✗ Failed to create worktree"(set_color normal)
                return 1
            end
        end
        
        cd "$worktree_path"
        return 0
    end
end
