---
name: gt-ship
description: Ship the current branch as a Graphite stacked PR - run lint/typecheck, commit cleanly, gt submit, and keep the PR description matching the diff. Use when the user says "ship it", "submit this", "create the PR", "gt submit", or wants to push the current stack for review. Personal Graphite flow, distinct from the built-in ship skill.
allowed-tools: Bash(gt*), Bash(git status*), Bash(git diff*), Bash(git log*), Bash(git add*), Bash(git commit*), Bash(gh pr view*), Bash(gh pr list*), Read, Grep
---

Ship the current branch as a Graphite stacked PR. Be terse; show the plan before mutating anything.

## Guardrails

- Never use `git commit --amend`, `--force`, or `--force-with-lease`. New commits only.
- Confirm the plan (what will be committed, which branches submit) before running `gt submit`.
- If lint/typecheck fails, stop and report - do not ship broken code.

## Procedure

1. **Survey state.**
   - !`git status --short`
   - !`gt log 2>/dev/null | head -30`
   - !`git diff HEAD --stat 2>/dev/null`
2. **Quality gate.** Detect the stack (Go/Ruby/TS) and run the matching lint + typecheck (`go vet ./... && gofmt -l`, `bundle exec rubocop`, `yarn lint && yarn typecheck`). Report failures and stop.
3. **Commit** any uncommitted work as a new commit with a clear message (no `--amend`). If nothing to commit, skip.
4. **Submit.** Run `gt submit` for the current stack. Capture the PR URL(s).
5. **Sync the PR description.** Read the current diff and ensure each PR body describes what the diff actually does. If it drifted, update it. (Behavioral contracts in the description must match the code.)

## Output

- The `gt log` stack after submit.
- PR URL(s) with title + review status.
- One line: what shipped and any follow-up needed.
