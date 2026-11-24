-- sabbirpc: desktop with two 1080p monitors.

-- Mi Monitor left, Redmi Monitor right
hl.monitor({ output = "HDMI-A-3", mode = "1920x1080@60", position = "0x0",    scale = "1" })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "1920x0", scale = "1" })
-- Workspaces are assigned automatically, 3 per monitor left to right
-- (modules/workspaces.lua): left 1-3, right 4-6.
