local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- Matched to the Ghostty setup (config/ghostty/config): Catppuccin Mocha,
-- Hack Nerd Font Mono, translucent + blurred, frameless, option-as-alt.

-- Appearance
config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font("Hack Nerd Font Mono")
config.font_size = 14.0

-- Window: translucent with background blur, no title bar (keep resize handles).
config.window_background_opacity = 0.80
config.macos_window_background_blur = 20
config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true

-- tmux is the multiplexer; keep native chrome minimal.
config.window_padding = { left = 4, right = 4, top = 4, bottom = 4 }

-- Option key forwards as Alt/Meta to terminal apps (tmux, nvim), matching
-- Ghostty's macos-option-as-alt = true. false here means "do not compose
-- accented characters", i.e. send the raw Alt chord.
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

-- Cursor: solid block, no blink.
config.default_cursor_style = "SteadyBlock"

-- Bell: no audio (Ghostty ran visual-only).
config.audible_bell = "Disabled"

-- Deep scrollback (Ghostty scrollback-limit = 10000000).
config.scrollback_lines = 10000000

return config
