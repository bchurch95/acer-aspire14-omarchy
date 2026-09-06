-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Chrome Profiles (Bypasses the profile picker / user switcher)
hl.unbind("SUPER + SHIFT + RETURN")
o.bind("SUPER + SHIFT + RETURN", "Chrome (Personal)", { launch = "google-chrome-stable --profile-directory=Default --no-profile-picker" })
o.bind("SUPER + CTRL + SHIFT + RETURN", "Chrome (Work)", { launch = 'google-chrome-stable --profile-directory="Profile 1" --no-profile-picker' })

-- Screenshot binding for Presentation key (Event Code 425)
o.bind("XF86Presentation", "Screenshot", "omarchy-capture-screenshot")

-- Antigravity coding agent with all permissions granted
hl.unbind("SUPER + SHIFT + A")
o.bind("SUPER + SHIFT + A", "Antigravity", { launch = "foot --app-id=org.omarchy.agent -e agy --dangerously-skip-permissions" })

-- Apple Music (Web App)
hl.unbind("SUPER + SHIFT + M")
o.bind("SUPER + SHIFT + M", "Apple Music", "apple-music")

-- Helper functions for keyboard shortcuts
local function send_shortcut_once(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))

    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

local function active_window_is_terminal()
  local window = hl.get_active_window()
  if not window then
    return false
  end

  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then
      return true
    end
  end

  return false
end

local function universal_shortcut(default_mods, default_key, terminal_mods, terminal_key)
  return function()
    if terminal_mods and terminal_key and active_window_is_terminal() then
      send_shortcut_once(terminal_mods, terminal_key)()
    else
      send_shortcut_once(default_mods, default_key)()
    end
  end
end

-- Select all (Super + A -> Ctrl + A)
o.bind("SUPER + A", "Select all", send_shortcut_once("CTRL", "A"))

-- New tab (Super + T -> Ctrl + T, or Ctrl + Shift + T in terminals)
hl.unbind("SUPER + T")
o.bind("SUPER + T", "New tab", universal_shortcut("CTRL", "T", "CTRL + SHIFT", "T"))

-- Toggle window floating/tiling (rebound to Super + Alt + T)
o.bind("SUPER + ALT + T", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))


