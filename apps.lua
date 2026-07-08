-- apps.lua — single source of truth for global app-launcher hotkeys.
-- Edit here and re-run install.sh; scripts/gen.lua compiles this to
-- .skhdrc (macOS/skhd) and hotkeys.ahk (Windows/AutoHotkey).
-- LuaJIT/5.1-compatible so it can be required from the wezterm/nvim configs.

-- Browsers share one macOS behavior: ensure a window exists on focus.
-- Declares it once instead of repeating the fields per browser.
local function browser(t)
  t.darwin_ensure_window = true
  t.darwin_new_window = t.darwin_new_window or "make_new_window"
  return t
end

return {
  {
    id = "slack",
    hotkey = "s",
    darwin_app = "Slack",
    brew_cask = "slack",
    winget_id = "SlackTechnologies.Slack",
    win_exe = "slack.exe",
    win_title = "Slack",
  },
  {
    id = "ghostty",
    hotkey = "1",
    darwin_app = "Ghostty",
    darwin_ensure_window = true, -- terminal: cmd-n keystroke if no window
    brew_cask = "ghostty",
    optional = true,
  },
  {
    id = "spotify",
    hotkey = "o",
    darwin_app = "Spotify",
    brew_cask = "spotify",
    winget_id = "Spotify.Spotify",
    win_exe = "spotify.exe",
    win_title = "Spotify",
  },
  {
    id = "notion",
    hotkey = "n",
    darwin_app = "Notion",
    brew_cask = "notion",
    winget_id = "Notion.Notion",
    win_exe = "notion.exe",
    win_title = "Notion",
  },
  {
    id = "zoom",
    hotkey = "z",
    darwin_app = "zoom.us",
    brew_cask = "zoom",
    winget_id = "Zoom.Zoom",
    win_exe = "zoom.exe",
    win_title = "Zoom",
  },
  {
    id = "discord",
    hotkey = "d",
    darwin_app = "Discord",
    brew_cask = "discord",
    winget_id = "Discord.Discord",
    win_exe = "discord.exe",
    win_title = "Discord",
  },
  {
    id = "1password",
    hotkey = "p",
    darwin_app = "1Password",
    brew_cask = "1password",
    winget_id = "AgileBits.1Password",
    win_exe = "1Password.exe",
    win_title = "1Password",
  },
  browser {
    id = "chrome",
    hotkey = "2",
    darwin_app = "Google Chrome",
    brew_cask = "google-chrome",
    winget_id = "Google.Chrome",
    win_exe = "chrome.exe",
    win_title = "Google Chrome",
  },
  browser {
    id = "firefox",
    hotkey = "f",
    darwin_app = "Firefox",
    darwin_new_window = "reopen",
    brew_cask = "firefox",
    winget_id = "Mozilla.Firefox",
    win_exe = "firefox.exe",
    win_title = "Mozilla Firefox",
  },
  {
    id = "rectangle",
    hotkey = "r",
    darwin_app = "Rectangle",
    brew_cask = "rectangle",
  },
  {
    id = "sdm",
    hotkey = "m",
    darwin_app = "SDM",
    win_title = "SDM",
    optional = true,
  },
}
