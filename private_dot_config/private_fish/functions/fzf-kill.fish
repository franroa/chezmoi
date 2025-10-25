function fzf-kill --description "Kill process with fzf"
    ps aux | fzf -m --header "Select processes to kill" | awk '{print $2}' | xargs -r kill -9
end
