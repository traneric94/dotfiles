# Bootstrap Homebrew — detect install location across macOS ARM, macOS Intel, and Linux.
# The visual-studio-code cask handles `code` on PATH; no manual export needed.
for _bp in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
  if [[ -x "$_bp/bin/brew" ]]; then
    eval "$("$_bp/bin/brew" shellenv)"
    break
  fi
done
unset _bp
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init --path)"
fi

# Source local, untracked overrides
if [ -f "$HOME/.zprofile.chime" ]; then
  source "$HOME/.zprofile.chime"
fi
