# Dotfiles

A simple, prompt-safe dotfile installer for macOS.

## Usage

```bash
./install.sh
```

- You will be prompted before replacing any existing files.
- Files are symlinked from this repo into your home directory.
- Claude and Codex config are symlinked into `~/.claude` and `~/.codex`.
- Entries inside `.config` (if present) are linked individually into `~/.config`.
- Homebrew is installed if missing. The script then uses the included Brewfiles
  with `brew bundle` and installs hotkey-managed GUI apps from `apps.json`.

## Notes

- Strict mode is enabled (`set -euo pipefail`) so the script fails fast on errors, undefined variables, and pipeline failures.
- VS Code press-and-hold is disabled for both Stable and Insiders.
- `.skhdrc` is generated from `apps.json` on macOS.

## Raw Vim Training

Use `rawvim` or `rv` to launch Vim with `config/vim/raw.vim`.

- No Neovim config is loaded.
- Project search uses `:Rg`, `:copen`, `:cnext`, and `:cprevious`.
- Tags use `:Tags`, `<C-]>`, and `<C-t>`.
- File browsing uses netrw with `:Explore` or `<leader>e`.
- Buffers use `:ls`, `:buffer`, and `<C-^>`.
- Tests/builds go through `:make` and the quickfix list.

## Undo

- Since links replace targets only after you confirm, you can cancel to keep existing files.
- To remove a link later, delete it from your home directory and re-run the script if needed.
