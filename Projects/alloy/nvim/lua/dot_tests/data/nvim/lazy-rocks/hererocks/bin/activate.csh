which deactivate-lua >&/dev/null && deactivate-lua

alias deactivate-lua 'if ( -x '\''/home/froa/.config/nvim/lua/local_plugins/alloy/lua/.tests/data/nvim/lazy-rocks/hererocks/bin/lua'\'' ) then; setenv PATH `'\''/home/froa/.config/nvim/lua/local_plugins/alloy/lua/.tests/data/nvim/lazy-rocks/hererocks/bin/lua'\'' '\''/home/froa/.config/nvim/lua/local_plugins/alloy/lua/.tests/data/nvim/lazy-rocks/hererocks/bin/get_deactivated_path.lua'\''`; rehash; endif; unalias deactivate-lua'

setenv PATH '/home/froa/.config/nvim/lua/local_plugins/alloy/lua/.tests/data/nvim/lazy-rocks/hererocks/bin':"$PATH"
rehash
