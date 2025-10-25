# set -gx LD_LIBRARY_PATH /usr/local/cuda-12.6/lib64 $LD_LIBRARY_PATH
# # set -gx DOTNET_ROOT = /usr/share/dotnet
# # set -gx DOTNET_home/froa = ~/dotnet6
#
# # Cursor styles
# set -gx fish_vi_force_cursor 1
# set -gx fish_cursor_default block
# set -gx fish_cursor_insert line blink
# set -gx fish_cursor_visual block
# set -gx fish_cursor_replace_one underscore
# set -gx PATH $PATH $HOME/.krew/bin
# direnv hook fish | source
# # Path
# set -x fish_user_paths
# fish_add_path /home/froa/.dotnet/tools
# fish_add_path /home/froa/.opencode/bin
# fish_add_path /home/froa/dotnet
# # fish_add_path /home/froa/dotnet8
# # fish_add_path /home/froa/.dotnet
# # fish_add_path ~/dotnet6
# fish_add_path /usr/local/go/bin
# fish_add_path /home/linuxbrew/.linuxbrew/opt/node@21/bin
# fish_add_path /usr/local/go/bin/go
# fish_add_path ~/.cargo/bin
# fish_add_path ~/.local/bin
# fish_add_path ~/.luarocks/bin
# fish_add_path ~/Library/Python/3.{8,9}/bin
# fish_add_path /usr/local/opt/sqlite/bin
# fish_add_path /usr/local/sbin
# fish_add_path ~/.gem/ruby/2.6.0/bin
# fish_add_path ~/.local/bin/pnpm
# fish_add_path /bin
# fish_add_path ~/.local/share/bob/nvim-bin
# fish_add_path /var/lib/flatpak/exports/bin/
# fish_add_path /home/froa/.local/bin
# fish_add_path /home/froa/.fzf/bin
# fish_add_path ~/.local/share/nvm/v22.14.0/bin
# fish_add_path /home/froa/.fzf/bin
# fish_add_path $HOME/.krew/bin
# fish_add_path /usr/local/cuda-12.8/bin
# fish_add_path $HOME/scripts/
# fish_add_path $HOME/scripts/git-scripts/
# fish_add_path GPG_TTY=$(tty)
# # NOTE: deno
# # set -gx DENO_INSTALL "~/.deno"
# # fish_add_path ~/.deno/bin
#
# # Fish
# set fish_emoji_width 2
# alias oil='~/.local/bin/oil-ssh.sh'
# alias ft='~/.local/bin/ft.sh'
# set -U fish_greeting ""
# # Go
# # set -x GOPATH ~/go
# fish_add_path $GOPATH $GOPATH/bin
# set -gx GOPATH /home/froa/go
# set -gx PATH $PATH /usr/local/bin/go $GOPATH/bin
#
# # Exports
# set -x LESS -rF
# set -x COMPOSE_DOCKER_CLI_BUILD 1
# set -x HOMEBREW_NO_AUTO_UPDATE 1
# set -x DOTDROP_AUTOUPDATE no
# set -x MANPAGER "nvim +Man!"
# # export MANPAGER="sh -c 'col -bx | batcat -l man -p'"
# set -x MANROFFOPT -c
# set -x OPENCV_LOG_LEVEL ERROR
# #set -x MANPAGER "sh -c 'col -bx | bat -l man -p'" # use bat to format man pages
# #set -x MANPAGER "most" # use bat to format man pages
# #
# # abbr -a --position anywhere --set-cursor -- -h "-h 2>&1 | bat --plain --language=help"
#
# # Dnf
# abbr dnfi 'sudo dnf install'
# abbr dnfs 'sudo dnf search'
# abbr dnfr 'sudo dnf remove'
# abbr dnfu 'sudo dnf upgrade --refresh'
#
# # # Tmux
# # abbr t tmux
# # abbr tc 'tmux attach'
# # abbr ta 'tmux attach -t'
# # abbr tad 'tmux attach -d -t'
# # abbr ts 'tmux new -s'
# # abbr tl 'tmux ls'
# # abbr tk 'tmux kill-session -t'
# # abbr mux tmuxinator
#
# alias gcl='gitlab-ci-local'
# # Kubernetes
# alias kco='kubie ctx __None__'
# alias kn='kubie ns'
# alias kneat="kubectl neat get -- pod mimir-ingester-zone-b-0 -oyaml | kubecolor describe pod --kubecolor-stdin"
#
# function akg
#     set domain $argv[1]
#     set tier $argv[2]
#     set region $argv[3]
#
#     # if not set -q $argv[1]
#     #     echo "Usage: akg <prod> <tier> <region>"
#     #     return 1
#     # end
#     #
#     # if not set -q $argv[2]
#     #     echo "Usage: akg <prod> <tier> <region>"
#     #     return 1
#     # end
#     #
#     # if not set -q $argv[3]
#     #     echo "Usage: akg <prod> <tier> <region>"
#     #     return 1
#     # end
#
#     rm $HOME/.kube/$domain-$tier-$region.yaml
#     az account set --subscription $domain-$tier
#     az aks get-credentials --resource-group $domain-$tier-$region --name k8s-$domain-$tier-$region --file $HOME/.kube/$domain-$tier-$region.yaml
#     kubelogin convert-kubeconfig -l azurecli
#     kubectl --kubeconfig $HOME/.kube/$domain-$tier-$region.yaml config rename-context k8s-$domain-$tier-$region $domain-$tier-$region
#     kubie ctx $domain-$tier-$region
# end
#
# # Files & Directories
# abbr mv "mv -iv"
# abbr cp "cp -riv"
# abbr mkdir "mkdir -vp"
# alias ls="eza --color=always --icons --group-directories-first"
# alias la 'eza --color=always --icons --group-directories-first --all'
# alias ll 'eza --color=always --icons --group-directories-first --all --long'
# abbr l ll
# abbr ncdu "ncdu --color dark"
#
# # Editor
# alias vimpager 'nvim - -c "lua require(\'util\').colorize()"'
# abbr vd "VIM=~/projects/neovim nvim --luamod-dev"
# abbr sv sudoedit
# abbr vudo sudoedit
# alias lazyvim "NVIM_APPNAME=lazyvim nvim"
# abbr lv lazyvim
# alias bt "coredumpctl -1 gdb -A '-ex \"bt\" -q -batch' 2>/dev/null | awk '/Program terminated with signal/,0' | bat -l cpp --no-pager --style plain"
#
# # # Dev
# # abbr git hub
# # abbr topgit topgrade --only git_repos
# # abbr g hub
# # abbr gg lazygit
# # abbr gl 'hub l --color | devmoji --log --color | less -rXF'
# # abbr gs "hub st"
# # abbr gb "hub checkout -b"
# # abbr gc "hub commit"
# # abbr gpr "hub pr checkout"
# # abbr gm "hub branch -l main | rg main > /dev/null 2>&1 && hub checkout main || hub checkout master"
# # abbr gcp "hub commit -p"
# # abbr gpp "hub push"
# # abbr gp "hub pull"
# # alias tn "npx --no-install ts-node --transpile-only"
# # abbr tt "tn src/tt.ts"
#
# # Other
# abbr git "env DELTA_FEATURES='+side-by-side' git"
# # abbr hub "env DELTA_FEATURES='+side-by-side' hub"
# abbr tg "tgpt -i"
# abbr df "grc /bin/df -h"
# abbr ntop "ultra --monitor"
# abbr ytop btm
# abbr gotop btm
# abbr fda "fd -IH"
# abbr rga "rg -uu"
# abbr grep rg
# abbr suod sudo
# abbr bat batcat
# alias cat batcat
# alias bat batcat
# abbr helpme "bat ~/HELP.md"
# abbr weather "curl -s wttr.in/Ghent | grep -v Follow"
# abbr show-cursor "tput cnorm"
# abbr hide-cursor "tput civis"
# abbr aria2c-daemon "aria2c -D"
# alias gnome-control-center "env XDG_CURRENT_DESKTOP=GNOME gnome-control-center"
#
# # systemctl
# abbr s systemctl
# abbr su "systemctl --user"
# abbr ss "command systemctl status"
# abbr sl "systemctl --type service --state running"
# abbr slu "systemctl --user --type service --state running"
# abbr se "sudo systemctl enable --now"
# abbr sd "sudo systemctl disable --now"
# abbr sr "sudo systemctl restart"
# abbr so "sudo systemctl stop"
# abbr sa "sudo systemctl start"
# abbr sf "systemctl --failed --all"
#
# # journalctl
# abbr jb "journalctl -b"
# abbr jf "journalctl --follow"
# abbr jg "journalctl -b --grep"
# abbr ju "journalctl --unit"
#
# # oh-my-posh init fish | source
#
# # NOTE: paru AUR HELPER
# # abbr p paru
# # abbr pai "paru -S"
# # abbr par "paru -Rns"
# # abbr pas "paru -Ss"
# # abbr pal "paru -Q"
# # abbr paf "paru -Ql"
# # abbr pao "paru -Qo"
# #
# #
# #
#
# function klookup
#     # kubectl run temp -it --rm --image docker.io/amouat/network-utils --command -- nslookup $argv
#     kubectl run temp --wait --image docker.io/amouat/network-utils --command -- nslookup $argv
#     kubectl wait --for=condition=Ready --timeout=5m pod temp || kubectl wait --for=condition=Ready --timeout=5m pod temp
#     kubectl logs temp
#     kubectl delete pod temp
# end
#
# function change_kubernetes_cluster_variable
#     kubelogin convert-kubeconfig -l azurecli
#     set -gx K8S_CLUSTER (kubectl config current-context 2>/dev/null)
#     set -gx FOREGROUND_COLOR grey
#     if string match -q -- "*docker-desktop*" $K8S_CLUSTER
#         set -gx BACKGROUND_COLOR "#303b33"
#         set -gx FOREGROUND_COLOR green
#         printf '\033]11;#303b33\007'
#     end
#     if string match -q -- "*kind*" $K8S_CLUSTER
#         set -gx BACKGROUND_COLOR "#303b33"
#         set -gx FOREGROUND_COLOR green
#         printf '\033]11;#303b33\007'
#     end
#     if string match -q -- "*None*" $K8S_CLUSTER
#         set -gx BACKGROUND_COLOR "#222436"
#         set -gx FOREGROUND_COLOR grey
#         printf '\033]11;#222436\007'
#     end
#     if string match -q -- "*live*" $K8S_CLUSTER
#         set -gx BACKGROUND_COLOR "#8E1600"
#         set -gx FOREGROUND_COLOR green
#         printf '\033]11;#8E1600\007'
#     end
#     if string match -q -- "*sandbox*" $K8S_CLUSTER
#         set -gx BACKGROUND_COLOR "#3c307f"
#         set -gx FOREGROUND_COLOR green
#         printf '\033]11;#3c307f\007'
#     end
# end
#
# function change_kubernetes_ns_variable
#     set -gx K8S_NAMESPACE (kubectl config view --minify -o jsonpath='{..namespace}')
# end
#
# function change_nvim_abbreviation
#     abbr vim K8S_CLUSTER=$K8S_CLUSTER K8S_NAMESPACE=$K8S_NAMESPACE nvim
#     abbr vi K8S_CLUSTER=$K8S_CLUSTER K8S_NAMESPACE=$K8S_NAMESPACE nvim
#     abbr v K8S_CLUSTER=$K8S_CLUSTER K8S_NAMESPACE=$K8S_NAMESPACE nvim
# end
#
# # if not status --is-login
# #     source ~/secrets.fish
# # end
#
# function kubie
#     set -gx IS_COMING_FROM_KUBIE TRUE
#     command kubie $argv
# end
# function refresh_prompt --on-event fish_prompt
#     if test "$IS_COMING_FROM_KUBIE" = TRUE
#         set -gx IS_COMING_FROM_KUBIE FALSE
#         change_kubernetes_cluster_variable
#         change_kubernetes_ns_variable
#         change_nvim_abbreviation
#     end
# end
#
# # HACK: for k9s to show the contexts
# # this doesnt work with kubie ctx
# # set -x KUBECONFIG (ls  $HOME/.kube/config* | tr '\n' ':')
# # function k9s
# #     set -x KUBECONFIG (ls  $HOME/.kube/config* | tr '\n' ':')
# #     command k9s
# # end
#
# # set fzf_dir_opts --bind "ctrl-o:execute($EDITOR {} &> /dev/tty)"
# # source ~/.asdf/asdf.fish
#
# # pnpm
# set -gx PNPM_HOME "/home/froa/.local/share/pnpm"
# if not string match -q -- $PNPM_HOME $PATH
#     set -gx PATH "$PNPM_HOME" $PATH
# end
# # pnpm end
# #
# fzf_configure_bindings --history=
# fzf_configure_bindings --directory=\cf --processes=\cp --git_status=\cs --git_log=\co
# set fzf_diff_highlighter delta --paging=never --width=200
#
# # Generated for envman. Do not edit.
# # test -s ~/.config/envman/load.fish; and source ~/.config/envman/load.fish
# # mise activate fish | source
#
# set _CONDA_ROOT /home/froa/miniconda3
#
# # >>> conda initialize >>>
# # !! Contents within this block are managed by 'conda init' !!
# if test -f /home/froa/miniconda3/bin/conda
#     eval /home/froa/miniconda3/bin/conda "shell.fish" hook $argv | source
# else
#     if test -f "/home/froa/miniconda3/etc/fish/conf.d/conda.fish"
#         . "/home/froa/miniconda3/etc/fish/conf.d/conda.fish"
#     else
#         set -x PATH /home/froa/miniconda3/bin $PATH
#     end
# end
# # <<< conda initialize <<<
#
# eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
#
# # adds alias for "kubectl" to "kubecolor" with completions
# function kubectl --wraps kubectl
#     command kubecolor $argv
# end
#
# # adds alias for "k" to "kubecolor" with completions
# function k --wraps kubectl
#     command kubecolor $argv
# end
#
# # mcfly init fish | source
# # set -gx MCFLY_KEY_SCHEME vim
# # set -gx MCFLY_FUZZY 2
# # set -gx MCFLY_RESULTS 50
# # set -gx MCFLY_PROMPT "❯"
# # set -x PATH (pwd)"/git-fuzzy/bin:$PATH"
#
# # TokyoNight Color Palette
# set -l foreground c0caf5
# set -l selection 2e3c64
# set -l comment 565f89
# set -l red f7768e
# set -l orange ff9e64
# set -l yellow e0af68
# set -l green 9ece6a
# set -l purple 9d7cd8
# set -l cyan 7dcfff
# set -l pink bb9af7
#
# # Syntax Highlighting Colors
# set -g fish_color_normal $foreground
# set -g fish_color_command $cyan
# set -g fish_color_keyword $pink
# set -g fish_color_quote $yellow
# set -g fish_color_redirection $foreground
# set -g fish_color_end $orange
# set -g fish_color_option $pink
# set -g fish_color_error $red
# set -g fish_color_param $purple
# set -g fish_color_comment $comment
# set -g fish_color_selection --background=$selection
# set -g fish_color_search_match --background=$selection
# set -g fish_color_operator $green
# set -g fish_color_escape $pink
# set -g fish_color_autosuggestion $comment
#
# # Completion Pager Colors
# set -g fish_pager_color_progress $comment
# set -g fish_pager_color_prefix $cyan
# set -g fish_pager_color_completion $foreground
# set -g fish_pager_color_description $comment
# set -g fish_pager_color_selected_background --background=$selection
#
# atuin init fish --disable-up-arrow | source
# set -g fish_key_bindings fish_vi_key_bindings
#
# function it -d 'Run Taskfile tasks interactively'
#     set -l selected (task --list | grep '^* ' | cut -d ' ' -f2 | sed 's/://' | sort | fzf -m --reverse --preview 'task --summary {}')
#     set -l cmd "task $argv $selected"
#     commandline -r $cmd
# end
#
# # function profile-dotnet --description 'Profile .NET app with perf for perfanno.nvim'
# #     # Parse arguments
# #     set -l duration 30
# #     set -l output "perf.data"
# #
# #     argparse 'd/duration=' 'o/output=' -- $argv
# #     or return
# #
# #     if set -q _flag_duration
# #         set duration $_flag_duration
# #     end
# #
# #     if set -q _flag_output
# #         set output $_flag_output
# #     end
# #
# #     # Setup environment
# #     set -x DOTNET_PerfMapEnabled 1
# #     set -x DOTNET_EnableEventLog 1
# #
# #     echo "Starting .NET app..."
# #     dotnet run -c Release &
# #     set app_pid $last_pid
# #
# #     echo "App started with PID: $app_pid"
# #     sleep 2
# #
# #     echo "Recording for $duration seconds with call graph..."
# #     sudo perf record --call-graph dwarf -e cycles -F 99 -p $app_pid -o $output sleep $duration
# #
# #     echo "Stopping app..."
# #     kill $app_pid
# #
# #     echo "✓ Profiling complete! Output: $output"
# #     echo "Open your code in nvim and press <leader>pla to load annotations"
# # end

