#!/usr/bin/env bash
# Project context injection for Claude Code (UserPromptSubmit hook).
# Generic router — company/project-specific routes go in ~/.claude/hooks/route.local.sh (not tracked).

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)

[ -z "$PROMPT" ] && [ -z "$CWD" ] && exit 0

CONTEXT=""

# Local override: project-specific routing not tracked in git.
# Expected to set CONTEXT based on CWD/PROMPT.
LOCAL_ROUTES="${HOME}/.claude/hooks/route.local.sh"
if [[ -f "$LOCAL_ROUTES" ]]; then
  # shellcheck disable=SC1090
  source "$LOCAL_ROUTES"
fi

[[ -z "$CONTEXT" ]] && exit 0

printf '%s' "$CONTEXT"
