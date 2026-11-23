-- Hyprland entry point.
-- Wiki: https://wiki.hypr.land/configuring/
--
-- Each concern lives in ./modules/<name>.lua and is loaded below.
-- require() resolves relative to this file's directory.

-- Drop cached modules so `hyprctl reload` picks up edits to them.
for name in pairs(package.loaded) do
    if name:match("^modules%.") or name:match("^themes%.") then
        package.loaded[name] = nil
    end
end

require("modules.monitors")
require("modules.env")
require("modules.autostart")
require("modules.looks")
require("modules.layouts")
require("modules.misc")
require("modules.input")
require("modules.keybinds")
require("modules.rules")

-- Machine-specific overrides: hosts/<hostname>.lua (keep last)
require("modules.host")
