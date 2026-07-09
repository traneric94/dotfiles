# Java review checklist (Effective Java)

- Item 17: Minimize mutability - unnecessary mutable state, missing `final`
- Item 50: Defensive copies for mutable inputs/outputs
- Item 64: Refer to objects by interface, not implementation class
- Item 69: Exceptions for exceptional conditions only, not control flow
- Item 76: Atomicity on failure - object left in inconsistent state after exception
- Item 80: Prefer `Executor`/`Stream` over raw threads
- Item 87: Custom serialization over default for non-trivial classes
- Unchecked casts, raw types, or `@SuppressWarnings` without justification
- Missing `@Override`, equals/hashCode contract violations
- Resource leaks - streams, connections not closed (missing try-with-resources)
