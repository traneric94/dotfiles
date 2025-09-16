# .zshenv - Environment variables for all zsh shells (interactive and non-interactive)

# Claude Code configuration
export MAX_THINKING_TOKENS=2048

# Support for zoxide (z command) - fallback to cd if z not available
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
else
    # Fallback: alias z to cd if zoxide is not available
    alias z="cd"
fi