alias gcl='gitlab-ci-local'
alias kco='kubie ctx __None__'
alias kn='kubie ns'
alias k kubectl
alias kneat="kubectl neat get -- pod mimir-ingester-zone-b-0 -oyaml | kubecolor describe pod --kubecolor-stdin"
alias k kubectl

fish_add_path /usr/local
fish_add_path ~/.local/share/nvm/v25.0.0/bin
fish_add_path ~/dotnet
set -gx DOTNET_ROOT /home/froa/dotnet
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
set -gx EDITOR (which nvim)
set -gx VISUAL $EDITOR
set -gx SUDO_EDITOR $EDITOR
set -gx BROWSER "chrome.exe"
set -g fish_key_bindings fish_vi_key_bindings
abbr v nvim

zoxide init fish | source
starship init fish | source
atuin init fish --disable-up-arrow | source

fish_config theme choose tokyonight

# Interactive pod selector with logs
function klog
    set -l pod (kubectl get pods --all-namespaces -o wide | fzf --header-lines=1 --preview 'kubectl logs --tail=50 {2} -n {1}' --preview-window=down:50%:wrap | awk '{print $2" -n "$1}')
    if test -n "$pod"
        kubectl logs -f $pod
    end
end

# Interactive pod exec
function kexec
    set -l pod (kubectl get pods --all-namespaces | fzf --header-lines=1 | awk '{print $2" -n "$1}')
    if test -n "$pod"
        set -l shell (test -n "$argv[1]"; and echo $argv[1]; or echo /bin/bash)
        kubectl exec -it $pod -- $shell
    end
