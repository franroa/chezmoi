function transient_rprompt_func
    set current_directory (test -n "$TRANSIENT_PWD" && echo $TRANSIENT_PWD || pwd)
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
