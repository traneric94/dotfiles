---
name: effective-java-review
description: Review Java (and Kotlin-on-JVM) code against the 88 Effective Java (Bloch, 3rd ed) items. Use when reviewing Java diffs/files/PRs, or when the user asks "is this idiomatic Java", "review this Java", "effective java check", or wants idiom/correctness feedback on JVM code.
---

# Effective Java Review

Apply the synthesized rules in `reference/effective-java.md` (88 items across 11 chapters, distilled from Effective Java 3rd edition and updated for modern Java) to Java code under review.

## When to use

- Reviewing a Java diff, file, class, or PR
- The user asks whether Java code is idiomatic, correct, or "effective"
- A pre-merge idiom/correctness pass on JVM code

Not for: non-JVM code; pure formatting (defer to the formatter). For general craftsmanship smells that aren't Java-specific, pair with `clean-code-review`.

## Procedure

1. **Scope the diff.** Changed Java files/hunks and the code they directly touch — not the whole module.
2. **Load the rules.** Read `reference/effective-java.md`. Each item: EJn · rule · why · smell · signal (bad/good) · exceptions · severity.
3. **Match against smells.** Highest-yield first:
   - **equals/hashCode** overridden inconsistently (EJ10-11), missing on value types
   - **Mutable escape** — no defensive copies of params/returns (EJ50); public mutable fields (EJ16)
   - **Raw types** / unchecked warnings / arrays+generics mixing (EJ26-28)
   - **Returning null** instead of empty collection / `Optional` (EJ54-55); `Optional` in fields/collections
   - **Boxed primitives** in hot paths / `==` on boxed (EJ61); float/double for money (EJ60)
   - **Exceptions for control flow** (EJ69); checked exceptions the caller can't recover from (EJ70-71); empty catch (EJ77)
   - **Raw threads** instead of executors (EJ80); unsynchronized shared mutable state (EJ78); `wait/notify` over concurrency utils (EJ81)
   - **Telescoping constructors** where a builder fits (EJ2); `Cloneable` (EJ13); Java serialization on untrusted input (EJ85)
   - **Modern Java**: prefer `record` (EJ17 immutability), `sealed` (EJ23 hierarchies), enum singleton (EJ3/EJ89)
4. **Report by severity** (high → medium → low). Per finding: `File.java:NN` · the **EJn title** · what's wrong · the idiomatic fix (short snippet).
5. **Respect exceptions.** Each item's `Exceptions` field — don't flag code that legitimately falls under one; note the tradeoff.

## Output

```
## Effective Java review — <scope>

### High
- `Foo.java:NN` — **EJ50 Defensive copies**: <problem>. Fix: <one-line idiom>.

### Medium
- ...

### Low / nits
- ...

### Clean
<idioms already applied well, if worth noting>
```

If nothing violates the rules, say so plainly — do not invent findings.

## Notes

- Rules are original synthesis; item numbers (EJ1-EJ90) are factual references to the book. Do not paste book prose. EJ29-31 (PECS) is one combined item.
- Where modern Java changes the advice (records, sealed classes, switch expressions, `java.util.concurrent`, virtual threads), the item says so — prefer the modern form.
