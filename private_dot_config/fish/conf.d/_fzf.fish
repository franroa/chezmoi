bind -M insert \co __fzf_history
bind -M insert \cp __fzf_tldr
bind -M insert \ct __fzf_files

set -l color00 '#292D3E'
set -l color01 '#444267'
set -l color02 '#32374D'
set -l color03 '#676E95'
set -l color04 '#8796B0'
set -l color05 '#959DCB'
set -l color06 '#959DCB'
set -l color07 '#FFFFFF'
set -l color08 '#F07178'
set -l color09 '#F78C6C'
set -l color0A '#FFCB6B'
set -l color0B '#C3E88D'
set -l color0C '#89DDFF'
set -l color0D '#82AAFF'
set -l color0E '#C792EA'
set -l color0F '#FF5370'

set -x FZF_DEFAULT_OPTS "--cycle --layout=reverse --border --height 90% --preview-window=right:70% \
    --color=bg+:$color01,bg:$color00,spinner:$color0C,hl:$color0D \
    --color=fg:$color04,header:$color0D,info:$color0A,pointer:$color0C \
    --color=marker:$color0C,fg+:$color06,prompt:$color0A,hl+:$color0D"

# export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
# --color=fg:#c8d3f5,bg:#222436,hl:#ff966c \
# --color=fg+:#c8d3f5,bg+:#2f334d,hl+:#ff966c \
# --color=info:#82aaff,prompt:#86e1fc,pointer:#86e1fc \
# --color=marker:#c3e88d,spinner:#c3e88d,header:#c3e88d"
