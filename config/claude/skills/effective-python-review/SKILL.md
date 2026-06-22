---
name: effective-python-review
description: Review Python code against the 127 Effective Python (Brett Slatkin, 2nd+3rd ed) items. Use when reviewing Python diffs/files/PRs, or when the user asks "is this Pythonic", "review this Python", "effective python check", or for idiom/correctness feedback on Python.
---

# Effective Python Review

Apply the synthesized rules in `reference/effective-python-rules.md` (127 items across 14 chapters, distilled from Effective Python 2nd + 3rd editions and adversarially verified) to Python code under review.

## When to use

- Reviewing a Python diff, file, function, or PR
- The user asks whether code is "Pythonic", idiomatic, or correct
- A pre-merge idiom/correctness pass on Python

Not for: non-Python code; pure formatting (defer that to `ruff format`).

## Procedure

1. **Scope the diff.** Identify the changed Python files/hunks. Review changed lines and the code they directly touch — not the whole repo.
2. **Load the rules.** Read `reference/effective-python-rules.md`. Each item has: rule · why · smell · signal (a ⚠ marks a code snippet the verifier flagged — use it as illustration, not gospel) · exceptions · severity.
3. **Match against smells.** For each changed region, scan for the `Smell` patterns. Highest-yield categories to check first:
   - **Mutable default args** (`def f(x=[])`) → use `None` sentinel
   - **`==`/`is` confusion**, `== None`, comparing to `True`/`False`
   - **Manual index loops** (`for i in range(len(x))`) → `enumerate`/`zip`
   - **`dict[key]` + `KeyError`/`in`** where `get`/`setdefault`/`defaultdict` fits
   - **bytes/str mixing** at I/O boundaries
   - **Bare `except:`** / catching `Exception` too broadly
   - **Returning lists where a generator fits**; re-iterating an exhausted iterator
   - **Deeply nested dict/list/tuple** that should be a class/dataclass
   - **Blocking calls in async**, threads for CPU-bound work (GIL)
   - **`time` for timezone math** → `datetime` + `zoneinfo`
4. **Report findings**, grouped by severity (high → medium → low). Per finding:
   - `file:line` · the item **title** it maps to · what's wrong · the idiomatic fix (short code).
   - Cite the item title so the user can look up full detail.
5. **Respect exceptions.** Each rule has an `Exceptions` field — do not flag code that legitimately falls under one. Note the tradeoff instead of demanding the change.

## Output format

```
## Effective Python review — <scope>

### High
- `path.py:NN` — **<Item Title>**: <problem>. Fix: <one-line idiom / snippet>.

### Medium
- ...

### Low / nits
- ...

### Clean
<idioms already applied well, if worth noting>
```

If nothing violates the rules, say so plainly — do not invent findings to fill sections.

## Notes

- Rules are original synthesis; item **titles** are factual references to the book. Do not paste book prose.
- The reference is a superset of both editions; `•2`/`•3`/`2nd,3rd` tags indicate provenance. 3rd-ed-only items (walrus, `match`, typing, dataclasses) apply only to code targeting modern Python.
- Pair with the team's Go-style review values in `memory/` — observability, fail-loud, type-vs-domain correctness — where they transfer to Python.
