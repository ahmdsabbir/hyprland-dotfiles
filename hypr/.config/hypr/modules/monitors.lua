-- See https://wiki.hypr.land/configuring/core/monitors/
--
-- Generic fallback: works on any machine.
-- Machine-specific layouts go in hosts/<hostname>.lua (loaded by modules/host.lua).

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})
