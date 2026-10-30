-- Shared variables (was UserConfigs/01-UserDefaults.conf + the $vars scattered over configs/*.conf)
local home = os.getenv("HOME")

return {
    mainMod     = "SUPER",
    scriptsDir  = home .. "/.config/hypr/scripts",
    userScripts = home .. "/.config/hypr/UserScripts",
    term        = home .. "/.config/hypr/scripts/term.sh", -- logging launcher around ~/.local/bin/ghostty (see term.sh)
    files       = "thunar",
    editor      = "nvim",
    searchEngine = "https://www.google.com/search?q={}",
    touchpadDevice = "asue1209:00-04f3:319f-touchpad", -- read by scripts/TouchPad.sh
}
