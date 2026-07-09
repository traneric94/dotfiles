---
name: memory-audit
description: Audit Claude memory files for stale references (file paths, symbols, flags, line numbers that no longer match the codebase) and fix them - update or delete each stale entry after you confirm. Use when the user says "audit my memory", "check memory for stale entries", or wants to keep memory trustworthy.
allowed-tools: Bash(ls*), Bash(grep*), Bash(rg*), Bash(test*), Bash(rm*), Read, Edit, Write, Glob, Grep
---

Check that memory still matches the codebase, then fix what has drifted. Flow: detect -> propose -> confirm -> apply. Do not apply blind - a false "stale" hit could delete a valid fact.

## Scope

Memory dir: `/Users/eric.tran/.claude/projects/-Users-eric-tran-codebase/memory/`
Codebase root: `/Users/eric.tran/codebase/`

## Procedure

1. List memory files: !`ls -1 /Users/eric.tran/.claude/projects/-Users-eric-tran-codebase/memory/ 2>/dev/null`
2. For each `.md`, read it and extract concrete, checkable references: file paths, symbol/type/function names stated as current, flags/env vars/config keys/table/metric names, and line numbers tied to a named file.
3. Verify each against the codebase with `rg` / `test -e`. Mark a reference **stale** only if you can confirm it no longer matches. If you cannot tell (ambiguous name, different repo, moved but present), mark it **UNCERTAIN**, not stale.
4. Classify each stale reference:
   - **UPDATE**: the fact is still true but the locator moved (path/line/symbol renamed). Propose the corrected value.
   - **DELETE**: the fact is no longer true (feature removed, decision reversed). Propose removing the entry, and its pointer line in `MEMORY.md`.
5. **Show the full proposed change set and stop for confirmation.** Editing memory is consequential - get an explicit yes.
6. On confirmation, apply:
   - `Edit` the affected memory files in place for UPDATE and entry-level DELETE.
   - If a whole memory file is being dropped, `rm` it and remove its pointer line from `MEMORY.md`.
   - Leave UNCERTAIN items untouched and list them for manual review.

## Output

- Proposed change set grouped by file: **UPDATE** (old -> new) / **DELETE** (entry) / **UNCERTAIN** (needs you).
- After confirm: exactly what changed (files edited, entries/files removed, MEMORY.md pointers updated), and the UNCERTAIN items left for you.

Never delete or rewrite a memory entry without an explicit yes. Never touch UNCERTAIN items automatically.
