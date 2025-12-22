#!/usr/bin/env fish
# Advanced git checkout examples and optional enhancements
# This file contains commented-out examples for potential future enhancements

# EXAMPLE 1: Extended version with delete branch option
# Uncomment and modify __fzf_git_checkout_branch to add Alt+D (delete) functionality:
#
# --bind "alt-d:execute(git branch -d {2} 2>/dev/null && echo 'Deleted: {2}' || echo 'Failed to delete {2}')" \
#

# EXAMPLE 2: Support for multiple remotes
# To support different remotes, you can modify the function to accept a remote parameter:
#
# function __fzf_git_checkout_branch --argument-names remote
#     set -l remote ${remote:-origin}
#     # ... rest of function using $remote instead of hardcoded 'origin'
#
# Usage: __fzf_git_checkout_branch upstream
#

# EXAMPLE 3: Preserve branch history in worktrees
# When working with worktrees, you might want to track which worktree created a branch:
#
# function __fzf_git_checkout_branch_with_worktree_info
#     set -l worktree_path (git rev-parse --show-toplevel)
#     set -l branch_name $selected
#     # Add metadata to branch if needed
#     git config branch.$branch_name.worktree_created_in "$worktree_path"
#

# EXAMPLE 4: Quick branch from issue number
# Create branches from issue numbers:
#
# function __fzf_git_quick_branch --argument-names issue_prefix
#     set -l prefix ${issue_prefix:-feature}
#     printf '%s' "Enter branch suffix: "
#     read -l suffix
#     set -l branch_name "$prefix/$suffix"
#     git checkout -b "$branch_name"
#

# EXAMPLE 5: Interactive branch with stash option
# When switching branches with uncommitted changes:
#
# function __fzf_git_checkout_branch_with_stash
#     if test (git status --porcelain | wc -l) -gt 0
#         printf '%s' "Uncommitted changes. Stash? (y/n): "
#         read -l response
#         if test "$response" = "y"
#             git stash
#         end
#     end
#     __fzf_git_checkout_branch
#

# EXAMPLE 6: Branch naming suggestions based on issue tracker
# If using GitHub/GitLab issues:
#
# function __fzf_git_smart_branch_name
#     # Fetch open issues and suggest branch names
#     set -l issues (gh issue list --limit 10 --json number,title --jq '.[] | "\(.number): \(.title)"')
#     set -l selected (printf '%s\n' $issues | fzf --preview 'echo {}')
#     set -l issue_num (echo "$selected" | cut -d: -f1)
#     set -l branch_name "issue-$issue_num"
#     git checkout -b "$branch_name"
#

# EXAMPLE 7: Show branch creator and last commit info
# Enhanced preview with more details:
#
# --preview "git log -1 --format='%B%n%nAuthor: %an%nDate: %ai' {2} -- 2>/dev/null || echo 'No commits yet'" \
#

# EXAMPLE 8: Persistent recent branches list
# Track and suggest recently used branches:
#
# function __fzf_git_recent_branches
#     set -l recent (git reflog --pretty=format:%D --abbrev-commit | grep 'checkout:' | sed 's/.*to //' | sort -u | head -10)
#     printf '%s\n' $recent
#
