---
name: go-review
description: Deep Go-only code review against the team's 12 code-review principles and 100 Go Mistakes. Use for a thorough Go audit, or when the user says "go review", "deep review this Go", "audit this Go package", or wants more than pr-review's quick multi-language Go pass.
allowed-tools: Bash(git diff*), Bash(git log*), Bash(gh pr diff*), Read, Glob, Grep
context: fork
---

Deep Go review. Heavier and more opinionated than `pr-review` - use the full checklist, not a skim.

## Input

$ARGUMENTS

If a PR number: !`gh pr diff $ARGUMENTS 2>/dev/null || echo "no PR found"`
If empty, working changes: !`git diff HEAD 2>/dev/null || echo "no changes"`

## Procedure

1. Scope to changed Go files and the code they directly touch.
2. Read `reference/checklist.md` and apply every section.
3. If present, cross-check against the deeper local sources (they may not exist on every machine - skip silently if absent):
   - `/Users/eric.tran/codebase/100-go-mistakes/`
   - the team `memory/ranking_service_checklist.md` and `memory/engineering-principles.md`
4. Report by severity, citing the principle or mistake number.

## Output

```
## Go review - <scope>

### BLOCKER
- `file.go:NN` - <principle/mistake>: <problem>. Fix: <one-line>.

### CONCERN
- ...

### NIT
- ...
```

End with blockers/concerns/nits counts and a merge recommendation. If clean, say so - do not invent findings.
