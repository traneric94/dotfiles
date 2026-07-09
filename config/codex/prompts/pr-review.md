# PR review (multi-language)

Perform a focused, multi-language pre-merge code review. Be direct and terse; prioritize signal over ceremony. Prefix any GitHub comment you post with `Codex:`.

## Scope

Argument: $ARGUMENTS
- If it is a PR number: run `gh pr diff $ARGUMENTS` and `gh pr view $ARGUMENTS --json title,body,additions,deletions,changedFiles`.
- If empty: run `git diff HEAD` for working changes and `git log --oneline -5` for context.

## General criteria (all languages)

- **Correctness**: logic errors, off-by-one, nil derefs, swallowed errors, wrong error types, races, bad assumptions about external systems.
- **Security**: unvalidated input to sensitive ops, secrets/PII in logs or responses, injection, auth bypass.
- **Performance**: N+1, avoidable O(n) work, unbounded allocation, missing pagination, blocking calls on hot paths.
- **Tests**: new behavior untested, tests that assert implementation not behavior, missing edge cases (empty, max, error).

## Language-specific

Detect which languages the diff touches, then read ONLY the matching shared checklists (the same source the Claude `pr-review` skill uses - do not duplicate rules here):

- Go: `~/codebase/dotfiles/config/claude/skills/pr-review/reference/go.md`
- TypeScript / React: `~/codebase/dotfiles/config/claude/skills/pr-review/reference/typescript.md`
- Java: `~/codebase/dotfiles/config/claude/skills/pr-review/reference/java.md`
- Ruby: `~/codebase/dotfiles/config/claude/skills/pr-review/reference/ruby.md`
- Proto / API: `~/codebase/dotfiles/config/claude/skills/pr-review/reference/proto.md`

## Output

Group by severity - **BLOCKER** (must fix: correctness, security, data loss), **CONCERN** (should fix), **NIT** (optional). Each finding: `[SEVERITY] file:line - one-line description` then why it matters + suggested fix. End with blockers/concerns/nits counts and a merge recommendation.
