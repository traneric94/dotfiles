# Clean Code - dense index (63 smells & heuristics)

Tier-1 scan layer for `clean-code-review`, mirroring `go-review/reference/checklist.md`. One line per item: `CODE · title · rule`. Scan the diff against these; open the full item in `clean-code.md` **only** for a candidate match. Severity/prioritization comes from the cross-language spine (`memory/engineering-principles.md`). Clean Code is guidance not law - the `Exceptions` tradeoffs live in the full reference.

## General (G)

G1. **Multiple Languages in One Source File** - Minimize the number of languages in any single source file, ideally to one.
G2. **Obvious Behavior Is Unimplemented** - Implement the behavior a reader expects from a function's or type's name before adding anything surprising.
G3. **Incorrect Behavior at the Boundaries** - Prove correct behavior at every boundary condition with an explicit test rather than trusting intuition.
G4. **Overridden Safeties** - Never disable, suppress, or route around compiler warnings, failing tests, or other safety mechanisms.
G5. **Duplication** - Eliminate every duplicated idea by extracting it to one named place (DRY).
G6. **Code at Wrong Level of Abstraction** - Keep each concept at its own abstraction level and never leak lower-level details through a higher-level interface.
G7. **Base Classes Depending on Their Derivatives** - Never let a base class reference, name, or branch on its derivatives.
G8. **Too Much Information** - Expose the smallest possible interface, hiding data, methods, constants, and helpers clients don't need.
G9. **Dead Code** - Delete code that can never execute the moment you find it.
G10. **Vertical Separation** - Declare variables and functions close to where they're used, minimizing vertical distance between definition and use.
G11. **Inconsistency** - Do the same thing the same way everywhere: pick one convention per concept and apply it uniformly.
G12. **Clutter** - Remove anything that serves no purpose: empty constructors, no-op methods, unused variables, redundant comments, dangling boilerplate.
G13. **Artificial Coupling** - Don't couple things with no real dependency; place each declaration where it logically belongs, not where it was convenient.
G14. **Feature Envy** - Put a method on the class whose data it manipulates, not one that reaches into another object's fields more than its own.
G15. **Selector Arguments** - Avoid flag arguments that select which of several behaviors a function performs; split into separate named functions.
G16. **Obscured Intent** - Write code so its intent is visible; never sacrifice expressiveness for terseness or premature cleverness.
G17. **Misplaced Responsibility** - Put each piece of code where a reader would naturally expect it (Principle of Least Surprise).
G18. **Inappropriate Static** - Prefer instance methods; go static only when the method operates on no instance and no caller will ever vary its behavior polymorphically.
G19. **Use Explanatory Variables** - Break intermediate calculations into named local variables that state what each subexpression means.
G20. **Function Names Should Say What They Do** - Name a function so the call site tells the reader exactly what happens without reading the implementation.
G21. **Understand the Algorithm** - Refactor until the structure makes the algorithm obviously correct, rather than tuning until tests happen to pass.
G22. **Make Logical Dependencies Physical** - When one module depends on an assumption about another, make it ask explicitly instead of silently duplicating the value.
G23. **Prefer Polymorphism to If/Else or Switch/Case** - Replace a type-based switch that recurs across the codebase with polymorphic dispatch behind an interface.
G24. **Follow Standard Conventions** - Adhere to the team's agreed conventions for layout, naming, and idioms, encoded somewhere shared rather than in each head.
G25. **Replace Magic Numbers with Named Constants** - Give any literal whose meaning isn't self-evident a named constant that states what it represents.
G26. **Be Precise** - Make a definite decision about ambiguous cases (types, concurrency, nulls, money, timeouts) instead of coding to the happy path.
G27. **Structure over Convention** - Enforce design decisions with structures that make violations impossible or obvious, rather than conventions that rely on discipline.
G28. **Encapsulate Conditionals** - Extract compound boolean logic into an intention-revealing predicate function.
G29. **Avoid Negative Conditionals** - Express conditionals in the positive form whenever the logic allows it.
G30. **Functions Should Do One Thing** - Split any function that performs multiple sequential responsibilities into functions that each do one thing.
G31. **Hidden Temporal Couplings** - Make required call ordering explicit by passing each step's output as the next step's input.
G32. **Don't Be Arbitrary** - Give every structural choice a rationale the reader can infer, and stay consistent with it.
G33. **Encapsulate Boundary Conditions** - Compute a boundary expression once, name it, and reuse the variable instead of repeating the arithmetic.
G34. **Functions Should Descend Only One Level of Abstraction** - Keep every statement in a function at a single level of abstraction, one step below the function's name.
G35. **Keep Configurable Data at High Levels** - Define configuration constants and defaults at the top level and pass them down to the low-level code that consumes them.
G36. **Avoid Transitive Navigation** - Ask objects only for what you directly need and let them delegate, rather than walking chains of intermediate objects.

