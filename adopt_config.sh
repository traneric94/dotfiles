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
  mkdir -p "$(dirname "$target_path")"
  ln -snf "$source_path" "$target_path"
  echo "Linked: $target_path -> $source_path"
}

home_cfg="$HOME/.config"
[ -d "$home_cfg" ] || { echo "$home_cfg not found"; exit 0; }

if ! prompt_yes_no "Adopt existing entries from $home_cfg into repo config/?"; then
  exit 0
fi

mkdir -p "$SCRIPT_DIR/config"

while IFS= read -r -d '' entry; do
  base_name="$(basename "$entry")"
  repo_path="$SCRIPT_DIR/config/$base_name"
  [ -e "$repo_path" ] && continue
  [ -L "$entry" ] && continue

  if prompt_yes_no "Move $entry into repo at $repo_path and link back?"; then
    if [ -d "$entry" ]; then
      mkdir -p "$repo_path"
      if command -v rsync >/dev/null 2>&1; then
        rsync -a "$entry/" "$repo_path/"
      else
        cp -R "$entry/" "$repo_path/"
      fi
    else
      mkdir -p "$(dirname "$repo_path")"
      cp -a "$entry" "$repo_path"
    fi

    mv "$entry" "$entry.bak.$(date +%Y%m%d%H%M%S)"
    link_item "$repo_path" "$HOME/.config/$base_name"
    echo "Adopted: $base_name (backup left at $entry.bak.*)"
  fi

done < <(find "$home_cfg" -mindepth 1 -maxdepth 1 -print0) 