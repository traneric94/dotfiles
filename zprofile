# Add Visual Studio Code (code)
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(pyenv init --path)"

# Source local, untracked overrides
if [ -f "$HOME/.zprofile.chime" ]; then
  source "$HOME/.zprofile.chime"
fi
