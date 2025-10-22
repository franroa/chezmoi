if functions -q deactivate-lua
    deactivate-lua
end

function deactivate-lua
    if test -x '/home/froa/.config/nvim/lua/local_plugins/alloy/lua/.tests/data/nvim/lazy-rocks/hererocks/bin/lua'
        eval ('/home/froa/.config/nvim/lua/local_plugins/alloy/lua/.tests/data/nvim/lazy-rocks/hererocks/bin/lua' '/home/froa/.config/nvim/lua/local_plugins/alloy/lua/.tests/data/nvim/lazy-rocks/hererocks/bin/get_deactivated_path.lua' --fish)
    end

    functions -e deactivate-lua
end

set -gx PATH '/home/froa/.config/nvim/lua/local_plugins/alloy/lua/.tests/data/nvim/lazy-rocks/hererocks/bin' $PATH
