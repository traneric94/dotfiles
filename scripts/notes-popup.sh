#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:$PATH"

NOTES_DIR="$HOME/notes"
INBOX="inbox.md"

CLIENT_WAIT_ATTEMPTS=50

latest_client() {
  tmux list-clients -F '#{client_activity} #{client_name}' 2>/dev/null | sort -rn | awk 'NR==1 {print $2}'
}

osascript -e 'tell application "Ghostty" to reopen' -e 'tell application "Ghostty" to activate'

client=$(latest_client)
attempts=0
while [[ -z "$client" && $attempts -lt $CLIENT_WAIT_ATTEMPTS ]]; do
  sleep 0.1
  client=$(latest_client)
  attempts=$((attempts + 1))
done

[[ -n "$client" ]] || exit 1

tmux display-popup -c "$client" -E -w 80% -h 80% -d "$NOTES_DIR" "nvim $INBOX"
