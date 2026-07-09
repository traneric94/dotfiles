# .zshenv - Environment variables for ALL zsh shells (interactive + scripts).
# Locale and tool roots belong here (not .zshrc) so non-interactive/script shells
# see them too.
export LANG=en_US.UTF-8
export PYENV_ROOT="$HOME/.pyenv"

# Claude Code tuning (MAX_THINKING_TOKENS / CLAUDE_CODE_MAX_OUTPUT_TOKENS) lives in
# ~/.claude/settings.json `env` — the native, machine-local place for it — rather
# than being exported into every shell from this tracked public file.
