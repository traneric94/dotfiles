# Dotfiles

A simple, prompt-safe dotfile installer for macOS (with partial Linux/WSL support).

## Usage

```bash
./install.sh
```

- You will be prompted before replacing any existing files.
- Files are symlinked from this repo into your home directory.
- Entries inside `.config` (if present) are linked individually into `~/.config`.
- Homebrew is installed if missing. The script then uses the included Brewfiles
  with `brew bundle` and installs hotkey-managed GUI apps from `apps.json`.
- On WSL, hotkeys are generated as AutoHotkey config and GUI apps install via winget.
- `git init.templatedir` is pointed at `git-templates/` (pre-commit hook for new clones).
- Targets not owned by the current user (e.g. configs deployed by corporate
  endpoint management) are never replaced.

## Claude / Codex config

Tools that write to their own config files can't have those files symlinked
into a repo, so two patterns are used:

- **Symlinked** (read-only from the tool's perspective): `~/.claude/CLAUDE.md`,
  `~/.claude/hooks`, `~/.claude/skills`, `~/.codex/hooks`.
- **Merged**: `config/claude/settings.base.json` holds generic settings (hooks,
  permission deny rules, defaults) and is jq-merged into the machine-local
  `~/.claude/settings.json` at install time. Machine- or employer-specific
  settings live only in the untracked target file. `config/codex/config.toml`
  is likewise a reference copy; the live `~/.codex/config.toml` stays local.

## Local overrides (untracked)

Machine- or employer-specific shell config goes in gitignored files that the
tracked configs source if present:

- `~/.zshrc.chime`, `~/.zprofile.chime`, `~/.bash_profile.chime`, `~/.vimrc.chime`
- `config/claude/hooks/route.local.sh` — per-project context routing for the
  Claude `route.sh` hook

## Notes

- Strict mode is enabled (`set -euo pipefail`) so the script fails fast on errors, undefined variables, and pipeline failures.
- Failed links are tallied and reported at the end; the script exits nonzero if any link failed.
- VS Code press-and-hold is disabled for both Stable and Insiders.
- `.skhdrc` is generated from `apps.json` on macOS (source of truth: `apps.json`).
- Ruby is installed via rbenv; `setup_ruby_versions.sh` can pin `.ruby-version` files per project (manual).

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
