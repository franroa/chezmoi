# fzf.fish is only meant to be used in interactive mode. If not in interactive mode and not in CI, skip the config to speed up shell startup
if not status is-interactive && test "$CI" != true
    exit
end

# Because of scoping rules, to capture the shell variables exactly as they are, we must read
# them before even executing _fzf_search_variables. We use psub to store the
# variables' info in temporary files and pass in the filenames as arguments.
# This variable is global so that it can be referenced by fzf_configure_bindings and in tests
set --global _fzf_search_vars_command '_fzf_search_variables (set --show | psub) (set --names | psub)'

# Install the default bindings, which are mnemonic and minimally conflict with fish's preset bindings
fzf_configure_bindings

# Doesn't erase autoloaded _fzf_* functions because they are not easily accessible once key bindings are erased
function _fzf_uninstall --on-event fzf_uninstall
    _fzf_uninstall_bindings

    set --erase _fzf_search_vars_command
    functions --erase _fzf_uninstall _fzf_migration_message _fzf_uninstall_bindings fzf_configure_bindings
    complete --erase fzf_configure_bindings

    set_color cyan
    echo "fzf.fish uninstalled."
    echo "You may need to manually remove fzf_configure_bindings from your config.fish if you were using custom key bindings."
    set_color normal
end

# FZF Configuration
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
    --layout=reverse \
    --height 100% \
    --scrollbar='▐' \
    --padding=1,1 \
    --color=bg+:#283457 \
    --color=bg:#24283b \
    --color=border:#27a1b9 \
    --color=fg:#c0caf5 \
    --color=gutter:#16161e \
    --color=header:#ff9e64 \
    --color=hl+:#2ac3de \
    --color=hl:#2ac3de \
    --color=info:#545c7e \
    --color=marker:#ff007c \
    --color=pointer:#ff007c \
    --color=prompt:#2ac3de \
    --color=query:#c0caf5:regular \
    --color=scrollbar:#27a1b9 \
    --color=separator:#ff9e64 \
    --color=spinner:#ff007c \
    --multi \
    --bind 'ctrl-/:toggle-preview' \
    --bind 'ctrl-l:clear-query' \
    --bind 'ctrl-k:kill-line' \
   "

# set -gx FZF_CTRL_T_OPTS "--preview='bat --color=always --line-range :500 {}' --bind 'ctrl-/:toggle-preview' --walker=file,dir,follow"
# set -gx FZF_ALT_C_OPTS "--preview='ls -lah {}' --walker=dir,follow"
# set -gx FZF_CTRL_R_OPTS "--preview='echo {}' --preview-window=up:3:wrap"
set fzf_diff_highlighter delta --paging=never --width=200

fzf_configure_bindings --history=
fzf_configure_bindings --directory=\cf --processes=\cp --git_status=\cs --git_log=\co
bind \ct fzf-file-widget
bind \ec fzf-cd-widget
bind \cr fzf-history-widget
