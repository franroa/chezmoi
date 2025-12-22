#!/usr/bin/env fish
# Git create branch function with worktree support
# Creates a new branch and sets up a worktree at git_root/branches/name-of-branch

function git_create_branch
    # Check if we're in a git repository
    if not git rev-parse --git-dir > /dev/null 2>&1
        echo (set_color red)"✗ Not a git repository"(set_color normal)
        return 1
    end

    # Get git root directory
    set -l git_root (git rev-parse --show-toplevel)
    
    # Prompt for branch name
    printf '%s' (set_color cyan)"Enter branch name (e.g., feature/my-feature): "(set_color normal)
    read -l branch_name
    
    # Validate branch name
    if test -z "$branch_name"
        echo (set_color yellow)"⚠ Branch name cannot be empty"(set_color normal)
        return 0
    end
    
    # Check for invalid characters in branch name
    if string match -q '*[[:space:]]*' "$branch_name"
        echo (set_color red)"✗ Branch name cannot contain spaces"(set_color normal)
        return 1
    end
    
    # Set the worktree path
    set -l worktree_path "$git_root/branches/$branch_name"
    
    # Check if worktree already exists
    if test -d "$worktree_path"
        echo (set_color red)"✗ Worktree already exists: $worktree_path"(set_color normal)
        return 1
    end
    
    # Prompt for base branch (default: main or master)
    printf '%s' (set_color cyan)"Base branch to branch from (default: main): "(set_color normal)
    read -l base_branch
    
    # Use default if not provided
    if test -z "$base_branch"
        set base_branch "main"
        # Try master if main doesn't exist
        if not git show-ref --verify --quiet "refs/heads/$base_branch"
            set base_branch "master"
        end
    end
    
    # Verify base branch exists
    if not git show-ref --verify --quiet "refs/heads/$base_branch"
        echo (set_color red)"✗ Base branch does not exist: $base_branch"(set_color normal)
        return 1
    end
    
    # Create branches directory if it doesn't exist
    if not test -d "$git_root/branches"
        mkdir -p "$git_root/branches"
    end
    
    # Create the new branch and worktree
    echo (set_color green)"✓ Creating branch '$branch_name' from '$base_branch'"(set_color normal)
    
    # Create the branch from the base branch
    git branch "$branch_name" "$base_branch" 2>&1
    if test $status -ne 0
        echo (set_color red)"✗ Failed to create branch"(set_color normal)
        return 1
    end
    
    # Create the worktree
    git worktree add "$worktree_path" "$branch_name" 2>&1
    if test $status -ne 0
        echo (set_color red)"✗ Failed to create worktree"(set_color normal)
        # Clean up the branch if worktree creation failed
        git branch -D "$branch_name"
        return 1
    end
    
    echo (set_color green)"✓ Worktree created at: $worktree_path"(set_color normal)
    
    # Optionally change to the new worktree
    printf '%s' (set_color cyan)"Change to new worktree? (y/n): "(set_color normal)
    read -l response
    
    if test "$response" = "y" -o "$response" = "Y"
        cd "$worktree_path"
        echo (set_color green)"✓ Changed to: $worktree_path"(set_color normal)
    end
    
    return 0
end
