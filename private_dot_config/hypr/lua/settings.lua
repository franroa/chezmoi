-- Core settings (merged configs/SystemSettings.conf + UserConfigs/UserSettings.conf; user overrides applied)
local v = require("lua.vars")

hl.config({
    general = {
        resize_on_border = true,
        layout = "dwindle",
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
        new_on_top = true,
        mfact = 0.5,
    },

    input = {
        kb_layout = "es,us",
        kb_variant = ",",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        repeat_rate = 50,
        repeat_delay = 300,
        sensitivity = 0, -- mouse sensitivity
        numlock_by_default = true,
        left_handed = false,
        follow_mouse = 1,
        float_switch_override_focus = false,
        touchpad = {
            disable_while_typing = true,
            natural_scroll = true,
            clickfinger_behavior = false,
            middle_button_emulation = false,
            tap_to_click = true,
            drag_lock = false,
        },
        touchdevice = {
            enabled = true,
        },
        tablet = {
            transform = 0,
            left_handed = false,
        },
    },

    gestures = {
        workspace_swipe_distance = 500,
        workspace_swipe_invert = true,
        workspace_swipe_min_speed_to_force = 30,
        workspace_swipe_cancel_ratio = 0.5,
        workspace_swipe_create_new = true,
        workspace_swipe_forever = true,
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        vrr = 1, -- variable refresh rate (user override of the default 0)
        mouse_move_enables_dpms = true,
        enable_swallow = false,
        swallow_regex = "^(kitty)$",
        focus_on_activate = true,
        initial_workspace_tracking = 1,
        middle_click_paste = false,
        enable_anr_dialog = true,
        anr_missed_pings = 15,            -- ANR threshold, default 1 is too low
        allow_session_lock_restore = true, -- prevent lockscreen crash when resuming from suspend
    },

    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles = true,
        pass_mouse_when_bound = false,
    },

    xwayland = {
        enabled = true,
        force_zero_scaling = true,
    },

    render = {
        direct_scanout = false,
    },

    quirks = {
        -- Hyprland 0.57 turned this on by default. With NVIDIA as primary GPU and the Intel-driven
        -- eDP-1 as KMS device it filters every explicit modifier out of the dmabuf format table and
        -- advertises only DRM_FORMAT_MOD_INVALID, which NVIDIA's egl-wayland can't allocate: native
        -- NVIDIA Wayland clients (ghostty, kitty, ...) then hang before mapping a window.
        skip_non_kms_dmabuf_formats = false,
    },

    cursor = {
        sync_gsettings_theme = true,
        no_hardware_cursors = true, -- NVIDIA
        enable_hyprcursor = true,
        warp_on_change_workspace = 2,
        no_warps = true,
    },
})

-- Special workspaces (scratchpads): windows at 80% scale.
-- Replaces the deprecated dwindle.special_scale_factor (Hyprland 0.57: "use workspace rules").
-- Kept here, not in workspaces.lua, because nwg-displays rewrites that file.
hl.workspace_rule({ workspace = "s[true]", layout_opts = { special_scale_factor = 0.8 } })
