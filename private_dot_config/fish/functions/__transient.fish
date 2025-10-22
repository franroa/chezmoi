function __transient
    function __transient_execute
        commandline --is-valid
        if test $status -eq 2 # The empty commandline is an error, not incomplete
            or commandline --paging-full-mode
            commandline -f execute
            return 0
        end
        set --global TRANSIENT transient
        commandline --function expand-abbr suppress-autosuggestion repaint execute
    end

    function __transient_ctrl_c_execute
        set --global TRANSIENT transient
        if test "$(commandline --current-buffer)" = ""
            commandline --function repaint execute
            return 0
        end

        commandline --function repaint cancel-commandline kill-inner-line repaint-mode repaint
    end

    # Key: enter
    bind --user --mode default \r __transient_execute
    bind --user --mode insert \r __transient_execute

    # Key: new line
    bind --user --mode default \cj __transient_execute
    bind --user --mode insert \cj __transient_execute

    # Key: Ctrl-C
    bind --user --mode default \cc __transient_ctrl_c_execute
    bind --user --mode insert \cc __transient_ctrl_c_execute
end

function transient_rprompt_func
    set current_directory (pwd)
    set home_directory $HOME

    # Replace home directory with ~
    set short_directory (string replace -- $home_directory '~' $current_directory)

    printf (set_color grey)"<- $short_directory"

    set cluster " 󱃾 $K8S_CLUSTER ($K8S_NAMESPACE)"
    if test "$K8S_CLUSTER" = __None__
        set cluster " 󱃾"
    end

    if test -n "$K8S_CLUSTER"
        printf (set_color $FOREGROUND_COLOR)"$cluster"
    end

    printf (set_color grey)" ->"
end