## Names, Functions, Comments, Environment (N / F / C / E)

N1. **Choose Descriptive Names** - Pick names that state what a thing is, does, or holds, and rename the moment its meaning drifts.
N2. **Choose Names at the Appropriate Level of Abstraction** - Name things for what they mean in the problem domain, not for the implementation mechanism behind them.
N3. **Use Standard Nomenclature Where Possible** - Reuse the established vocabulary of your language, framework, and design patterns so a name carries its conventional meaning for free.
N4. **Unambiguous Names** - Choose a name that admits exactly one reasonable interpretation, even if it costs more characters.
N5. **Use Long Names for Long Scopes** - Scale a name's length to its scope: tiny scope tolerates tiny names, wide scope demands descriptive ones.
N6. **Avoid Encodings** - Don't bake type, scope, or membership prefixes into names; let the type system and IDE carry that information.
N7. **Names Should Describe Side-Effects** - Name a function for everything it does, including hidden work like creation, mutation, lazy initialization, or I/O.
F1. **Too Many Arguments** - Prefer zero, one, or two arguments; treat three as a warning and more than three as needing a parameter object.
F2. **Output Arguments** - Don't use a parameter as an output channel; return the result or mutate the object the method belongs to.
F3. **Flag Arguments** - Don't pass a boolean that selects behavior; split the function into the two operations the flag chooses between.
F4. **Dead Function** - Delete methods that are never called; recover them from version control if ever needed.
C1. **Inappropriate Information** - Keep comments to what code can't express; put change history, authorship, and ticket metadata in their own tools.
C2. **Obsolete Comment** - Update a comment the instant the code it describes changes, or delete it.
C3. **Redundant Comment** - Don't write a comment that only restates what the code already says plainly.
C4. **Poorly Written Comment** - If a comment is worth writing, write it well: concise, correct, grammatical, free of rambling or in-jokes.
C5. **Commented-Out Code** - Delete commented-out code on sight; version control preserves it.
E1. **Build Requires More Than One Step** - Make a full build achievable with a single trivial command from a clean checkout.
E2. **Tests Require More Than One Step** - Make the whole test suite runnable with one command from the IDE or a clean shell.

## Tests (T)

T1. **Insufficient Tests** - Write enough tests to exercise every condition and behavior that could plausibly break, not just the first happy path.
T2. **Use a Coverage Tool!** - Run a coverage tool and read its report to find the untested paths your eyes glossed over.
T3. **Don't Skip Trivial Tests** - Write the trivial tests too; their documentary value usually exceeds their defect-catching value.
T4. **An Ignored Test Is a Question about an Ambiguity** - Record uncertainty about a requirement as an explicitly disabled test with a reason, not a deleted test or mental note.
T5. **Test Boundary Conditions** - Test the boundaries explicitly: zero, one, empty, full, max, and the off-by-one ends of every range.
T6. **Exhaustively Test Near Bugs** - When you find one bug, write a cluster of tests around it, because defects congregate.
T7. **Patterns of Failure Are Revealing** - Read the pattern of which tests pass and fail across the suite as a diagnostic, not each red test in isolation.
T8. **Test Coverage Patterns Can Be Revealing** - Inspect which paths the passing tests do and don't execute to help localize why the failing cases fail.
T9. **Tests Should Be Fast** - Keep the unit suite fast, because a slow suite gets skipped and a skipped suite rots.