end

# Pod describe with preview
function kdesc
    kubectl get pods --all-namespaces | fzf --header-lines=1 --preview 'kubectl describe pod {2} -n {1}' \
        --preview-window=right:70%:wrap
end

# Delete pods interactively (with confirmation)
function kdel
    set -l pods (kubectl get pods --all-namespaces | fzf -m --header-lines=1 | awk '{print $2" -n "$1}')
    if test -n "$pods"
        echo "Delete these pods?"
        echo "$pods"
        read -l -P "Confirm (y/N): " confirm
        if test "$confirm" = y -o "$confirm" = Y
            echo "$pods" | xargs -I {} sh -c 'kubectl delete pod {}'
        end
    end
end

# Switch context with preview showing current resources
function kctx
    set -l context (kubectl config get-contexts -o name | \
        fzf --preview 'kubectl config use-context {} && kubectl get pods --all-namespaces' \
        --preview-window=right:70%:wrap)
    if test -n "$context"
        kubectl config use-context "$context"
    end
end

# Switch namespace with resource preview
function kns
    set -l ns (kubectl get ns | fzf --header-lines=1 \
        --preview 'kubectl get pods,svc,ing -n {1}' \
        --preview-window=right:60%:wrap | awk '{print $1}')
    if test -n "$ns"
        kubectl config set-context --current --namespace="$ns"
    end
