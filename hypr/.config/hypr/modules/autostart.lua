-- See https://wiki.hypr.land/configuring/core/autostart/
-- Runs once when Hyprland starts (not on reload).

hl.on("hyprland.start", function ()
    hl.exec_cmd("waybar")

    -- Idle: dim, lock, screens off (hypridle.conf). Guard against a second
    -- copy in case its systemd unit is ever started too.
    hl.exec_cmd("pgrep -x hypridle >/dev/null || hypridle")

    -- Record clipboard history for SUPER+SHIFT+V (needs wl-clipboard + cliphist).
    hl.exec_cmd("command -v cliphist >/dev/null && wl-paste --type text  --watch cliphist store")
    hl.exec_cmd("command -v cliphist >/dev/null && wl-paste --type image --watch cliphist store")
end)
