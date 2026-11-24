-- Light: monotone greys on paper, inspired by "hyprink monotone".
-- Colors are hex without "#"; modules turn them into rgb()/rgba().

return {
    name = "light",

    colors = {
        base      = "d9d9d9", -- desktop background
        surface   = "cccccc", -- window / launcher background
        surface2  = "c2c2c2", -- bar pills, raised elements
        overlay   = "a8a8a8", -- inactive pills, inactive border
        border    = "7a7a7a", -- active window border
        muted     = "828282", -- placeholder, disabled text
        subtext   = "646464", -- secondary text
        text      = "3b3b3b", -- primary text
        accent    = "474747", -- selection, active workspace
        accent_fg = "c8c8c8", -- text on accent
        shadow    = "8f8f8f", -- drop shadow (if enabled)
        green     = "0b5c2c", -- the one quiet color accent
    },

    look = {
        gaps_in     = 3, -- between windows (the visible gap is 2x this)
        gaps_out    = 6, -- between windows and screen edges
        border_size = 2,
        rounding    = 6,

        -- Darken behind layers with dim_around (0 = off, 1 = black).
        -- Not used by the launcher anymore (it blurs instead); kept for others.
        dim_around = 0.15,

        -- Launcher backdrop blur: radius and passes (more = softer, more GPU).
        blur_size   = 2,
        blur_passes = 1,

        -- Off by default to keep it light on the GPU.
        -- The reference uses a soft offset shadow; set true to get that look.
        shadow = false,
    },
}
