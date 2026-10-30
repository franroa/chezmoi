function k9s --description "k9s with every kubeconfig under ~/.kube merged (switch with :ctx)"
    # Only real kubeconfigs: skip *.bak, kubie/color settings, __None__.yaml placeholder
    set -l files
    for f in $HOME/.kube/config $HOME/.kube/*.yaml
        test -f $f; or continue
        string match -q '__*' (path basename $f); and continue
        grep -q '^contexts:' $f; or continue
        set -a files $f
    end

    if test (count $files) -eq 0
        command k9s $argv
        return
    end

    # Keep the context the shell is on (e.g. the tmux session's kubeconfig),
    # otherwise the merged config would start on whichever file sorts first
    set -l ctx_args
    if not contains -- --context $argv
        set -l ctx (kubectl config current-context 2>/dev/null)
        test -n "$ctx"; and set ctx_args --context $ctx
    end

    # Scoped to this invocation, so the shell's own KUBECONFIG is untouched
    set -lx KUBECONFIG (string join : $files)
    command k9s $ctx_args $argv
end
