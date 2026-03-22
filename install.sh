#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$SCRIPT_DIR/apps.json"

# ── OS / environment detection ────────────────────────────────────────────────

OS="$(uname -s)"   # Darwin | Linux

IS_WSL=false
if [[ -f /proc/version ]] && grep -qi microsoft /proc/version 2>/dev/null; then
  IS_WSL=true
fi

# ── Helpers ───────────────────────────────────────────────────────────────────

prompt_yes_no() {
  local prompt_msg="$1"
  local response

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

# ── Homebrew ──────────────────────────────────────────────────────────────────

install_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    echo "Homebrew already installed"
    return
  fi

  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # On Linux (WSL2), Homebrew installs to /home/linuxbrew — add to PATH for this session.
  if [[ "$OS" == "Linux" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
}

# ── Package installation ──────────────────────────────────────────────────────

install_packages() {
  install_homebrew

  echo "Installing shared packages..."
  brew bundle --file="$SCRIPT_DIR/Brewfile"

  if [[ "$OS" == "Darwin" ]]; then
    echo "Installing macOS-only packages..."
    brew bundle --file="$SCRIPT_DIR/Brewfile.darwin"
  fi
}

# ── App installation (from apps.json) ─────────────────────────────────────────

install_apps() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found; skipping app installation"
    return
  fi

  if [[ "$OS" == "Darwin" ]]; then
    echo "Installing GUI apps via Homebrew Cask..."
    jq -r '.[] | select(.brew_cask != null) | .brew_cask' "$MANIFEST" | while read -r cask; do
      if brew list --cask "$cask" >/dev/null 2>&1; then
        echo "Already installed: $cask"
      else
        brew install --cask "$cask" || echo "Warning: failed to install cask $cask"
      fi
    done

  elif [[ "$IS_WSL" == "true" ]]; then
    echo "Installing GUI apps via winget..."

    # AutoHotkey is infrastructure — install before the app loop.
    winget.exe install --id AutoHotkey.AutoHotkey \
      --silent --accept-package-agreements --accept-source-agreements \
      2>/dev/null || echo "Warning: AutoHotkey install failed or already present"

    jq -r '.[] | select(.winget_id != null) | .winget_id' "$MANIFEST" | while read -r id; do
      winget.exe install --id "$id" \
        --silent --accept-package-agreements --accept-source-agreements \
        2>/dev/null || echo "Warning: winget failed for $id (may already be installed)"
    done
  fi
}

# ── Config generation ─────────────────────────────────────────────────────────

generate_configs() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found; skipping config generation"
    return
  fi

  if [[ "$OS" == "Darwin" ]]; then
    echo "Generating .skhdrc from apps.json..."
    bash "$SCRIPT_DIR/scripts/gen-skhdrc.sh" > "$SCRIPT_DIR/.skhdrc"
  fi

  if [[ "$IS_WSL" == "true" ]]; then
    echo "Generating hotkeys.ahk from apps.json..."
    bash "$SCRIPT_DIR/scripts/gen-hotkeys.ahk.sh" > "$SCRIPT_DIR/hotkeys.ahk"

    # Register hotkeys.ahk in the Windows Startup folder so it auto-runs on login.
    local win_user
    win_user=$(powershell.exe -Command 'echo $env:USERNAME' | tr -d '\r\n')
    local startup_dir="/mnt/c/Users/$win_user/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup"

    if [[ -d "$startup_dir" ]]; then
      local win_ahk_path
      win_ahk_path=$(wslpath -w "$SCRIPT_DIR/hotkeys.ahk")
      # VBS launcher runs AHK with no console window.
      printf 'CreateObject("WScript.Shell").Run "autohotkey.exe ""%s""", 0\n' "$win_ahk_path" \
        > "$startup_dir/hotkeys.vbs"
      echo "Registered hotkeys.ahk in Windows Startup"
    else
      echo "Warning: could not locate Windows Startup folder for $win_user"
    fi
  fi
}

