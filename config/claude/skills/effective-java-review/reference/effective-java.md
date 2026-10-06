# Effective Java (Bloch, 3rd ed) — full rule detail (88 items)

Synthesized from *Effective Java* 3rd edition (Joshua Bloch), updated for modern Java (records, sealed classes, switch expressions, text blocks, virtual threads where they change the advice). Original wording; item numbers (EJ1-EJ90) are factual references. EJ29-31 (PECS) is one combined item.

## Creating and Destroying Objects

### EJ1. Static factory methods  [creation] · medium
- **Rule:** Expose object creation through named static factory methods when a plain constructor would be ambiguous, uncacheable, or locked to a concrete return type.
- **Why:** A constructor must share the class name, so two constructors with the same parameter types are impossible and the call site never explains intent. A static factory can carry a descriptive name (`from`, `of`, `getInstance`, `newInstance`), can return a cached or shared instance instead of always allocating, and can return any subtype or hidden implementation of its declared return type - which is what makes APIs like `List.of` and `EnumSet.of` possible (`EnumSet.of` returns a `RegularEnumSet` or `JumboEnumSet` depending on element count). The subtle cost people miss: a class with only static factories and no public/protected constructor cannot be subclassed, and factories are harder to discover in Javadoc than constructors.
- **Smell:** Multiple overloaded public constructors distinguished only by argument order/type, or a `new` that always allocates a value that is immutable and could be interned.
- **Signal:**
```java
// bad
public final class Color {
    public Color(int rgb) { ... }
    public Color(float h, float s, float b) { ... } // ambiguous intent at call site
}
Color c = new Color(255); // rgb? or something else?

// good
public final class Color {
    private Color(int rgb) { ... }
    public static Color fromRgb(int rgb) { ... }
    public static Color fromHsb(float h, float s, float b) { ... }
}
Color c = Color.fromRgb(255);
```
- **Exceptions:** When the type is a public data carrier meant to be subclassed or instantiated with `new` by convention (JavaBeans, framework-required no-arg constructors), or when a `record`'s canonical constructor already reads clearly - don't hide it behind a factory for its own sake.

### EJ2. Builder pattern  [creation] · medium
- **Rule:** Use a builder when a class has several parameters, especially optional ones, instead of telescoping constructors or a JavaBeans setter sequence.
- **Why:** Telescoping constructors force callers to pass values for parameters they don't care about and make long same-typed argument lists (three `int`s, two `boolean`s) trivially transposable with no compiler error. The JavaBeans alternative leaves the object in a partially-initialized, mutable, non-thread-safe state between the `new` and the last setter, so it can never be immutable. A builder gives named setter-like calls, validates invariants in `build()` (failure atomicity before the object escapes), and produces an immutable result.
- **Smell:** A constructor with 4+ parameters, several of the same type; or an object constructed via `new X()` followed by a run of `setX(...)` calls before first use.
- **Signal:**
```java
// bad
NutritionFacts f = new NutritionFacts(240, 8, 100, 0, 35, 27); // which arg is which?

// good
NutritionFacts f = new NutritionFacts.Builder(240, 8) // required args in ctor
        .calories(100)
        .sodium(35)
        .carbohydrate(27)
        .build();               // build() validates and freezes
```
- **Exceptions:** A `record` covers the immutable-data case with far less code when nearly all components are required and rarely defaulted; reach for a builder only once optional/defaulted components or cross-field validation make the canonical constructor unwieldy. For 1-3 required parameters a static factory is lighter than a builder.

### EJ3. Singleton enforcement  [creation] · low
- **Rule:** Implement a singleton as a single-element enum, or as a private constructor with a static field, rather than trusting a plain field-and-getter to stay single.
- **Why:** A naive singleton (private constructor + public static field) is defeated three ways: reflection can call `setAccessible(true)` on the private constructor, deserialization creates a second instance unless you supply `readResolve`, and cloning would too. A single-element enum is immune to all three for free - the JVM guarantees exactly one instance across reflection and serialization - which is why it is the most robust singleton. The subtlety people miss is that "singleton" also makes the type nearly impossible to mock in tests; prefer dependency injection (EJ5) when the single instance is a service.
- **Smell:** `INSTANCE` static field with a public constructor still reachable, a `Serializable` singleton class with no `readResolve`, or lazy-init singleton guarded by an unsynchronized check.
- **Signal:**
```java
// bad
public class Registry implements Serializable {
    public static final Registry INSTANCE = new Registry();
    public Registry() {}          // reflection + a second `new` both break singularity
}

// good
public enum Registry {
    INSTANCE;
    public void register(String key) { ... }
}
```
- **Exceptions:** When the singleton must extend a class (enums can only implement interfaces), fall back to the private-constructor-plus-static-field form and add `readResolve` if `Serializable`. If the "singleton" is really a stateless service dependency, inject it instead of making it a global.

### EJ4. Utility class noninstantiability  [creation] · low
- **Rule:** Give a class that holds only static members a single private constructor that throws, so it can never be instantiated.
- **Why:** A class with no explicit constructor gets a public default one, so `new MathUtils()` compiles and produces a meaningless empty instance, and the class can be accidentally subclassed. Making the class `abstract` does not stop instantiation - it invites subclassing, and a subclass is instantiable. A private constructor that throws `AssertionError` blocks both `new` from outside and any reflective or in-class call, and the thrown error documents that the constructor is never meant to run.
- **Smell:** A class of only `static` methods/constants with no declared constructor, or one marked `abstract` to "prevent instantiation."
- **Signal:**
```java
// bad
public abstract class StringUtils {   // abstract invites subclassing, not prevention
    public static boolean isBlank(String s) { ... }
}

// good
public final class StringUtils {
    private StringUtils() { throw new AssertionError("no instances"); }
    public static boolean isBlank(String s) { ... }
}
```
- **Exceptions:** Not for classes that carry instance state or are meant to be a dependency; those should be instantiated (and injected, EJ5). A `final class` with only nested types and no static entry points needs no throwing constructor.

### EJ5. Dependency injection  [creation] · high
- **Rule:** Pass a class's dependent resources into it (constructor, factory, or builder) instead of having the class create or look them up statically.
- **Why:** A class that news-up or reads a resource from a static singleton is welded to one concrete implementation: you cannot substitute a stub in tests, cannot vary it per environment, and cannot share a costly resource across instances. Hardwiring also hides coupling - the dependency does not appear in the constructor signature, so callers can't see what the object needs. Injecting the resource makes the dependency explicit, testable, and swappable, and lets you inject a factory (`Supplier<T>`) when the class must create many instances lazily.
- **Smell:** `new ConcreteDependency()` or `SomeSingleton.getInstance()` inside a class's methods/constructor rather than a field assigned from a parameter.
- **Signal:**
```java
// bad
public class SpellChecker {
    private final Lexicon dictionary = new EnglishDictionary(); // unswappable, untestable
    public boolean isValid(String word) { ... }
}

// good
public class SpellChecker {
    private final Lexicon dictionary;
    public SpellChecker(Lexicon dictionary) {           // injected; supply a fake in tests
        this.dictionary = Objects.requireNonNull(dictionary);
    }
}
```
- **Exceptions:** Genuinely stateless, behavior-free utilities (EJ4) and truly universal constants need not be injected. Very large dependency graphs are better wired by a framework (Spring, Guice, Dagger) than by hand, but the injection principle is unchanged.

### EJ6. Avoid unnecessary objects  [creation] · medium
- **Rule:** Reuse an existing immutable object or an expensive-to-create object instead of allocating an equivalent one on every call.
- **Why:** Repeatedly creating semantically identical immutable objects (or recompiling the same regex, or reparsing the same format) burns CPU and heap for no behavioral gain. The classic silent killer is autoboxing: declaring an accumulator as `Long` instead of `long` boxes a new `Long` on every `+=` in a loop, turning an O(1) allocation into millions. Hoisting an expensive constant (`Pattern`, `DateTimeFormatter`) into a static final field creates it once. The counter-subtlety: do not fight this by reusing mutable objects or caching defensively when object creation is actually cheap - creating small objects to gain clarity is fine, and pooling short-lived objects usually hurts.
- **Smell:** A `Pattern.compile(...)` / formatter / `new BigDecimal("...")` inside a hot method or loop; a boxed-type (`Long`, `Integer`, `Double`) loop accumulator; `new String("x")`; deprecated `new Integer(x)`/`new Boolean(x)`.
- **Signal:**
```java
// bad
static boolean isRoman(String s) {
    return s.matches("^(?=.)M*(C[MD]|D?C{0,3})...$"); // recompiles the regex every call
}
Long sum = 0L;
for (long i = 0; i < N; i++) sum += i;                // boxes a new Long each iteration

// good
private static final Pattern ROMAN = Pattern.compile("^(?=.)M*(C[MD]|D?C{0,3})...$");
static boolean isRoman(String s) { return ROMAN.matcher(s).matches(); }
long sum = 0L;
for (long i = 0; i < N; i++) sum += i;                // primitive, no allocation
```
- **Exceptions:** Defensive copies (EJ50) are necessary allocations - do not "reuse" a caller's mutable object to save one. Object pools are worthwhile only for genuinely heavyweight resources (DB connections, threads), not ordinary objects.

### EJ7. Eliminate obsolete references  [creation] · medium
- **Rule:** Null out references your class no longer needs when it manages its own memory (its own backing array/store), so the garbage collector can reclaim them.
- **Why:** In a class that manages its own storage - a stack over an array, a cache, a manual object pool - shrinking the logical size does not remove the physical reference. An element popped off a stack is still reachable through the backing array slot, so it (and everything it transitively references) is never collected: an unbounded memory leak that shows only as gradual heap growth and eventual OOM, with no exception at the leak site. Nulling the slot on pop severs the chain. The nuance: this is the exception, not the rule - nulling out references everywhere clutters code; do it only where the class owns the storage.
- **Smell:** A `pop`/`remove`/`evict` that decrements a size counter but leaves the array slot or map entry pointing at the old object; long-lived collections/caches keyed on objects that are never removed.
- **Signal:**
```java
// bad
public Object pop() {
    if (size == 0) throw new EmptyStackException();
    return elements[--size];          // elements[size] still holds the popped object -> leak
}

// good
public Object pop() {
    if (size == 0) throw new EmptyStackException();
    Object result = elements[--size];
    elements[size] = null;            // release for GC
    return result;
}
```
- **Exceptions:** Don't null out local variables that fall out of scope naturally - the JVM reclaims them; manual nulling there is noise. For caches, prefer `WeakHashMap` or a size/time-bounded cache (e.g. Caffeine) over hand-nulling entries.

### EJ8. Avoid finalizers/cleaners  [creation] · high
- **Rule:** Never rely on `finalize()` or `Cleaner` for critical, timely cleanup; free resources deterministically via `AutoCloseable` and try-with-resources.
- **Why:** Finalizers and cleaners run at the garbage collector's discretion - possibly seconds later, possibly never (e.g. at abrupt JVM exit) - so anything time- or correctness-critical (releasing file handles, DB connections, locks) can be delayed until the resource is exhausted. They also carry a severe performance penalty, can resurrect the object being finalized, and an uncaught exception in a finalizer is swallowed, leaving the object in a corrupt half-finalized state. `finalize()` is deprecated (since Java 9) and being removed, so writing new finalizers is building on a condemned mechanism.
- **Smell:** An overridden `protected void finalize()`; a class that documents "resources are freed when the object is collected"; a `Cleaner` used as the primary (not backstop) cleanup path.
- **Signal:**
```java
// bad
public class FileHandle {
    private final FileInputStream in;
    @Override protected void finalize() throws Throwable { in.close(); } // may run late or never
}

// good
public class FileHandle implements AutoCloseable {
    private final FileInputStream in;
    @Override public void close() throws IOException { in.close(); } // deterministic
}
```
- **Exceptions:** A `Cleaner` is acceptable purely as a safety-net for a class that also implements `AutoCloseable`, to reclaim native resources if a careless caller forgets to `close()`. It is a backstop, never the contract.

### EJ9. try-with-resources  [creation] · high
- **Rule:** Use try-with-resources for every `AutoCloseable`; never hand-write try-finally to close resources.
- **Why:** A hand-written try-finally with two resources is easy to get subtly wrong, and worse, it loses information: if the body throws and then `close()` also throws in the finally block, the second exception masks the first, so the stack trace points at the close failure and hides the real cause. Try-with-resources closes resources in reverse order automatically, and when both the body and a close throw, it keeps the body exception as primary and attaches the close exception as a suppressed exception (visible via `getSuppressed()`) - you lose nothing. It is also simply shorter and impossible to forget the close.
- **Smell:** `finally { x.close(); }`, nested try-finally blocks to close multiple resources, or a `close()` call not guaranteed on the exceptional path.
- **Signal:**
```java
// bad
BufferedReader br = new BufferedReader(new FileReader(path));
try {
    return br.readLine();
} finally {
    br.close(); // if readLine() threw, a close() throw here masks the original
}

// good
try (BufferedReader br = new BufferedReader(new FileReader(path))) {
    return br.readLine();
} // auto-closed; a close() failure is suppressed, not masking the real exception
```
- **Exceptions:** None for `AutoCloseable` resources. If the resource variable already exists and is effectively final, Java 9+ lets you name it directly in the `try (existing)` header without redeclaring. Objects that are not resources (no `close()` semantics) obviously don't apply.

## Methods Common to All Objects

