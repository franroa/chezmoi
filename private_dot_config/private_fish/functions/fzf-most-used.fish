function fzf-most-used --description "FZF with most frequently used commands"
    history | awk '{print $1}' | sort | uniq -c | sort -rn | awk '{for(i=2;i<=NF;i++) printf "%s ", $i; print ""}' | fzf --preview='which {} 2>/dev/null || echo "Command not found"'
end