# ── File linking ──────────────────────────────────────────────────────────────

link_configs() {
  local links=(
    ".zshrc:$HOME/.zshrc"
    ".zshenv:$HOME/.zshenv"
    ".zprofile:$HOME/.zprofile"
    ".bash_profile:$HOME/.bash_profile"
    "tmux.conf:$HOME/.tmux.conf"
    "alacritty.toml:$HOME/.config/alacritty/alacritty.toml"
    "config/nvim:$HOME/.config/nvim"
    "config/claude/CLAUDE.md:$HOME/.claude/CLAUDE.md"
  )

  # .skhdrc is macOS-only; hotkeys.ahk is generated and run directly from the repo dir.
  if [[ "$OS" == "Darwin" ]]; then
    links+=(".skhdrc:$HOME/.skhdrc")
  fi

  for item in "${links[@]}"; do
    local src_rel="${item%%:*}"
    local dst_abs="${item#*:}"
    link_item "$SCRIPT_DIR/$src_rel" "$dst_abs"
  done

  # Link remaining config/ subdirectories into ~/.config/.
  if [[ -d "$SCRIPT_DIR/config" ]]; then
    while IFS= read -r -d '' entry; do
      local base_name
      base_name="$(basename "$entry")"
      link_item "$entry" "$HOME/.config/$base_name"
    done < <(find "$SCRIPT_DIR/config" -mindepth 1 -maxdepth 1 -print0)
  fi
}

# ── oh-my-zsh ─────────────────────────────────────────────────────────────────

ensure_oh_my_zsh() {
  local target="$HOME/.oh-my-zsh"

  if [[ -d "$target" ]]; then
    echo "oh-my-zsh already installed at $target"
    return
  fi

  echo "Installing oh-my-zsh..."
  if git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$target"; then
    echo "oh-my-zsh installed"
  else
    echo "Failed to install oh-my-zsh. Install manually from https://ohmyz.sh/"
  fi
}

# ── TPM (Tmux Plugin Manager) ─────────────────────────────────────────────────

install_tpm() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"

  if [[ -d "$tpm_dir" ]]; then
    echo "TPM already installed"
    return
  fi

  echo "Installing TPM..."
  git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  echo "TPM installed"
}

# ── Ruby ──────────────────────────────────────────────────────────────────────

install_ruby() {
  if ! command -v rbenv >/dev/null 2>&1; then
    echo "rbenv not installed; skipping Ruby installation."
    return
  fi

  eval "$(rbenv init - bash)"

  local ruby_version="3.3.7"
  if rbenv versions --bare | grep -Fxq "$ruby_version"; then
    echo "Ruby $ruby_version already installed"
  else
    echo "Installing Ruby $ruby_version..."
    if rbenv install "$ruby_version"; then
      echo "Ruby $ruby_version installed"
    else
      echo "Failed to install Ruby $ruby_version"
      return
    fi
  fi

  local current_global
  current_global="$(rbenv global 2>/dev/null || true)"
  if [[ "$current_global" != "$ruby_version" ]]; then
    rbenv global "$ruby_version"
    echo "Set global Ruby to $ruby_version"
  fi

  rbenv rehash
}

# ── macOS system settings ─────────────────────────────────────────────────────

configure_macos() {
  /usr/bin/defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false || true
  /usr/bin/defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false || true
}

# ── Main ──────────────────────────────────────────────────────────────────────

install_packages
install_apps
generate_configs
link_configs
ensure_oh_my_zsh
install_tpm
install_ruby

if [[ "$OS" == "Darwin" ]]; then
  configure_macos
fi

echo ""
echo "Installation complete!"
echo ""
echo "To finish tmux setup:"
echo "  1. Start a new tmux session: tmux new"
echo "  2. Install plugins: Ctrl-a + I"
echo ""
if [[ "$IS_WSL" == "true" ]]; then
  echo "AutoHotkey hotkeys registered in Windows Startup."
  echo "Run hotkeys.ahk now or log out/in to activate."
  echo ""
fi