### EJ10. equals contract  [obj-methods] · high
- **Rule:** Override `equals` only when logical (value) equality differs from object identity, and when you do, satisfy all five clauses: reflexive, symmetric, transitive, consistent, and non-null.
- **Why:** `HashSet`, `HashMap`, `List.contains`, and dedup logic all lean on these clauses; a violation produces silent wrong answers (a key you just inserted appears absent) rather than an exception. The clause people break most is symmetry/transitivity: extending an instantiable class to add a value component and comparing with `instanceof` makes `a.equals(b) != b.equals(a)`, while switching to `getClass()` fixes symmetry but violates Liskov substitution for subclasses. There is no way to add a value field to a subclass of a concrete class and preserve the contract - favor composition over inheritance for value types.
- **Smell:** an `equals(Object)` typed as `equals(MyType)` (an overload, not an override, so it silently doesn't dispatch), a cast with no `instanceof` guard, or `instanceof`-based equality spanning a subclass that adds a field.
- **Signal:**
```java
// bad
public boolean equals(Object o) {
    Point p = (Point) o;            // ClassCastException on foreign types
    return p.x == x && p.y == y;    // no instanceof, no null handling
}
// bad: subclass adds a field -> breaks symmetry
class ColorPoint extends Point {
    public boolean equals(Object o) {
        return o instanceof ColorPoint cp && super.equals(cp) && cp.color == color;
    }
}
// good: value type as a record - equals auto-generated and correct
record Point(int x, int y) {}
// good: hand-written, contract-honoring
@Override public boolean equals(Object o) {
    return o instanceof Point p && p.x == x && p.y == y;
}
```
- **Exceptions:** `record` types generate a compliant `equals` (component-wise) - don't hand-write one; enums and other instance-controlled/singleton types where identity *is* equality should inherit `Object.equals`; abstract classes may legitimately share `equals` across subclasses that add no value component.

### EJ11. hashCode with equals  [obj-methods] · high
- **Rule:** Override `hashCode` whenever you override `equals`, deriving it from exactly the fields `equals` uses, so equal objects always yield equal hash codes.
- **Why:** Hash-based collections locate an entry by bucket (`hashCode`) *then* confirm with `equals`; if two `equals` objects hash differently they land in different buckets and lookups miss, so a `HashMap` "loses" keys with no error. A subtle mutable-key trap: computing `hashCode` from fields that change after insertion strands the entry in its old bucket forever. `Objects.hash(...)` is correct and readable but autoboxes every argument and allocates a varargs array on each call - for hot paths hand-roll the `31 * result + c` accumulation or cache the code in a `final` field for immutable objects.
- **Smell:** a class overriding `equals` with no `hashCode` (or vice versa), the two methods reading different field sets, or `hashCode` computed from mutable state on a type used as a map key.
- **Signal:**
```java
// bad: equals overridden, hashCode inherited from Object
@Override public boolean equals(Object o) { /* value equality */ }
// (no hashCode) -> equal objects scatter across buckets, HashMap lookups miss
// good: record derives both from the same components
record PhoneNumber(short areaCode, short prefix, short lineNum) {}
// good: hand-rolled, same fields as equals, cached for immutables
private int hash;               // lazily cached, 0 until computed
@Override public int hashCode() {
    int h = hash;
    if (h == 0) {
        h = Short.hashCode(areaCode);
        h = 31 * h + Short.hashCode(prefix);
        h = 31 * h + Short.hashCode(lineNum);
        hash = h;
    }
    return h;
}
```
- **Exceptions:** `record` types generate a matching `hashCode`; caching is only safe when the object is immutable; you must still override even if you believe instances never enter a hash-based collection, because the equals/hashCode contract is unconditional.

### EJ12. toString  [obj-methods] · medium
- **Rule:** Override `toString` to return a concise, human-readable summary that includes every field useful for diagnosis.
- **Why:** Log lines, assertion-failure messages, and debugger displays all call `toString` implicitly; the default `ClassName@1b6d3586` forces you into heap dumps to answer "what was in this object." Whether or not you document the exact format is a real API decision: once callers parse the string you can no longer change it, so either specify and commit to the format or explicitly say it's subject to change, and always provide programmatic accessors for the data so nobody needs to parse. The modern trap is the auto-generated record `toString`, which prints *all* components - including passwords, tokens, and PII that then flow straight into logs.
- **Smell:** a domain or value class with no `toString`, a log statement that interpolates an object relying on the default, or a `record` holding secret/PII fields logged verbatim.
- **Signal:**
```java
// bad: default toString -> "Order@6d06d69c" in every log line
class Order { long id; Money total; }
// bad: record leaks a secret into logs via generated toString
record Credentials(String user, String password) {}
log.info("auth {}", creds);     // prints password=hunter2
// good: explicit, informative, all significant fields
@Override public String toString() {
    return "Order[id=%d, total=%s, status=%s]".formatted(id, total, status);
}
// good: record with a redacting override
record Credentials(String user, String password) {
    @Override public String toString() { return "Credentials[user=" + user + ", password=***]"; }
}
```
- **Exceptions:** static utility classes and most enums need nothing (`Enum.toString` already returns the constant name); a class whose superclass `toString` is already adequate; value classes where a generated record representation is both complete and free of sensitive data.

### EJ13. clone judiciously  [obj-methods] · medium
- **Rule:** Do not implement `Cloneable`; provide a copy constructor or static copy factory instead.
- **Why:** `Cloneable` is a mixin interface with no `clone` method, so it merely flips the behavior of the protected, `native` `Object.clone`, which returns a shallow field-by-field copy that constructs the object *without running any constructor* - final fields and invariants can't be enforced, and mutable internals (arrays, collections) are shared between original and copy until you recursively clone each one. The API also drags in a pointless checked `CloneNotSupportedException` and the covariant-return cast dance. A copy constructor `Foo(Foo other)` or factory `Foo.copyOf(other)` takes an interface-typed argument, throws nothing checked, runs real construction logic, and lets the caller pick the destination implementation.
- **Smell:** a class declaring `implements Cloneable`, an overridden `public Foo clone()`, or `super.clone()` calls threaded through a class hierarchy.
- **Signal:**
```java
// bad: Cloneable + clone - shallow copy shares the internal array, bypasses ctor
class Stack implements Cloneable {
    private Object[] elements;
    @Override public Stack clone() {
        try { return (Stack) super.clone(); }   // elements still aliased!
        catch (CloneNotSupportedException e) { throw new AssertionError(e); }
    }
}
// good: copy constructor + copy factory, real construction, deep as needed
public Stack(Stack src) { this.elements = src.elements.clone(); this.size = src.size; }
public static Stack copyOf(Stack src) { return new Stack(src); }
```
- **Exceptions:** arrays - `arr.clone()` is the idiomatic and correct way to duplicate an array (the one place `clone` shines); and you may be forced to implement `Cloneable` for interop with a legacy API that demands it.

### EJ14. Comparable  [obj-methods] · medium
- **Rule:** Implement `Comparable` for any class with a natural ordering, and build `compareTo` from `Comparator` combinators or `Integer.compare`-style helpers - never from subtraction.
- **Why:** `TreeSet`, `TreeMap`, `Collections.sort`, `Arrays.sort`, and binary search require a total order; a `compareTo` that isn't transitive or isn't consistent with itself corrupts sorted structures silently (elements vanish from a `TreeSet`) or throws `IllegalArgumentException: Comparison method violates its general contract`. The infamous subtraction shortcut `a - b` overflows when the difference exceeds `int` range (reversing the sign) and is meaningless for `float`/`double`; `Integer.compare`, `Double.compare`, and `Comparator.comparingInt(...).thenComparing(...)` are overflow-safe and read as intent. Keep `compareTo` consistent with `equals` - when they disagree, a value that `equals` considers present becomes invisible in a `TreeSet`, which dedups by comparison.
- **Smell:** `compareTo` returning `this.x - other.x`, a comparator built from subtraction, or a class placed in a `TreeSet`/`TreeMap` whose `compareTo` uses a different field set than `equals`.
- **Signal:**
```java
// bad: overflow reverses ordering when x is large-negative vs large-positive
public int compareTo(PhoneNumber pn) { return this.lineNum - pn.lineNum; }
// good: comparator combinators, overflow-safe, multi-key
private static final Comparator<PhoneNumber> ORDER =
    Comparator.comparingInt((PhoneNumber p) -> p.areaCode)
              .thenComparingInt(p -> p.prefix)
              .thenComparingInt(p -> p.lineNum);
@Override public int compareTo(PhoneNumber pn) { return ORDER.compare(this, pn); }
// good (single field): use the static helper
@Override public int compareTo(PhoneNumber pn) { return Integer.compare(lineNum, pn.lineNum); }
```
- **Exceptions:** classes with no single obvious ordering shouldn't implement `Comparable` - hand callers explicit `Comparator`s at each sort site instead; `record` types do *not* auto-implement `Comparable`, so you still write `compareTo` (ideally via combinators over the components) when a natural order exists.

## Classes and Interfaces

### EJ15. Minimize accessibility  [classes-interfaces] · high
- **Rule:** Give every class and member the least access level that still lets the code work.
- **Why:** Accessibility is the primary tool of encapsulation; a member that leaks into the public API becomes a permanent contract you can never tighten without breaking clients. The subtle trap is that `protected` is nearly as bad as `public` for extensibility — it is part of the exported API for every subclass forever — and that widening access to "just make a test pass" silently promotes an implementation detail to a contract. Loosening later is free; tightening later breaks callers.
- **Smell:** `public` on fields/helpers that only one package touches; `protected` added to satisfy a subclass or test; package-private classes promoted to `public` with no external caller.
- **Signal:**
```java
// bad
public class Config {
    public Map<String, String> settings = new HashMap<>(); // exported, mutable
    public String buildInternalKey(String s) { ... }        // impl detail leaked
}
// good
public class Config {
    private final Map<String, String> settings = new HashMap<>();
    public Map<String, String> settings() { return Collections.unmodifiableMap(settings); }
    private String buildInternalKey(String s) { ... }
}
```
- **Exceptions:** `public static final` primitive/immutable constants are fine to expose. A `public static final` array is never safe — it is mutable; expose an unmodifiable list or a defensive-copy accessor instead. Members overriding a superclass method cannot be made less accessible than the original.

### EJ16. Accessor methods, not public fields  [classes-interfaces] · medium
- **Rule:** Expose the state of a public class through accessor (and, if needed, mutator) methods, never through public fields.
- **Why:** Public fields fix the representation in the API, so you can never change the field's type, compute it lazily, validate on write, or fire a change notification without breaking every caller. The nuance most people miss: this rule is about the *degree of exposure*, not dogma — a package-private or private nested class exposing fields directly is perfectly fine and often clearer, because you can refactor everything that touches it in one place. Records (Java 16+) give you the accessor discipline automatically for immutable carriers.
- **Smell:** `public double x;` on a widely-used class; a public class whose fields are all public and mutable; getters/setters demanded on a private static nested helper where direct field access would read better.
- **Signal:**
```java
// bad
public final class Point { public double x; public double y; }
// good
public record Point(double x, double y) {}   // accessors x(), y() generated
// or, if mutable state is genuinely needed:
public final class Point {
    private double x, y;
    public double x() { return x; }
    public void setX(double x) { this.x = x; }
}
```
- **Exceptions:** Package-private or private nested classes may expose fields directly — no API commitment escapes the package/class. Immutable public fields are less harmful than mutable ones but still lock in representation and cost you lazy init and validation.

### EJ17. Minimize mutability  [classes-interfaces] · high
- **Rule:** Make classes immutable unless there is a concrete reason they must be mutable, and limit mutability when you can't eliminate it.
- **Why:** Immutable objects are inherently thread-safe, freely shareable and cacheable, make great map keys and set elements, and can never be observed in an inconsistent state. The five rules: (1) no mutators; (2) the class can't be extended (`final`, or all constructors private + static factories); (3) all fields `final`; (4) all fields `private`; (5) defensively copy any mutable component on the way in and out. The subtle failure: a `final` field holding a `List` or array is not immutable — callers can mutate the referent — so you must copy on construction and never hand out the internal reference.
- **Smell:** A "value" or "DTO" class with setters; a `final List<T>` field returned directly from a getter; `Date`/array fields stored or returned without copying; a class you treat as a key that has mutators.
- **Signal:**
```java
// bad
public final class Money {
    private final BigDecimal amount;
    private final List<String> tags;
    public List<String> getTags() { return tags; }   // caller can mutate internals
}
// good
public record Money(BigDecimal amount, List<String> tags) {
    public Money {                                    // compact canonical constructor
        tags = List.copyOf(tags);                     // defensive copy -> unmodifiable
    }
}
```
- **Exceptions:** Objects with expensive-to-build or large state may need mutable companions (`String`/`StringBuilder`). For performance you may cache derived values in nonfinal fields as long as the cache is not externally observable. Records replace most hand-written immutable classes but can't extend a class and don't fit when you need lazy caching or a non-canonical representation.

### EJ18. Favor composition over inheritance  [classes-interfaces] · high
- **Rule:** Reuse another class by holding an instance of it (composition + forwarding), not by extending it, unless a genuine is-a relationship holds within the same package or an explicitly inheritance-designed class.
- **Why:** Implementation inheritance breaks encapsulation: a subclass depends on the superclass's *self-use* patterns (which method calls which), and a superclass change in a later release can silently break the subclass — the classic `HashSet.addAll` calling `add` bug that double-counts in a size-tracking subclass. A forwarding wrapper (decorator) is immune because it only depends on the superclass's public API. The cost people overlook: wrappers are unsuitable for callback frameworks (the SELF problem — the wrapped object passes `this`, not the wrapper).
- **Smell:** `extends` across package boundaries or across a class not documented for inheritance; a subclass overriding methods to "fix" or augment inherited behavior; `extends HashMap`/`extends ArrayList` to add a feature.
- **Signal:**
```java
// bad
public class CountingSet<E> extends HashSet<E> {   // depends on HashSet's self-use
    private int added = 0;
    @Override public boolean add(E e) { added++; return super.add(e); }
    @Override public boolean addAll(Collection<? extends E> c) {
        added += c.size(); return super.addAll(c);  // double counts: addAll calls add
    }
}
// good
public class CountingSet<E> implements Set<E> {    // forwarding wrapper
    private final Set<E> s;
    private int added = 0;
    public CountingSet(Set<E> s) { this.s = s; }
    public boolean add(E e) { added++; return s.add(e); }
    public boolean addAll(Collection<? extends E> c) { added += c.size(); return s.addAll(c); }
    // remaining Set methods forward to s ...
}
```
- **Exceptions:** Inheritance is right for a true subtype relationship where the superclass is designed and documented for it (EJ19) and both live under the same maintainer's control. Sealed hierarchies (Java 17+) make safe inheritance explicit by naming the permitted subclasses.

### EJ19. Design and document for inheritance, or prohibit it  [classes-interfaces] · medium
- **Rule:** If a class is meant to be subclassed, document its self-use of overridable methods and provide hooks; otherwise make the class `final` or its constructors private.
- **Why:** A subclass can only override safely if it knows which overridable methods the superclass calls internally (the "@implSpec / self-use" contract). The lethal, non-obvious rule: a constructor must never invoke an overridable method — the override runs before the subclass's fields are initialized, reading nulls/zeros. The same danger applies to `clone` and `readObject`. If you won't do the documentation work, close the class so nobody depends on undocumented behavior.
- **Smell:** A non-final public class with overridable methods but no `@implSpec` notes; a constructor (or `clone`/`readObject`) calling a non-`private`/non-`final`/non-`static` method of its own class; "open for extension" claimed with zero documentation.
- **Signal:**
```java
// bad
public class Super {
    public Super() { overrideMe(); }        // runs subclass override too early
    public void overrideMe() { }
}
final class Sub extends Super {
    private final Instant when = Instant.now();
    @Override public void overrideMe() { System.out.println(when); } // prints null
}
// good
public final class Super {                  // prohibit inheritance
    public Super() { init(); }
    private void init() { }                 // private -> not overridable
}
```
- **Exceptions:** Abstract classes and skeletal implementations are designed for inheritance by definition. Sealed classes (Java 17+) are the modern middle ground: permit a fixed, known set of subclasses instead of an all-or-nothing `final`.

### EJ20. Prefer interfaces to abstract classes  [classes-interfaces] · medium
- **Rule:** Define types with interfaces; use an abstract class only when you need a skeletal implementation with shared state.
- **Why:** A class can implement many interfaces but extend only one abstract class, so an abstract class as a type forces itself into the single-inheritance slot and precludes mixins. Interfaces enable nonhierarchical type frameworks and safe retrofitting of existing classes. The pattern people miss: pair an interface with an *abstract skeletal implementation* (`AbstractList`) so implementers get code reuse without sacrificing the interface's flexibility; default methods can supply small pieces but can't hold state and can't override `Object` methods.
- **Smell:** An `abstract class Foo` used purely as a type with no shared state; forcing clients to `extends` when `implements` would do; duplicated boilerplate across implementations because no skeletal `Abstract*` was provided.
- **Signal:**
```java
// bad
public abstract class Animal {              // occupies the one inheritance slot
    public abstract String sound();
}
// good
public interface Animal { String sound(); }
public abstract class AbstractAnimal implements Animal {  // optional skeletal impl
    @Override public String toString() { return getClass().getSimpleName() + ":" + sound(); }
}
```
- **Exceptions:** When implementations must share mutable state or non-trivial constructors, an abstract skeletal class is appropriate. Default methods cover simple shared logic but cannot provide fields, so state-bearing reuse still needs an abstract class.

### EJ21. Design interfaces for posterity  [classes-interfaces] · medium
- **Rule:** Treat a released interface as frozen; add a default method only when you are certain it preserves every existing implementation's invariants.
- **Why:** Since Java 8 you *can* add methods to interfaces via `default`, but a default implementation is injected into implementers that never knew about it and were never compiled against it — it can violate their invariants at runtime (the canonical case: `Collection.removeIf` breaking a synchronized wrapper that assumed all mutation went through its own locked methods). There is no way for the interface author to know every implementation's assumptions, so defaults are a compatibility tool for evolution, not a substitute for getting the interface right up front.
- **Smell:** Adding a `default` method to a published, widely-implemented interface; a default that mutates state or calls other interface methods assuming a particular threading/consistency model; treating defaults as free extension points.
- **Signal:**
```java
// bad — added to a shipped interface, runs in impls that never saw it
public interface Collection<E> {
    default boolean removeIf(Predicate<? super E> f) {   // ignores a wrapper's lock
        boolean r = false;
        for (Iterator<E> it = iterator(); it.hasNext();)
            if (f.test(it.next())) { it.remove(); r = true; }
        return r;
    }
}
// good — bake required behavior into the interface before release, and test every
// known implementation against any default you must add later.
```
- **Exceptions:** Adding defaults is acceptable when creating a brand-new interface (defaults for convenience methods) or when you control and can retest all implementations. Even then, test with at least three independent implementations before release.

### EJ22. Use interfaces only to define types  [classes-interfaces] · low
- **Rule:** An interface should declare a type that clients implement; never use one merely to export constants.
- **Why:** The constant interface antipattern leaks an implementation detail — which constants a class uses — into its exported API via `implements`, and pollutes every subclass's namespace with those constants forever. Clients may even come to depend on the interface being implemented, cementing the mistake. Constants belong to a class/enum they describe, a utility class of static finals, or an `enum` when they form a natural set.
- **Smell:** `interface` containing only `static final` fields and no methods; a class `implements SomeConstants` just to use its values unqualified.
- **Signal:**
```java
// bad
public interface PhysicalConstants {
    double AVOGADRO = 6.022_140_857e23;
    double BOLTZMANN = 1.380_648_52e-23;
}
public class Calc implements PhysicalConstants { ... }  // leaks constants into API
// good
public final class PhysicalConstants {
    private PhysicalConstants() {}
    public static final double AVOGADRO = 6.022_140_857e23;
    public static final double BOLTZMANN = 1.380_648_52e-23;
}
// use: PhysicalConstants.AVOGADRO   (or static import if used heavily)
```
- **Exceptions:** None as a type-definition rule. Grouping related constants as an `enum` is preferred when they form a closed set; a noninstantiable utility class is right otherwise.

### EJ23. Prefer class hierarchies to tagged classes  [classes-interfaces] · medium
- **Rule:** Replace a class that carries a "kind" tag field and switches on it with a subtype per kind.
- **Why:** A tagged class is a class hierarchy in disguise, but worse: it mixes multiple flavors' fields into one bloated object (fields irrelevant to the current tag sit uninitialized), scatters `switch`/`if` on the tag through every method, and offers the compiler no way to enforce that a given instance is well-formed for its tag. Refactoring to subclasses lets each type carry exactly its own fields, makes illegal states unrepresentable, and enables the compiler to check exhaustiveness.
- **Smell:** An `enum`/`int`/`String` field named `type`/`kind`/`shape` plus `switch (type)` in multiple methods; constructors that leave some fields null "because this kind doesn't use them."
- **Signal:**
```java
// bad
class Figure {
    enum Shape { RECTANGLE, CIRCLE }
    final Shape shape;
    double length, width;   // rectangle only
    double radius;          // circle only
    double area() { return switch (shape) {
        case RECTANGLE -> length * width;
        case CIRCLE    -> Math.PI * radius * radius; }; }
}
// good — sealed hierarchy (Java 17+) gives compiler-checked exhaustiveness
sealed interface Figure permits Rectangle, Circle {}
record Rectangle(double length, double width) implements Figure {}
record Circle(double radius) implements Figure {}
double area(Figure f) { return switch (f) {          // no default needed; exhaustive
    case Rectangle r -> r.length() * r.width();
    case Circle c    -> Math.PI * c.radius() * c.radius();
}; }
```
- **Exceptions:** A tag can be pragmatic for a tiny, closed, performance-critical representation where allocation of many subtype objects matters and behavior barely varies. Modern `sealed` interfaces + records + pattern-matching `switch` make the hierarchy form cheaper than in the book's era, further narrowing this exception.

### EJ24. Favor static member classes over nonstatic  [classes-interfaces] · medium
- **Rule:** Declare a nested class `static` unless it genuinely needs access to an instance of the enclosing class.
- **Why:** A nonstatic (inner) class holds a hidden reference to its enclosing instance, which costs time and space to establish and — the failure people miss — can pin the enclosing object in memory long after it is otherwise garbage, causing leaks. If you don't need the outer instance, the `static` modifier removes the reference. Anonymous and local classes follow the same rule via their capture behavior.
- **Smell:** An inner class (helper, node, entry, iterator, comparator) declared without `static` that never references an enclosing field or method; a memory leak traced to nested-class instances retaining a large outer object.
- **Signal:**
```java
// bad
public class Cache {
    private final Map<K,V> map = new HashMap<>();
    class Entry {                 // implicit Cache reference, never used
        K key; V value;
    }
}
// good
public class Cache {
    private final Map<K,V> map = new HashMap<>();
    static class Entry<K,V> {     // no outer reference
        K key; V value;
    }
}
```
- **Exceptions:** Keep the class nonstatic when it truly acts as a view/adapter of a specific enclosing instance — e.g. the `keySet`/`iterator` returned by a collection, which must reference its backing object.

### EJ25. Limit source files to a single top-level class  [classes-interfaces] · low
- **Rule:** Put at most one top-level class or interface in each source file.
- **Why:** Defining two top-level classes in one file makes the program's behavior depend on the order files are passed to the compiler — the same identifier can resolve to different definitions across builds, or you get a duplicate-definition error, entirely at the mercy of command-line order. It never buys anything you can't get from nested classes, and it produces silent, build-order-dependent bugs that are maddening to reproduce.
- **Smell:** A `.java` file whose name matches one class but that also declares a second, unrelated top-level class or interface; two files each defining the same two classes in different orders.
- **Signal:**
```java
// bad — Utensil.java AND Dessert.java both declare Utensil and Dessert;
// output depends on which file compiles first
// Utensil.java
class Utensil { static final String NAME = "pan"; }
class Dessert { static final String NAME = "cake"; }
// good — one top-level type per file; if grouping helps, nest them static
public class Meal {
    private static class Utensil { static final String NAME = "pan"; }
    private static class Dessert { static final String NAME = "cake"; }
}
```
- **Exceptions:** Multiple *nested* (static member) classes in one file are fine and often desirable for cohesion. Package-private helper types tightly bound to a single public class are best expressed as nested classes rather than separate top-level ones.

## Generics

### EJ26. No raw types  [generics] · high
- **Rule:** Never use a raw generic type like `List`; write `List<?>` when the element type is genuinely unknown.
- **Why:** A raw type opts the whole variable out of generic checking, so it accepts any element and defers the `ClassCastException` to a distant read site instead of the store site. `List<Object>` is still checked (you cannot pass it where `List<String>` is wanted) and `List<?>` is safe because you cannot insert anything but `null`; the raw type gives up both. The subtle trap is contagion - one raw parameter erases type safety through every call that flows through it, and the compiler stops warning.
- **Smell:** `List list =`, `Map map =`, bare `Collection`/`Iterator` params or fields, `new ArrayList()` without the diamond.
- **Signal:**
```java
// bad
List names = new ArrayList();      // raw: accepts anything
names.add(42);                     // compiles; blows up on read as a String
// good
List<String> names = new ArrayList<>();
List<?> unknown = names;           // read-safe when element type is irrelevant
```
- **Exceptions:** Class literals must be raw (`List.class`; `List<String>.class` is illegal) and `instanceof` must use the raw form (`o instanceof Set`, then cast to `Set<?>`) because generic type info is erased at runtime.

### EJ27. Eliminate unchecked warnings  [generics] · medium
- **Rule:** Remove every unchecked warning you can, and suppress each survivor with the narrowest-possible `@SuppressWarnings("unchecked")` plus a comment proving it is safe.
- **Why:** Each unchecked warning marks a spot the compiler cannot prove type-safe, so a genuinely dangerous cast hides in the noise of the ones you have mentally cleared. Applying the annotation to the smallest scope - ideally a single local variable declaration, never a method or class - keeps it from silently swallowing a *new* unsafe warning introduced by a later edit. The comment is the load-bearing part: if you cannot articulate why the cast can never fail, the suppression is a latent bug.
- **Smell:** `@SuppressWarnings("unchecked")` on a method or type, or with no adjacent justification comment; leftover "unchecked cast"/"unchecked conversion" lines in build output.
- **Signal:**
```java
// bad
@SuppressWarnings("unchecked")     // whole method: hides future warnings too
public <T> T[] toArray(T[] a) { return (T[]) elements.clone(); }
// good
public <T> T[] toArray(T[] a) {
    // safe: elements only ever holds T, guaranteed by add()
    @SuppressWarnings("unchecked") T[] result = (T[]) elements.clone();
    return result;
}
```
- **Exceptions:** None as a category - the rule already contains its own escape hatch (suppress + comment). It just must be minimal in scope.

### EJ28. Lists over arrays  [generics] · high
- **Rule:** Prefer generic lists to arrays, and never mix the two in one abstraction.
- **Why:** Arrays are covariant and reified - `Long[]` is-a `Object[]`, and the element type is checked at runtime - while generics are invariant and erased, checked only at compile time. That mismatch is why `new E[]` is illegal and why a covariant array store compiles cleanly then throws `ArrayStoreException` at runtime, the exact opposite of fail-fast. Lists surface the same mistake as a compile error, so bugs move left.
- **Smell:** `new E[]`/`new T[]` (won't compile), `(E[]) new Object[n]`, `E[]` fields inside a generic class, arrays of parameterized types like `List<String>[]`.
- **Signal:**
```java
// bad
Object[] a = new Long[1];
a[0] = "oops";                     // compiles; ArrayStoreException at runtime
// good
List<Long> a = new ArrayList<>();
// a.add("oops");                   // won't compile - error moves left
```
- **Exceptions:** Low-level generic containers (`ArrayList` itself holds an `Object[]`), varargs internals, and array-API interop legitimately use an array - confine it to a private field and suppress the one unchecked cast. Modern note: a generic `record Pair<A,B>(A a, B b)` gives you a typed immutable container with no array involved (EJ17).

### EJ29-31. PECS  [generics] · medium
- **Rule:** Make your types (EJ29) and methods (EJ30) generic, and apply bounded wildcards per PECS (EJ31) - `<? extends T>` for parameters you only read from, `<? super T>` for parameters you only write to.
- **Why:** Generifying eliminates casts and pushes `ClassCastException` back to compile time; invariance then makes `List<Integer>` *not* a `List<Number>`, so an un-wildcarded API is needlessly rigid and rejects callers it could safely serve. PECS restores flexibility exactly where it is provably safe: a producer hands you `T`s (covariant read), a consumer accepts `T`s (contravariant write). Two subtleties people miss - return types must never carry wildcards (that just forces wildcards onto every caller), and `Comparable`/`Comparator` are always consumers, so bound them `Comparable<? super T>`; also, if a type parameter appears exactly once in a signature, replace it with a wildcard.
- **Smell:** `List<T>` params in a method that only reads (should be `? extends T`) or only writes (should be `? super T`); `Comparable<T>` where `Comparable<? super T>` belongs; a `<T>` declared but used only once.
- **Signal:**
```java
// bad
void pushAll(Collection<E> src) { for (E e : src) push(e); }        // rejects Collection<subtype>
void popAll(Collection<E> dst)  { while (!empty()) dst.add(pop()); } // rejects Collection<supertype>
// good
void pushAll(Collection<? extends E> src) { for (E e : src) push(e); }  // producer: extends
void popAll(Collection<? super E> dst)     { while (!empty()) dst.add(pop()); } // consumer: super
```
- **Exceptions:** Never wildcard a return type. Use an explicit type parameter (not a wildcard) when a parameter's type must relate to the return type or to another parameter, since a wildcard cannot capture that linkage.

### EJ32. Varargs + generics  [generics] · medium
- **Rule:** Add `@SafeVarargs` to a generic varargs method only if it neither stores into the varargs array nor lets a reference to it escape; otherwise take a `List` instead.
- **Why:** A generic varargs parameter creates a `T[]` of a non-reifiable type, so the array is a heap-pollution hazard the moment a reference to it leaves the method - unrelated code can then trigger a `ClassCastException` far from the cause. `@SafeVarargs` only silences the caller-side warning; it is a promise the compiler cannot verify, not a safety check. The failure people miss: returning the varargs array, or forwarding it to another varargs method, breaks safety even though the annotation is present and everything compiles.
- **Smell:** `T... args` / `List<E>... lists` with no `@SafeVarargs`; a generic varargs method that returns `args`, assigns it to a field, or passes it to another varargs call.
- **Signal:**
```java
// bad
static <T> T[] pick(T... a) { return a; }   // leaks the T[]; heap pollution escapes
// good
@SafeVarargs static <T> List<T> flatten(List<? extends T>... lists) {
    var out = new ArrayList<T>();
    for (var l : lists) out.addAll(l);       // only reads args; nothing escapes
    return out;
}
```
- **Exceptions:** A `List<T>` parameter with `List.of(...)` (Java 9+) at the call site sidesteps the varargs array entirely and is provably safe - prefer it whenever the `@SafeVarargs` safety argument is not glaringly obvious.

### EJ33. Typesafe heterogeneous containers  [generics] · low
- **Rule:** Parameterize the *key* with `Class<T>` (a type token) rather than the container, so one map can hold many types while each entry keeps compile-time type safety.
- **Why:** A normal generic container fixes a single element type; moving the type parameter onto the key lets every entry carry its own type, with `Map<Class<?>, Object>` plus `type.cast(value)` recovering the static type on read. The dynamic `cast()` also validates the invariant at store time, converting a latent heap-pollution bug into an immediate `ClassCastException` at the offending `put`. Two limits people miss: a *raw* `Class` key silently defeats the safety, and non-reifiable types have no class literal (`List<String>.class` is illegal), so all `List<?>` collapse onto one `List.class` key.
- **Smell:** casts pulling values out of a `Map<String, Object>`; attribute/config bags keyed by string with unchecked casts on read; a "registry" that really only ever holds one type.
- **Signal:**
```java
// bad
Map<String, Object> attrs = new HashMap<>();
String name = (String) attrs.get("name");          // unchecked, string-keyed
// good
Map<Class<?>, Object> favorites = new HashMap<>();
<T> void put(Class<T> t, T v) { favorites.put(t, t.cast(v)); }  // validates on store
<T> T get(Class<T> t) { return t.cast(favorites.get(t)); }      // typesafe on read
```
- **Exceptions:** For generic keys use a super type token (Gafter's idiom) or Guava `TypeToken`. Overkill when the container genuinely holds one type - just parameterize the container normally.

## Enums and Annotations

### EJ34. Enums over int constants  [enums] · high
- **Rule:** Model a fixed set of related constants as an `enum`, never as `public static final int` (or `String`) constants.
- **Why:** Int constants are not type-safe (`setSeason(Planet.MARS)` compiles against an int parameter), have no namespace (so every group needs a shared prefix), and print as meaningless numbers in logs and debuggers. Enums are full classes with their own namespace, compile-time type checking, useful `toString`, and the ability to carry data and behavior. A subtle failure with int constants is that they are inlined into client bytecode at compile time, so renumbering the source silently corrupts every client that wasn't recompiled.
- **Smell:** a cluster of `static final int` / `static final String` with a shared name prefix, or a method parameter typed `int` that only accepts a handful of blessed values.
- **Signal:**
```java
// bad
public static final int SEASON_SPRING = 0;
public static final int SEASON_SUMMER = 1;
void plant(int season) { ... }   // plant(SEASON_SUMMER) — or plant(42), also compiles

// good
public enum Season { SPRING, SUMMER, FALL, WINTER }
void plant(Season season) { ... }
// modern: an exhaustive switch expression needs no default and fails to compile
// when a new constant is added (Java 21 pattern switch; Java 14+ arrow switch)
int daysToHarvest = switch (season) {
    case SPRING, SUMMER -> 90;
    case FALL, WINTER   -> 120;
};
```
- **Exceptions:** interop boundaries you don't control (a wire protocol, JNI, or a legacy DB column) may force an int representation — map it to an enum at the boundary via a lookup, don't leak the int inward.

### EJ35. Instance fields not ordinals  [enums] · medium
- **Rule:** Never derive an enum's associated value from `ordinal()`; store the value in a `final` instance field set from the constructor.
- **Why:** `ordinal()` returns the declaration position, an implementation detail meant only for `EnumSet`/`EnumMap`. Coupling semantics to it means reordering constants silently changes values, you cannot add a constant in the middle, and you cannot give two constants the same associated value. A field is explicit, order-independent, and survives refactoring the declaration order. This is the same "don't encode meaning in position" instinct as avoiding magic array indices.
- **Smell:** `ordinal()` appearing anywhere outside an `EnumSet`/`EnumMap` construction, especially `ordinal() + 1` or `values()[i]` arithmetic.
- **Signal:**
```java
// bad
enum Planet {
    MERCURY, VENUS, EARTH;
    int position() { return ordinal() + 1; }   // reorder → wrong position
}
// good
enum Planet {
    MERCURY(1), VENUS(2), EARTH(3);
    private final int position;
    Planet(int position) { this.position = position; }
    int position() { return position; }
}
```
- **Exceptions:** none for associated values. `ordinal()` is legitimate only as the internal index for `EnumSet`/`EnumMap`, which is exactly why those types exist — so you never write the arithmetic yourself.

### EJ36. EnumSet over bit fields  [enums] · medium
- **Rule:** Represent a set of enum values with `EnumSet`, not an OR-ed together bit field of int constants.
- **Why:** Bit fields (`1 << 0`, `1 << 1`, ...) reintroduce every int-constant problem plus new ones: the union prints as an inscrutable integer, there is no way to iterate the members, and you silently cap the set at 32 or 64 elements. `EnumSet` is internally a single `long` (or long array) bit vector, so it is as fast as hand-rolled bit twiddling, while presenting a type-safe `Set<E>` API with iteration, `contains`, and a readable `toString`.
- **Smell:** `int flags`, `1 << n` constants, `flags & MASK`, or `flags |= X` for anything that is conceptually a set of named options.
- **Signal:**
```java
// bad
public static final int STYLE_BOLD      = 1 << 0;
public static final int STYLE_ITALIC    = 1 << 1;
public void applyStyles(int styles) { ... }   // applyStyles(BOLD | ITALIC)

// good
public enum Style { BOLD, ITALIC, UNDERLINE, STRIKETHROUGH }
public void applyStyles(Set<Style> styles) { ... }   // take Set, not EnumSet, for flexibility
applyStyles(EnumSet.of(Style.BOLD, Style.ITALIC));
```
- **Exceptions:** the one real gap is that there is no immutable `EnumSet` in the JDK; wrap with `Collections.unmodifiableSet` (or copy via `Set.copyOf`, which loses the `EnumSet` performance profile) when you must hand out a read-only view.

### EJ37. EnumMap over ordinal arrays  [enums] · medium
- **Rule:** Index data by an enum using `EnumMap<K extends Enum<K>, V>`, not an array indexed by `key.ordinal()`.
- **Why:** An `ordinal()`-indexed array forces an unchecked generic-array cast, gives no compile-time guarantee the index matches the array length, and breaks the instant constants are reordered or added. `EnumMap` uses the ordinal internally for array-speed access but exposes a type-safe `Map` whose keys print readably and whose iteration order matches the enum's natural (declaration) order. It's the map analog of EnumSet.
- **Smell:** `new Set[Enum.values().length]`, `array[key.ordinal()]`, or `(Set<X>[]) new Set[...]` with a suppressed unchecked warning.
- **Signal:**
```java
// bad
Set<Plant>[] byCycle = (Set<Plant>[]) new Set[LifeCycle.values().length];
for (int i = 0; i < byCycle.length; i++) byCycle[i] = new HashSet<>();
byCycle[p.lifeCycle.ordinal()].add(p);

// good
Map<LifeCycle, Set<Plant>> byCycle = new EnumMap<>(LifeCycle.class);
for (LifeCycle lc : LifeCycle.values()) byCycle.put(lc, new HashSet<>());
byCycle.get(p.lifeCycle).add(p);
// modern: build it directly with a stream, supplying the EnumMap factory
Map<LifeCycle, List<Plant>> m = plants.stream()
    .collect(Collectors.groupingBy(p -> p.lifeCycle,
             () -> new EnumMap<>(LifeCycle.class), Collectors.toList()));
```
- **Exceptions:** for a two-dimensional enum-to-enum mapping a nested `EnumMap` is still preferred over a 2-D ordinal array; drop to arrays only in a profiled hot path where the map's object overhead is proven to matter.

### EJ38. Extensible enums via interfaces  [enums] · low
- **Rule:** When you need an "extensible enum," have the enum implement a shared interface and program clients against the interface, since enums themselves cannot be subclassed.
- **Why:** Language enums are implicitly `final`, so you cannot add constants to one from another module. The workaround is an interface that defines the operation contract; multiple independent enums implement it, and callers accept the interface type (often as `<T extends Enum<T> & Operation>`). The subtle limitation people miss: implementations cannot inherit shared code from each other, so any common logic must live in a helper class or a default method, not a shared base enum.
- **Smell:** `extends SomeEnum` (a compile error people try anyway), or a giant single enum that different teams keep appending unrelated constants to because "there's nowhere else to put them."
- **Signal:**
```java
// bad — impossible; enums are final
enum ExtendedOp extends BasicOperation { EXP, REMAINDER }

// good
public interface Operation { double apply(double x, double y); }
public enum BasicOperation implements Operation {
    PLUS  { public double apply(double x, double y) { return x + y; } },
    MINUS { public double apply(double x, double y) { return x - y; } };
}
public enum ExtendedOperation implements Operation {
    EXP { public double apply(double x, double y) { return Math.pow(x, y); } };
}
// client accepts any Operation-implementing enum
static <T extends Enum<T> & Operation> void test(Class<T> opType, double x, double y) { ... }
```
- **Exceptions:** if the constant set is genuinely closed, don't add an interface for hypothetical extension — a plain enum is simpler. For an open hierarchy that also needs shared state/implementation, a sealed interface with record/class implementations (EJ23, Java 17+) may fit better than the enum-per-implementer pattern.

### EJ39. Annotations over naming patterns  [enums] · low
- **Rule:** Signal metadata (tests, lifecycle hooks, serialization intent) with annotations, not by encoding it in method or field names.
- **Why:** A naming convention like a `test` prefix is invisible to the compiler: a typo (`tsetFoo`) is silently skipped, the pattern can't carry parameters (which exception a test expects, a timeout), and it can't be restricted to the right program element. Annotations are compiler-checked, targetable via `@Target`, and can carry typed parameters. This is why every modern testing and DI framework (JUnit 5, Jakarta) is fully annotation-driven — the fragile name-scanning era is over.
- **Smell:** reflection that does `method.getName().startsWith(...)`, or documentation that says "name your method X so the framework finds it."
- **Signal:**
```java
// bad
public void testDivideByZero() { ... }   // typo "tset..." → silently never runs

// good
@Retention(RUNTIME) @Target(METHOD)
public @interface ExceptionTest { Class<? extends Throwable> value(); }

@ExceptionTest(ArithmeticException.class)
public void divideByZero() { ... }        // typed parameter, compiler-checked target
```
- **Exceptions:** annotations you define are worthwhile only when something (a framework, an annotation processor, or your own reflection) actually consumes them; don't invent an annotation that nothing reads. Genuinely dynamic, data-driven test generation may still be programmatic (e.g. JUnit `@TestFactory`) rather than annotation-per-case.

### EJ40. @Override consistently  [enums] · high
- **Rule:** Put `@Override` on every method that is intended to override a supertype declaration.
- **Why:** The compiler verifies an `@Override` method actually overrides something; without it, a signature mismatch silently becomes an unrelated overload that never runs. The classic trap is `equals`: writing `equals(MyType)` instead of `equals(Object)` compiles fine, self-consistent unit tests may even pass, but collections invoke `Object.equals` and get reference identity — producing duplicate keys and lost lookups that surface far from the bug. `@Override` turns that into a compile error at the definition site.
- **Smell:** an overriding method with no `@Override`; any `equals`, `hashCode`, `compareTo`, or `toString` whose parameter is a concrete type rather than the supertype's declared type.
- **Signal:**
```java
// bad — overloads Object.equals; HashSet sees two "equal" bigrams as distinct
public boolean equals(Bigram b) { return b.first == first && b.second == second; }

// good — compiler confirms it overrides; wrong signature fails to compile
@Override public boolean equals(Object o) {
    if (!(o instanceof Bigram b)) return false;   // pattern instanceof, Java 16+
    return b.first == first && b.second == second;
}
```
- **Exceptions:** strictly optional (though harmless and IDE-recommended) on a concrete class implementing an abstract method, because failing to implement it is already a compile error. Apply it everywhere anyway for uniformity — modern IDEs and linters flag the missing annotation.

### EJ41. Marker interfaces  [enums] · low
- **Rule:** Mark a type-level capability with a marker interface (no methods) rather than a marker annotation when the mark should participate in the type system.
- **Why:** A marker interface defines a real type, so the compiler can enforce it: a method can require `<T extends Serializable>` and reject unmarked arguments at compile time, whereas a marker annotation's presence is only checkable at runtime via reflection. Marker interfaces are also more precise in scope — implementing one applies only to that class and its subtypes, and you can narrow the marker by extending a specific base interface. The subtle miss: people reach for a marker annotation out of habit and thereby forfeit compile-time checking for something that is fundamentally a type property.
- **Smell:** a zero-element `@interface` whose only job is to tag a class, used in code that then does `getClass().isAnnotationPresent(...)` to decide behavior that could have been a static type constraint.
- **Signal:**
```java
// bad — presence only observable at runtime; no compile-time guarantee
@Retention(RUNTIME) @Target(TYPE) public @interface Persistable {}
void store(Object o) { if (!o.getClass().isAnnotationPresent(Persistable.class)) throw ...; }

// good — a type the compiler enforces at the call site
public interface Persistable {}                 // marker interface, no methods
<T extends Persistable> void store(T o) { ... } // non-Persistable arg won't compile
```
- **Exceptions:** prefer a marker annotation when the marker must apply to program elements other than types (methods, fields, parameters), when the codebase is already annotation-heavy and consistency matters, or when the framework only inspects markers reflectively anyway. Also favor an annotation if you may later add parameters — an interface can't grow attributes.

## Lambdas and Streams

### EJ42. Lambdas over anonymous classes  [lambdas] · medium
- **Rule:** Instantiate a functional interface with a lambda, not an anonymous class.
- **Why:** A lambda expresses the one abstract method directly with no boilerplate, so intent survives the read. The trap is scope: inside a lambda `this` refers to the *enclosing* instance, whereas inside an anonymous class `this` refers to the anonymous instance itself, so mechanically converting one to the other can silently rebind `this`. Lambdas also have no name, no way to reference themselves, and don't serialize reliably; a lambda longer than a few lines becomes unreadable and should be extracted to a named method. Lambdas only work for interfaces with a single abstract method.
- **Smell:** `new Comparator<>() { public int compare(...) { ... } }` or any anonymous class implementing a one-method interface; also a lambda body spanning many lines.
- **Signal:**
```java
// bad
Collections.sort(words, new Comparator<String>() {
    public int compare(String a, String b) { return Integer.compare(a.length(), b.length()); }
});
// good
words.sort(Comparator.comparingInt(String::length));
```
- **Exceptions:** Interfaces with multiple abstract methods, abstract classes, code that needs `this` to mean the created instance, or bodies long enough that a named method reads better. Modern note: for immutable data carriers reach for records (EJ17) rather than anonymous classes.

### EJ43. Method references over lambdas  [lambdas] · low
- **Rule:** Prefer a method reference wherever it is as clear as, or clearer than, the equivalent lambda.
- **Why:** When a lambda does nothing but forward its parameters to an existing method, the reference (`Class::method`) removes parameter noise and names the operation. The five kinds - static, bound instance, unbound instance, constructor (`Foo::new`), and array constructor (`int[]::new`) - cover most delegation. The subtlety: a reference is not automatically clearer. When parameters carry meaning the reader needs, or the target method lives in the current class with a long name, the inlined lambda documents intent better.
- **Smell:** `x -> Integer.parseInt(x)`, `s -> s.length()`, or `(a, b) -> a + b` where `Integer::sum` exists.
- **Signal:**
```java
// bad
map.merge(key, 1, (count, incr) -> count + incr);
// good
map.merge(key, 1, Integer::sum);
```
- **Exceptions:** When the enclosing class or method name is long and unwieldy, when the lambda does more than delegate, or when a same-class helper reference reads worse than just inlining the body. `GoshThisClassNameIsHumongous::action` vs `() -> action()` favors the lambda.

### EJ44. Standard functional interfaces  [lambdas] · medium
- **Rule:** Use the `java.util.function` interfaces instead of declaring your own functional interface.
- **Why:** The 43 standard interfaces - built on the six basic shapes `UnaryOperator`, `BinaryOperator`, `Predicate`, `Function`, `Supplier`, `Consumer` - are already understood by every reader and by the JDK's own APIs. The performance trap is boxing: `Function<Integer, Integer>` autoboxes on every call, so in hot paths use the primitive specializations (`IntUnaryOperator`, `IntPredicate`, `ToLongFunction`, etc.). Write a custom interface only when none fits *and* it earns its keep with a self-documenting name, a shared contract, or useful default methods - and always annotate it `@FunctionalInterface`.
- **Smell:** A hand-rolled single-abstract-method interface that duplicates a standard one; `Function<Integer, Integer>` in a tight loop where `IntUnaryOperator` avoids boxing.
- **Signal:**
```java
// bad
@FunctionalInterface interface StringProcessor { String process(String s); } // == Function<String,String>
// good
Function<String, String> processor = String::strip;
```
- **Exceptions:** When the interface deserves a descriptive name and strong contract (as `Comparator` does), will have many implementations exercising the type, or needs default methods the standard interfaces lack.

### EJ45. Streams judiciously  [lambdas] · medium
- **Rule:** Use streams for transform/filter/aggregate pipelines, but keep an ordinary loop where it reads more clearly.
- **Why:** Streams are ideal for expressing a computation as a sequence of transformations, but a pipeline is not automatically better than a loop and overuse harms readability. The hard limits people forget: a lambda can only read *effectively final* locals (it cannot mutate an enclosing local), cannot `break`/`continue`/`return` out of the enclosing method, and cannot cleanly propagate checked exceptions - all of which a loop does natively. `char` streams are a specific trap because `String.chars()` yields an `IntStream`, so printing elements shows codepoints, not characters.
- **Smell:** Deeply nested stream pipelines; forcing stateful/early-exit logic into a stream; try/catch wrapping every `map` lambda; `"abc".chars()` treated as characters.
- **Signal:**
```java
// bad
"abc".chars().forEach(System.out::print); // prints 979899
// good
"abc".chars().forEach(c -> System.out.print((char) c)); // or just a for-each loop over the chars
```
- **Exceptions:** Use a loop when you need mutable locals, early exit, checked-exception propagation, or simultaneous access to several stages' variables. Modern note: switch expressions and pattern matching often replace a stream's `map` chain with clearer branching.

### EJ46. Side-effect-free stream functions  [lambdas] · high
- **Rule:** Keep the functions passed to stream operations pure and accumulate results with collectors, not by mutating state in `forEach`.
- **Why:** A stream pipeline is meant to express computation as pure transformations; a `forEach` that mutates external state (appending to a list, bumping a counter, filling a map) reads as procedural code wearing a stream costume and is the single most common stream anti-pattern. It is also a correctness bug: such side effects are not thread-safe, so the pipeline breaks or silently corrupts the moment anyone adds `.parallel()`. Use `Collectors` - `toList`, `toMap`, `groupingBy`, `counting`, `joining` - which are designed to be safe and associative. `forEach` should *report* the result of a computation, never *perform* it.
- **Smell:** `stream.forEach(e -> list.add(e))`, `forEach` incrementing an external counter or `map.put`-ing; a reduce/merge function that is non-associative or reads shared state.
- **Signal:**
```java
// bad
Map<String, Long> freq = new HashMap<>();
words.forEach(w -> freq.merge(w, 1L, Long::sum));
// good
Map<String, Long> freq = words.stream()
    .collect(Collectors.groupingBy(w -> w, Collectors.counting()));
```
- **Exceptions:** `forEach` is legitimate for a genuine terminal side effect on an already-computed result - printing, logging, writing each element. Use `forEachOrdered` when encounter order must be preserved.

### EJ47. Collection over Stream as return type  [lambdas] · medium
- **Rule:** Return `Collection` (or an appropriate subtype) from a sequence-returning method rather than a bare `Stream`.
- **Why:** `Stream` does not extend `Iterable`, so a caller who wants a plain `for-each` over a returned stream must write the ugly `for (T x : (Iterable<T>) stream::iterator)` cast. A `Collection` gives callers both iteration *and* `stream()`, letting each caller pick the idiom; returning `Stream` unilaterally forces every caller into the stream world and breaks the most common loop. The subtlety for large results: don't materialize a giant list just to satisfy this - back it with a purpose-built `AbstractList` (e.g. the power set indexed by a bitmask) so the collection is cheap.
- **Smell:** A public general-purpose method returning `Stream<T>`; callers wrapping the returned stream in a cast just to iterate.
- **Signal:**
```java
// bad
public Stream<Suit> suits() { return Arrays.stream(Suit.values()); }
// good
public Collection<Suit> suits() { return List.of(Suit.values()); }
```
- **Exceptions:** Return `Stream` (or `Iterable`) when the sequence is lazy or infinite, when materializing a `Collection` would exceed memory or exceed `Integer.MAX_VALUE` elements, or when the API is explicitly stream-oriented and no caller will iterate.

### EJ48. Parallel streams carefully  [lambdas] · high
- **Rule:** Do not call `parallel()` unless a benchmark shows a real speedup on an efficiently splittable source with substantial independent per-element work.
- **Why:** Parallelizing a stream rarely helps and frequently hurts, corrupts, or hangs. Sources split well only when the runtime can cheaply divide and estimate them - `ArrayList`, arrays, `IntStream.range`, `HashMap`, `ConcurrentHashMap`; `Stream.iterate` and any pipeline with `limit` split badly and even do speculative extra work that wastes cores. Worse, a parallel stream with a non-associative reducer, a stateful lambda, or shared mutable state produces wrong answers *silently* (a safety failure), and misbehaving pipelines can degrade the shared common ForkJoinPool for the entire JVM. Parallelism only pays when elements times per-element cost is large (rule of thumb: ~100,000 units of work).
- **Smell:** `.parallel()` added speculatively; parallel streams over `Stream.iterate`, over small collections, or combined with side-effecting/order-dependent operations.
- **Signal:**
```java
// bad
Stream.iterate(TWO, BigInteger::nextProbablePrime).parallel()
      .limit(n).filter(...).count(); // iterate + limit: no speedup, may hang
// good
IntStream.rangeClosed(1, n).parallel().mapToObj(...).reduce(...); // splittable range, associative reduce, benchmarked
```
- **Exceptions:** Large arrays / `ArrayList` / `IntStream.range` with heavy, independent, associative per-element work, confirmed faster by measurement; `SplittableRandom`-driven Monte-Carlo-style workloads.

## Methods

### EJ49. Validate parameters  [methods] · high
- **Rule:** Check every parameter's constraints at the top of a public or protected method and throw before any state is read or stored.
- **Why:** An unchecked bad argument either fails deep inside with a confusing exception or silently corrupts an object that detonates as an unrelated failure much later. Failing fast at the boundary localizes the bug to the offending caller. The failure people miss: storing an unvalidated argument in a field (constructor, setter) so the corruption surfaces on a later method call, long after that caller left the stack.
- **Smell:** a public method that dereferences or stores a parameter with no `Objects.requireNonNull` or range check; a constructor assigning `this.x = x` directly.
- **Signal:**
```java
// bad
public Rational(int num, int denom) {
    this.num = num;
    this.denom = denom; // denom == 0 detonates later, inside equals/hashCode
}
// good
public Rational(int num, int denom) {
    if (denom == 0) throw new IllegalArgumentException("denom == 0");
    this.num = num;
    this.denom = denom;
}
```
- **Exceptions:** Skip when the check is expensive and validation happens implicitly anyway (a computation that would itself throw on the bad value), or on private/package methods where you control all callers and can use `assert`. In records, put the checks in the compact canonical constructor, which runs before field assignment.

### EJ50. Defensive copies  [methods] · high
- **Rule:** Copy mutable constructor and setter arguments before storing them, and copy mutable fields before returning them.
- **Why:** If you store a caller's mutable object directly, the caller keeps a reference and can mutate your internals after construction, breaking invariants you already validated. The subtle bug: validate-then-copy is a time-of-check/time-of-use hole - copy first, then validate the copy, because another thread can mutate the argument between the check and the assignment. Records do NOT copy for you; a record holding a `Date`, array, or `List` leaks exactly like a hand-written class unless the compact constructor and accessors copy.
- **Smell:** `this.date = date` / `this.list = list` where the type is mutable; a getter returning a mutable field directly (`return this.date;`).
- **Signal:**
```java
// bad
public Period(Date start, Date end) {
    this.start = start; // caller keeps the ref and mutates it later
    this.end = end;
}
public Date start() { return start; } // leaks the internal object
// good
public Period(Date start, Date end) {
    this.start = new Date(start.getTime()); // copy FIRST
    this.end = new Date(end.getTime());
    if (this.start.compareTo(this.end) > 0) // validate the copy
        throw new IllegalArgumentException(start + " after " + end);
}
public Date start() { return new Date(start.getTime()); }
```
- **Exceptions:** Not needed when the field type is immutable - prefer `java.time` (`Instant`, `LocalDate`), `String`, or boxed primitives over `Date`, and the problem disappears entirely. Also skip when the class documents that the caller transfers ownership (same-package, trusted contract).

### EJ51. Method signature design  [methods] · medium
- **Rule:** Keep parameter lists short (aim for three or fewer), avoid long runs of same-typed parameters, and favor interfaces and enums over concrete classes and booleans.
- **Why:** Long lists - especially adjacent same-typed ones - let callers transpose arguments silently; the compiler cannot catch `copy(dest, src)` invoked as `copy(src, dest)`. A boolean parameter reads as `foo(true)` at the call site with no hint what `true` means. The miss: reaching for more overloads instead of a parameter object or helper, which multiplies the surface without cutting the confusion.
- **Smell:** a method with 4+ params; two or more consecutive params of the same type; a `boolean` flag parameter; a parameter typed `ArrayList`/`HashMap` instead of `List`/`Map`.
- **Signal:**
```java
// bad
Room newRoom(double width, double length, double height, boolean heated) { ... }
newRoom(4, 3, 2, true); // which dimension is which? what does true mean?
// good
Room newRoom(Dimensions d, HeatingMode mode) { ... } // param object + enum
newRoom(new Dimensions(4, 3, 2), HeatingMode.HEATED);
```
- **Exceptions:** Three-plus parameters are fine when they are distinct types in an obvious order. A two-value enum can be overkill for a genuinely internal helper. Once optional parameters proliferate, a builder (EJ2) supersedes this guidance.

### EJ52. Overloading is resolved at compile time  [methods] · medium
- **Rule:** Never export two overloads with the same parameter count that a caller could reach ambiguously; remember that overload selection binds to the static type, not the runtime type.
- **Why:** Which overload runs is fixed at compile time by the declared type of the argument, unlike overriding, which dispatches on the runtime type. So a `print(Collection)`/`print(List)` pair called through a `Collection` reference always picks `print(Collection)`, even for a `List` object - surprising everyone who expects polymorphism. The miss: adding an overload that "helpfully" narrows a type silently rebinds existing call sites.
- **Smell:** two overloads with identical arity whose parameter types are in a subtype relationship (`List`/`Collection`, `int`/`Integer`); an overload set where you have to stop and think about which one runs.
- **Signal:**
```java
// bad
void print(Collection<?> c) { ... }
void print(List<?> c)       { ... } // never chosen via a Collection reference
// good
void print(Collection<?> c) {                 // one method, branch on runtime type
    if (c instanceof List<?> list) { ... }     // pattern matching, JDK 16+
    else { ... }
}
```
- **Exceptions:** Safe when you keep the same arity but make the overloads behave identically - e.g. the more specific one forwards to the more general. Also safe when the types are radically different with no subtype or autobox relation (`(int)` vs `(String)`). The autobox trap `List.remove(int)` vs `remove(Object)` is the classic footgun.

### EJ53. Varargs carefully  [methods] · low
- **Rule:** Use varargs only for genuinely variable arity, and when at least one argument is required, take that one as an explicit leading parameter.
- **Why:** Every varargs call allocates and initializes a fresh array, so it is wrong for hot paths, and a "must have one argument" contract enforced by checking `args.length == 0` at runtime is a bug that should have been a compile error. The miss: `min(int... args)` accepts zero arguments and throws at runtime; `min(int first, int... rest)` makes the empty call uncompilable.
- **Smell:** a varargs method whose body opens with `if (args.length == 0) throw ...`; varargs on a method called in a tight loop.
- **Signal:**
```java
// bad
static int min(int... args) {
    if (args.length == 0) throw new IllegalArgumentException("need 1+ args");
    ...
}
// good
static int min(int first, int... rest) { ... } // an empty call won't compile
```
- **Exceptions:** For performance-critical APIs where most calls pass few args, provide fixed-arity overloads for 0..k args plus one varargs catch-all (as `EnumSet.of` does). Generic varargs require `@SafeVarargs` (EJ32); the JDK's `List.of`/`Map.of` use exactly this fixed-overloads-plus-varargs pattern.

### EJ54. Return empty not null  [methods] · medium
- **Rule:** Return an empty collection or array rather than `null` from methods that produce zero results.
- **Why:** A `null` return forces every caller to remember a special-case check, and the one caller who forgets ships an NPE that fires only when the result set happens to be empty - often long after release. Returning empty lets callers iterate unconditionally. The miss: fearing the allocation of an empty collection - there is none if you return the shared immutable `Collections.emptyList()` or a zero-length array constant.
- **Smell:** `return null;` in a method whose declared return type is a collection, array, `List`/`Set`/`Map`; a caller guarding a returned collection with `if (result != null)`.
- **Signal:**
```java
// bad
public List<Cheese> cheeses() {
    return inventory.isEmpty() ? null : new ArrayList<>(inventory);
}
// good
public List<Cheese> cheeses() {
    return new ArrayList<>(inventory); // empty list when empty; or List.copyOf(inventory)
}
```
- **Exceptions:** None for collections and arrays. For a scalar "maybe absent" result, express absence with `Optional<T>` (EJ55) rather than either `null` or a single-element container.

### EJ55. Optional judiciously  [methods] · medium
- **Rule:** Use `Optional<T>` as a return type to signal "possibly no result"; never use it for fields, method parameters, collection elements, or map values.
- **Why:** `Optional` states absence in the type system and pushes the caller to handle it (`orElse`, `orElseThrow`, `ifPresent`), which is its entire value at a return boundary. But an `Optional` is a heap-allocated wrapper with its own indirection, so nesting it in collections or fields adds cost and a second axis of emptiness (an `Optional` that is itself null). The miss: `Optional.of(x)` throws NPE when `x` may be null - use `Optional.ofNullable`; and boxing an `int` as `Optional<Integer>` when `OptionalInt` exists.
- **Smell:** a field, parameter, `Map` value, or `List` element typed `Optional<...>`; `Optional.of(possiblyNull)`; `opt.get()` with no prior `isPresent`/`isEmpty` guard.
- **Signal:**
```java
// bad
private Optional<String> name;      // field
Optional<Integer> max(...)          // boxes the int
return Optional.of(lookup());       // NPE if lookup() returns null
// good
public Optional<String> findName(...) { return Optional.ofNullable(lookup()); }
OptionalInt max(...)                // no boxing
```
- **Exceptions:** On a performance-critical path where the wrapper allocation matters, a documented `null` or a sentinel can win. Don't wrap collection returns in `Optional` - return an empty collection (EJ54). Use `OptionalInt`/`OptionalLong`/`OptionalDouble` for primitive results.

### EJ56. Write documentation  [methods] · medium
- **Rule:** Write a Javadoc comment for every exported class, interface, method, and field, stating the contract precisely - preconditions, postconditions, thrown exceptions, and side effects.
- **Why:** The doc comment is the API contract; without it callers reverse-engineer behavior from source they may not have, or from trial and error, and refactors silently break undocumented assumptions. The miss: documenting *how* instead of *what* - a method comment describes the contract between method and client, not the implementation, so you can rewrite the body without invalidating the docs. Document thread safety (EJ82) explicitly; silence reads as "not thread-safe" to careful callers and "probably fine" to careless ones.
- **Smell:** a public method with no `/** */`; a comment that merely restates the method name; a missing `@param`/`@return`/`@throws` for a parameter, non-void return, or declared exception; prose describing the algorithm instead of the contract.
- **Signal:**
```java
// bad
/** Gets the element. */
public E get(int index) { ... }
// good
/**
 * Returns the element at the specified position in this list.
 * @param index index of the element, {@code 0 <= index < size()}
 * @return the element at {@code index}
 * @throws IndexOutOfBoundsException if the index is out of range
 */
public E get(int index) { ... }
```
- **Exceptions:** Trivial private helpers don't need full Javadoc. Modern Java: use the `{@snippet}` tag (JDK 18+) for compilable code samples instead of `<pre>{@code}`, and Markdown doc comments with `///` (JDK 23+, JEP 467) for readability.

## General Programming

### EJ57. Minimize the Scope of Local Variables  [general] · medium
- **Rule:** Declare each local variable at the point of first use and initialize it there, never earlier.
- **Why:** A variable declared before it is needed widens the window in which it can be misread, reused, or left in a stale intermediate state, and a declaration without an initializer signals that logic to compute the value has not been reached yet. Loop variables scoped to the loop (`for`/for-each) can't leak into code that runs after the loop, so the compiler catches accidental reuse. The classic bug is copy-pasting a `for (Iterator i = ...)` loop and forgetting to rename the iterator in the second copy - a for-each or index scoped to each loop makes that a compile error instead of a silent skip.
- **Smell:** A block of `int x; String y; List z;` declarations at the top of a method; a loop index or iterator referenced after its loop; a variable initialized to a dummy value (`null`, `-1`) far above where it's really assigned.
- **Signal:**
```java
// bad
Iterator<Element> i = c.iterator();
while (i.hasNext()) { doSomething(i.next()); }
Iterator<Element> i2 = c2.iterator();
while (i.hasNext()) { doSomethingElse(i2.next()); } // uses stale i, silent bug

// good
for (Element e : c) doSomething(e);
for (Element e : c2) doSomethingElse(e);
```
- **Exceptions:** A variable whose value is set inside a `try` block but used after it must be declared before the `try`. A variable holding an expensive result reused across iterations (e.g. a hoisted `list.size()` bound) is legitimately declared once before the loop.

### EJ58. Prefer for-each to Traditional for Loops  [general] · medium
- **Rule:** Use the enhanced for (for-each) loop for iterating over collections and arrays unless you need the index, the iterator, or to replace/remove elements.
- **Why:** The traditional indexed or iterator loop exposes the index/iterator, which is pure boilerplate that offers only opportunities for error: an off-by-one, a wrong iterator advanced in a nested loop, or an index used against the wrong collection. for-each eliminates the counter entirely and works identically across arrays, collections, and anything implementing `Iterable`. The subtle nested-loop bug (calling `i.next()` in the outer loop body when you meant `j.next()`) simply cannot be written with for-each.
- **Smell:** `for (int i = 0; i < list.size(); i++) list.get(i)`; `for (Iterator it = ...; it.hasNext(); )` where the body only calls `it.next()` once and never `it.remove()`.
- **Signal:**
```java
// bad
for (int i = 0; i < suits.length; i++)
    for (int j = 0; j < ranks.length; j++)
        deck.add(new Card(suits[i], ranks[j]));

// good
for (Suit suit : suits)
    for (Rank rank : ranks)
        deck.add(new Card(suit, rank));
```
- **Exceptions:** You cannot use for-each when you need to remove elements (use `Iterator.remove` or `Collection.removeIf`), replace elements by index, or iterate multiple collections in lockstep. Parallel iteration over two arrays by index is one such case.

### EJ59. Know and Use the Libraries  [general] · high
- **Rule:** Reach for the standard library (and well-established third-party ones) before writing your own algorithm.
- **Why:** Library code is written by experts, reviewed by the community, and hardened over years across edge cases you will not think of. The canonical trap is a hand-rolled random-number routine: `Math.abs(rnd.nextInt()) % n` is subtly non-uniform and returns a negative number when `nextInt()` returns `Integer.MIN_VALUE` (because `Math.abs(MIN_VALUE)` is still negative). `ThreadLocalRandom.current().nextInt(n)` is correct, uniform, and faster. Beyond correctness, you inherit performance improvements and new features for free on each JDK release.
- **Smell:** Hand-written shuffle, binary search, gcd, `%`-based bounded random, manual UTF-8 decoding, or a bespoke `readAllBytes` loop; any `while` loop that re-implements something in `java.util`, `java.nio.file`, `Collections`, `Arrays`, or `Objects`.
- **Signal:**
```java
// bad
int random(int n) { return Math.abs(rnd.nextInt()) % n; } // biased + can be negative

// good
int random(int n) { return ThreadLocalRandom.current().nextInt(n); }
// files: Files.readString(path), Files.readAllLines(path) over manual reader loops
```
- **Exceptions:** None for well-covered functionality; write your own only when no library provides it, or when profiling proves the library version is a real bottleneck for your specific workload.

### EJ60. Avoid float and double Where Exact Answers Are Required  [general] · high
- **Rule:** Use `BigDecimal`, `int`, or `long` for monetary and other calculations that require exact decimal results, never `float`/`double`.
- **Why:** Binary floating point cannot represent most decimal fractions (0.1, 0.01) exactly, so errors accumulate: `1.03 - 0.42` yields `0.6100000000000001`, and a naive "buy candy until broke" loop reports the wrong count and wrong change. `BigDecimal` gives exact decimal arithmetic and lets you set rounding explicitly, but is slower and clunkier; scaling to the smallest unit (integer cents) with `int`/`long` is faster and simpler when you can track scale yourself. Construct `BigDecimal` from a `String` (`new BigDecimal("0.1")`), never from a `double`, or you re-introduce the binary error you were avoiding.
- **Smell:** `double price`, `float balance`, money fields typed as floating point; `new BigDecimal(0.1)` (double constructor); comparing FP values with `==`.
- **Signal:**
```java
// bad
double funds = 1.00;
for (double price = 0.10; funds >= price; price += 0.10) { funds -= price; ... } // wrong count

// good
long funds = 100; // cents
for (long price = 10; funds >= price; price += 10) { funds -= price; ... }
// or BigDecimal with new BigDecimal("0.10") and setScale/RoundingMode
```
- **Exceptions:** Scientific and engineering computations that tolerate approximation and prioritize speed legitimately use `double`. Any code where the inherent inexactness is acceptable and performance matters.

### EJ61. Prefer Primitive Types to Boxed Primitives  [general] · high
- **Rule:** Use primitives (`int`, `long`, `boolean`, `double`) rather than their boxed counterparts unless you genuinely need an object (collections, generics, nullability).
- **Why:** Boxed primitives introduce three hazards that primitives don't have. First, `==` on boxed values compares object identity, not value, so two `Integer`s holding `42` may be unequal - always `.equals` or unbox. Second, mixing a boxed and a primitive in an operation auto-unboxes the box, so a `null` box throws `NullPointerException` at a line that looks like plain arithmetic. Third, autoboxing in a loop silently allocates an object per iteration; a mistyped accumulator (`Long sum` instead of `long sum`) can box billions of times and run orders of magnitude slower.
- **Smell:** `Integer`/`Long`/`Boolean` used as a local counter or accumulator; `==` between two wrapper objects; a wrapper field with no reason to be nullable; a `Long sum = 0L` accumulating in a hot loop.
- **Signal:**
```java
// bad
Long sum = 0L;
for (long i = 0; i < Integer.MAX_VALUE; i++) sum += i; // boxes every iteration

Comparator<Integer> c = (a, b) -> a > b ? 1 : (a == b ? 0 : -1); // == compares identity

// good
long sum = 0L;
for (long i = 0; i < Integer.MAX_VALUE; i++) sum += i;

Comparator<Integer> c = Integer::compare; // or Comparator.naturalOrder()
```
- **Exceptions:** Boxed types are required as type parameters (`List<Integer>`, `Map<K, Integer>`), as keys/values in collections, and when a value must legitimately be `null` to signal absence.

### EJ62. Avoid Strings Where Other Types Are More Appropriate  [general] · medium
- **Rule:** Don't use `String` to model values that have a proper type - enums, aggregates, capabilities, or numeric quantities.
- **Why:** Strings are a poor substitute for structured data: they defeat the compiler's type checking, so a wrong value is caught only at runtime if at all. Parsing a "compound" string like `"className#fieldName"` with `split` is slow, fragile, and breaks if the data contains the separator. A "capability" modeled as a string key (e.g. a thread-local keyed by a client-chosen name) can be forged or collided by any other code that guesses the same string. Each of these has a real type - an enum, a small class, or an unforgeable key object - that makes illegal states unrepresentable.
- **Smell:** An enum-shaped set of values stored as `String` and compared with `.equals`; `String.split("#")` to unpack fields; a `Map<String, ?>` used as a namespace where the string is really a capability/identity.
- **Signal:**
```java
// bad
String status = "ACTIVE"; // stringly-typed; typo "ACTIV" compiles fine

// good
enum Status { ACTIVE, SUSPENDED, CLOSED }
Status status = Status.ACTIVE;
```
- **Exceptions:** Genuinely free-form textual input (names, descriptions, log messages) is correctly a `String`. Data that is fundamentally text at the boundary and only later parsed is fine as a string until you give it structure.

### EJ63. Beware the Performance of String Concatenation  [general] · medium
- **Rule:** Use `StringBuilder.append` (or `String.join`/`Collectors.joining`) to combine many strings; never use the `+` operator in a loop.
- **Why:** Because `String` is immutable, each `+` builds a brand-new string by copying both operands, so concatenating `n` items with `+` in a loop is O(n²) in both time and allocation. `StringBuilder` appends into a single growable buffer for O(n). A single `a + b + c` expression on one line is fine - the compiler fuses it - but the moment concatenation spans loop iterations, each iteration re-copies everything accumulated so far. This turns a report-building method from milliseconds into seconds as the input grows.
- **Smell:** `result += line;` or `s = s + x;` inside a `for`/`while`; string accumulation across iterations without a `StringBuilder`.
- **Signal:**
```java
// bad
String result = "";
for (int i = 0; i < numItems(); i++) result += lineForItem(i); // O(n^2)

// good
StringBuilder sb = new StringBuilder(numItems() * LINE_WIDTH);
for (int i = 0; i < numItems(); i++) sb.append(lineForItem(i));
String result = sb.toString();
// or: String.join("\n", lines) / lines.stream().collect(Collectors.joining("\n"))
```
- **Exceptions:** A fixed, small number of `+` concatenations in a single expression is idiomatic and readable - leave it. Modern JITs also optimize non-loop `+`, and text blocks (`"""..."""`, Java 15+) cover multiline literals without runtime concatenation.

### EJ64. Refer to Objects by Their Interfaces  [general] · medium
- **Rule:** Declare variables, parameters, return types, and fields using the most general interface type that fits, not a concrete implementation class.
- **Why:** Programming to the interface decouples your code from a specific implementation: you can swap `ArrayList` for `LinkedList`, or `HashMap` for a `ConcurrentHashMap`, by changing one `new` expression, because nothing else in the code named the concrete type. If you instead declare `ArrayList<E> list`, every method that takes or returns it is now welded to `ArrayList`, and switching implementations becomes a wide refactor. The one thing to watch: only switch if the new implementation honors the same general contract - relying on a special property (e.g. `LinkedHashMap`'s iteration order) means the interface type must be one that guarantees that property.
- **Smell:** `ArrayList<T> x = new ArrayList<>()`, `HashMap<K,V> m = ...`, method signatures returning `ArrayList`/`HashMap`/`Vector` rather than `List`/`Map`/`Collection`.
- **Signal:**
```java
// bad
LinkedHashMap<String, Integer> counts = new LinkedHashMap<>();

// good
Map<String, Integer> counts = new LinkedHashMap<>(); // impl swappable
```
- **Exceptions:** When there is no suitable interface, refer to the class (value classes like `String`, `BigInteger`; framework types like `Optional`). When you depend on implementation-specific methods or guarantees (e.g. `ArrayDeque` operations, `TreeMap`'s navigable API), declare the type that exposes them.

### EJ65. Prefer Interfaces to Reflection  [general] · medium
- **Rule:** Avoid `java.lang.reflect` for normal programming; when you must instantiate types unknown at compile time, do it reflectively but access the objects through a known interface or superclass.
- **Why:** Reflection throws away every benefit of the static type system: errors that would be compile-time become runtime `ClassNotFoundException`/`NoSuchMethodException`, the code is verbose and hard to read, and reflective dispatch is dramatically slower than direct calls. The disciplined pattern - create instances via `Class.getDeclaredConstructor().newInstance()` but then hold and call them through an interface the type implements - confines reflection to a single object-creation seam and keeps all downstream code type-checked and fast.
- **Smell:** `Method.invoke` in application logic; casting reflectively created objects to concrete classes; reflection used to reach non-public members for convenience rather than framework necessity; `Class.forName` deep inside business code.
- **Signal:**
```java
// bad
Object set = Class.forName(name).getDeclaredConstructor().newInstance();
set.getClass().getMethod("add", Object.class).invoke(set, x); // no type checking

// good
@SuppressWarnings("unchecked")
Class<? extends Set<String>> cl = (Class<? extends Set<String>>) Class.forName(name);
Set<String> s = cl.getDeclaredConstructor().newInstance();
s.add(x); // type-checked, fast, from here on
```
- **Exceptions:** Frameworks that legitimately need it - dependency injection, serializers, ORMs, service loaders, plugin systems, test runners. There, confine reflection to the framework's edge. Modern alternatives (`ServiceLoader`, `VarHandle`, `MethodHandles`, records' component APIs) are preferable where they fit.

### EJ66. Use Native Methods Judiciously  [general] · low
- **Rule:** Do not use JNI native methods for performance; use them only for platform-specific facilities or established native libraries with no Java equivalent.
- **Why:** The historical reason to drop to C/C++ - speed - has almost entirely evaporated: the JVM's JIT now matches or beats native code for most tasks, and `BigInteger`-style hotspots have long since been optimized in the platform. What remains is all downside: native code is not memory-safe (it reintroduces buffer overruns, use-after-free, and segfaults that crash the whole JVM), it's harder to debug, the JNI boundary has its own crossing cost, and it destroys portability. The cost of the glue code frequently outweighs any speedup.
- **Smell:** `native` method declarations added to "go faster"; `System.loadLibrary` for functionality that has a pure-Java library; JNI wrappers around trivial computation.
- **Signal:**
```java
// bad
public native long factorial(int n); // "for speed" - JIT'd Java is as fast, and safe

// good
// pure Java; if you truly need native access, prefer the Foreign Function & Memory API:
// java.lang.foreign.Linker / MethodHandle over hand-written JNI
```
- **Exceptions:** Accessing OS/hardware facilities with no Java API, or reusing a mature, correct native library. In modern Java (21+), the Foreign Function & Memory API is the preferred, safer replacement for JNI when native interop is genuinely required.

### EJ67. Optimize Judiciously  [general] · high
- **Rule:** Write good, clean, well-structured programs first; optimize only after profiling identifies a measured bottleneck.
- **Why:** More sins are committed in the name of efficiency than for any other reason, and premature optimization usually fails on its own terms - programmers' intuitions about where time goes are notoriously wrong on modern JVMs with a JIT, inlining, and escape analysis. Worse, contorting code for speed damages the architecture, and a bad architectural decision (a leaky API that forces callers into slow patterns, a public type that pins an inefficient representation) can be impossible to fix later. Good design and good performance are usually aligned: strive for sound structure and information-hiding, measure, then tune the one hotspot the profiler names.
- **Smell:** Micro-optimizations (manual loop unrolling, caching `list.size()` everywhere, bit-twiddling) with no benchmark; API design justified by "it's faster" without data; optimization of code that isn't on any measured hot path.
- **Signal:**
```java
// bad
// rewrite clean code into obscure bit-hacks based on a guess about the bottleneck

// good
// 1. write clear code  2. profile (JFR, async-profiler, JMH)
// 3. optimize only the confirmed hotspot  4. re-measure to confirm the win
```
- **Exceptions:** Do consider performance up front in one place: API and data-representation design, where a mistake is permanent (e.g. don't expose a mutable type you'll want to make immutable). That's design foresight, not micro-optimization.

### EJ68. Adhere to Generally Accepted Naming Conventions  [general] · low
- **Rule:** Follow the standard Java naming conventions - `UpperCamelCase` types, `lowerCamelCase` methods and fields, `SCREAMING_SNAKE_CASE` constants, single-word lowercase packages - and match the grammatical conventions for method names.
- **Why:** Naming conventions are a shared vocabulary: a reader who sees `MAX_SIZE` knows it's a constant, `getBalance()` returns a value, `isEmpty()` returns a boolean, and `toList()`/`asList()` signal a conversion vs a view. Violating them forces every reader to slow down and re-derive intent, and misleads tooling and code generators. The typographical rules (case) prevent ambiguity; the grammatical rules (verb phrases for actions, `get/set` for accessors, `is/has` for booleans, noun phrases for types) let method names read like the operation they perform.
- **Smell:** `class user`, `int MaxCount`, `final int maxSize = 100`, `void Balance()`, a boolean accessor named `balance()` instead of `isActive()`, package names with capitals or underscores.
- **Signal:**
```java
// bad
class order_service { static int maxRetries = 3; boolean active() {...} }

// good
class OrderService { static final int MAX_RETRIES = 3; boolean isActive() {...} }
```
- **Exceptions:** Long-standing platform names that predate or bend the rules (`Integer.MIN_VALUE` is a constant; acronyms like `HttpUrl` vs `HTTPURL` - prefer treating acronyms as words). Follow an existing codebase's local convention when it's consistent, even if it differs slightly, rather than introducing a second style.

## Exceptions

### EJ69. Exceptions for exceptional conditions  [exceptions] · medium
- **Rule:** Use exceptions only for genuinely exceptional conditions, never for ordinary control flow.
- **Why:** Exceptions are optimized for the failure path, so the JVM skips inlining and other hot-path optimizations around a `try` block; a loop that terminates by catching `ArrayIndexOutOfBoundsException` runs far slower than one that tests its bound and hides real bugs when an unrelated exception is swallowed as the "normal" exit. The subtle failure is that the exception-driven loop keeps "working" even after a genuine indexing bug is introduced deeper in the body, because your `catch` treats every out-of-bounds as loop termination. A well-designed API also provides a state-testing method (`hasNext`) or an `Optional`/distinguished return value so clients never need a `try` to drive iteration.
- **Smell:** a `catch` block that is the intended exit of a loop; `try`/`catch` used to test whether an operation would succeed instead of a boolean predicate.
- **Signal:**
```java
// bad
try {
    int i = 0;
    while (true) range[i++].climb();
} catch (ArrayIndexOutOfBoundsException e) { /* done */ }
// good
for (Mountain m : range) m.climb();
```
- **Exceptions:** none for control flow; the only debate is whether to offer a state-testing method vs. an `Optional`-returning method, and `Optional`/distinguished value wins under concurrency where the state can change between the test and the call.

### EJ70. Checked vs unchecked  [exceptions] · medium
- **Rule:** Use checked exceptions for conditions from which a caller can plausibly recover, and runtime exceptions for programming errors.
- **Why:** A checked exception is a compile-time contract forcing the caller to either handle or propagate, which is appropriate only when there is a meaningful recovery action; using one for a precondition violation (a bug) just clutters every call site with `catch` blocks that can do nothing useful. Runtime exceptions signal that the caller violated the API contract (`IllegalArgumentException`, `IllegalStateException`, `NullPointerException`) and should propagate to crash the thread with a stack trace, not be caught. Errors are reserved by convention for the JVM; never subclass `Error` or throw `Throwable` directly. The subtle failure is the opposite of overuse: catching a runtime exception that indicates a bug converts a loud, debuggable crash into silent corruption.
- **Smell:** a checked exception whose only realistic handling at every call site is log-and-rethrow or an empty catch; `catch (RuntimeException e)` that suppresses a programming error.
- **Signal:**
```java
// bad
public void transfer(Account to, long cents) throws InsufficientFundsException { ... } // caller can't add funds mid-call
// good
public boolean tryTransfer(Account to, long cents) { ... }       // recoverable -> return value / Optional
public void transfer(Account to, long cents) { ... }             // programming error -> IllegalArgumentException on negative cents
```
- **Exceptions:** for a single, expected failure mode, returning `Optional<T>` (or an empty collection) is often cleaner than a checked exception - but only when the caller needs no extra failure detail, since `Optional` carries none.

### EJ71. Avoid unnecessary checked exceptions  [exceptions] · medium
- **Rule:** Do not declare a checked exception when the caller cannot do better than propagate it or when a single-failure API can instead return `Optional` or expose a state-testing method.
- **Why:** A single checked exception forces callers into `try`/`catch` and disqualifies the method from being used in a stream pipeline, lambda, or method reference (functional interfaces don't declare checked types), which quietly forces wrapper boilerplate throughout the codebase. Splitting the method into a boolean state-tester plus an action that throws an unchecked exception, or returning `Optional`, removes the syntactic burden while preserving safety. The cost is real and compounding: one gratuitous checked exception in a widely called API multiplies into thousands of `catch` clauses.
- **Smell:** a method `throws SomeCheckedException` where every caller immediately wraps it in an unchecked exception or in a "this can't happen" empty catch; a checked-throwing method you want to call from `stream().map(...)`.
- **Signal:**
```java
// bad
if (obj.actionPermitted(args)) {          // still may throw at the action
    obj.action(args);                     // throws SomeCheckedException
}
// good
Optional<Result> r = obj.tryAction(args); // absence encodes the one failure mode
r.ifPresent(this::use);
```
- **Exceptions:** keep the checked exception when the failure is genuinely recoverable AND the caller needs the exception's carried detail (message, cause, typed subclasses) to decide how to recover.

### EJ72. Standard exceptions  [exceptions] · low
- **Rule:** Reuse the JDK's standard exceptions instead of defining your own for common failure modes.
- **Why:** Standard exceptions make your API instantly familiar, avoid loading extra classes, and reduce memory footprint; every reader already knows what `IllegalArgumentException`, `IllegalStateException`, `NullPointerException`, `IndexOutOfBoundsException`, `ConcurrentModificationException`, and `UnsupportedOperationException` mean. The subtle distinction people miss: use `IllegalStateException` when the failure depends on object state regardless of arguments, `IllegalArgumentException` when the argument value is wrong; and `IndexOutOfBoundsException`, not `IllegalArgumentException`, for an out-of-range index. Never throw `Exception`, `RuntimeException`, `Throwable`, or `Error` directly - they can't be caught selectively.
- **Smell:** a hand-rolled `InvalidInputException` or `NullValueException` that duplicates a standard type; `throw new RuntimeException(...)` where a specific standard exception fits.
- **Signal:**
```java
// bad
if (count < 0) throw new NegativeCountException(count);
if (name == null) throw new IllegalArgumentException("name null");
// good
if (count < 0) throw new IllegalArgumentException("count < 0: " + count);
this.name = Objects.requireNonNull(name, "name");                 // NPE with message
Objects.checkIndex(i, size);                                      // JDK 9+ IndexOutOfBoundsException
```
- **Exceptions:** define a custom exception when you need to carry extra typed state for recovery, or when no standard type captures the semantics precisely; subclassing a standard exception (rather than `Exception`) is usually the right middle ground.

### EJ73. Exception translation  [exceptions] · medium
- **Rule:** Catch lower-layer exceptions and rethrow ones appropriate to the abstraction, chaining the original as the cause.
- **Why:** Letting a `SQLException` or `IOException` propagate out of a persistence-layer method leaks implementation details into the API contract, so a later switch from JDBC to a different store becomes a source-breaking change for every caller. Translating to a layer-appropriate exception (e.g., a domain `RepositoryException`) decouples callers from internals, and passing the original via the `Throwable`-cause constructor preserves the full stack trace for debugging. The subtle failure people miss is translating but dropping the cause, which discards the root-cause stack trace and turns a five-minute diagnosis into an hour. Translation is not a license to over-catch: it is better to prevent the lower-layer exception (validate inputs first) than to catch and translate.
- **Smell:** a public method declaring `throws SQLException`/`IOException` from a non-I/O abstraction; `throw new MyException(e.getMessage())` that stringifies instead of chaining the cause.
- **Signal:**
```java
// bad
try { return jdbc.query(...); }
catch (SQLException e) { throw new DataAccessException(e.getMessage()); } // cause lost
// good
try { return jdbc.query(...); }
catch (SQLException e) { throw new DataAccessException("load user " + id, e); } // cause chained
```
- **Exceptions:** if the lower-layer exception is itself already at the right abstraction level (or the method's contract legitimately exposes it), propagate it unchanged rather than wrapping for the sake of wrapping.

### EJ74. Document all exceptions  [exceptions] · medium
- **Rule:** Document every exception a method can throw with a Javadoc `@throws` tag, checked and unchecked alike, precisely stating the conditions that trigger each.
- **Why:** The set of unchecked exceptions a method throws is effectively part of its contract - it tells callers which preconditions they must satisfy - yet the compiler never enforces documenting them, so they silently rot. Documenting each `@throws` with its triggering condition lets callers validate inputs up front instead of discovering failure modes at runtime. The subtle rule: declare checked exceptions individually (never a common superclass like `throws Exception`), and document unchecked exceptions with `@throws` but deliberately omit them from the method's `throws` clause, so readers can visually distinguish the two categories.
- **Smell:** `throws Exception` or `throws Throwable` in a signature; a public method that throws `IllegalArgumentException`/`IllegalStateException` with no `@throws` describing when; identical exception conditions copy-pasted per method instead of documented once at class level.
- **Signal:**
```java
// bad
/** Withdraws funds. */
public void withdraw(long cents) throws Exception { ... }
// good
/**
 * @throws IllegalArgumentException if {@code cents} is negative
 * @throws IllegalStateException    if the account is frozen
 * @throws InsufficientFundsException if balance < {@code cents}
 */
public void withdraw(long cents) throws InsufficientFundsException { ... }
```
- **Exceptions:** if many methods in a class throw the same unchecked exception for the same reason (e.g., every method NPEs on a null arg), document it once in the class-level Javadoc rather than repeating per method.

### EJ75. Detail message  [exceptions] · medium
- **Rule:** Put every value that contributes to the failure into the exception's detail message.
- **Why:** For many production failures the stack trace plus detail message is the only forensic data you get - no debugger, no reproduction - so a message of `"Index out of bounds"` wastes the one shot at diagnosis, whereas `"Index: 4, Size: 3"` names the bug outright. The message should contain the values and interrelations of all parameters and fields that could have caused the throw, and the cleanest way to guarantee that is a constructor that takes those values as typed arguments and builds the message itself. The subtle line: capture what is needed to diagnose, but never leak passwords, keys, or PII into a message that will land in logs and bug reports.
- **Smell:** `throw new IllegalArgumentException("invalid value")` with no offending value; a message built from a constant string while the relevant `index`/`size`/`limit` locals are in scope and omitted.
- **Signal:**
```java
// bad
throw new IndexOutOfBoundsException("bad index");
// good
throw new IndexOutOfBoundsException(
    "index: " + index + ", lower: " + lower + ", upper: " + upper);
// Helpful NPE messages (JEP 358): on by default since JDK 15 (JDK 14 needed -XX:+ShowCodeDetailsInExceptionMessages)
```
- **Exceptions:** don't include the description of what an exception means in its detail message - that belongs in Javadoc/source; and redact secrets/PII even at the cost of a less specific message.

### EJ76. Failure atomicity  [exceptions] · high
- **Rule:** A failed method invocation should leave the object in the same well-defined state it was in before the call.
- **Why:** If a method mutates state and then throws partway through, the object is left corrupt, and callers who catch the exception intending to recover instead operate on garbage - the classic case is a `pop()` that decrements size before checking for empty, so a subsequent successful call reads a stale element and leaks a reference. Achieve atomicity by checking parameters before any mutation, ordering the computation so all failure-prone work happens before any state change, performing the operation on a temporary copy and swapping on success, or writing recovery code that rolls back. The subtlest miss is that immutable objects (including records) are failure-atomic for free, since a failed construction simply produces no object - reaching for immutability sidesteps the whole problem.
- **Smell:** a field mutated (`size--`, `list.add(...)`) before the validity check that can throw; multi-field updates with no rollback where the second update can fail after the first succeeded.
- **Signal:**
```java
// bad
public E pop() {
    size--;                                          // mutate first -> size = -1 on empty
    if (size < 0) throw new EmptyStackException();   // throws, but object left corrupt (size = -1)
    return elements[size];
}
// good
public E pop() {
    if (size == 0) throw new EmptyStackException();  // check before mutating
    E result = elements[--size];
    elements[size] = null;                           // eliminate obsolete reference
    return result;
}
```
- **Exceptions:** atomicity is not always achievable or worth it - concurrent modification by two threads can leave shared state inconsistent regardless, and for some operations the cost of a defensive copy is prohibitive; when you deliberately forgo atomicity, document the resulting object state in the API.

### EJ77. Don't ignore exceptions  [exceptions] · high
- **Rule:** Never write an empty catch block; handle the exception, propagate it, or explicitly document a deliberate decision to ignore it.
- **Why:** An empty `catch` defeats the entire purpose of exceptions - it lets a program silently continue past a failure that should have stopped it, and the resulting corruption surfaces far from the cause with no trace back to the swallowed exception. The subtle trap is that ignoring feels safe for "unlikely" cases (closing a read-only stream, a timeout you don't care about), but even there the correct move is to make the choice explicit: name the caught variable `ignored` and add a comment stating why it's safe, so a reviewer can distinguish an intentional decision from a forgotten TODO. This applies identically to checked and unchecked exceptions.
- **Smell:** `catch (SomeException e) { }`; `catch (Exception e) { /* ignore */ }` with no rationale; a caught exception whose variable is never referenced and never logged.
- **Signal:**
```java
// bad
try { future.get(1, SECONDS); }
catch (Exception e) { }              // swallowed - a real failure vanishes
// good
try { future.get(1, SECONDS); }
catch (TimeoutException | ExecutionException ignored) {
    // Recover by using a sensible default; the numGames default is fine.
    numGames = DEFAULT_GAMES;
}
```
- **Exceptions:** ignoring is legitimate when there is genuinely nothing to do and continuing is correct (e.g., best-effort cleanup) - but it must be signaled by naming the variable `ignored` and commenting the reason, never by a bare empty block.

## Concurrency

### EJ78. Synchronize access to shared mutable data  [concurrency] · high
- **Rule:** Guard every read and write of shared mutable state with the same lock (or a proper atomic/`volatile`), never just the writes.
- **Why:** Synchronization is not only about mutual exclusion — it establishes a happens-before edge that makes one thread's writes *visible* to another. Without it the JIT and CPU may hoist a field read out of a loop, cache it in a register, or reorder writes, so a thread can spin forever on a flag another thread already flipped. The subtle trap: a single unsynchronized `boolean` looks harmless because the value is atomic, but atomicity does not imply visibility, and even long/double reads can tear without `volatile`.
- **Smell:** A `boolean stopRequested` / status flag read in one thread's loop and written by another with no `volatile`, no lock, and no `Atomic*`; or reads outside a lock that writes hold.
- **Signal:**
```java
// bad
private boolean stopRequested;                 // no visibility guarantee
void run() { while (!stopRequested) work(); }   // may never see the write, loop hoisted
void stop() { stopRequested = true; }
// good
private volatile boolean stopRequested;         // write is visible to the reader
// or, when read-modify-write is involved, use an atomic:
private final AtomicLong nextId = new AtomicLong();
long generate() { return nextId.getAndIncrement(); }  // atomic + visible
```
- **Exceptions:** Truly confined data (never escapes one thread), effectively-immutable data published safely once (via `volatile`, `final`, a lock, or a concurrent collection), or genuinely immutable objects (EJ17 — `record`s with only immutable components) need no per-access synchronization.

### EJ79. Avoid excessive synchronization  [concurrency] · high
- **Rule:** Never cede control to client-provided ("alien") code — callbacks, listeners, overridable methods, or `equals`/`hashCode` on foreign objects — while holding a lock.
- **Why:** An alien method invoked inside a synchronized region can reenter your lock and deadlock, or mutate the very collection you are iterating and throw `ConcurrentModificationException`, or block for an unbounded time and destroy throughput. Over-synchronizing also serializes work that could run in parallel and can defeat JVM optimizations. The fix is an *open call*: snapshot the state you need under the lock, release it, then invoke the alien code outside — or use a `CopyOnWriteArrayList` so iteration needs no lock at all.
- **Smell:** A `synchronized` block or method that loops over a listener/observer list and calls `listener.onX(...)`, or calls any method passed in or overridable, without first copying out of the lock.
- **Signal:**
```java
// bad
public synchronized void notifyObservers(E e) {
    for (Observer<E> o : observers) o.onEvent(this, e); // alien call under lock -> deadlock/CME
}
// good
public void notifyObservers(E e) {
    List<Observer<E>> snapshot;
    synchronized (this) { snapshot = new ArrayList<>(observers); }
    for (Observer<E> o : snapshot) o.onEvent(this, e);   // open call
}
// or: private final List<Observer<E>> observers = new CopyOnWriteArrayList<>();
```
- **Exceptions:** Calling code you fully control and know cannot reenter or block is safe. When in doubt, do as little as possible inside the lock and push everything else out.

### EJ80. Prefer executors, tasks, and streams to threads  [concurrency] · medium
- **Rule:** Submit work as tasks to an `ExecutorService` (or `CompletableFuture`) instead of creating and managing `Thread` objects by hand.
- **Why:** Raw `new Thread(...).start()` gives you no lifecycle management, no bounded pool, no backpressure, no failure propagation, and no clean shutdown, so you leak threads and swallow exceptions. Executors decouple *what* runs from *how* it runs: you get pooling, queuing, `Future` results, timeouts, and graceful `shutdown()`. The subtle failure is an unbounded thread-per-request design that runs fine in test and collapses under load with `OutOfMemoryError: unable to create new native thread`.
- **Smell:** `new Thread(runnable).start()`, `Thread` subclasses holding app logic, hand-rolled work queues with `wait/notify`, or a raw `Thread` used as a background worker.
- **Signal:**
```java
// bad
new Thread(() -> handle(req)).start();          // unmanaged, unbounded, results/exceptions lost
// good
ExecutorService pool = Executors.newFixedThreadPool(N);
Future<Result> f = pool.submit(() -> handle(req));
// ... pool.shutdown(); pool.awaitTermination(...);
```
- **Exceptions:** Modern Java updates the ceiling on this advice: for high-fan-out blocking I/O, `Executors.newVirtualThreadPerTaskExecutor()` (Java 21) makes thread-per-task cheap again — still an executor, not raw threads. For coordinated task trees prefer `CompletableFuture` or structured concurrency (`StructuredTaskScope`). Direct `Thread` use is legitimate only for niche cases like implementing a scheduler primitive itself.

### EJ81. Prefer concurrency utilities to wait and notify  [concurrency] · medium
- **Rule:** Build coordination out of `java.util.concurrent` primitives (`ConcurrentHashMap`, `BlockingQueue`, `CountDownLatch`, `Semaphore`, `CyclicBarrier`); reach for `wait`/`notify` only to maintain legacy code.
- **Why:** `wait`/`notify` is a minefield: `notify` can wake the wrong thread, a missed signal deadlocks, and a spurious wakeup corrupts state unless you always wait inside a `while` loop re-checking the condition. The high-level utilities encode these patterns correctly and perform better — e.g. `ConcurrentHashMap` beats a synchronized `Map`, and a `CountDownLatch` expresses "wait for N events" in one line. The classic bug people miss is using `if` instead of `while` around `wait()`, so a thread proceeds on a false condition.
- **Smell:** `synchronized`/`wait()`/`notify()`/`notifyAll()` in application code; `if (!condition) obj.wait();`; a hand-built latch or bounded buffer.
- **Signal:**
```java
// bad
synchronized (lock) {
    if (!ready) lock.wait();   // if (not while) -> proceeds on spurious/early wakeup
    proceed();
}
// good
CountDownLatch ready = new CountDownLatch(1);
// worker: ready.countDown();
ready.await();                 // correct, race-free, no manual loop
proceed();
```
- **Exceptions:** If you are forced to touch existing `wait`/`notify` code: always wait in a `while` loop guarding the condition, and prefer `notifyAll()` over `notify()` unless you can prove exactly one waiter must wake.

### EJ82. Document thread safety  [concurrency] · low
- **Rule:** State each class's thread-safety level explicitly in its doc comment — immutable, unconditionally thread-safe, conditionally thread-safe, not thread-safe, or thread-hostile — rather than leaving clients to guess from the presence of `synchronized`.
- **Why:** `synchronized` is an implementation detail, not part of the contract, so its presence or absence tells a caller nothing reliable about safe concurrent use. Undocumented safety forces callers to either over-synchronize or race. For conditionally thread-safe classes you must also document *which* lock guards *which* sequence of calls (e.g. iterating `Collections.synchronizedMap`). The subtle attack this prevents: a hostile client can grab your public lock and hold it (DoS) — so a private final lock object keeps the lock out of the API.
- **Smell:** A mutable shared-use class with no thread-safety statement in its Javadoc; `synchronized(this)`/`synchronized` methods on a class clients could lock against; a "thread-safe" claim with no note on iteration or compound actions.
- **Signal:**
```java
// bad
public synchronized void put(K k, V v) { ... }  // safety is undocumented; lock is public (this)
// good
/** Unconditionally thread-safe. */
public final class Counter {
    private final Object lock = new Object();     // private lock: clients can't grab it (no DoS)
    private long count;
    public void inc() { synchronized (lock) { count++; } }
}
```
- **Exceptions:** Purely immutable value types (EJ17 — a `record` with immutable components) need only say "immutable"; private/package classes whose locking discipline is documented at the call sites can skip a formal statement.

### EJ83. Use lazy initialization judiciously  [concurrency] · medium
- **Rule:** Initialize fields eagerly by default; add lazy initialization only when profiling proves the init cost or the access frequency justifies it, and then use the exact idiom for the field kind.
- **Why:** Lazy init trades startup cost for per-access complexity and, under concurrency, for correctness hazards. For a *static* field, the lazy-initialization holder class idiom is best: the class isn't loaded until first use, and the JVM guarantees safe, lock-free publication. For an *instance* field needing laziness, the double-check idiom requires the field be `volatile` — omit that and a reader can observe a partially constructed object through reordered writes, the canonical subtle bug.
- **Smell:** `if (field == null) field = compute();` with no synchronization on a shared field; a double-checked block whose field is not `volatile`; lazy init added without a measured reason.
- **Signal:**
```java
// bad
private FieldType field;
FieldType get() { if (field == null) field = compute(); return field; } // race: torn/partial publish
// good (static): holder idiom - lazy, thread-safe, no locking
private static class Holder { static final FieldType VALUE = compute(); }
static FieldType get() { return Holder.VALUE; }
// good (instance): double-check with volatile
private volatile FieldType field;
FieldType get() {
    FieldType f = field;
    if (f == null) synchronized (this) { if ((f = field) == null) field = f = compute(); }
    return f;
}
```
- **Exceptions:** Skip laziness entirely for cheap-to-init fields — eager init is simpler and safe. If a repeated recomputation is acceptable and the type is a primitive/word-tearing-free value, the single-check idiom (drop the second read, tolerate racing computations) can omit synchronization.

### EJ84. Don't depend on the thread scheduler  [concurrency] · medium
- **Rule:** Write programs whose correctness never rests on thread priorities, `Thread.yield`, or how many threads happen to be runnable at once.
- **Why:** The scheduler's policy varies across OSes and JVMs, so a program tuned by priorities on one platform starves or deadlocks on another. `Thread.yield()` has no semantic guarantee — it may do nothing — and `Thread.sleep(1)` in a spin loop just burns CPU while pretending to fix a race. The durable fix is to keep the number of *runnable* threads near the core count by having threads block on real work (a bounded queue, a latch) rather than busy-waiting, so the scheduler's choices stop mattering.
- **Smell:** `Thread.yield()` or `setPriority(...)` used to "fix" a flaky test or ordering bug; busy-wait loops (`while (!done) {}` or `while (!done) Thread.sleep(1);`); tests that pass only under load.
- **Signal:**
```java
// bad
while (count.get() < target) Thread.yield();   // spins, correctness depends on scheduler
// good
CountDownLatch done = new CountDownLatch(target);
// workers: done.countDown();
done.await();                                   // blocks, scheduler-independent
```
- **Exceptions:** `Thread.yield()` / priorities are acceptable purely as *performance hints* on an already-correct program, though even then a real fix (fewer runnable threads, proper blocking) usually beats them. Virtual threads (Java 21) further reduce the temptation to hand-manage scheduling.

## Serialization

### EJ85. Prefer alternatives to Java serialization  [serialization] · high
- **Rule:** Never deserialize bytes you don't fully trust with Java's `ObjectInputStream`; move interchange to a cross-platform format (JSON, protobuf, Avro, CBOR) with an explicit schema.
- **Why:** `readObject` is effectively a hidden constructor that can instantiate any `Serializable` type on the classpath, so a crafted byte stream turns object graph reconstruction into a gadget-chain remote-code-execution or resource-exhaustion primitive before any of your code runs. The attack surface is the transitive closure of every serializable class you depend on, not just your own types, so you cannot audit it. Deserialization bombs (deeply nested `HashSet`s) also DoS you with a tiny payload because equality/hashing recursion explodes. `ObjectInputFilter` (JEP 290, Java 9) and per-context filters (JEP 415, Java 17) are a mitigation for legacy code, not a reason to keep using Java serialization for new work.
- **Smell:** `new ObjectInputStream(socket.getInputStream()).readObject()`, RMI, or a cache/session store reading `Serializable` blobs off the wire or disk.
- **Signal:**
```java
// bad
Object o = new ObjectInputStream(untrustedIn).readObject(); // arbitrary type graph instantiated

// good
Order order = objectMapper.readValue(untrustedIn, Order.class); // fixed target type, schema-checked
// if legacy Java serialization is unavoidable, install an allowlist filter:
ois.setObjectInputFilter(ObjectInputFilter.Config.createFilter("com.acme.dto.*;java.base/*;!*"));
```
- **Exceptions:** Reading data you produced and control end-to-end (e.g. an in-JVM deep-copy) is safe; a locked-down `ObjectInputFilter` allowlist is acceptable for legacy protocols you cannot yet migrate.

### EJ86. Implement Serializable judiciously  [serialization] · medium
- **Rule:** Don't implement `Serializable` unless the type genuinely crosses a serialization boundary; if you must, declare an explicit `serialVersionUID`.
- **Why:** Implementing `Serializable` freezes the class's private field layout into a permanent public API - rename or drop a field and you break every previously serialized stream, so refactoring freedom is gone for the life of the format. Without an explicit `private static final long serialVersionUID`, the compiler synthesizes one from the class structure, so any incidental change (adding a method, reordering members) silently flips it and turns old bytes into `InvalidClassException`. Serializability also widens the attack surface (EJ85) and complicates subclassing, since every subclass inherits the burden. Records (Java 16+) are far safer here: a serializable record serializes its components and reconstructs through the canonical constructor, so the format is derived from the public API rather than private fields.
- **Smell:** `implements Serializable` on a domain/entity/service class with no `serialVersionUID`, or added reflexively to satisfy a framework that actually wants JSON.
- **Signal:**
```java
// bad
public class Money implements Serializable { // no UID; layout is now a frozen API by accident
    private long cents;
    private String currency;
}
// good
public record Money(long cents, String currency) implements Serializable {
    @Serial private static final long serialVersionUID = 1L; // explicit, and canonical ctor guards invariants
}
```
- **Exceptions:** Framework contracts (some caches, distributed sessions, RMI) require it; value classes that will legitimately be persisted or sent between JVMs can implement it - just pin the UID and prefer a record.

### EJ87. Consider a custom serialized form  [serialization] · medium
- **Rule:** Accept the default serialized form only when it matches the logical content of the object; otherwise override it with `transient` fields plus `writeObject`/`readObject` (or a proxy).
- **Why:** The default form encodes every non-`transient` field and the entire physical topology, so a linked-list or hash-bucket implementation ships its pointers/buckets over the wire and into the permanent format - you can never change the internal representation again without breaking compatibility. It can also be catastrophically inefficient (serializing a doubly-linked list writes every node and its two links) and can even overflow the stack via deep recursion. A custom form writes only the logical state (e.g. the element count and each element) and marks representation fields `transient`. When you use a custom form, still call `defaultWriteObject`/`defaultReadObject` so future non-transient fields serialize correctly, and re-establish any invariants and `transient` caches on read.
- **Smell:** A class whose internal data structure (nodes, buckets, capacity, load factor) is directly serializable with the default form, or `writeObject` that omits `defaultWriteObject`.
- **Signal:**
```java
// bad
public final class StringList implements Serializable {
    private Entry head;                 // serializes every node + both links, forever frozen
    private static class Entry implements Serializable { String data; Entry prev, next; }
}
// good
public final class StringList implements Serializable {
    private transient int size = 0;
    private transient Entry head;       // physical layout excluded from the form
    @Serial private void writeObject(ObjectOutputStream s) throws IOException {
        s.defaultWriteObject();
        s.writeInt(size);
        for (Entry e = head; e != null; e = e.next) s.writeObject(e.data); // logical content only
    }
}
```
- **Exceptions:** The default form is fine when the physical representation *is* the logical content and is stable (e.g. a small record or a value class holding exactly the fields you'd serialize anyway).

### EJ88. Protect invariants during deserialization  [serialization] · high
- **Rule:** Treat `readObject` as a public constructor fed hostile bytes: validate every invariant and make defensive copies of mutable fields before the deserialized object escapes.
- **Why:** Deserialization bypasses your constructors, so class invariants a constructor enforces (positive amounts, `start <= end`, non-null fields) are not re-checked unless you re-check them - a hand-crafted stream can produce an object your constructor would have rejected. Worse, an attacker can append extra references in the byte stream that alias a mutable field of the deserialized object, so even after `readObject` returns, external code holds a live handle to your internal state and can mutate it past validation (the classic `Period` attack). Defending requires `readObject` to defensively copy mutable fields *before* validating them, and to validate after copying - copying after validating leaves a TOCTOU window. Records sidestep most of this: they deserialize through the canonical/compact constructor, so your normal validation and copies run automatically.
- **Smell:** A mutable-field class with `implements Serializable` and either no `readObject`, or a `readObject` that validates without copying (or copies non-final fields after the check).
- **Signal:**
```java
// bad
private void readObject(ObjectInputStream s) throws Exception {
    s.defaultReadObject();
    if (start.compareTo(end) > 0) throw new InvalidObjectException("bad"); // start/end still alias attacker refs
}
// good
private void readObject(ObjectInputStream s) throws Exception {
    s.defaultReadObject();
    start = new Date(start.getTime());   // defensive copy FIRST
    end   = new Date(end.getTime());
    if (start.compareTo(end) > 0)        // then validate the copies
        throw new InvalidObjectException("start after end");
}
// better: a record validates in its compact constructor automatically on deserialization
```
- **Exceptions:** Fully immutable classes with only primitive/immutable fields need only value validation, not copies; a serialization proxy (EJ90) or a serializable record removes the hand-written `readObject` entirely.

### EJ89. Prefer enum types to readResolve for instance control  [serialization] · medium
- **Rule:** Implement a singleton (or any fixed-instance type) as a single-element enum rather than a serializable class relying on `readResolve`.
- **Why:** A `Serializable` singleton created by any other means silently becomes a factory: every deserialization produces a *new* instance, breaking `==` identity unless you add a `readResolve` method. Even with `readResolve`, any object reference field that isn't declared `transient` opens a "stolen instance" attack - a crafted stream can capture the pre-`readResolve` instance and defeat the guarantee. A single-element enum gets iron-clad instance control from the JVM: the serialization system guarantees enum constants are singletons, immune to these attacks and to reflection, with no boilerplate. This is also the cleanest thread-safe lazy-free singleton.
- **Smell:** `implements Serializable` on a singleton class, a private constructor plus a static `INSTANCE`, and a hand-written `readResolve()` returning that instance.
- **Signal:**
```java
// bad
public class Registry implements Serializable {
    public static final Registry INSTANCE = new Registry();
    private Registry() {}
    @Serial private Object readResolve() { return INSTANCE; } // fragile; non-transient fields leak
}
// good
public enum Registry {
    INSTANCE;
    // methods here; JVM guarantees one instance across serialization/reflection
}
```
- **Exceptions:** If the singleton must extend a class (enums can't) or the set of instances isn't known at compile time, you need a class with a carefully written `readResolve` and all reference fields marked `transient`.

### EJ90. Consider serialization proxies instead of serialized instances  [serialization] · medium
- **Rule:** For a serializable class with nontrivial invariants, serialize a small private static `SerializationProxy` that captures the logical state, via `writeReplace`, and reconstruct the real object through public constructors in `readResolve`.
- **Why:** The proxy pattern removes the "extralinguistic constructor" hazard entirely: the real class never appears in the byte stream, so an attacker cannot craft one directly, and reconstruction goes through your ordinary public API (`readResolve`), meaning all normal validation and defensive copying run automatically - no bug-prone hand-written `readObject`. It also enables fields to be `final`, and lets the deserialized object be a *different* class than the serialized one (e.g. `EnumSet` uses this pattern, so its proxy's `readResolve` rebuilds a `RegularEnumSet` or `JumboEnumSet` depending on element count). Add a `readObject` on the enclosing class that always throws, so bytes purporting to be the real class (rather than the proxy) are rejected. The proxy cannot serialize classes extendable by clients or with circular object references, since `readResolve` runs before the graph is fully linked.
- **Smell:** A class with strong invariants doing serialization by hand (`readObject` with copies and validation) instead of a `writeReplace`/proxy pair; `final` fields dropped just to support deserialization.
- **Signal:**
```java
// good
public final class Period implements Serializable {
    private final Date start, end;
    @Serial private Object writeReplace() { return new SerializationProxy(this); }
    @Serial private void readObject(ObjectInputStream s) throws InvalidObjectException {
        throw new InvalidObjectException("Proxy required"); // reject direct-instance streams
    }
    private static final class SerializationProxy implements Serializable {
        private final Date start, end;
        SerializationProxy(Period p) { this.start = p.start; this.end = p.end; }
        @Serial private Object readResolve() { return new Period(start, end); } // public ctor validates
        @Serial private static final long serialVersionUID = 1L;
    }
}
// modern: a serializable record needs no proxy - the canonical constructor already does this job
```
- **Exceptions:** Doesn't work for client-extendable (non-final) classes or object graphs with cycles; a serializable record supersedes the pattern for plain immutable data because its deserialization already routes through the validating canonical constructor.
