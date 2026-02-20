# Override slow system flatpak.fish - hardcoded paths
if type -q flatpak
    set -x --path XDG_DATA_DIRS $XDG_DATA_DIRS
    set -q XDG_DATA_DIRS[1]; or set XDG_DATA_DIRS /usr/local/share /usr/share

    # Hardcoded instead of calling `flatpak --installations`
    for dir in /var/lib/flatpak/exports/share $HOME/.local/share/flatpak/exports/share
        if test -d $dir; and not contains $dir $XDG_DATA_DIRS
            set -p XDG_DATA_DIRS $dir
        end
    end
end
