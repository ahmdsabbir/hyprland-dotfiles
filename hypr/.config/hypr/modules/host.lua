-- Loads hosts/<hostname>.lua if it exists.
-- Loaded last, so a host file can override any setting (monitors, input, looks...).
-- Machines without a host file just use the generic modules.

local function hostname()
    local f = io.open("/etc/hostname", "r")
    if not f then return nil end
    local name = f:read("l")
    f:close()
    -- Strip whitespace and any domain part ("box.local" -> "box")
    return name and name:match("^%s*([^.%s]+)")
end

local name = hostname()
if not name then return end

local module = "hosts." .. name
package.loaded[module] = nil -- pick up edits on `hyprctl reload`

-- Only require when the file exists, so real errors inside a host file still surface.
if package.searchpath(module, package.path) then
    require(module)
end
