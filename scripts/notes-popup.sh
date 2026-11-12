#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:$PATH"

CLIENT_WAIT_ATTEMPTS=50
CLIENT_PATTERN='/bin/herdr$'

# herdr has no popup API, so type its notes binding (prefix ctrl+b, then e; see
# config/herdr/config.toml) into the frontmost Ghostty window once a client is attached.
osascript -e 'tell application "Ghostty" to reopen' -e 'tell application "Ghostty" to activate'

attempts=0
until pgrep -f "$CLIENT_PATTERN" >/dev/null; do
  (( attempts++ < CLIENT_WAIT_ATTEMPTS )) || exit 1
  sleep 0.1
done

osascript \
  -e 'tell application "System Events" to keystroke "b" using control down' \
  -e 'tell application "System Events" to keystroke "e"'
