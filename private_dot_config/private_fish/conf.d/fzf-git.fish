set -gx FZF_GIT_FZF_COMMAND "fzf --height 100% --layout reverse --multi --min-height 20+ --border=rounded --no-separator --header-border horizontal --border-label-pos 2 --color 'label:blue' --padding=1,2 --margin=1 --preview-window 'right,50%' --preview-border line --bind 'ctrl-/:change-preview-window(down,50%|hidden|)'"

function __fzf_git_sh
    set --function fzf_git_sh_path (realpath (status dirname))
    commandline --insert (FZF_GIT_FZF="$FZF_GIT_FZF_COMMAND" SHELL=bash bash "$fzf_git_sh_path/fzf-git.sh" --run $argv | string join ' ')
end

set --local commands branches each_ref files hashes lreflogs remotes stashes tags worktrees

for command in $commands
    set --function key (string sub --length=1 $command)

    eval "bind -M default \cg$key   '__fzf_git_sh $command'"
    eval "bind -M insert  \cg$key   '__fzf_git_sh $command'"
    eval "bind -M default \cg\c$key '__fzf_git_sh $command'"
    eval "bind -M insert  \cg\c$key '__fzf_git_sh $command'"
end
