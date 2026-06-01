#!/usr/bin/env bash

# Codex lifecycle notification hook.
# Keep stdout empty: several Codex hook events treat stdout as structured data.

input="$(cat 2>/dev/null || true)"
event="${1:-}"

json_get() {
  local query="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r "$query // empty" 2>/dev/null
  fi
}

collapse() {
  tr '\r\n\t' '   ' | awk '{$1=$1; print}'
}

first_words() {
  awk -v max_words="${1:-10}" '{
    limit = NF < max_words ? NF : max_words
    out = ""
    for (i = 1; i <= limit; i++) {
      out = out (i > 1 ? " " : "") $i
    }
    if (NF > max_words) out = out "..."
    print out
  }'
}

notify() {
  local title="$1"
  local message="$2"
  local sound="$3"
  local sound_file="/System/Library/Sounds/${sound}.aiff"

  if command -v osascript >/dev/null 2>&1; then
    osascript \
      -e 'on run argv' \
      -e 'display notification (item 2 of argv) with title (item 1 of argv) sound name (item 3 of argv)' \
      -e 'end run' \
      "$title" "$message" "$sound" >/dev/null 2>&1 && return 0
  fi

  if [[ -f "$sound_file" ]]; then
    afplay "$sound_file" >/dev/null 2>&1 || true
  fi
}

if [[ -z "$event" ]]; then
  event="$(json_get '.hook_event_name')"
fi

tmux_name=""
if [[ -n "${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
  tmux_name="$(tmux display-message -p '#S' 2>/dev/null || true)"
fi

title="Terminal"
if [[ -n "$tmux_name" ]]; then
  title="Terminal:${tmux_name}"
fi

case "$event" in
  prompt|UserPromptSubmit)
    prompt="$(json_get '.prompt' | collapse | first_words 10)"
    notify "$title" "${prompt:-Prompt submitted}" "Pop"
    ;;
  stop|Stop)
    last_message="$(json_get '.last_assistant_message' | collapse | first_words 10)"
    notify "$title" "${last_message:-Task complete}" "Glass"
    ;;
  permission|PermissionRequest)
    tool_name="$(json_get '.tool_name' | collapse)"
    description="$(json_get '.tool_input.description' | collapse | first_words 10)"
    if [[ -n "$description" ]]; then
      message="Approval needed: $description"
    elif [[ -n "$tool_name" ]]; then
      message="Approval needed: $tool_name"
    else
      message="Approval needed"
    fi
    notify "$title" "$message" "Basso"
    ;;
  compact|PreCompact|PostCompact)
    notify "$title" "Compacting context..." "Purr"
    ;;
  *)
    notify "$title" "Codex needs attention" "Basso"
    ;;
esac

exit 0
