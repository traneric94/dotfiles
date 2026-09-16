# Effective Java - dense index (88 items)

Tier-1 scan layer for `effective-java-review`, mirroring `go-review/reference/checklist.md`. One line per item: `EJn · rule`. Scan the diff against these; open the full item in `effective-java.md` **only** for a candidate match. Severity/prioritization comes from the cross-language spine (`memory/engineering-principles.md`). Do not add `why`/`signal` prose here - that lives in the full reference.

## Creation & Destruction

EJ1. **Static factory methods** - prefer over constructors; they have names, can return subtypes, and can cache instances.
EJ2. **Builder pattern** - use when you have 4+ parameters or optional parameters; avoids telescoping constructors.
EJ3. **Singleton enforcement** - use a private constructor + static field, or a single-element enum (serialization-safe).
EJ4. **Utility class noninstantiability** - private constructor + `throw new AssertionError()` prevents accidental instantiation.
EJ5. **Dependency injection** - inject resources; hardwiring makes testing impossible and creates hidden coupling.
EJ6. **Avoid unnecessary objects** - reuse immutable objects; autoboxed expressions like `new Integer(x)` allocate on every call.
EJ7. **Eliminate obsolete references** - null out stale references in custom data structures; GC can't collect what you hold.
EJ8. **Avoid finalizers/cleaners** - unpredictable and slow; use try-with-resources and `AutoCloseable` instead.
EJ9. **try-with-resources** - always use over try-finally for `Closeable` resources; cleaner and exception-safe.

## Methods Common to All Objects

EJ10. **equals contract** - reflexive, symmetric, transitive, consistent, null-safe; `==` for type check breaks subclasses.
EJ11. **hashCode with equals** - always override `hashCode` when overriding `equals`; equal objects must have equal hash codes.
EJ12. **toString** - include all significant fields; debugging without `toString` requires reading heap dumps.
EJ13. **clone judiciously** - `Cloneable` is broken; prefer copy constructors or copy factory methods.
EJ14. **Comparable** - implement for natural ordering; use `Comparator.comparingInt(...)` chained methods to avoid subtraction overflow.

## Classes and Interfaces

EJ15. **Minimize accessibility** - every element should be as private as possible; public API must be deliberate.
EJ16. **Accessor methods not public fields** - public mutable fields break encapsulation; expose state via getters.
EJ17. **Minimize mutability** - immutable objects are simpler, thread-safe, and freely shareable.
EJ18. **Composition over inheritance** - inheritance breaks encapsulation; prefer composition + forwarding for extensibility.
EJ19. **Design for inheritance or prohibit** - document every overridable method; if you can't, make the class `final`.
EJ20. **Interfaces over abstract classes** - interfaces allow multiple-type mixin; abstract classes force single-parent hierarchy.
EJ21. **Design interfaces for posterity** - adding default methods to released interfaces can break existing implementations.
EJ22. **Interfaces only for types** - a constants interface (only static finals) is an abuse; use a class or enum instead.
EJ23. **Class hierarchies over tagged classes** - a class with a "shape type" enum field is a disguised class hierarchy; model as subclasses.
EJ24. **Static member classes** - non-static inner classes hold an implicit reference to the enclosing instance; prefer static.
EJ25. **One top-level class per file** - two top-level classes in one file creates compile-order-dependent behavior.

## Generics

EJ26. **No raw types** - `List` loses type safety at compile time; use `List<?>` for unknown types.
EJ27. **Eliminate unchecked warnings** - fix or annotate `@SuppressWarnings("unchecked")` with a comment explaining why it's safe.
EJ28. **Lists over arrays** - arrays are covariant and reifiable; generics are invariant and erased; mixing them causes runtime failures.
EJ29-31. **PECS** - `<? extends T>` for producers (reading from), `<? super T>` for consumers (writing to).
EJ32. **Varargs + generics** - annotate `@SafeVarargs` on generic varargs methods that don't leak the varargs array.
EJ33. **Typesafe heterogeneous containers** - use `Class<T>` as a map key to store multiple types with compile-time safety.

## Enums and Annotations

EJ34. **Enums over int constants** - enums are full classes: type-safe, have methods, print readable names.
EJ35. **Instance fields not ordinals** - `ordinal()` is fragile (declaration order); store semantics in a constructor field.
EJ36. **EnumSet over bit fields** - as fast as bit manipulation, but type-safe and readable.
EJ37. **EnumMap over ordinal arrays** - uses ordinals internally but exposes a safe, idiomatic API.
EJ38. **Extensible enums via interfaces** - define the type as an interface; use multiple enums to implement it.
EJ39. **Annotations over naming patterns** - annotations are compiler-checked; naming prefixes (like `test_`) are fragile.
EJ40. **@Override consistently** - annotate every intended override; catches accidental overloads at compile time.
EJ41. **Marker interfaces** - prefer marker interfaces over marker annotations when the marking affects compile-time type checking.

## Lambdas and Streams

EJ42. **Lambdas over anonymous classes** - lambdas are concise; anonymous classes are verbose; lambdas can't access `this`.
EJ43. **Method references over lambdas** - `Class::method` is clearer than `x -> Class.method(x)` when the lambda just delegates.
EJ44. **Standard functional interfaces** - prefer `Function`, `Predicate`, `Supplier`, `Consumer` over rolling your own.
EJ45. **Streams judiciously** - streams excel at transforms and aggregations; prefer loops for stateful operations or checked exceptions.
EJ46. **Side-effect-free stream functions** - stream operations should be pure; side effects in `forEach` break parallelism.
EJ47. **Collection over Stream as return type** - returning `Collection` lets callers choose iteration style; `Stream` forces the caller into stream mode.
EJ48. **Parallel streams carefully** - parallelism overhead dominates for small data; only parallelize when the source is splittable and work is substantial.

