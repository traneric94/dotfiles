# Deep Go review

Deep Go-only review, heavier and more opinionated than `pr-review`. Be terse. Prefix any GitHub comment you post with `Codex:`.

## Scope

Argument: $ARGUMENTS
- If it is a PR number: run `gh pr diff $ARGUMENTS`.
- If empty: run `git diff HEAD`.
Scope to changed Go files and the code they directly touch.

## Apply

Read and apply the full checklist (the same source the Claude `go-review` skill uses - do not duplicate rules here):
`~/codebase/dotfiles/config/claude/skills/go-review/reference/checklist.md`

If present, also cross-check the deeper local sources (skip silently if absent):
- `~/codebase/100-go-mistakes/`
- the team `memory/ranking_service_checklist.md` and `memory/engineering-principles.md`

## Output

Group by severity - **BLOCKER** / **CONCERN** / **NIT**. Each finding: `file:line - <principle or mistake>: problem`, then the one-line fix. End with counts and a merge recommendation. If clean, say so - do not invent findings.