end

# Get any resource type interactively
function kget
    set -l resource_type (kubectl api-resources --namespaced=true -o name | fzf)
    if test -n "$resource_type"
        kubectl get "$resource_type" --all-namespaces | fzf --header-lines=1 --preview "kubectl describe $resource_type {2} -n {1}" \
            --preview-window=down:50%:wrap
    end
end

# Port forward with service selection
function kpf
    set -l svc (kubectl get svc --all-namespaces | \
        fzf --header-lines=1 --preview 'kubectl describe svc {2} -n {1}' | \
        awk '{print $2" -n "$1}')
    if test -n "$svc"
        read -l -P "Local port: " local_port
        read -l -P "Remote port: " remote_port
        kubectl port-forward svc/$svc $local_port:$remote_port
    end
end

# Watch events for selected resource
function kevents
    set -l resource (kubectl get all --all-namespaces -o wide | \
        fzf --header-lines=1 | awk '{print $1}')
    if test -n "$resource"
        set -l resource_name (string split "/" $resource)[-1]
        kubectl get events --field-selector involvedObject.name=$resource_name -w
    end
end

# Multi-pod log tailing
function kmultilog
    set -l pods (kubectl get pods --all-namespaces | fzf -m --header-lines=1 | awk '{print $2" -n "$1}')
    if test -n "$pods"
        echo "$pods" | xargs -I {} -P 10 sh -c 'kubectl logs -f {} --prefix=true --timestamps=true &'
    end
