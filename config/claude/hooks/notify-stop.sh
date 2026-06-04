#!/usr/bin/env bash
# Stop hook: send completion notification via terminal-notifier.
# Activates Ghostty on click.

INPUT=$(cat 2>/dev/null)
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)

if [ -z "$TRANSCRIPT" ] && [ -n "$SESSION_ID" ]; then
  TRANSCRIPT=$(find ~/.claude/projects -name "${SESSION_ID}.jsonl" 2>/dev/null | head -1)
fi

TMUX_WIN=$([ -n "$TMUX" ] && tmux display-message -p '#S' 2>/dev/null)
TITLE=$([ -n "$TMUX_WIN" ] && echo "Claude:$TMUX_WIN" || echo "Claude")

MSG=""
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  MSG=$(jq -r 'select(.type == "system" and .subtype == "away_summary") | .content' "$TRANSCRIPT" 2>/dev/null \
    | tail -1 \
    | awk '{m=NF<12?NF:12; s=""; for(i=1;i<=m;i++) s=s (i>1?" ":"") $i; if(NF>12) s=s "..."; print s}')

  if [ -z "$MSG" ]; then
    MSG=$(jq -r 'select(.type == "assistant") | .message.content[] | select(.type == "text") | .text' "$TRANSCRIPT" 2>/dev/null \
      | tail -1 \
      | awk '{m=NF<10?NF:10; s=""; for(i=1;i<=m;i++) s=s (i>1?" ":"") $i; if(NF>10) s=s "..."; print s}')
  fi
fi

terminal-notifier \
  -title "$TITLE" \
  -message "${MSG:-Task complete}" \
  -activate com.mitchellh.ghostty \
  2>/dev/null
afplay /System/Library/Sounds/Glass.aiff 2>/dev/null
