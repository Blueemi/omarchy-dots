-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults.

-- Keyboard layout and options.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input
-- hl.config({
--   input = {
--     -- Use multiple keyboard layouts and switch between them with Left Alt + Right Alt.
--     kb_layout = "us,dk,eu",
--     kb_options = "omarchy:shift_caps_compose,grp:alts_toggle",
--
--     -- Use a specific keyboard variant if needed (e.g. intl for international keyboards).
--     kb_variant = "intl",
--
--     -- Change speed of keyboard repeat.
--     repeat_rate = 40,
--     repeat_delay = 250,
--
--     -- Start with numlock on by default.
--     numlock_by_default = true,
--
--     -- Increase sensitivity for mouse/trackpad (default: 0).
--     sensitivity = 0.35,
--
--     -- Turn off mouse acceleration (default: adaptive).
--     accel_profile = "flat",
--
--     touchpad = {
--       -- Use natural (inverse) scrolling.
--       natural_scroll = true,
--
--       -- Use two-finger clicks for right-click instead of lower-right corner.
--       clickfinger_behavior = true,
--
--       -- Control the speed of your scrolling.
--       scroll_factor = 0.4,
--
--       -- Enable the touchpad while typing.
--       disable_while_typing = false,
--
--       -- Left-click-and-drag with three fingers.
--       drag_3fg = 1,
--     },
--   },
-- })

-- App-specific touchpad scroll speeds.
-- o.window("(Alacritty|kitty)", { scroll_touchpad = 1.5 })
-- o.window("foot", { scroll_touchpad = 2.0 })
-- o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- Enable touchpad gestures for changing workspaces.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
-- Discrete 3-finger swipe (no drag/slide animation): right = next workspace,
-- left = previous, switched instantly. m+1/m-1 = same as SUPER+TAB.
-- Hyprland's own left/right gestures lock the direction after only 5 units of
-- movement, so a slightly wobbly start reads as "up/down" and the swipe is
-- lost. Instead match any 3-finger swipe, sum its movement, and switch mid-swipe
-- as soon as enough sideways travel builds up. (End callback key is "finish".)
local SWIPE_MIN = 12      -- total horizontal travel needed (libinput units ~ px)
local SWIPE_RATIO = 0.6   -- horizontal must be >= 0.6x vertical (lenient on diagonals)
local SWIPE_GAP_MS = 250  -- updates further apart than this = a new swipe
local swipe = { x = 0, y = 0, fired = false, t = 0 }
local function swipe_reset() swipe.x, swipe.y, swipe.fired = 0, 0, false end
-- Switches mid-swipe, once per swipe, as soon as enough sideways travel has
-- built up (doesn't depend on the end callback).
local function swipe_add(e)
  if not (e and e.delta) then return end
  local t = e.time_ms or 0
  if t - swipe.t > SWIPE_GAP_MS or t < swipe.t then swipe_reset() end
  swipe.t = t
  swipe.x = swipe.x + (e.delta.x or 0)
  swipe.y = swipe.y + (e.delta.y or 0)
  local ax, ay = math.abs(swipe.x), math.abs(swipe.y)
  if not swipe.fired and ax >= SWIPE_MIN and ax >= ay * SWIPE_RATIO then
    swipe.fired = true
    hl.dispatch(hl.dsp.focus({ workspace = swipe.x > 0 and "m+1" or "m-1" }))
  end
end
hl.gesture({
  fingers = 3,
  direction = "swipe",
  action = {
    start = function(e) swipe_reset(); swipe_add(e) end,
    update = swipe_add,
    finish = swipe_reset,
  },
})

-- Enable touchpad gestures for moving focus (helpful on scrolling layout).
-- hl.gesture({ fingers = 3, direction = "left", action = function() hl.dispatch(hl.dsp.focus({ direction = "l" })) end })
-- hl.gesture({ fingers = 3, direction = "right", action = function() hl.dispatch(hl.dsp.focus({ direction = "r" })) end })

-- Carried over from GNOME (2026-11-08). The macOS-curve libinput plugin
-- (~/.config/libinput/plugins/50-touchpad-slow-scroll.lua) is DISABLED: its link
-- sits in /etc/libinput/disabled-plugins, not /etc/libinput/plugins. The
-- touchpad curve is done natively below instead.
--   mouse: flat (no acceleration)
hl.config({
  input = {
    accel_profile = "flat",
    sensitivity = -0.545,  -- external mouse, flat (no acceleration): GNOME's speed; -0.7 was too slow
    touchpad = {
      natural_scroll = false,
      clickfinger_behavior = true,
      tap_to_click = false,
      tap_and_drag = true,
      -- Scroll: the scroll_points curve below outputs macOS's content pixels.
      -- Default 0.4 is for GTK4 apps (they multiply by 2.5); other toolkits get
      -- per-app scroll_touchpad rules at the end of this file.
      scroll_factor = 0.4,
    },
  },
})

-- Touchpad pointer = macOS's default trackpad curve, natively in libinput (no
-- plugin). libinput's custom profile on this touchpad works in device units
-- (98/mm) in, pixels out: point i = macOS output speed (px/ms) at finger speed
-- i x 11 mm/s, so step = 11 x 0.098 = 1.078. Measured on real libinput: within
-- ~1% of macOS from 5 to 400 mm/s (4.0 px/mm slow ... 27 px/mm fast).
-- scroll_points = macOS trackpad scroll acceleration (IOHIDScrollAccelerator,
-- Magic Trackpad scroll curves, default scrolling speed), slow end anchored
-- 1:1 to the fingers on the 14" panel (5 pt/mm). Output = macOS content pixels
-- per ms at finger speed i x 11 mm/s: 5.9 px/mm at 10 mm/s ... 30 px/mm at 300.
-- Points below: macOS's default trackpad curve x1.0 exactly (user's macOS slider = default).
-- Slower/faster pointer overall: scale every point (macOS = x1.0).
-- macOS scroll curve (px/ms at finger speed i x 11 mm/s, step 1.078).
-- SCROLL_SPEED scales all of it: 1.0 = the computed macOS curve, which the
-- user found "very fast in basically everything" (2026-11-09).
local SCROLL_SPEED = 0.45
local MACOS_SCROLL = { 0, 0.06617, 0.15468, 0.26553, 0.39872, 0.55425, 0.73211, 0.93232, 1.1549, 1.3998, 1.667, 1.9565, 2.2685, 2.6027, 2.9593, 3.3382, 3.7395, 4.1631, 4.609, 5.0771, 5.5535, 6.0299, 6.5064, 6.9828, 7.4592, 7.9356, 8.412, 8.8885, 9.3649, 9.8413, 10.318, 10.794, 11.271, 11.747, 12.223, 12.7, 13.176, 13.643, 14.095, 14.532, 14.957, 15.37, 15.772, 16.164, 16.547, 16.921, 17.287, 17.646, 17.997, 18.342, 18.68, 19.012, 19.339, 19.66, 19.976, 20.287, 20.594, 20.895, 21.193, 21.486, 21.776, 22.062, 22.344, 22.622 }
local function scroll_curve(k)
  local out = {}
  for i, v in ipairs(MACOS_SCROLL) do out[i] = string.format("%.5f", v * k) end
  return "1.078 " .. table.concat(out, " ")
