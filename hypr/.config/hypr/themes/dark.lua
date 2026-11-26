-- Dark theme: shapes and effects. Colors live in dark.colors.

return {
    look = {
        gaps_in     = 3, -- between windows (the visible gap is 2x this)
        gaps_out    = 6, -- between windows and screen edges
        border_size = 2,
        rounding    = 6,

        -- Darken behind layers with dim_around (0 = off, 1 = black).
        dim_around = 0.3,

        -- Darken unfocused windows (0 = off, 1 = black).
        dim_inactive = 0.2,

        -- Launcher backdrop blur: radius and passes (more = softer, more GPU).
        blur_size   = 2,
        blur_passes = 1,

        -- Drop shadows: off to keep it light on the GPU.
        shadow = false,
    },
}
