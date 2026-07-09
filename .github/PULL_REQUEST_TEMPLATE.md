## What

<!-- What does this change, and why? -->

## Checklist

- [ ] `bash -n install.sh` passes
- [ ] `install.sh` sources cleanly (linking / config-generation logic runs)
- [ ] `luajit scripts/gen.lua skhd` and `luajit scripts/gen.lua ahk` generate without error
- [ ] Every `apps.lua` entry has `id`, `hotkey`, and `darwin_app`
- [ ] No secrets in the diff (repo is PUBLIC); `.gitignore` covers any new secret-bearing paths
