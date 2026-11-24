-- Window and layer rules.
-- See https://wiki.hypr.land/configuring/core/rules/

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Blur is only for short-lived pop-ups, never windows: a window that is
-- partly transparent (menus, some apps) would cost GPU on every redraw.
hl.window_rule({
    name  = "no-blur-windows",
    match = { class = ".*" },

    no_blur = true,
})

-- Launcher: frosted backdrop. Rofi draws a full-screen, slightly tinted
-- transparent window (rofi/layout.rasi); Hyprland blurs what's behind it.
-- Costs GPU only while rofi is open, and the screen behind it is static.
hl.layer_rule({
    name  = "blur-behind-launcher",
    match = { namespace = "^rofi$" },

    blur         = true,
    ignore_alpha = 0, -- blur behind every pixel, including the faint tint
})

-- Pop-up tools opened from Waybar (right-click volume / network): float, centered.
hl.window_rule({
    name  = "float-mixer",
    match = { class = "^hypr-mixer$" },

    float  = true,
    size   = "900 520",
    center = true,
})

hl.window_rule({
    name  = "float-nmtui",
    match = { class = "^hypr-nmtui$" },

    float  = true,
    size   = "820 600",
    center = true,
})

hl.window_rule({
    name  = "float-htop",
    match = { class = "^hypr-top$" },

    float  = true,
    size   = "1000 640",
    center = true,
})

-- Drop-down terminal (SUPER+SHIFT+Enter, hypr-dropdown): floating, top-center below the
-- bar, on the hidden special workspace "dropdown" until toggled in.
hl.window_rule({
    name  = "dropdown-terminal",
    match = { class = "^hypr-dropdown$" },

    float     = true,
    size      = "monitor_w*0.8 monitor_h*0.5",
    move      = "monitor_w*0.1 44",
    workspace = "special:dropdown silent",
})

-- Screenshot annotation editor
hl.window_rule({
    name  = "float-swappy",
    match = { class = "^swappy$" },

    float  = true,
    center = true,
})

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})
