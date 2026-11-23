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

-- Launcher: dim everything behind it so it reads as a focused pop-up
-- (a cheap stand-in for the reference's blurred backdrop).
-- Strength: decoration.dim_around, set from the theme in looks.lua.
hl.layer_rule({
    name  = "dim-behind-launcher",
    match = { namespace = "^rofi$" },

    dim_around = true,
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

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})
