-- Misc, layers and permissions.

local theme = require("modules.theme")

hl.config({
    misc = {
        -- Plain theme-colored background instead of the default wallpaper/logo:
        -- nothing extra to render, and no wallpaper daemon needed.
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        background_color         = theme.rgb("base"),

        -- If hyprlock ever crashes, let a new hyprlock take over the lock
        -- (otherwise you'd be stuck on Hyprland's "lockdead" screen).
        allow_session_lock_restore = true,
    },

    layers = {
        allow_new_top_layers_over_existing_fullscreen = true, -- Set to false to make newly mapped top layers render below existing covering fullscreen window
    },
})

-- Permissions
-- See https://wiki.hypr.land/configuring/core/advanced-configuration/permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")
