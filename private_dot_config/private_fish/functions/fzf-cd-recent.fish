function fzf-cd-recent --description "CD to recent directories"
    z -l 2>&1 | awk '{print $2}' | fzf --preview='ls -lah {}' | read -z selection
    and cd $selection
end
