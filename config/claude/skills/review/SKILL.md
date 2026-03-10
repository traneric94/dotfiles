---
name: review
description: Review code changes for correctness, security, performance, and idiomatic patterns
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

## Review Criteria

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

**Language-specific (Go)**
- Interface defined at consumer not producer
- Overuse of `any` / empty interface
- Utility packages (`util`, `common`, `helper`) — flag these
- Naked returns, init() side effects
- Error wrapping with `%w` vs `%v`
- Context propagation — is it threaded through?
- Goroutine leaks — are all goroutines guaranteed to exit?

**Language-specific (TypeScript/React)**
- Missing dependency arrays in hooks
- Prop drilling that should be context or state
- Unhandled promise rejections
- Type assertions (`as`) hiding real type errors

**Language-specific (Java) — Effective Java**
- Item 17: Minimize mutability — unnecessary mutable state, missing `final`
- Item 50: Defensive copies for mutable inputs/outputs
- Item 64: Refer to objects by interface, not implementation class
- Item 69: Exceptions for exceptional conditions only, not control flow
- Item 76: Atomicity on failure — object left in inconsistent state after exception
- Item 80: Prefer `Executor`/`Stream` over raw threads
- Item 87: Custom serialization over default for non-trivial classes
- Unchecked casts, raw types, or `@SuppressWarnings` without justification
- Missing `@Override`, equals/hashCode contract violations
- Resource leaks — streams, connections not closed (missing try-with-resources)

**Language-specific (Ruby)**
- N+1 ActiveRecord queries without includes
- Missing database indexes for query patterns
- Mutable default arguments

**Tests**
- New behavior without test coverage
- Tests that only test implementation, not behavior
- Missing edge cases: empty input, max bounds, error paths

**Proto/API changes**
- Breaking changes to field numbers or types
- Missing `validate` rules on new fields
- Removed required fields

## Output Format

Group findings by severity:

**BLOCKER** — must fix before merge (correctness, security, data loss)
**CONCERN** — should fix (performance, bad pattern, missing tests)
**NIT** — optional (style, naming, minor cleanup)

For each finding:
```
[SEVERITY] file.go:42 — one-line description
  Why it matters + suggested fix
```

End with a one-line summary: total blockers / concerns / nits, and overall merge recommendation.
