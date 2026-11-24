-- Workspaces per monitor, assigned automatically.
--
-- Each connected monitor gets PER_MONITOR workspaces, numbered left to right:
--   1 monitor:  1-3
--   2 monitors: left 1-3, right 4-6
--   3 monitors: 1-3, 4-6, 7-9   ... and so on.
-- They always exist (persistent), so each Waybar shows its monitor's three.
-- Plugging a monitor in or out reloads the config, which re-runs this.
-- SUPER+number still reaches any workspace 1-10; ones beyond the assigned
-- range open on the focused monitor and disappear when empty.

local PER_MONITOR = 3

-- Enabled, non-mirrored monitors sorted left to right (then top to bottom).
local function monitors_left_to_right()
    local ok, all = pcall(hl.get_monitors)
    if not ok or type(all) ~= "table" then return {} end
    local list = {}
    for _, m in ipairs(all) do
        if m.enabled ~= false and not m.is_mirror then
            list[#list + 1] = m
        end
    end
    table.sort(list, function(a, b)
        if a.x ~= b.x then return a.x < b.x end
        return a.y < b.y
    end)
    return list
end

local monitors = monitors_left_to_right()

if #monitors == 0 then
    -- Monitors not known yet (e.g. very early at startup): plain 1-3.
    -- The monitor.added events below reload once they appear.
    for i = 1, PER_MONITOR do
        hl.workspace_rule({ workspace = tostring(i), persistent = true })
    end
else
    for index, monitor in ipairs(monitors) do
        for slot = 1, PER_MONITOR do
            local ws = (index - 1) * PER_MONITOR + slot
            hl.workspace_rule({
                workspace  = tostring(ws),
                monitor    = monitor.name,
                persistent = true,
                default    = (slot == 1), -- what this monitor shows at first
            })
        end
    end
end

-- Re-assign when monitors change.
hl.on("monitor.added",   function () hl.exec_cmd("hyprctl reload") end)
hl.on("monitor.removed", function () hl.exec_cmd("hyprctl reload") end)
