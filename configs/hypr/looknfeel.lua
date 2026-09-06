-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
hl.config({
  general = {
    -- Remove all window borders and gaps.
    gaps_in = 0,
    gaps_out = 0,
    border_size = 0,
    col = {
      active_border = "rgba(00000000)",
      inactive_border = "rgba(00000000)",
    },
  },
  decoration = {
    rounding = 0,
    shadow = {
      enabled = false,
    },
  },
  group = {
    col = {
      border_active = "rgba(00000000)",
      border_inactive = "rgba(00000000)",
    },
  },
})


-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
-- hl.config({
--   decoration = {
--     -- Use round window corners.
--     rounding = 8,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })

-- Dropdown special workspace animation (slides smoothly from top)
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3.5, bezier = "easeOutQuint", style = "slidefadevert -100%" })
