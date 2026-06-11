#!/usr/bin/env bash
# Notification hook: surface Claude Code notifications as macOS notifications.
# Catch-all (no matcher) so unknown notification types still alert; every event
# is logged to ~/.claude/notification.log for diagnosing missed notifications.

INPUT=$(cat 2>/dev/null)
TYPE=$(echo "$INPUT" | jq -r '.notification_type // "unknown"' 2>/dev/null)
MSG=$(echo "$INPUT" | jq -r '.message // "Claude needs attention"' 2>/dev/null)

echo "$(date '+%Y-%m-%d %H:%M:%S') [$TYPE] $MSG" >> ~/.claude/notification.log

case "$TYPE" in
  auth_success|elicitation_complete|elicitation_response) exit 0 ;;
esac

case "$TYPE" in
  permission_prompt|elicitation_dialog) SOUND=Basso ;;
  idle_prompt)                          SOUND=Ping ;;
  *)                                    SOUND=Pop ;;
esac

TMUX_WIN=$([ -n "$TMUX" ] && tmux display-message -p '#S' 2>/dev/null)
TITLE=$([ -n "$TMUX_WIN" ] && echo "Claude:$TMUX_WIN" || echo "Claude")

terminal-notifier \
  -title "$TITLE" \
  -message "$MSG" \
  -activate com.mitchellh.ghostty \
  2>/dev/null

# terminal-notifier exits 0 even when macOS suppresses the banner (permission
# denied, Focus mode), so play the sound separately as a guaranteed cue.
afplay "/System/Library/Sounds/${SOUND}.aiff" 2>/dev/null || true
exit 0
