-- See https://wiki.hypr.land/configuring/core/autostart/
-- Runs once when Hyprland starts (not on reload).

hl.on("hyprland.start", function ()
    hl.exec_cmd("waybar")
end)
