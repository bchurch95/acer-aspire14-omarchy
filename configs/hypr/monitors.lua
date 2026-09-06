-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1.2

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Default fallback (1.2x scale divides evenly into 1920x1200 and 30px bar)
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Built-in laptop display (1920x1200 -> 1600x1000 logical, bar is exactly 36 physical px)
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.2 })

-- 5K Home Monitors (5120x2880 at 2x integer scale for retina sharpness without gaps)
hl.monitor({ output = "desc:5K", mode = "5120x2880@60", position = "auto", scale = 2 })
-- Specific display port rules for 5K / 4K external monitors (adjust output name if needed)
-- hl.monitor({ output = "DP-1", mode = "5120x2880@60", position = "auto", scale = 2 })
-- hl.monitor({ output = "DP-2", mode = "5120x2880@60", position = "auto", scale = 2 })
