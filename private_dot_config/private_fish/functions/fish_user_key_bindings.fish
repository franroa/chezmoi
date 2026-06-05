function fish_user_key_bindings
    fish_vi_key_bindings

    # Custom binds defined here so they survive every (re)init of the vi
    # key bindings. A bare `fish_vi_key_bindings` call erases all binds, so
    # binds set in conf.d at load time get wiped; re-applying them here keeps
    # them alive. Requires __which_key_vi_normal / __reload_fish_config
    # (defined in conf.d/which_key.fish, sourced before this runs).
    bind -M default ' ' __which_key_vi_normal
    bind -M default '\cr' __reload_fish_config
    bind -M insert '\cr' __reload_fish_config
end
