-- General, decoration and animations, driven by the active theme.
-- Tuned to be light on the machine: no blur, opaque windows, short animations.
-- Refer to https://wiki.hypr.land/configuring/core/config-options/

local theme = require("modules.theme")
local look  = theme.look

hl.config({
    general = {
        gaps_in     = look.gaps_in,
        gaps_out    = look.gaps_out,
        border_size = look.border_size,

        col = {
            active_border   = theme.rgb("border"),
            inactive_border = theme.rgb("overlay"),
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/configuring/extra/tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = look.rounding,
        rounding_power = 2,

        -- Opaque windows: transparency forces redrawing what's behind them.
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = look.shadow,
            range        = 24,
            render_power = 3,
            offset       = "2 6",
            color        = theme.rgba("shadow", 0.6),
        },

        -- Blur: enabled for the launcher's backdrop only (layer rule in
        -- rules.lua); every window opts out (no-blur-windows rule), so it costs
        -- nothing until rofi opens. Light settings for an integrated GPU.
        blur = {
            enabled           = true,
            size              = look.blur_size,
            passes            = look.blur_passes,
            new_optimizations = true,
            xray              = false,
            popups            = false,
        },

        -- How much to darken behind layers with dim_around (the launcher).
        dim_around = look.dim_around,

        -- Mute unfocused windows with a light dark overlay so the focused one
        -- stands out beyond its border. A flat overlay, so it costs ~nothing.
        dim_inactive = look.dim_inactive > 0,
        dim_strength = look.dim_inactive,
    },

    animations = {
        enabled = true,
    },
})

-- Short, simple animations (speed is in 100 ms units: 2.5 = 250 ms).
hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("linear",       { type = "bezier", points = { {0, 0},    {1, 1}    } })
hl.curve("quick",        { type = "bezier", points = { {0.15, 0}, {0.1, 1}  } })

hl.animation({ leaf = "global",     enabled = true, speed = 3,   bezier = "quick" })
hl.animation({ leaf = "windows",    enabled = true, speed = 2.5, bezier = "easeOutQuint", style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.5, bezier = "linear",       style = "popin 90%" })
hl.animation({ leaf = "fade",       enabled = true, speed = 2,   bezier = "quick" })
hl.animation({ leaf = "border",     enabled = true, speed = 3,   bezier = "linear" })
hl.animation({ leaf = "layers",     enabled = true, speed = 2,   bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2,   bezier = "easeOutQuint", style = "fade" })
-- Special workspaces (scratchpad, drop-down terminal) slide in from the top.
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2.5, bezier = "easeOutQuint", style = "slidevert" })
