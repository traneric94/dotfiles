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
2. Prioritize with `memory/engineering-principles.md` (the cross-language spine, P1-P14), then scan changed regions against `reference/checklist.md` (Tier-1 dense index: the team's 12 principles applied to Go + one-line traps). Apply every checklist section.
3. For each candidate the checklist surfaces, open **only that item** in `reference/100-go-mistakes.md` (100 items, each: rule · why · smell · signal · exceptions · severity) for the full smell/signal/exceptions - do not read the file end-to-end. Highest-yield: nil-interface trap (#39), goroutine leaks (#51), context propagation (#56), mutex copy (#50), slice append aliasing (#17), map iteration order (#23), `defer` in loops (#25), integer overflow before widening (#12), missing HTTP client/server timeouts (#69-70), ignored/double-handled errors (#47-48). Cite the item number.
4. Respect each item's `Exceptions` - note the tradeoff instead of flagging code that legitimately falls under one.
5. If present, cross-check the team `memory/ranking_service_checklist.md` and `memory/engineering-principles.md` (skip silently if absent).
6. Report by severity, citing the principle or mistake number.

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
