---
name: clean-code-review
description: Language-agnostic craftsmanship review against the 63 Clean Code (Robert C. Martin) Smells & Heuristics (G/N/F/C/E/T codes). Use when the user asks "is this clean", "clean code review", "any code smells", "review for maintainability/readability", or wants a refactoring/craftsmanship pass distinct from language-specific idiom checks.
---

# Clean Code Review

Apply the `reference/clean-code.md` Smells & Heuristics (63 items, G/N/F/C/E/T) to code under review. This is the cross-language craftsmanship layer — readability, naming, function/class design, duplication, test hygiene — that complements the language-specific idiom skills (`effective-python-review`, `effective-java-review`, `go-review`).

## When to use

- The user asks whether code is "clean", readable, or maintainable
- A refactoring / craftsmanship / code-smell pass on any language
- Reviewing a large change for structure and design, not just correctness

Pair with the language skill: run the language idiom check for correctness, this for craftsmanship. Don't duplicate a finding both skills would raise — cite the more specific one.

## Procedure

1. **Scope the diff.** Changed regions and the functions/classes they live in.
2. **Load the heuristics.** Read `reference/clean-code.md`. Each item: code · rule · why · smell · signal (bad/good) · exceptions · severity.
3. **Match against smells.** Highest-yield first:
   - **Duplication** (G5) — the top smell; extract the repeated logic
   - **Functions doing >1 thing** (G30) / descending >1 abstraction level (G34); long param lists, flag/selector args (G15)
   - **Names** — non-descriptive, non-searchable, encoded, at wrong scope length (N1-N7)
   - **Comments that should be code** (C1-C5) — commented-out code, redundant/obsolete comments
   - **Dead code** (G9), **clutter** (G12), **artificial coupling** (G13), **feature envy** (G14), **misplaced responsibility** (G17)
   - **Magic numbers** (G25), **negative conditionals** (G29), **unencapsulated conditionals/boundaries** (G28, G33)
   - **Tests** — insufficient, not automated, not FIRST, coverage gaps, skipped/quarantined (T1-T9)
4. **Report by severity** (high → medium → low), citing the code (e.g. `G30`). Prefer a concrete refactor over a lecture.
5. **Respect exceptions.** Clean Code is guidance, not law — each item's `Exceptions` notes real tradeoffs (performance vs clarity, framework constraints). Don't dogmatically flag; weigh the tradeoff.

## Output

```
## Clean Code review — <scope>

### High
- `path:NN` — **G5 Duplication**: <problem>. Refactor: <one-line>.

### Medium
- ...

### Low / nits
- ...
```

If the code is already clean, say so — do not invent smells to fill sections.

## Notes

- Codes (G1-G36, N1-N7, F1-F4, C1-C5, E1-E2, T1-T9) are factual references to the book's appendix. Original synthesis; do not paste book prose.
- Judgment over dogma: several heuristics are contested (G23 polymorphism-over-switch, comment rules). The `Exceptions` fields flag where; honor them.