## Methods

EJ49. **Validate parameters** - check invariants at method entry; fail fast with `IllegalArgumentException` / `NullPointerException`.
EJ50. **Defensive copies** - copy mutable parameters on entry and mutable return values on exit; don't trust caller-provided objects.
EJ51. **Method signature design** - choose names carefully; avoid overloading ambiguously; prefer max two parameters per overload.
EJ52. **Overloading is resolved at compile time** - `override` dispatches at runtime; mixing them causes confusing behavior.
EJ53. **Varargs carefully** - varargs create an array on every call; use for truly variable arity, not for convenience overloads.
EJ54. **Return empty not null** - null returns force callers to null-check everywhere; return `Collections.emptyList()` or `Optional.empty()`.
EJ55. **Optional judiciously** - `Optional<T>` communicates "may be absent" in return types; never put Optional in collections or as fields.
EJ56. **Write documentation** - document every exported API element with preconditions, postconditions, exceptions, thread safety.

## General Programming

EJ57. **Local variables in narrow scope** - declare close to first use; reduces bugs from misreading intermediate state.
EJ58. **for-each over traditional for** - use enhanced for everywhere iterable/array; cleaner and less error-prone.
EJ59. **Know and use the libraries** - don't reinvent `Collections.shuffle`, `Arrays.sort`, `Objects.requireNonNull`; library code is battle-tested.
EJ60. **Avoid float/double for money** - binary FP can't represent 0.1 exactly; use `BigDecimal` or integer cents.
EJ61. **Primitive over boxed primitive** - autoboxing hides `NullPointerException`s and is slower; prefer `int` over `Integer` for local vars.
EJ62. **Avoid strings as substitutes** - don't use strings where an enum, int, or proper type exists; strings are stringly-typed.
EJ63. **String concatenation performance** - `+` in a loop is O(n²); use `StringBuilder`.
EJ64. **Refer to objects by interfaces** - `List<E> list = new ArrayList<>()` not `ArrayList<E> list`; decouples from implementation.
EJ65. **Prefer interfaces to reflection** - reflection bypasses compile-time checks and is slow; use only for frameworks and plugin systems.
EJ66. **Native methods judiciously** - JNI is error-prone; only use for performance-critical sections that profiling has identified.
EJ67. **Optimize judiciously** - don't optimize prematurely; profile first, then fix the measured bottleneck.
EJ68. **Naming conventions** - `UpperCamelCase` classes, `lowerCamelCase` methods/fields, `SCREAMING_SNAKE_CASE` constants; follow consistently.

## Exceptions

EJ69. **Exceptions for exceptional conditions** - never use exceptions for control flow; they're slow and mislead readers.
EJ70. **Checked vs unchecked** - checked for recoverable conditions; `RuntimeException` for programming errors the caller can't recover from.
EJ71. **Avoid unnecessary checked exceptions** - if callers can't realistically recover, use unchecked; too many checked exceptions bloat every call site.
EJ72. **Standard exceptions** - prefer `IllegalArgumentException`, `NullPointerException`, `UnsupportedOperationException` over custom exceptions.
EJ73. **Exception translation** - convert low-level exceptions to abstraction-appropriate ones at layer boundaries.
EJ74. **Document all exceptions** - `@throws` for both checked and unchecked; callers need this to handle correctly.
EJ75. **Detail message** - include all relevant state: `"Index: 4, Size: 3"` beats `"Index out of bounds"`.
EJ76. **Failure atomicity** - leave objects in a consistent state on failure; check preconditions before mutating state.
EJ77. **Don't ignore exceptions** - empty catch blocks silently hide bugs; at minimum log or rethrow as unchecked.

## Concurrency

EJ78. **Synchronized access to shared mutable data** - every read and write to shared mutable state must be synchronized; visibility isn't guaranteed otherwise.
EJ79. **Avoid excessive synchronization** - hold locks for the minimum time; never call alien methods (callbacks, listeners) inside a sync block.
EJ80. **Executors over raw threads** - `ExecutorService` + `Future` / `CompletableFuture` is far safer than managing raw `Thread` objects.
EJ81. **Concurrency utilities over wait/notify** - `CountDownLatch`, `Semaphore`, `BlockingQueue` cover most patterns; `wait/notify` is legacy.
EJ82. **Document thread safety** - state explicitly: thread-safe, conditionally thread-safe, not thread-safe; clients need to know.
EJ83. **Lazy initialization** - only when profiling shows it's needed; double-check idiom requires `volatile`; use `Holder` class idiom for static fields.
EJ84. **Thread scheduler independence** - correct code doesn't depend on thread priorities or `Thread.yield`; these are hints, not guarantees.

## Serialization

EJ85. **Prefer alternatives to Java serialization** - never deserialize untrusted data with Java serialization; use JSON, protobuf, or Avro.
EJ86. **Implement Serializable judiciously** - serialization creates a permanent public API of field names; version carefully with `serialVersionUID`.
EJ87. **Custom serialized form** - the default serialized form may expose implementation details; design the form explicitly.
EJ88. **Protect invariants during deserialization** - `readObject` is a public constructor; validate invariants and make defensive copies.
EJ89. **Enum singleton** - single-element enum is the serialization-safe singleton; no `readResolve` needed.
EJ90. **Serialization proxy** - use a serialization proxy pattern to serialize complex objects safely and maintain invariants.