end

# Search through pod logs
function klogsearch
    set -l pod (kubectl get pods --all-namespaces | fzf --header-lines=1 | awk '{print $2" -n "$1}')
    if test -n "$pod"
        read -l -P "Search pattern: " pattern
        kubectl logs $pod | grep --color=always "$pattern"
    end
end

# Get pod by label selector
function klabel
    set -l labels (kubectl get pods --show-labels --all-namespaces | \
        awk '{print $NF}' | tr ',' '\n' | sort -u | fzf -m | paste -sd "," -)
    if test -n "$labels"
        kubectl get pods --all-namespaces -l "$labels"
    end
end

# Top pods by CPU/memory with selection
function ktop
    kubectl top pods --all-namespaces | fzf --header-lines=1 \
        --preview 'kubectl describe pod {2} -n {1}' \
        --preview-window=right:60%:wrap
end

# Resource usage for nodes
function knodes
    kubectl get nodes | fzf --header-lines=1 \
        --preview 'kubectl describe node {1}; echo "---"; kubectl top node {1}' \
        --preview-window=right:60%:wrap
end

# Rolling restart deployment
function krestart
    set -l deployment (kubectl get deployments --all-namespaces | \
        fzf --header-lines=1 --preview 'kubectl describe deployment {2} -n {1}' | \
        awk '{print $2" -n "$1}')
    if test -n "$deployment"
        kubectl rollout restart deployment $deployment
    end
