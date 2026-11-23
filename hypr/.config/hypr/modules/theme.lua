-- Selects the active theme from themes/<name>.lua.
-- Usage: local theme = require("modules.theme")
--        theme.colors.text, theme.look.rounding, theme.rgb("text"), theme.rgba("shadow", 0.6)

local NAME = "light" -- "light" | "dark" (later)

local module = "themes." .. NAME
package.loaded[module] = nil -- pick up edits on `hyprctl reload`
local theme = require(module)

-- "rgb(3b3b3b)" for a palette key
function theme.rgb(key)
    return "rgb(" .. theme.colors[key] .. ")"
end

-- "rgba(3b3b3bcc)" for a palette key and 0..1 alpha
function theme.rgba(key, alpha)
    return string.format("rgba(%s%02x)", theme.colors[key], math.floor(alpha * 255 + 0.5))
end

return theme
