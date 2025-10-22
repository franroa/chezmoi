-- LuaRocks configuration

rocks_trees = {
   { name = "user", root = home .. "/.luarocks" };
   { name = "system", root = "/home/froa/.config/nvim/lua/local_plugins/alloy/lua/.tests/data/nvim/lazy-rocks/hererocks" };
}
variables = {
   LUA_DIR = "/home/froa/.config/nvim/lua/local_plugins/alloy/lua/.tests/data/nvim/lazy-rocks/hererocks";
   LUA_BINDIR = "/home/froa/.config/nvim/lua/local_plugins/alloy/lua/.tests/data/nvim/lazy-rocks/hererocks/bin";
   LUA_VERSION = "5.1";
   LUA = "/home/froa/.config/nvim/lua/local_plugins/alloy/lua/.tests/data/nvim/lazy-rocks/hererocks/bin/lua";
}
