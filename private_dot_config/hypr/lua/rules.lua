-- Window / layer rules (merged: defaults first, user overrides after; order matters)

-- from configs/WindowRules.conf
hl.window_rule({ match = { class = "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^(chrome-.+-Default)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^([Cc]hromium)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^([Mm]icrosoft-edge(-stable|-beta|-dev|-unstable))$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^(Brave-browser(-beta|-dev|-unstable)?)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^([Tt]horium-browser|[Cc]achy-browser)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^(zen)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^(swaync-control-center|swaync-notification-window|swaync-client|class)$" }, tag = "+notif" })
hl.window_rule({ match = { title = "^(KooL Quick Cheat Sheet)$" }, tag = "+KooL_Cheat" })
hl.window_rule({ match = { title = "^(KooL Hyprland Settings)$" }, tag = "+KooL_Settings" })
hl.window_rule({ match = { class = "^(nwg-displays|nwg-look)$" }, tag = "+KooL-Settings" })
hl.window_rule({ match = { class = "^(Alacritty|kitty|kitty-dropterm|com\\.mitchellh\\.ghostty|ghostty|foot|footclient)$" }, tag = "+terminal" })
hl.window_rule({ match = { class = "^([Tt]hunderbird|org.gnome.Evolution)$" }, tag = "+email" })
hl.window_rule({ match = { class = "^(eu.betterbird.Betterbird)$" }, tag = "+email" })
hl.window_rule({ match = { class = "^(org.gnome.Evolution)$" }, tag = "+email" })
hl.window_rule({ match = { class = "^(codium|codium-url-handler|VSCodium)$" }, tag = "+projects" })
hl.window_rule({ match = { class = "^(VSCode|code|code-url-handler)$" }, tag = "+projects" })
hl.window_rule({ match = { class = "^(jetbrains-.+)$" }, tag = "+projects" })
hl.window_rule({ match = { class = "^(dev.zed.Zed|antigravity)$" }, tag = "+projects" })
hl.window_rule({ match = { class = "^(com.obsproject.Studio)$" }, tag = "+screenshare" })
hl.window_rule({ match = { class = "^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^(teams-for-linux)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^(im.riot.Riot|Element)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^(gamescope)$" }, tag = "+games" })
hl.window_rule({ match = { class = "^(steam_app_\\d+)$" }, tag = "+games" })
hl.window_rule({ match = { class = "^([Ss]team)$" }, tag = "+gamestore" })
hl.window_rule({ match = { title = "^([Ll]utris)$" }, tag = "+gamestore" })
hl.window_rule({ match = { class = "^(com.heroicgameslauncher.hgl)$" }, tag = "+gamestore" })
hl.window_rule({ match = { class = "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$" }, tag = "+file-manager" })
hl.window_rule({ match = { class = "^(app.drey.Warp)$" }, tag = "+file-manager" })
hl.window_rule({ match = { class = "^([Ww]aytrogen)$" }, tag = "+wallpaper" })
hl.window_rule({ match = { class = "^([Aa]udacious)$" }, tag = "+multimedia" })
hl.window_rule({ match = { class = "^([Mm]pv|vlc)$" }, tag = "+multimedia_video" })
hl.window_rule({ match = { title = "^(ROG Control)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(wihotspot(-gui)?)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^([Bb]aobab|org.gnome.[Bb]aobab)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(gnome-disks|wihotspot(-gui)?)$" }, tag = "+settings" })
hl.window_rule({ match = { title = "(Kvantum Manager)" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(file-roller|org.gnome.FileRoller)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(nm-applet|nm-connection-editor|blueman-manager)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(qt5ct|qt6ct)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "(xdg-desktop-portal-gtk)" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^([Rr]ofi)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(btrfs-assistant)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(timeshift-gtk)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(gnome-system-monitor|org.gnome.SystemMonitor|io.missioncenter.MissionCenter)$" }, tag = "+viewer" })
hl.window_rule({ match = { class = "^(evince)$" }, tag = "+viewer" })
hl.window_rule({ match = { class = "^(eog|org.gnome.Loupe)$" }, tag = "+viewer" })
hl.window_rule({ match = { tag = "multimedia_video" }, no_blur = true })
hl.window_rule({ match = { tag = "multimedia_video" }, opacity = "1.0" })
hl.window_rule({ match = { tag = "KooL_Cheat" }, center = true })
hl.window_rule({ match = { class = "([Tt]hunar)", title = "negative:(.*[Tt]hunar.*)" }, center = true })
hl.window_rule({ match = { title = "^(ROG Control)$" }, center = true })
hl.window_rule({ match = { tag = "KooL-Settings" }, center = true })
hl.window_rule({ match = { title = "^(Keybindings)$" }, center = true })
hl.window_rule({ match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" }, center = true })
hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" }, center = true })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, center = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, move = { "(monitor_w*0.72)", "(monitor_h*0.07)" } })
hl.window_rule({ match = { fullscreen = true }, idle_inhibit = "fullscreen" })
hl.window_rule({ match = { tag = "KooL_Cheat" }, float = true })
hl.window_rule({ match = { tag = "wallpaper" }, float = true })
hl.window_rule({ match = { tag = "settings" }, float = true })
hl.window_rule({ match = { tag = "viewer" }, float = true })
hl.window_rule({ match = { tag = "KooL-Settings" }, float = true })
hl.window_rule({ match = { class = "([Zz]oom|onedriver|onedriver-launcher)" }, float = true })
hl.window_rule({ match = { class = "(org.gnome.Calculator)", title = "(Calculator)" }, float = true })
hl.window_rule({ match = { class = "^(mpv|com.github.rafostar.Clapper)$" }, float = true })
hl.window_rule({ match = { class = "^([Qq]alculate-gtk)$" }, float = true })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, float = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, float = true })
hl.window_rule({ match = { title = "^(Authentication Required)$" }, float = true, center = true })
hl.window_rule({ match = { class = "(codium|codium-url-handler|VSCodium)", title = "negative:(.*codium.*|.*VSCodium.*)" }, float = true })
hl.window_rule({ match = { class = "^(com.heroicgameslauncher.hgl)$", title = "negative:(Heroic Games Launcher)" }, float = true })
hl.window_rule({ match = { class = "^([Ss]team)$", title = "negative:^([Ss]team)$" }, float = true })
hl.window_rule({ match = { class = "([Tt]hunar)", title = "negative:(.*[Tt]hunar.*)" }, float = true })
hl.window_rule({
    match = { title = "^(Add Folder to Workspace)$" },
    float = true,
    size = { "(monitor_w*0.7)", "(monitor_h*0.6)" },
    center = true,
})
hl.window_rule({
    match = { title = "^(Save As)$" },
    float = true,
    size = { "(monitor_w*0.7)", "(monitor_h*0.6)" },
    center = true,
})
hl.window_rule({ match = { initial_title = "(Open Files)" }, float = true, size = { "(monitor_w*0.7)", "(monitor_h*0.6)" } })
hl.window_rule({
    match = { title = "^(SDDM Background)$" },
    float = true,
    center = true,
    size = { "(monitor_w*0.16)", "(monitor_h*0.12)" },
})
hl.window_rule({
    match = { class = "^(yad)$", title = "^(YAD)$" },
    float = true,
    center = true,
    size = { "(monitor_w*0.2)", "(monitor_h*0.2)" },
})
hl.window_rule({ match = { tag = "browser" }, opacity = "0.99 0.8" })
hl.window_rule({ match = { tag = "projects" }, opacity = "0.9 0.8" })
hl.window_rule({ match = { tag = "im" }, opacity = "0.94 0.86" })
hl.window_rule({ match = { tag = "multimedia" }, opacity = "0.94 0.86" })
hl.window_rule({ match = { tag = "file-manager" }, opacity = "0.9 0.8" })
hl.window_rule({ match = { tag = "terminal" }, opacity = "0.9 0.7" })
hl.window_rule({ match = { tag = "settings" }, opacity = "0.8 0.7" })
hl.window_rule({ match = { tag = "viewer" }, opacity = "0.82 0.75" })
hl.window_rule({ match = { tag = "wallpaper" }, opacity = "0.9 0.7" })
hl.window_rule({ match = { class = "^(gedit|org.gnome.TextEditor|mousepad)$" }, opacity = "0.8 0.7" })
hl.window_rule({ match = { class = "^(deluge)$" }, opacity = "0.9 0.8" })
hl.window_rule({ match = { class = "^(seahorse)$" }, opacity = "0.9 0.8" })
hl.window_rule({ match = { tag = "KooL_Cheat" }, size = { "(monitor_w*0.65)", "(monitor_h*0.9)" } })
hl.window_rule({ match = { tag = "wallpaper" }, size = { "(monitor_w*0.7)", "(monitor_h*0.7)" } })
hl.window_rule({ match = { tag = "settings" }, size = { "(monitor_w*0.7)", "(monitor_h*0.7)" } })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, size = { "(monitor_w*0.6)", "(monitor_h*0.7)" } })
hl.window_rule({ match = { class = "(org.gnome.Calculator|qalculate-gtk)" }, center = true, size = { "(monitor_w*0.25)", "(monitor_h*0.3)" } })
hl.window_rule({ match = { tag = "games" }, no_blur = true })
hl.window_rule({ match = { class = "^(jetbrains-*)" }, no_initial_focus = true })
hl.window_rule({ match = { title = "^(wind.*)$" }, no_initial_focus = true })
hl.layer_rule({ match = { namespace = "rofi" }, blur = true })
hl.layer_rule({ match = { namespace = "notifications" }, blur = true })
hl.window_rule({
    name = "Whatsapp-zapzap",
    match = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" },
    size = { "(monitor_w*0.6)", "(monitor_h*0.7)" },
    center = true,
})
hl.window_rule({
    name = "Picture-in-Picture",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    move = { "(monitor_w*0.72)", "(monitor_h*0.07)" },
    opacity = "0.95 0.75",
    pin = true,
    keep_aspect_ratio = true,
    size = { "(monitor_w*0.3)", "(monitor_h*0.3)" },
})
hl.window_rule({
    name = "Thunar-Progress-bar",
    match = { class = "^(thunar)$", title = "^(File Operation Progress)$" },
    float = true,
    center = true,
    size = { "(monitor_w*0.26)", "(monitor_h*0.18)" },
})

-- from UserConfigs/WindowRules.conf
hl.window_rule({ match = { class = "^(com\\.mitchellh\\.ghostty|ghostty|kitty|Alacritty|foot)$" }, opacity = "1.0 0.65" })
hl.window_rule({ match = { class = "^(com\\.mitchellh\\.ghostty|ghostty)$" }, workspace = "1" })
hl.window_rule({ match = { class = "^([Mm]icrosoft-edge(-stable|-beta|-dev|-unstable)?)$" }, workspace = "2" })
hl.window_rule({ match = { class = "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$" }, workspace = "3" })
hl.window_rule({ match = { class = "^(Slack)$" }, workspace = "4 silent" })
hl.window_rule({ match = { class = "^(1Password)$" }, workspace = "5 silent" })
hl.window_rule({ match = { class = "^(ZSTray6?)$" }, workspace = "99 silent" })
hl.window_rule({ match = { class = "^([Tt]hunar|[Pp]cmanfm-qt)$" }, workspace = "5" })
hl.window_rule({ match = { class = "^(org.gnome.Nautilus)$" }, float = true })
hl.window_rule({ match = { class = "^(scratchpad)$" }, tag = "+scratchpad_term" })
hl.window_rule({ match = { class = "^(btop-scratchpad)$" }, tag = "+scratchpad_btop" })
hl.window_rule({ match = { class = "^(files-scratchpad)$" }, tag = "+scratchpad_files" })
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" }, tag = "+scratchpad_volume" })
hl.window_rule({ match = { class = "^(org.gnome.Calculator)$" }, tag = "+scratchpad_calc" })
hl.window_rule({ match = { class = "^(spotify)$" }, tag = "+scratchpad_music" })
hl.window_rule({ match = { class = "^(org.keepassxc.KeePassXC)$" }, tag = "+scratchpad_keepass" })
hl.window_rule({
    name = "scratchpad-term",
    match = { class = "^(scratchpad)$" },
    float = true,
    opacity = "1.0 1.0",
})
hl.window_rule({
    name = "scratchpad-btop",
    match = { class = "^(btop-scratchpad)$" },
    float = true,
    opacity = "0.90 0.85",
})
hl.window_rule({
    name = "scratchpad-files",
    match = { class = "^(files-scratchpad)$" },
    float = true,
    opacity = "0.95 0.90",
})
hl.window_rule({
    name = "scratchpad-volume",
    match = { class = "^(org.pulseaudio.pavucontrol)$" },
    float = true,
    center = true,
    opacity = "0.92 0.88",
})
hl.window_rule({
    name = "scratchpad-music",
    match = { class = "^(spotify)$" },
    float = true,
    opacity = "1.0 0.95",
    no_blur = true,
})
hl.window_rule({
    name = "scratchpad-calc",
    match = { class = "^(org.gnome.Calculator)$" },
    float = true,
    center = true,
    opacity = "0.92 0.88",
    size = { "(monitor_w*0.25)", "(monitor_h*0.35)" },
})
hl.window_rule({
    name = "scratchpad-keepass",
    match = { class = "^(org.keepassxc.KeePassXC)$" },
    float = true,
    opacity = "0.95 0.90",
})
hl.window_rule({
    name = "opencode-chezmoi",
    match = { class = "^(opencode-chezmoi)$" },
    float = true,
    opacity = "0.95 0.90",
    size = { "(monitor_w*0.80)", "(monitor_h*0.80)" },
})
hl.window_rule({
    name = "opencode-hypr",
    match = { class = "^(opencode-hypr)$" },
    float = true,
    opacity = "0.95 0.90",
    size = { "(monitor_w*0.80)", "(monitor_h*0.80)" },
})
hl.window_rule({
    name = "opencode-nvim",
    match = { class = "^(opencode-nvim)$" },
    float = true,
    opacity = "0.95 0.90",
    size = { "(monitor_w*0.80)", "(monitor_h*0.80)" },
})
hl.window_rule({
    name = "opencode-cwd",
    match = { class = "^(opencode-cwd)$" },
    float = true,
    opacity = "0.95 0.90",
    size = { "(monitor_w*0.80)", "(monitor_h*0.80)" },
})
hl.window_rule({
    name = "aoe-cwd",
    match = { class = "^(aoe-cwd)$" },
    float = true,
    opacity = "0.95 0.90",
    size = { "(monitor_w*0.80)", "(monitor_h*0.80)" },
    workspace = "99 silent",
})
hl.window_rule({
    name = "random-scratch",
    match = { class = "^(random-scratch)$" },
    float = true,
    opacity = "0.95 0.90",
    size = { "(monitor_w*0.80)", "(monitor_h*0.80)" },
    workspace = "99 silent",
})
hl.window_rule({
    name = "jira-scratch",
    match = { class = "^(jira-scratch)$" },
    float = true,
    opacity = "0.95 0.90",
    size = { "(monitor_w*0.80)", "(monitor_h*0.80)" },
    workspace = "99 silent",
})
hl.window_rule({
    name = "opencode-readitlater",
    match = { class = "^(opencode-readitlater)$" },
    float = true,
    opacity = "0.95 0.90",
    size = { "(monitor_w*0.80)", "(monitor_h*0.80)" },
})
hl.window_rule({
    name = "koreader",
    match = { class = "^(KOReader)$" },
    float = true,
    size = { "(monitor_w*0.45)", "(monitor_h*0.90)" },
    center = true,
})
hl.window_rule({ match = { class = "^(opencode-koreader)$" }, float = false })
hl.window_rule({ match = { class = "^(KOReader)$", workspace = "special:koreader_dev" }, float = false })
hl.window_rule({
    name = "foot-dropterm",
    match = { class = "^(foot-dropterm)$" },
    float = true,
    opacity = "1.0 1.0",
})
hl.window_rule({
    name = "foot-btop",
    match = { class = "^(foot-btop)$" },
    float = true,
    opacity = "0.90 0.85",
})
hl.window_rule({
    name = "spotify-scratchpad",
    match = { class = "^([Ss]potify)$" },
    float = true,
    opacity = "1.0 0.95",
    no_blur = true,
})
hl.window_rule({
    name = "obsidian-scratchpad",
    match = { class = "^(obsidian)$" },
    float = true,
    opacity = "0.95 0.90",
})
hl.window_rule({
    name = "k9s-sandbox",
    match = { class = "^(k9s-sandbox)$" },
    float = true,
    opacity = "0.95 0.90",
})
hl.window_rule({
    name = "k9s-platform-eu01",
    match = { class = "^(k9s-platform-eu01)$" },
    float = true,
    opacity = "0.95 0.90",
})
hl.window_rule({
    name = "k9s-platform-us01",
    match = { class = "^(k9s-platform-us01)$" },
    float = true,
    opacity = "0.95 0.90",
})
hl.window_rule({
    name = "k9s-platform-ca01",
    match = { class = "^(k9s-platform-ca01)$" },
    float = true,
    opacity = "0.95 0.90",
})
hl.window_rule({
    name = "k9s-technosylva-eu01",
    match = { class = "^(k9s-technosylva-eu01)$" },
    float = true,
    opacity = "0.95 0.90",
})
hl.window_rule({
    name = "k9s-technosylva-us01",
    match = { class = "^(k9s-technosylva-us01)$" },
    float = true,
    opacity = "0.95 0.90",
})
hl.window_rule({
    name = "k9s-technosylva-ca01",
    match = { class = "^(k9s-technosylva-ca01)$" },
    float = true,
    opacity = "0.95 0.90",
})
hl.window_rule({
    name = "op-signin",
    match = { class = "^(op-signin)$" },
    float = true,
    center = true,
    opacity = "1.0 1.0",
    size = { "(monitor_w*0.40)", "(monitor_h*0.22)" },
})
hl.window_rule({
    name = "digest-scratch",
    match = { class = "^(digest-scratch)$" },
    float = true,
    center = true,
    size = { "(monitor_w*0.85)", "(monitor_h*0.85)" },
})
hl.layer_rule({ match = { namespace = "selection" }, no_anim = true })
hl.layer_rule({ match = { namespace = "rofi" }, no_anim = true })
