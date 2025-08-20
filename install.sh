#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

prompt_yes_no() {
  local prompt_msg="$1"
  local response
  while true; do
    read -r -p "$prompt_msg [y/n] " response < /dev/tty || true
    case "${response:-}" in
      [Yy]) return 0 ;;
      [Nn]) return 1 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}

link_item() {
  local source_path="$1"
  local target_path="$2"

  if [ ! -e "$source_path" ]; then
    echo "Source does not exist: $source_path"
    return 0
  fi

  if [ -L "$target_path" ]; then
    # If it's already the correct symlink, skip
    if [ "$(readlink "$target_path")" = "$source_path" ]; then
      echo "Already linked: $target_path -> $source_path (skipping)"
      return 0
    fi
  fi

  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    if prompt_yes_no "Target exists: $target_path. Replace it?"; then
      rm -rf "$target_path"
    else
      echo "Skipped: $target_path"
      return 0
    fi
  fi

  mkdir -p "$(dirname "$target_path")"
  ln -snf "$source_path" "$target_path"
  echo "Linked: $target_path -> $source_path"
}

# Dotfiles to link into $HOME
files=(
  ".vimrc"
  ".vimrccomplete"
  ".zprofile"
  ".zshrc"
  ".skhdrc"
  ".bash_profile"
)

for file in "${files[@]}"; do
  link_item "$SCRIPT_DIR/$file" "$HOME/$file"
done

# Handle items inside .config (link each entry rather than the whole directory)
if [ -d "$SCRIPT_DIR/.config" ]; then
  if prompt_yes_no "Link items inside .config into $HOME/.config?"; then
    while IFS= read -r -d '' entry; do
      rel=".config/${entry#${SCRIPT_DIR}/.config/}"
      link_item "$SCRIPT_DIR/$rel" "$HOME/$rel"
    done < <(find "$SCRIPT_DIR/.config" -mindepth 1 -maxdepth 1 -print0)
  fi
fi

ensure_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Please install it from https://brew.sh and re-run."
    exit 1
  fi
}

brew_setup_and_install() {
  ensure_brew
  brew update
  brew tap koekeishiya/formulae || true

  if [ -f "$SCRIPT_DIR/Brewfile" ]; then
    brew bundle --file "$SCRIPT_DIR/Brewfile"
  else
    # Fallback to inline lists if Brewfile is missing
    local formulae=(
      git
      node
      java
      python
      awscli
      go
      1password-cli
      koekeishiya/formulae/skhd
    )

    local casks=(
      google-chrome
      firefox
      cron
      zoom
      slack
      1password
      raycast
      rectangle
      visual-studio-code
      postman
      spotify
      # authy # deprecated desktop app; leave commented by default
    )

    for formula in "${formulae[@]}"; do
      brew install "$formula" || true
    done

    for cask in "${casks[@]}"; do
      brew install --cask "$cask" || true
    done
  fi
}

brew_setup_and_install

# Start/restart skhd if available
if command -v skhd >/dev/null 2>&1; then
  brew services restart skhd || true
fi

# macOS defaults: disable press-and-hold for VS Code and Insiders
/usr/bin/defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false || true
/usr/bin/defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false || true
