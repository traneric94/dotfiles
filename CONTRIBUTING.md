# Contributing

These are my personal dotfiles, public so anyone can read, learn from, and fork
them freely. If you want a different setup, fork and make it yours rather than
asking for changes to match your machine.

## Bugs

Bug reports are welcome via GitHub Issues — please use the bug report template.
Include what happened, what you expected, steps to reproduce, and your
environment (macOS / Linux / WSL, shell, and whether `install.sh` ran
interactively or with `NON_INTERACTIVE=1`).

## Pull requests

PRs are accepted but not guaranteed — this is a personal setup. CI
(`.github/workflows/install.yml`) runs on every PR; keep it green. Before
opening one:

- `bash -n install.sh` passes and `install.sh` sources cleanly.
- `luajit scripts/gen.lua skhd` and `luajit scripts/gen.lua ahk` generate without error.
- Every `apps.lua` entry has `id`, `hotkey`, and `darwin_app`.
- No secrets in the diff — this repo is PUBLIC. `.gitignore` covers common
  secret-bearing paths, and `gitleaks` runs in CI and in the pre-commit hook.
