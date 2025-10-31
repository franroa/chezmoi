set -gx FZF_GIT_FZF_COMMAND "fzf --height 100% --layout reverse --multi --min-height 20+ --border=rounded --no-separator --header-border horizontal --border-label-pos 2 --color 'label:blue' --padding=1,2 --margin=1 --preview-window 'right,50%' --preview-border line --bind 'ctrl-/:change-preview-window(down,50%|hidden|)'"

function __fzf_git_sh
    set --function fzf_git_sh_path (realpath (status dirname))
    commandline --insert (FZF_GIT_FZF="$FZF_GIT_FZF_COMMAND" SHELL=bash bash "$fzf_git_sh_path/fzf-git.sh" --run $argv | string join ' ')
end

set --local commands branches each_ref files hashes lreflogs remotes stashes tags worktrees

for command in $commands
    set --function key (string sub --length=1 $command)

    if test "$command" != "files"
        eval "bind -M default \cg$key   '__fzf_git_sh $command'"
        eval "bind -M insert  \cg$key   '__fzf_git_sh $command'"
        eval "bind -M default \cg\c$key '__fzf_git_sh $command'"
        eval "bind -M insert  \cg\c$key '__fzf_git_sh $command'"
    end
end

# For files: space+g+f binding using state variables
set -g __fzf_git_space_state ""

function __fzf_git_space_leader --description "Space leader key for space+g+f"
    set -g __fzf_git_space_state "space"
    commandline -f end-of-line
end

function __fzf_git_space_g --description "g key handler for space+g+f sequence"
    if test "$__fzf_git_space_state" = "space"
        set -g __fzf_git_space_state "space_g"
        commandline -f end-of-line
    else
        set -g __fzf_git_space_state ""
        commandline -f self-insert
    end
end

function __fzf_git_space_g_f --description "f key handler for space+g+f sequence"
    if test "$__fzf_git_space_state" = "space_g"
        set -g __fzf_git_space_state ""
        __fzf_git_sh files
    else
        set -g __fzf_git_space_state ""
        commandline -f self-insert
    end
end

bind -M default ' ' __fzf_git_space_leader
bind -M default 'g' __fzf_git_space_g
bind -M default 'f' __fzf_git_space_g_f




