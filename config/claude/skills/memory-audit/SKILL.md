---
name: memory-audit
description: Audit Claude memory files for stale references - file paths, function names, flags, or line numbers that no longer exist in the codebase. Use when the user says "audit my memory", "check memory for stale entries", or wants to keep memory trustworthy. Reports only; never edits memory automatically.
allowed-tools: Bash(ls*), Bash(grep*), Bash(rg*), Bash(test*), Read, Glob, Grep
context: fork
---

Check that the facts in memory still match the codebase. Recalled memory reflects what was true when written - flag anything that has drifted.

## Scope

Memory dir: `/Users/eric.tran/.claude/projects/-Users-eric-tran-codebase/memory/`
Codebase root: `/Users/eric.tran/codebase/`

## Procedure

1. List the memory files: !`ls -1 /Users/eric.tran/.claude/projects/-Users-eric-tran-codebase/memory/ 2>/dev/null`
2. For each `.md` file, read it and extract concrete, checkable references:
   - repo-relative or absolute **file paths**
   - **function / symbol / type names** presented as current
   - **flags, env vars, config keys, table/metric names**
   - **line numbers** tied to a named file (`foo.go:2264`)
3. Verify each against the codebase (path exists; symbol/flag still greps; the cited line still matches the described content). Use `rg`/`test -e`.
4. Do not touch anything - this is report-only.

## Output

Group by memory file:

```
### <memory-file>.md
- STALE: <reference> - <why: path gone / symbol not found / line moved>. Suggest: update to <X> | delete entry.
- OK: <n> references verified.
```

End with a summary: total stale vs verified, and which files need the most attention. Recommend fixes; let the user decide what to update or delete.
