-- See https://wiki.hypr.land/configuring/core/binds/

local programs = require("modules.programs")
local mainMod  = programs.mainMod

-- Apps and window actions
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(programs.terminal))   -- terminal
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd("$HOME/.local/bin/hypr-dropdown")) -- drop-down terminal
local closeWindowBind = hl.bind(mainMod .. " + C", hl.dsp.window.close())
-- closeWindowBind:set_enabled(false)
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(programs.fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd(programs.menu))   -- app launcher
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))    -- dwindle only

-- Reload every config (Hyprland, Waybar, kitty, hypridle)
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("$HOME/.local/bin/hypr-reload"))

-- Theme: light <-> dark (hypr-theme)
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("$HOME/.local/bin/hypr-theme toggle"))

-- Menus (rofi). SUPER+SPACE above opens the app launcher.
hl.bind(mainMod .. " + period",     hl.dsp.exec_cmd("rofimoji --action copy --skin-tone neutral")) -- emoji / symbols
hl.bind(mainMod .. " + equal",      hl.dsp.exec_cmd("$HOME/.local/bin/hypr-calc"))          -- calculator
hl.bind(mainMod .. " + Tab",        hl.dsp.exec_cmd("$HOME/.local/bin/hypr-windows"))       -- window switcher
hl.bind(mainMod .. " + SHIFT + V",  hl.dsp.exec_cmd("$HOME/.local/bin/hypr-clipboard"))     -- clipboard history
-- Screenshots (hypr-screenshot): saved to ~/Pictures/Screenshots + clipboard
hl.bind(mainMod .. " + SHIFT + S",  hl.dsp.exec_cmd("$HOME/.local/bin/hypr-screenshot area"))    -- drag an area
hl.bind("Print",                    hl.dsp.exec_cmd("$HOME/.local/bin/hypr-screenshot area"))    -- (same)
hl.bind("SHIFT + Print",            hl.dsp.exec_cmd("$HOME/.local/bin/hypr-screenshot screen"))  -- this monitor
hl.bind("CTRL + Print",             hl.dsp.exec_cmd("$HOME/.local/bin/hypr-screenshot window"))  -- active window
hl.bind(mainMod .. " + Print",      hl.dsp.exec_cmd("$HOME/.local/bin/hypr-screenshot menu"))    -- menu + delays

-- Color picker: click any pixel, hex code is copied
hl.bind(mainMod .. " + SHIFT + C",  hl.dsp.exec_cmd("c=$(hyprpicker -a -f hex) && notify-send -a 'Color picker' \"$c\" 'Copied to clipboard'"))

-- Notifications (mako)
hl.bind(mainMod .. " + N",          hl.dsp.exec_cmd("$HOME/.local/bin/hypr-notify dismiss"))     -- dismiss newest
hl.bind(mainMod .. " + SHIFT + N",  hl.dsp.exec_cmd("$HOME/.local/bin/hypr-notify dismiss-all")) -- dismiss all
hl.bind(mainMod .. " + CTRL + N",   hl.dsp.exec_cmd("$HOME/.local/bin/hypr-notify restore"))     -- show last again
hl.bind(mainMod .. " + ALT + N",    hl.dsp.exec_cmd("$HOME/.local/bin/hypr-notify dnd"))         -- do not disturb

hl.bind(mainMod .. " + L",          hl.dsp.exec_cmd("$HOME/.local/bin/hypr-power lock"))    -- lock screen
hl.bind(mainMod .. " + Escape",     hl.dsp.exec_cmd("$HOME/.local/bin/hypr-power menu"))    -- power menu

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + ALT + S",   hl.dsp.window.move({ workspace = "special:magic" }))   -- SHIFT+S is the area screenshot

-- Previous / next workspace on the current monitor (wraps around)
hl.bind("CTRL + ALT + left",  hl.dsp.focus({ workspace = "m-1" }))
hl.bind("CTRL + ALT + right", hl.dsp.focus({ workspace = "m+1" }))
-- ...and carry the focused window along
hl.bind("CTRL + ALT + SHIFT + left",  hl.dsp.window.move({ workspace = "m-1" }))
hl.bind("CTRL + ALT + SHIFT + right", hl.dsp.window.move({ workspace = "m+1" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
