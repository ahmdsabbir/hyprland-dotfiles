-- Active theme: name from hypr-theme's state file, colors from
-- themes/<name>.colors (the palette shared with every other app), look from
-- themes/<name>.lua.
--
-- Usage: local theme = require("modules.theme")
--        theme.colors.text, theme.look.rounding, theme.color_scheme,
--        theme.rgb("text"), theme.rgba("shadow", 0.6)
--
-- Switch themes with `hypr-theme light|dark|toggle` (SUPER+SHIFT+T).

local DEFAULT = "light"

-- ~/.local/state/yonko/theme, written by hypr-theme.
local function saved_name()
    local home  = os.getenv("HOME") or ""
    local state = os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")
    local f = io.open(state .. "/yonko/theme", "r")
    if not f then return nil end
    local name = f:read("l")
    f:close()
    return name and name:match("^%s*([%w_-]+)")
end

-- key = value lines; "#" starts a comment.
local function read_colors(path)
    local colors = {}
    for line in io.lines(path) do
        local key, value = line:match("^%s*([%w_]+)%s*=%s*([^%s#]+)")
        if key then colors[key] = value end
    end
    return colors
end

local name = saved_name() or DEFAULT
local lua_path = package.searchpath("themes." .. name, package.path)
if not lua_path then
    name = DEFAULT
    lua_path = package.searchpath("themes." .. name, package.path)
end
local dir = lua_path:match("^(.*)/[^/]+$")

local module = "themes." .. name
package.loaded[module] = nil -- pick up edits on `hyprctl reload`
local theme = require(module)

theme.name         = name
theme.colors       = read_colors(dir .. "/" .. name .. ".colors")
theme.color_scheme = theme.colors.color_scheme

-- "rgb(3b3b3b)" for a palette key
function theme.rgb(key)
    return "rgb(" .. theme.colors[key] .. ")"
end

-- "rgba(3b3b3bcc)" for a palette key and 0..1 alpha
function theme.rgba(key, alpha)
    return string.format("rgba(%s%02x)", theme.colors[key], math.floor(alpha * 255 + 0.5))
end

return theme
