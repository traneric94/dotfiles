# .zshenv - Environment variables for all zsh shells (interactive and non-interactive)

# Smart directory jumping (zoxide)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi