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

# Map visible repo files/dirs to hidden targets under $HOME
# Left side is relative to SCRIPT_DIR, right side is the absolute target
declare -A LINK_MAP=(
  ["zshrc"]="$HOME/.zshrc"
  ["zprofile"]="$HOME/.zprofile"
  ["bash_profile"]="$HOME/.bash_profile"
  ["vimrc"]="$HOME/.vimrc"
  ["vimrccomplete"]="$HOME/.vimrccomplete"
  ["skhdrc"]="$HOME/.skhdrc"
  ["config/nvim"]="$HOME/.config/nvim"
)

for src in "${!LINK_MAP[@]}"; do
  link_item "$SCRIPT_DIR/$src" "${LINK_MAP[$src]}"
done

# Also link any other top-level entries under config/ into ~/.config/
if [ -d "$SCRIPT_DIR/config" ]; then
  while IFS= read -r -d '' entry; do
    base_name="$(basename "$entry")"
    link_item "$entry" "$HOME/.config/$base_name"
  done < <(find "$SCRIPT_DIR/config" -mindepth 1 -maxdepth 1 -print0)
fi


# Brew setup
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

if command -v skhd >/dev/null 2>&1; then
  brew services restart skhd || true
fi

/usr/bin/defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false || true
/usr/bin/defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false || true
