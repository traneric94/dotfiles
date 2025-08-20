# Dotfiles

A simple, prompt-safe dotfile installer for macOS.

## Usage

```bash
./install.sh
```

- You will be prompted before replacing any existing files.
- Files are symlinked from this repo into your home directory.
- Entries inside `.config` (if present) are linked individually into `~/.config`.
- Homebrew is required. If installed, the script will:
  - `brew update` and `brew tap koekeishiya/formulae`
  - Use the included `Brewfile` via `brew bundle` to install formulae and casks

## Notes

- Strict mode is enabled (`set -euo pipefail`) so the script fails fast on errors, undefined variables, and pipeline failures.
- VS Code press-and-hold is disabled for both Stable and Insiders.
- `skhd` will be restarted if installed.

## Optional: Using GNU Stow

GNU Stow can manage symlinks for you using a clean package layout.

- Install: `brew install stow` (already included in the `Brewfile`).
- Typical layout in this repo:
  - Create directories like `zsh/`, `vim/`, `skhd/` containing files with their final paths relative to `$HOME` (e.g., `zsh/.zshrc`, `vim/.vimrc`).
- Apply symlinks:

```bash
stow --target "$HOME" zsh vim skhd
```

- Helpful flags:
  - `-n` dry run, `-v` verbose, `-R` restow (relink), `-D` delete.
  - `--dotfiles` if you keep leading dots in filenames inside package dirs.

Stow makes it easy to enable/disable groups without hand-rolling link logic.

## Undo

- Since links replace targets only after you confirm, you can cancel to keep existing files.
- To remove a link later, delete it from your home directory and re-run the script if needed. 