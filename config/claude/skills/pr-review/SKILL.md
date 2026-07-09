---
name: pr-review
description: Multi-language pre-merge code review (Go, TypeScript/React, Java, Ruby, proto/API) of a PR or your working changes, grouped by severity. Use when the user says "review this PR", "review my changes", "code review", "review before merge", or passes a PR number - and the diff is not Python-only (use effective-python-review for Python).
allowed-tools: Bash(git diff*), Bash(git log*), Bash(git show*), Bash(gh pr diff*), Bash(gh pr view*), Read, Glob, Grep
context: fork
---

You are performing a focused code review. Be direct, terse, and prioritize signal over ceremony.

## Input

$ARGUMENTS

If $ARGUMENTS is a number, treat it as a PR number and review that PR:
- Diff: !`gh pr diff $ARGUMENTS 2>/dev/null || echo "no PR found"`
- PR context: !`gh pr view $ARGUMENTS --json title,body,additions,deletions,changedFiles 2>/dev/null || echo "no PR found"`

If $ARGUMENTS is empty, review current working changes:
- Staged+unstaged diff: !`git diff HEAD 2>/dev/null || echo "no changes"`
- Recent context: !`git log --oneline -5 2>/dev/null`

## Procedure

1. Apply the **general criteria** below to every changed region (all languages).
2. Detect which languages the diff touches, then read ONLY the matching
   references and apply them:
   - Go -> `reference/go.md`
   - TypeScript / React -> `reference/typescript.md`
   - Java -> `reference/java.md`
   - Ruby -> `reference/ruby.md`
   - Proto / API (`.proto`) -> `reference/proto.md`
   Skip languages absent from the diff - do not load their references.
3. Report findings in the output format below.

## General criteria (all languages)

**Correctness**
- Logic errors, off-by-one, nil/null dereferences
- Error handling: errors swallowed, wrong error types returned
- Race conditions, missing locks on shared state
- Incorrect assumptions about external system behavior

**Security**
- Unvalidated input reaching sensitive operations
- Secrets or PII in logs, errors, or response bodies
- SQL/command injection vectors
- Auth bypass paths

**Performance**
- N+1 queries or loops doing O(n) work avoidably
- Unbounded allocations, missing pagination
- Blocking calls on hot paths

**Tests**
- New behavior without test coverage
- Tests that only test implementation, not behavior
- Missing edge cases: empty input, max bounds, error paths

## Output Format

Group findings by severity:

**BLOCKER** - must fix before merge (correctness, security, data loss)
**CONCERN** - should fix (performance, bad pattern, missing tests)
**NIT** - optional (style, naming, minor cleanup)

For each finding:
```
[SEVERITY] file.go:42 - one-line description
  Why it matters + suggested fix
```

End with a one-line summary: total blockers / concerns / nits, and overall merge recommendation.
