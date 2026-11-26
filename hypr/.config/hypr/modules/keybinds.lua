-- Key and mouse bindings. See https://wiki.hypr.land/configuring/core/binds/
--
-- Every bind carries a description, "Category: what it does", which the
-- cheat sheet (SUPER+/, hypr-keys) reads from the running Hyprland, so it is
-- always in sync. For a family of keys (arrows, 1..0), only the first gets a
-- description, with "|label" naming the whole family: "Windows: Focus|arrows".

local programs = require("modules.programs")
local mainMod  = programs.mainMod
local bin      = "$HOME/.local/bin/"

-- bind(keys, action, description, options)
local function bind(keys, action, desc, opts)
    -- Copy, so shared option tables (e.g. `held` below) never collect labels.
    local o = {}
    for k, v in pairs(opts or {}) do o[k] = v end
    if desc then o.description = desc end
    if next(o) then
        return hl.bind(keys, action, o)
    end
    return hl.bind(keys, action)
end

local function run(cmd) return hl.dsp.exec_cmd(cmd) end

-- --- Apps -----------------------------------------------------------------------

bind(mainMod .. " + Return",         run(programs.terminal),            "Apps: Terminal")
bind(mainMod .. " + SHIFT + Return", run(bin .. "hypr-dropdown"),       "Apps: Drop-down terminal (toggle)")
bind(mainMod .. " + E",              run(programs.fileManager),         "Apps: File manager")
bind(mainMod .. " + space",          run(programs.menu),                "Apps: App launcher")
bind(mainMod .. " + period",         run("rofimoji --action copy --skin-tone neutral"), "Apps: Emoji / symbols (copies)")
bind(mainMod .. " + equal",          run(bin .. "hypr-calc"),           "Apps: Calculator")
bind(mainMod .. " + SHIFT + V",      run(bin .. "hypr-clipboard"),      "Apps: Clipboard history")
bind(mainMod .. " + SHIFT + C",      run("c=$(hyprpicker -a -f hex) && notify-send -a 'Color picker' \"$c\" 'Copied to clipboard'"),
                                                                        "Apps: Color picker (copies the hex code)")
bind(mainMod .. " + slash",          run(bin .. "hypr-keys"),           "Apps: Keybinding cheat sheet")

-- --- Windows --------------------------------------------------------------------

local closeWindowBind = bind(mainMod .. " + C", hl.dsp.window.close(), "Windows: Close window")
-- closeWindowBind:set_enabled(false)
bind(mainMod .. " + V",   hl.dsp.window.float({ action = "toggle" }), "Windows: Toggle floating")
bind(mainMod .. " + P",   hl.dsp.window.pseudo(),                     "Windows: Pseudo-tile")
bind(mainMod .. " + J",   hl.dsp.layout("togglesplit"),               "Windows: Toggle split direction") -- dwindle only
bind(mainMod .. " + Tab", run(bin .. "hypr-windows"),                 "Windows: Window switcher (all workspaces)")

-- Move focus / swap with the neighbour (also across monitors)
bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }),  "Windows: Move focus|arrows")
bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

bind(mainMod .. " + SHIFT + left",  hl.dsp.window.swap({ direction = "l" }), "Windows: Swap with neighbour|arrows")
bind(mainMod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "r" }))
bind(mainMod .. " + SHIFT + up",    hl.dsp.window.swap({ direction = "u" }))
bind(mainMod .. " + SHIFT + down",  hl.dsp.window.swap({ direction = "d" }))

-- Move / resize with the mouse
bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   "Windows: Move (drop on a window to swap)", { mouse = true })
bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), "Windows: Resize",                          { mouse = true })

-- --- Workspaces -------------------------------------------------------------------

for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }),
         i == 1 and "Workspaces: Go to workspace|1…0" or nil)
    bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }),
         i == 1 and "Workspaces: Move window to workspace|1…0" or nil)
end