end

hl.device({
  name = "apple-mtp-multi-touch",
  accel_profile = "custom 1.078 0 0.04425 0.10053 0.19062 0.28687 0.39515 0.51815 0.65609 0.80915 0.97743 1.161 1.3598 1.574 1.8035 2.0482 2.3082 2.5833 2.8736 3.179 3.4993 3.8344 4.1838 4.547 4.9234 5.3124 5.7132 6.1251 6.5475 6.9798 7.4211 7.8708 8.3283 8.7928 9.2636 9.7401 10.222 10.707 11.197 11.689 12.183 12.679 13.176 13.673 14.169 14.664 15.157 15.648 16.135 16.618 17.096 17.569 18.036 18.495 18.948 19.392 19.827 20.252 20.668 21.072 21.464 21.844 22.211 22.564 22.903",
  scroll_points = scroll_curve(SCROLL_SPEED),
})

-- Electron apps on Chromium < 156 multiply Wayland touchpad scroll by 12 and
-- have no switch to stop it (Chromium 156+ apps get
-- WaylandUnscaledTouchpadScrolling:scroll_scaling_factor/1 in their flags file
-- instead: Helium, Vesktop, Chromium). 1/12 makes them scroll like those.
-- T3 Code (Chromium 152), Claude desktop (152), Obsidian (150).
for _, class in ipairs({ "com\\.t3tools\\.T3Code", "t3code", "com\\.anthropic\\.Claude", "obsidian" }) do
  o.window(class, { scroll_touchpad = 1 / 12 })
end

-- Per-app touchpad scroll so every app moves content 1:1 like macOS (the curve
-- above outputs macOS pixels; each factor undoes what the app multiplies by).
o.window("(helium|vesktop|chromium)", { scroll_touchpad = 1.0 })    -- Chromium 156 + WaylandUnscaledTouchpadScrolling/1: 1 px per unit
o.window("firefox", { scroll_touchpad = 0.25 })                     -- Firefox: 4 px per unit
o.window("libreoffice.*", { scroll_touchpad = 0.125 })              -- GTK3 (approximate)
o.window("com\\.mitchellh\\.ghostty", { scroll_touchpad = 2.0 })  -- precision:0.1 in ghostty config (x10 inside), cells in device px at scale 2
-- foot keeps Omarchy's 2.0 (it counts in device pixels: x0.5 at scale 2).

-- Middle click never pastes the primary selection.
hl.config({ misc = { middle_click_paste = false } })
