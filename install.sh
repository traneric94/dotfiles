#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

prompt_yes_no() {
  local prompt_msg="$1"
  local response
  
  # Check if running in interactive mode
  if [[ ! -t 0 ]] || [[ "${NON_INTERACTIVE:-}" == "1" ]]; then
    echo "$prompt_msg [y/n] y (auto-answering yes in non-interactive mode)"
    return 0
  fi
  
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

# Map visible repo files/dirs to hidden targets under $HOME (portable without assoc arrays)
links=(
  ".zshrc:$HOME/.zshrc"
  ".zshenv:$HOME/.zshenv"
  ".zprofile:$HOME/.zprofile"
  ".bash_profile:$HOME/.bash_profile"
  ".skhdrc:$HOME/.skhdrc"
  "tmux.conf:$HOME/.tmux.conf"
  "alacritty.toml:$HOME/.config/alacritty/alacritty.toml"
  "config/nvim:$HOME/.config/nvim"
)

for item in "${links[@]}"; do
  src_rel="${item%%:*}"
  dst_abs="${item#*:}"
  link_item "$SCRIPT_DIR/$src_rel" "$dst_abs"
done

# Also link any other top-level entries under config/ into ~/.config/
if [ -d "$SCRIPT_DIR/config" ]; then
  while IFS= read -r -d '' entry; do
    base_name="$(basename "$entry")"
    link_item "$entry" "$HOME/.config/$base_name"
  done < <(find "$SCRIPT_DIR/config" -mindepth 1 -maxdepth 1 -print0)
fi

ensure_oh_my_zsh() {
  local target="$HOME/.oh-my-zsh"

  if [ -d "$target" ]; then
    echo "oh-my-zsh already installed at $target"
    return 0
  fi

  echo "Installing oh-my-zsh..."
  if git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$target"; then
    echo "oh-my-zsh installed to $target"
  else
    echo "Failed to install oh-my-zsh. You can install it manually from https://ohmyz.sh/."
  fi
}

ensure_oh_my_zsh

# Install TPM (Tmux Plugin Manager)
install_tpm() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  
  if [ ! -d "$tpm_dir" ]; then
    echo "Installing TPM (Tmux Plugin Manager)..."
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
    echo "TPM installed successfully!"
  else
    echo "TPM already installed at $tpm_dir"
  fi
}

install_tpm

install_go_tools() {
  if ! command -v go >/dev/null 2>&1; then
    echo "Go not installed; skipping go tool bootstrap."
    return
  fi

  local tools=(
    "golang.org/x/tools/cmd/goimports@latest"
    "github.com/daixiang0/gci@latest"
  )

  for tool in "${tools[@]}"; do
    echo "Installing ${tool}..."
    GO111MODULE=on go install "$tool" >/dev/null 2>&1 || true
  done
}

install_go_tools

/usr/bin/defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false || true
/usr/bin/defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false || true

echo ""
echo "✅ Installation complete!"
echo ""
echo "To finish tmux setup:"
echo "1. Start a new tmux session: 'tmux new'"
echo "2. Install tmux plugins: Press 'Ctrl-a + I' (capital I)"
echo "3. Use tmux-resurrect:"
echo "   • Save session: 'Ctrl-a + Ctrl-s'"
echo "   • Restore session: 'Ctrl-a + Ctrl-r'"
echo ""