end

# Watch rollout status
function krollout
    set -l deployment (kubectl get deployments --all-namespaces | \
        fzf --header-lines=1 | awk '{print $2" -n "$1}')
    if test -n "$deployment"
        kubectl rollout status deployment $deployment --watch
    end
end

# Scale deployment interactively
function kscale
    set -l deployment (kubectl get deployments --all-namespaces | \
        fzf --header-lines=1 --preview 'kubectl describe deployment {2} -n {1}' | \
        awk '{print $2" -n "$1}')
    if test -n "$deployment"
        read -l -P "Scale to: " replicas
        kubectl scale deployment $deployment --replicas=$replicas
    end
end

# Interactive configmap editor
function kconfigmap
    set -l cm (kubectl get configmap --all-namespaces | \
        fzf --header-lines=1 --preview 'kubectl describe configmap {2} -n {1}' | \
        awk '{print $2" -n "$1}')
    if test -n "$cm"
        kubectl edit configmap $cm
    end
end

# Interactive secret viewer (base64 decoded)
function ksecret
    set -l secret (kubectl get secrets --all-namespaces | \
        fzf --header-lines=1 --preview 'kubectl get secret {2} -n {1} -o yaml | grep -A 999 "^data:"' | \
        awk '{print $2" -n "$1}')
    if test -n "$secret"
        kubectl get secret $secret -o yaml
    end
end

# Get YAML for any resource
function kyaml
    set -l resource (kubectl get all --all-namespaces | \
        fzf --header-lines=1 --preview 'kubectl get {1} -o yaml' | \
        awk '{print $1}')
    if test -n "$resource"
        kubectl get $resource -o yaml
    end
end

# Apply/dry-run files from directory
function kapply
    set -l file (find . -name "*.yaml" -o -name "*.yml" | \
        fzf --preview 'cat {}' --preview-window=right:60%:wrap)
    if test -n "$file"
        read -l -P "Dry run first? (y/N): " dryrun
        if test "$dryrun" = y -o "$dryrun" = Y
            kubectl apply --dry-run=client -f $file
            read -l -P "Apply for real? (y/N): " confirm
            if test "$confirm" = y -o "$confirm" = Y
                kubectl apply -f $file
            end
        else
            kubectl apply -f $file
        end
    end
end