-- Previous / next workspace on the current monitor (wraps); SHIFT carries the window
bind("CTRL + ALT + left",          hl.dsp.focus({ workspace = "m-1" }),       "Workspaces: Previous / next on this monitor|← / →")
bind("CTRL + ALT + right",         hl.dsp.focus({ workspace = "m+1" }))
bind("CTRL + ALT + SHIFT + left",  hl.dsp.window.move({ workspace = "m-1" }), "Workspaces: Carry window to previous / next|← / →")
bind("CTRL + ALT + SHIFT + right", hl.dsp.window.move({ workspace = "m+1" }))

bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), "Workspaces: Next / previous|scroll")
bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Scratchpad (special workspace). SUPER+SHIFT+S is the area screenshot.
bind(mainMod .. " + S",       hl.dsp.workspace.toggle_special("magic"),            "Workspaces: Show / hide scratchpad")
bind(mainMod .. " + ALT + S", hl.dsp.window.move({ workspace = "special:magic" }), "Workspaces: Move window to scratchpad")

-- --- Screenshots (hypr-screenshot: ~/Pictures/Screenshots + clipboard) -------------

bind(mainMod .. " + SHIFT + S", run(bin .. "hypr-screenshot area"),   "Screenshots: Area (drag to select)")
bind("Print",                   run(bin .. "hypr-screenshot area"),   "Screenshots: Area (drag to select)")
bind("SHIFT + Print",           run(bin .. "hypr-screenshot screen"), "Screenshots: This monitor")
bind("CTRL + Print",            run(bin .. "hypr-screenshot window"), "Screenshots: Active window")
bind(mainMod .. " + Print",     run(bin .. "hypr-screenshot menu"),   "Screenshots: Menu (with delays)")
bind(mainMod .. " + SHIFT + X", run(bin .. "hypr-screenshot text"),   "Screenshots: Copy the text in an area (OCR)")

-- --- Notifications (mako) ---------------------------------------------------------

bind(mainMod .. " + N",         run(bin .. "hypr-notify dismiss"),     "Notifications: Dismiss newest")
bind(mainMod .. " + SHIFT + N", run(bin .. "hypr-notify dismiss-all"), "Notifications: Dismiss all")
bind(mainMod .. " + CTRL + N",  run(bin .. "hypr-notify restore"),     "Notifications: Bring back the last one")
bind(mainMod .. " + ALT + N",   run(bin .. "hypr-notify dnd"),         "Notifications: Do not disturb")

-- --- System -----------------------------------------------------------------------

bind(mainMod .. " + L",         run(bin .. "hypr-power lock"),    "System: Lock screen")
bind(mainMod .. " + Escape",    run(bin .. "hypr-power menu"),    "System: Power menu")
bind(mainMod .. " + M",         run("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"),
                                                                  "System: Exit Hyprland")
bind(mainMod .. " + SHIFT + T", run(bin .. "hypr-theme toggle"),  "System: Switch light / dark theme")
bind(mainMod .. " + SHIFT + R", run(bin .. "hypr-reload"),        "System: Reload all configs")

-- --- Media keys (work on the lock screen too) -------------------------------------

local held = { locked = true, repeating = true }
bind("XF86AudioRaiseVolume",  run("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), "Media: Volume up / down|volume keys", held)
bind("XF86AudioLowerVolume",  run("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      nil, held)
bind("XF86AudioMute",         run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     "Media: Mute", held)
bind("XF86AudioMicMute",      run("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   "Media: Mute microphone", held)
bind("XF86MonBrightnessUp",   run("brightnessctl -e4 -n2 set 5%+"),                  "Media: Brightness up / down|brightness keys", held)
bind("XF86MonBrightnessDown", run("brightnessctl -e4 -n2 set 5%-"),                  nil, held)

-- Requires playerctl
local locked = { locked = true }
bind("XF86AudioPlay",  run("playerctl play-pause"), "Media: Play / pause", locked)
bind("XF86AudioPause", run("playerctl play-pause"), nil, locked)
bind("XF86AudioNext",  run("playerctl next"),       "Media: Next / previous track|next / previous keys", locked)
bind("XF86AudioPrev",  run("playerctl previous"),   nil, locked)
