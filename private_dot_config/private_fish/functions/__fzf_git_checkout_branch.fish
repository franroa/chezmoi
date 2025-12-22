#!/usr/bin/env fish
# Git checkout branch function with worktree support and FZF integration
# Allows checking out branches with optional creation of new branches
# Handles both local and remote branches

function __fzf_git_checkout_branch
    # Check if we're in a git repository
    if not git rev-parse --git-dir > /dev/null 2>&1
        echo (set_color red)"Not a git repository"(set_color normal)
        return 1
    end
    
    # Debug: show that function is being called
    # echo (set_color cyan)"[DEBUG] Function __fzf_git_checkout_branch started"(set_color normal) >&2

    # Get local branches (with current branch marked with *)
    set -l local_branches (git branch --format='%(refname:short)' 2>/dev/null)
    
    # Get remote branches (deduplicated, without origin/ prefix for cleaner display)
    set -l remote_branches (git branch -r --format='%(refname:short)' 2>/dev/null | while read branch
        if not string match -q "*HEAD*" "$branch"
            echo "$branch" | string replace "origin/" ""
        end
    end | sort -u)
    
    # Combine branches: local first (with indicator), then remote
    set -l all_branches
    for branch in $local_branches
        set all_branches $all_branches "(local) $branch"
    end
    for branch in $remote_branches
        # Only add if not already in local
        if not contains "$branch" $local_branches
            set all_branches $all_branches "(remote) $branch"
        end
    end

    # Use fzf to select a branch with your existing FZF config style
    set -l selected (printf '%s\n' $all_branches | \
        fzf --ansi \
            --preview "git log --oneline --graph --date=short --color=always --pretty='format:%C(auto)%cd %h%d %s' {2} -- 2>/dev/null || true" \
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
    set -l branch_name (echo "$selected" | awk '{print $NF}')
    
    # Check if branch exists locally
    if git show-ref --verify --quiet "refs/heads/$branch_name"
        # Local branch exists, just checkout
        echo (set_color green)"✓ Checking out branch: $branch_name"(set_color normal)
        git checkout "$branch_name"
        return $status
    end
    
    # Check if branch exists on remote
    if git show-ref --verify --quiet "refs/remotes/origin/$branch_name"
        # Remote branch exists, create local tracking branch
        echo (set_color green)"✓ Creating local tracking branch: $branch_name"(set_color normal)
        git checkout --track "origin/$branch_name"
        return $status
    end
    
    # Branch doesn't exist, prompt to create new branch
    echo (set_color yellow)"\n⚠ Branch '$branch_name' not found locally or remote."(set_color normal)
    printf '%s' (set_color cyan)"Create new branch? (y/n): "(set_color normal)
    read -l response
    
    if test "$response" = "y" -o "$response" = "Y"
        echo (set_color green)"✓ Creating new branch: $branch_name"(set_color normal)
        git checkout -b "$branch_name"
        return $status
    else
        echo (set_color yellow)"Cancelled"(set_color normal)
        return 0
    end
end
