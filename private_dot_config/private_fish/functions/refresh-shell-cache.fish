function refresh-shell-cache --description "Regenerate cached shell init files"
    echo "Regenerating cached init files..."
    /home/linuxbrew/.linuxbrew/bin/brew shellenv > ~/.config/fish/conf.d/_cached_brew.fish
    /home/froa/.nix-profile/bin/starship init fish --print-full-init > ~/.config/fish/conf.d/_cached_starship.fish
    atuin init fish --disable-up-arrow > ~/.config/fish/conf.d/_cached_atuin.fish
    zoxide init fish > ~/.config/fish/conf.d/_cached_zoxide.fish
    direnv hook fish > ~/.config/fish/conf.d/_cached_direnv.fish
    echo "Done. Restart your shell to apply."
end
