# Clean Code — Smells & Heuristics (63 items)

The review checklist from *Clean Code* (Robert C. Martin), Appendix "Smells and Heuristics" — the book's own distillation of its chapters into greppable spot-checks. Original wording; codes (G/N/F/C/E/T) are factual references. Language-agnostic principles, Java examples. Clean Code is guidance, not law — each item's Exceptions notes real tradeoffs.

## General (G)

### G1. Multiple Languages in One Source File  [structure] · low
- **Rule:** Minimize the number of languages that appear in any single source file, ideally to one.
- **Why:** Every embedded language (SQL, HTML, regex, XML, shell, templating) adds its own syntax, escaping rules, and mental context; interleaving them forces the reader to switch parsers mid-line and hides bugs in the seams between grammars. The failure people miss is not the presence of a second language but its diffusion - a stray `<style>` block, an inline SQL string, and a regex all in one method quietly triple the surface area a maintainer must understand and test. Confining each language to its own file or a clearly bounded region restores the ability to reason about one grammar at a time.
- **Smell:** Java files with inline HTML/JSP scriptlets, SQL concatenated into query strings, or long regex literals scattered through business logic instead of extracted to resources or dedicated helpers.
- **Signal:**
```java
// bad
out.println("<table><tr><td>" + name + "</td></tr></table>");
String sql = "SELECT * FROM users WHERE region = '" + region + "'";

// good
render("user-row.html", Map.of("name", name));   // markup lives in template
users = userRepo.findByRegion(region);            // SQL lives in repository/mapper
```
- **Exceptions:** Some multi-language mixing is unavoidable and idiomatic - JSX in React, HEREDOC SQL in a thin data-access layer, or annotations that embed a query DSL. The heuristic targets diffusion and accidental mixing, not deliberate, well-bounded embedding where the second language is the file's whole purpose.

### G2. Obvious Behavior Is Unimplemented  [correctness] · high
- **Rule:** Implement the behavior a reasonable reader expects from a function's or type's name before adding anything surprising.
- **Why:** This is the Principle of Least Surprise: a function named `getDayName` should return day names for any legal input, not just the ones the author happened to need. When obvious behavior is missing, callers lose trust in every abstraction and start reading implementations instead of names, which defeats the point of the abstraction. The subtle failure is that the code works for the author's immediate case and silently misbehaves at the edges the name promised to cover, so the gap surfaces only in production.
- **Smell:** A method whose name implies a total mapping but whose body handles a subset; helpers that throw or return null for inputs the name clearly admits; "TODO: handle other cases" under a confident name.
- **Signal:**
```java
// bad
Day dayFor(String abbrev) {
    if (abbrev.equals("Mon")) return MONDAY;   // silently null for the rest
    return null;
}

// good
Day dayFor(String abbrev) {
    Day d = ABBREV_TO_DAY.get(abbrev);
    if (d == null) throw new IllegalArgumentException("Unknown day: " + abbrev);
    return d;                                  // handles the full set the name promises
}
```
- **Exceptions:** When a deliberately narrow contract is documented in the name itself (`parseKnownWeekdayOrNull`) the reduced scope becomes the obvious behavior. The rule is about matching implementation to the expectation the name sets, not about maximizing scope.

### G3. Incorrect Behavior at the Boundaries  [correctness] · high
- **Rule:** Prove correct behavior at every boundary condition with an explicit test rather than trusting intuition.
- **Why:** Bugs cluster at edges - empty collections, zero and negative counts, first and last iterations, off-by-one indices, null, and overflow - precisely because the happy path is what authors picture while writing. Intuition routinely misses that the loop runs one time too few, that an empty list should short-circuit, or that a max value wraps. Only a written test that exercises the corner pins the behavior down and keeps a later refactor from silently reintroducing the error.
- **Smell:** Loops and index math with no test covering empty/one/last-element cases; conditionals that assume non-empty input; arithmetic on sizes/counts with no zero or negative case.
- **Signal:**
```java
// bad
int last(int[] xs) { return xs[xs.length - 1]; }   // xs.length == 0 → crash

// good
Optional<Integer> last(int[] xs) {
    if (xs.length == 0) return Optional.empty();    // boundary handled + tested
    return Optional.of(xs[xs.length - 1]);
}
```
- **Exceptions:** None as a review value - boundary correctness is not optional. The only latitude is where the check lives: a validated precondition at an outer layer can let inner code assume a non-empty range, but that assumption must itself be enforced and tested somewhere.

### G4. Overridden Safeties  [correctness] · high
- **Rule:** Do not disable, suppress, or route around compiler warnings, failing tests, or other safety mechanisms.
- **Why:** Safeties encode hard-won knowledge; turning off a warning or commenting out a failing test trades a loud, cheap signal now for a silent, expensive failure later. The subtle trap is that the override looks like progress - the build goes green - while the underlying defect remains and the next reader assumes green means correct. Chernobyl is Martin's cautionary example: the operators overrode safeties to hit a deadline. Suppressing the signal never removes the risk; it only removes your ability to see it.
- **Smell:** `@SuppressWarnings` without justification, `serialVersionUID` warnings ignored wholesale, `@Ignore`/`@Disabled` on tests, `-Xlint:none`, `// NOSONAR`, or commented-out assertions.
- **Signal:**
```java
// bad
@SuppressWarnings("unchecked")   // silence, ship, forget
List<User> users = (List<User>) raw;
@Disabled("flaky") @Test void transferFundsIsAtomic() { ... }

// good
List<User> users = mapper.readValue(raw, USER_LIST_TYPE);  // typed, no cast
@Test void transferFundsIsAtomic() { ... }                 // fix the flake, keep the guard
```
- **Exceptions:** A narrowly scoped, commented suppression is legitimate when the tool is provably wrong (a false-positive warning on generics you have already verified) - suppress the single line, not the file, and say why. Skipping a test is acceptable only with a linked ticket and a deadline to re-enable it; a permanent `@Disabled` is a deleted test wearing a disguise.

### G5. Duplication  [duplication] · high
- **Rule:** Eliminate every duplicated idea by extracting it to one named place - "DRY," Don't Repeat Yourself.
- **Why:** Martin calls this one of the most important rules in the book: each duplicate is a missed abstraction, and every copy is a place a future change can be forgotten, producing divergent behavior. Duplication comes in grades - literal copy-paste, `switch`/`if-else` chains repeated across files (fixable by polymorphism), and modules solving the same problem differently (fixable by a shared interface like Template Method or Strategy). The failure people miss is subtle duplication of *intent*: two blocks that look different but say the same thing, so a fix applied to one silently leaves the other wrong.
- **Smell:** Copy-pasted blocks, parallel `switch` statements on the same type keyed across files, repeated validation/formatting logic, and near-identical methods differing by one literal.
- **Signal:**
```java
// bad
double area(Rectangle r) { return r.w * r.h; }
// ...elsewhere, same computation re-derived inline
double total = shape.w * shape.h + margin;

// good
double area(Rectangle r) { return r.w * r.h; }
double total = area(shape) + margin;   // one definition, one place to change
```
- **Exceptions:** Not every textual repetition is a duplicated idea - two constants that happen to equal `3` for unrelated reasons should stay separate (coupling them is worse than the dup). Beware premature extraction: forcing an abstraction over incidental similarity creates the wrong coupling. Tolerate small, honest duplication until the shared concept is clear enough to name.

### G6. Code at Wrong Level of Abstraction  [abstraction] · high
- **Rule:** Keep concepts at the abstraction level they belong to - high-level policy separate from low-level detail, and never leak lower-level details through a higher-level interface.
- **Why:** Good abstractions let a reader operate at one altitude without falling into the machinery below; a base class or interface that exposes a detail meant only for a specific implementation forces every client to know about that implementation. The subtle failure is a constant, utility method, or field that seems harmless on a general interface but silently binds the whole hierarchy to one concrete case, so the abstraction stops being a barrier and becomes a leak. The test is whether a detail could be false for some valid implementation of the concept - if so, it does not belong at that level.
- **Smell:** A general interface carrying implementation-specific methods/constants; a `Stack` interface exposing `percentFull()` though a bounded stack is only one variant; low-level field access mixed into high-level policy methods.
- **Signal:**
```java
// bad
public interface Stack {
    void push(Object o);
    Object pop();
    int percentFull();   // meaningless for an unbounded stack — leaks a detail
}

// good
public interface Stack {
    void push(Object o);
    Object pop();
}
public interface BoundedStack extends Stack {
    int percentFull();   // detail lives only where it is always true
}
```
- **Exceptions:** Judging "level" is not mechanical; some pragmatic leakage is accepted at true system boundaries (a persistence interface may expose paging cursors, an I/O type may expose buffer sizes) where the detail is genuinely part of the contract. The rule targets details that are accidental to the concept, not those intrinsic to it.

### G7. Base Classes Depending on Their Derivatives  [design] · high
- **Rule:** Never let a base class reference, name, or branch on its derivatives.
- **Why:** Splitting concepts into base and derived exists to let the base stand alone and the derivatives vary independently; the moment a base mentions a subclass, that independence is gone and adding a new derivative requires editing the base, defeating the purpose of the hierarchy. The failure people miss is the deployment-level cost: base and derivatives can no longer ship in separate components, because the base now compiles against its children, creating a dependency cycle in the module graph. A well-formed base is ignorant of everything below it.
- **Smell:** `if (this instanceof SubType)`, a `switch` on a type/enum tag inside the superclass, base-class imports of subclass packages, or a factory method hardwired into the base returning concrete children.
- **Signal:**
```java
// bad
abstract class Account {
    double fee() {
        if (this instanceof PremiumAccount) return 0;   // base knows its child
        return 5.0;
    }
}

// good
abstract class Account {
    abstract double fee();                    // base defines the slot
}
class PremiumAccount extends Account { double fee() { return 0; } }
class BasicAccount   extends Account { double fee() { return 5.0; } }
```
- **Exceptions:** A base referencing a *sibling abstraction* it collaborates with (not its own subclasses) is fine, and some framework base classes legitimately know a fixed, closed set of variants defined in the same module. The prohibition is specifically on a base depending on the concrete children that are supposed to extend it independently.

### G8. Too Much Information  [design] · medium
- **Rule:** Expose the smallest possible interface; hide data, methods, constants, and helpers that clients do not need.
- **Why:** Coupling is proportional to surface area, so a well-defined module offers a few tight handles and conceals the rest, letting the implementation change without breaking callers. The subtle failure is that every public method, protected field, or exported constant is a promise you must keep forever - a bloated interface locks in decisions and invites clients to depend on internals you meant to be private. Fewer methods, fewer variables, and tighter scoping are what make a class replaceable.
- **Smell:** Many public methods that could be private; `protected` used as a default; exposed instance variables; helper types visible outside their module; interfaces with dozens of members.
- **Signal:**
```java
// bad
public class OrderService {
    public Connection conn;                 // internal wiring exposed
    public String buildSql(Order o) { ... } // helper leaked to the world
    public void submit(Order o) { ... }
}

// good
public class OrderService {
    private final Connection conn;
    private String buildSql(Order o) { ... } // hidden
    public void submit(Order o) { ... }      // the one handle clients need
}
```
- **Exceptions:** Public utility libraries and framework SPIs must expose broad surfaces by design, and test-only visibility (`@VisibleForTesting`) is a pragmatic, documented widening. The rule is about not leaking incidental internals of an ordinary module, not about artificially starving a genuine public API.

### G9. Dead Code  [clutter] · medium
- **Rule:** Delete code that can never execute the moment you find it.
- **Why:** Dead code - an unreachable branch, a method no one calls, a `catch` for an exception that is never thrown - rots because it is not exercised by tests or updated by refactors, so it drifts out of sync with reality while still costing every reader attention to understand and dismiss. The subtle danger is that dead code looks authoritative: a maintainer may read it, believe it reflects intended behavior, and reason incorrectly. Version control remembers deletions, so there is no reason to keep a corpse in the tree "just in case."
- **Smell:** `if (false)`, methods with zero call sites, unreachable statements after `return`/`throw`, commented-out blocks, and `catch` clauses for impossible exceptions.
- **Signal:**
```java
// bad
if (featureEnabled) { doNew(); }
else { doOld(); }        // doOld unreachable: featureEnabled is a compile-time true

// good
doNew();                 // dead branch and its helper deleted; git keeps the history
```
- **Exceptions:** Code reachable only via reflection, dependency injection, serialization, or native/JNI callbacks is not dead even though static analysis sees no caller - annotate it so reviewers and tools do not remove it. Feature-flagged code retained deliberately for a live rollout is dormant, not dead, but it needs a removal date.

### G10. Vertical Separation  [structure] · low
- **Rule:** Declare variables and functions close to where they are used, minimizing vertical distance between definition and use.
- **Why:** Reading is a top-to-bottom scan, and a variable declared far above its first use, or a private helper defined pages away from its caller, forces the reader to hold context across a long gap or scroll to reconcile the two. Local variables should appear just before the block that uses them; private functions should sit just below the first function that calls them, so the code reads like prose with each reference resolvable nearby. The failure people miss is that C-style "declare everything at the top" habits scatter a function's working set across its whole body, inflating working memory for no benefit.
- **Smell:** All locals declared at method top before a long body; a helper used once but defined 300 lines earlier; instance fields used by only one method sitting far from it.
- **Signal:**
```java
// bad
void report() {
    double total; int count; String header;   // declared far from first use
    // ... 30 lines ...
    total = compute();
}

// good
void report() {
    // ... setup ...
    double total = compute();                  // declared at point of use
}
```
- **Exceptions:** Language and convention override this: Java constants and fields belong grouped at the class top, and some style guides mandate declaration ordering that trumps proximity. Distance also matters less in short functions where everything is already visible at once.

### G11. Inconsistency  [clarity] · medium
- **Rule:** Do the same thing the same way everywhere - pick one convention for a concept and apply it uniformly.
- **Why:** Consistency is what lets a reader form an expectation from one example and trust it across the codebase; if you name one variable `response` in one handler, name it `response` in all of them, and if `processVerificationRequest` is your verb, do not switch to `handleDeletion` for a sibling. The subtle failure is that inconsistency is not a bug but a tax - each deviation makes the reader stop and ask whether the difference is meaningful, and sometimes it accidentally is, hiding a real distinction under noise. Careful, deliberate conventions turn code into something scannable.
- **Smell:** Mixed naming for the same concept (`userId` vs `memberId` vs `uid`), some methods returning `null` and siblings throwing, inconsistent parameter order across overloads, or varied error-handling styles in one layer.
- **Signal:**
```java
// bad
void addUser(String name, int id) { ... }
void removeUser(int id, String name) { ... }   // parameter order flipped

// good
void addUser(int id, String name) { ... }
void removeUser(int id, String name) { ... }    // same order everywhere
```
- **Exceptions:** Consistency with a genuinely wrong or deprecated pattern is not a virtue - when you are deliberately migrating to a better convention, the transitional inconsistency is justified, but confine it and finish the migration. Blind uniformity that propagates a mistake (see the memory note on Go acronym casing: do not copy legacy `userId` into new symbols) is worse than a clean break.

### G12. Clutter  [clutter] · low
- **Rule:** Remove anything that serves no purpose - empty constructors, no-op methods, unused variables, redundant comments, and dangling boilerplate.
- **Why:** Clutter is code that occupies space and attention without carrying meaning, and it accumulates silently because nothing forces its removal. A default constructor with an empty body, a comment restating the method name, an import no longer referenced - each individually trivial, collectively they bury the code that matters under noise the reader must still parse and discard. Keeping source files clean is what preserves the signal-to-noise ratio that makes the meaningful parts easy to find.
- **Smell:** Empty `{}` method bodies with no override reason, `// default constructor` comments, unused imports/fields/parameters, redundant `return;` at method end, and getters/setters generated but never used.
- **Signal:**
```java
// bad
public class Report {
    public Report() {}          // adds nothing the default already gives
    private int unused;         // never read
    public void render() { ... return; }
}

// good
public class Report {
    public void render() { ... }
}
```
- **Exceptions:** Some "clutter" is required by frameworks or the language: a no-arg constructor a serializer needs, an explicitly overridden method that documents an intentional no-op, or a placeholder demanded by an interface. If an empty element is load-bearing, keep it and say why in one line.

### G13. Artificial Coupling  [design] · medium
- **Rule:** Do not couple things that have no real dependency on each other - place each declaration where it logically belongs, not where it was momentarily convenient.
- **Why:** Artificial coupling is when two modules become entangled for no reason intrinsic to the problem - a general enum stuffed inside one specific class, a constant parked in whatever file was open, a static that forces callers to import a class they otherwise would not touch. The subtle cost is that the coupling propagates: anyone needing the enum now depends on the unrelated class, and moving or deleting that class ripples outward. Declarations should live where a reader would naturally look for them, so dependencies reflect the domain, not the editing history.
- **Smell:** A widely used constant/enum nested in an unrelated class; a general-purpose helper defined inside a specific feature; imports that exist only to reach one misplaced declaration.
- **Signal:**
```java
// bad
public class InvoicePrinter {
    public enum Currency { USD, EUR, GBP }   // general concept trapped in one printer
}
// callers now import InvoicePrinter just to name a Currency

// good
public enum Currency { USD, EUR, GBP }       // stands on its own, coupled to nothing
public class InvoicePrinter { ... }
```
- **Exceptions:** A type genuinely private to one class - a small helper or enum that is meaningless outside it - belongs nested inside it; that is real cohesion, not artificial coupling. The rule targets declarations forced together by convenience, not those that are legitimately local to their owner.

### G14. Feature Envy  [design] · medium
- **Rule:** Put a method on the class whose data it manipulates; a method that reaches into another object's fields more than its own is misplaced.
- **Why:** From Martin Fowler's catalog, feature envy names a method more interested in another class's data than its own - it calls a foreign object's getters repeatedly to compute something the foreign object should compute itself. This breaks encapsulation: the envied class exposes internals just so an outsider can operate on them, and any change to those internals now ripples into the envious method. Moving the behavior next to the data it uses shrinks the interface, localizes change, and lets the owning class enforce its own invariants.
- **Smell:** A method calling `other.getX()`, `other.getY()`, `other.getZ()` to build a result; long chains of accessors on one foreign object; logic that would be a one-liner if it lived on the other class.
- **Signal:**
```java
// bad
class Report {
    String line(Employee e) {
        return e.getName() + " " + e.getGrade() + " " + e.getSalary();  // envies Employee
    }
}

// good
class Employee {
    String summaryLine() { return name + " " + grade + " " + salary; }  // behavior with its data
}
```
- **Exceptions:** Envy is sometimes the lesser evil. Deliberately behavior-free data types - DTOs, protobuf/domain structs, records at a boundary - are meant to be operated on from outside, and pushing logic into them would violate their role or create a bad dependency (a domain type importing a presentation concern). When moving the method would couple the data class to something it must not know about, leaving the method where it is is correct.

### G15. Selector Arguments  [clarity] · medium
- **Rule:** Avoid boolean or enum flag arguments that select which of several behaviors a function performs; split into separate, named functions instead.
- **Why:** A selector argument is an admission that a function does more than one thing, and it forces the reader to remember what `true` means at every call site (`calc(x, false)` is opaque). Worse, the flag couples unrelated behaviors into one body with branching, so a change to one mode risks the other, and callers cannot tell from the signature which combinations are valid. Splitting into `overtimeRate()` and `straightRate()` makes each call site self-documenting and each function single-purpose.
- **Smell:** Trailing `boolean` parameters, `render(item, true)`, enum "mode" parameters gating an `if/switch` at the top of the body, and repeated flags threaded through call chains.
- **Signal:**
```java
// bad
double pay(boolean overtime) {
    if (overtime) return hours * rate * 1.5;
    return hours * rate;
}
double p = pay(true);   // what is true?

// good
double straightPay() { return hours * rate; }
double overtimePay() { return hours * rate * 1.5; }
double p = overtimePay();   // intent obvious at the call site
```
- **Exceptions:** Not absolute. A flag that is genuinely a data attribute rather than a behavior selector (`newFile(name, /*createIfMissing=*/true)` reflecting configuration) can be reasonable, and a well-named enum modeling a real domain dimension is fine. Named/keyword arguments and builder options mitigate the readability cost in languages that support them; the core objection is a flag that switches *behavior*, especially a bare boolean.

### G16. Obscured Intent  [clarity] · medium
- **Rule:** Write code so its intent is visible; never sacrifice expressiveness for terseness or premature cleverness.
- **Why:** Code is read far more than written, so a compact expression that hides what it does - cryptic names, magic numbers, dense one-liners, Hungarian remnants, run-together operations - costs every future reader more than it ever saved the author. The subtle failure is that the author, holding full context, cannot see the obscurity; it only appears to the next person who must reverse-engineer intent from mechanics. Small, well-named intermediate variables and explicit steps make the "why" legible even when the "how" is unavoidably intricate.
- **Smell:** One-letter names in nontrivial scope, magic literals with no named constant, deeply nested ternaries, packed boolean expressions, and formulas with no explanatory decomposition.
- **Signal:**
```java
// bad
return (l[0]<<24)|(l[1]<<16)|(l[2]<<8)|l[3];   // what is being built?

// good
int b3 = bytes[0], b2 = bytes[1], b1 = bytes[2], b0 = bytes[3];
return (b3 << 24) | (b2 << 16) | (b1 << 8) | b0;   // an int assembled from 4 bytes
```
- **Exceptions:** Conventional terseness is fine where the idiom is universally understood - `i`/`j` for loop indices, `x`/`y` for coordinates, standard math notation in a well-commented numeric kernel. In genuinely performance-critical hot paths a less obvious form may be justified, but it must be paid for with a comment explaining what and why.

### G17. Misplaced Responsibility  [design] · medium
- **Rule:** Put each piece of code where a reader would naturally expect it, based on what it conceptually does - follow the Principle of Least Surprise.
- **Why:** Deciding *where* code lives is as important as writing it: a total computed for a report might belong in the reporting code, the module that accumulates the values, or a shared utility, and the right home is the one a maintainer looks in first. The subtle failure is placing logic where it was convenient (next to the code that happened to call it) rather than where it belongs (with the data or concept it serves), which scatters related behavior and makes the codebase unsearchable. Names hint at placement - a function named `PI` belongs in a `Math` class, not a `Trig` helper.
- **Smell:** Business calculations sitting in UI/controllers, timestamp assignment in a handler instead of the repository, formatting logic in the domain model, and constants defined far from the concept they describe.
- **Signal:**
```java
// bad
class OrderController {
    void submit(Order o) {
        o.setCreatedAt(Instant.now());   // when did the controller own persistence time?
        repo.save(o);
    }
}

// good
class OrderRepository {
    void save(Order o) {
        o.setCreatedAt(clock.instant());  // the layer that owns storage owns its timestamps
        ...
    }
}
```
- **Exceptions:** "Where a reader expects it" is a judgment that varies by team and architecture; a layered design and a hexagonal one disagree on where validation lives, and both can be right internally. The rule is to place responsibility deliberately and consistently with the codebase's conventions, not to chase one universal answer.

### G18. Inappropriate Static  [design] · medium
- **Rule:** Prefer instance methods; make a method static only when it truly operates on no instance and you are certain no caller will ever want to vary its behavior polymorphically.
- **Why:** A static method cannot be overridden or substituted, so choosing static is choosing to forbid polymorphism forever - fine for a pure function like `Math.max(a, b)`, wrong for anything a caller might later need to specialize or mock. The subtle failure is that statics look harmless (`HourlyPayCalculator.calculatePay(employee, overtimeRate)`) until a second pay policy appears and you discover the behavior is welded to one implementation with no seam to swap it out. Statics also invite hidden global coupling and make code hard to test because the dependency cannot be injected.
- **Smell:** Static methods taking a domain object as their first parameter (a disguised instance method), static "manager"/"util" classes holding real logic, and business rules behind `ClassName.doThing(...)` calls that tests cannot stub.
- **Signal:**
```java
// bad
double pay = HourlyPayCalculator.calculatePay(employee, rate);  // frozen, unmockable

// good
double pay = employee.calculatePay(rate);   // instance method; overridable and testable
```
- **Exceptions:** Static is exactly right for genuinely stateless, behavior-invariant utilities - `Math.max`, `Integer.parseInt`, pure formatting/conversion helpers - where polymorphism would add nothing and a factory would be ceremony. Static factory methods (Effective Java Item 1) are a deliberate, endorsed idiom. The test is whether any caller could reasonably want to vary the behavior; if not, static is appropriate and clearer.

### G19. Use Explanatory Variables  [General] · medium
- **Rule:** Break intermediate calculations into named local variables that state what each subexpression means.
- **Why:** Explanatory variables move meaning out of your head and into the code, so the reader learns intent from the name rather than re-deriving it from operators and indices. The subtle failure is that regexes, arithmetic chains, and nested calls encode domain concepts (a "key", a "value", a "match group") that vanish when inlined, and the next maintainer silently guesses wrong. Naming the pieces also makes the debugger useful: each concept has a slot you can inspect. There is essentially no runtime cost - the JIT folds the temporaries away.
- **Smell:** A single expression that combines a regex match, an array index, a cast, and an operator; `if`/`return` lines that a reviewer has to read three times to parse.
- **Signal:**
```java
// bad
return Math.sqrt(Math.pow(p2.x - p1.x, 2) + Math.pow(p2.y - p1.y, 2));

// good
double dx = p2.x - p1.x;
double dy = p2.y - p1.y;
return Math.sqrt(dx * dx + dy * dy);
```
- **Exceptions:** A short, idiomatic expression whose meaning is obvious (`total = price * qty`) needs no ceremony; over-splitting trivial math into five temporaries adds noise without adding intent.

### G20. Function Names Should Say What They Do  [General] · high
- **Rule:** Name a function so the call site tells the reader exactly what happens without consulting the implementation.
- **Why:** The call site is the contract; if you must open the function body to learn what it does or what it returns, the name has failed and the abstraction leaks. The subtle failure is names that describe half the behavior or the wrong tense - `date.add(5)` hides whether it mutates `date`, returns a new date, or adds days vs. weeks. A name that lies is worse than a long name, because readers stop double-checking and encode the wrong mental model everywhere the function is used.
- **Smell:** You read a call and can't tell the return value, the unit, or whether it mutates; a comment next to the call re-explaining what the function "actually" does.
- **Signal:**
```java
// bad
Date newDate = date.add(5); // days? mutates date? returns new?

// good
Date fiveDaysLater = date.plusDays(5); // clearly returns a new Date
```
- **Exceptions:** Well-established idioms carry their contract by convention (`toString`, `hashCode`, `equals`, Stream `map`/`filter`); ubiquitous terse names in a domain the whole team shares don't need to spell out every detail.

### G21. Understand the Algorithm  [General] · high
- **Rule:** Refactor code until its structure makes the algorithm obviously correct, rather than tuning it until the tests happen to pass.
- **Why:** "It passes" is not the same as "I understand why it passes"; code that works by accident works only until an input the tests didn't cover arrives. The subtle failure is the accreted stack of special-case `if`s and off-by-one nudges that each fixed one failing test - the whole thing is a house of cards nobody can reason about. Genuinely understanding the algorithm usually collapses that mess into a short, self-evidently correct routine, and the act of simplifying is how you prove you understand it.
- **Smell:** Clusters of narrow conditionals with comments like "needed for edge case"; boundary constants nudged by ±1 until green; a function nobody can explain end to end.
- **Signal:**
```java
// bad
// keep adding cases until the suite goes green
if (i == 0) x = a; else if (i == n - 1) x = b; else if (weird) x = c; ...

// good
// derive the invariant, then the body is obvious
for (int i = 0; i < n; i++) result[i] = interpolate(a, b, i, n);
```
- **Exceptions:** A deliberately documented workaround for a known upstream bug or hardware quirk is legitimate - the point is that you understand the algorithm and are choosing the exception, not papering over confusion.

### G22. Make Logical Dependencies Physical  [General] · medium
- **Rule:** When one module depends on an assumption about another, make it ask for that assumption explicitly instead of silently duplicating it.
- **Why:** A logical dependency that isn't physical is a landmine: the two modules agree on a value (a page size, a column count, a format) by coincidence of shared literals, and changing one breaks the other with no compiler warning. The subtle failure is that the code looks decoupled and reads fine, so the hidden coupling survives review; it only surfaces at runtime when someone edits one side. Exposing the dependency through a query or accessor turns an invisible contract into a checked one.
- **Smell:** Two modules with the same magic number or format string that "must" stay in sync; a consumer that hardcodes a producer's internal constant.
- **Signal:**
```java
// bad
// report assumes 55 lines/page, printer decides 55 elsewhere - coincidence
for (int i = 0; i < 55; i++) printLine();

// good
for (int i = 0; i < printer.getLinesPerPage(); i++) printLine();
```
- **Exceptions:** If the shared value is a genuinely universal constant (`0`, `1`, seconds-per-minute) the "dependency" is on math, not on another module, and threading an accessor through adds coupling for no benefit.

### G23. Prefer Polymorphism to If/Else or Switch/Case  [General] · medium
- **Rule:** Replace a type-based switch that recurs across the codebase with polymorphic dispatch behind an interface.
- **Why:** A single switch is fine; the danger is the same switch-on-type appearing in many functions, because each new type then forces you to hunt down and edit every copy - and you will miss one. Polymorphism localizes the per-type behavior in one class so adding a type is adding a class, not editing N functions (Open/Closed). The subtle failure is that the first switch feels harmless, so nobody applies the "one switch" rule until the pattern has metastasized. Prefer one switch that builds the polymorphic objects, then dispatch through them everywhere else.
- **Smell:** `switch (shape.type)` or `if (obj instanceof X)` chains repeated in more than one method; a new enum value requiring edits in several files.
- **Signal:**
```java
// bad
switch (shape.type) { case CIRCLE: return PI*r*r; case SQUARE: return s*s; }

// good
interface Shape { double area(); }
class Circle implements Shape { public double area() { return PI*r*r; } }
```
- **Exceptions:** A switch that appears exactly once, or one that maps external input (parse tokens, protocol codes) to internal types, is the right tool; forcing polymorphism there just scatters trivial logic across many tiny classes.

### G24. Follow Standard Conventions  [General] · medium
- **Rule:** Adhere to the team's agreed conventions for layout, naming, and idioms, and encode them somewhere shared rather than in each person's head.
- **Why:** Conventions exist so readers spend zero attention on where the braces go and all of it on what the code does; every deviation is a tiny speed bump that compounds across a large codebase. The subtle failure is "personal style" - each engineer applying their own brace/import/naming habits makes the code a patchwork that's harder to scan and diff-noisy. The specific convention matters far less than that everyone follows the same one; consistency is the value, not the particular choice.
- **Smell:** Mixed brace styles or import ordering within one repo; a file that reads unmistakably like one author's private preferences; review comments re-litigating style per PR.
- **Signal:**
```java
// bad
public int Get_count(){return count;}   // ad hoc casing and layout

// good
public int getCount() {
    return count;
}
```
- **Exceptions:** Conventions are a means, not an end - when a rule actively harms readability for a specific construct, deviate deliberately and document why; and adopting a better team-wide standard is progress, not a violation.

### G25. Replace Magic Numbers with Named Constants  [General] · high
- **Rule:** Give any literal whose meaning isn't self-evident a named constant that states what it represents.
- **Why:** A bare literal forces the reader to reverse-engineer its meaning and forces the editor to find every duplicate when it changes, and duplicates drift out of sync silently. The subtle point is that "magic number" covers more than numbers - a hardcoded string, a format spec, or a repeated array size is equally magic, while a truly self-explanatory constant is not (a `0` or `1` used as an index/sentinel usually reads fine). Naming also lets you assert the relationship between values (`SECONDS_PER_DAY = 60 * 60 * 24`) instead of an opaque `86400`.
- **Smell:** `86400`, `3.14159`, `"yyyy-MM-dd"`, or a repeated dimension literal scattered across methods; the same tuning value pasted in several places.
- **Signal:**
```java
// bad
if (elapsed > 86400) rotate();

// good
static final int SECONDS_PER_DAY = 60 * 60 * 24;
if (elapsed > SECONDS_PER_DAY) rotate();
```
- **Exceptions:** Literals that are self-explanatory in context (`0` and `1` as loop bounds or increments, `2` in a "divide in half") gain nothing from a name; over-constantizing them (`ZERO`, `ONE`) is noise that hurts readability.

### G26. Be Precise  [General] · high
- **Rule:** Make a definite decision about ambiguous cases - types, concurrency, nulls, money, timeouts - instead of coding to the happy path.
- **Why:** Vagueness is a bug in waiting: floating-point for currency loses cents, an unchecked `null` return NPEs at 2 a.m., an unlocked shared field corrupts under load, and "the query returns one row" fails the day it returns zero or two. The subtle failure is that imprecise code passes every test and demo because the ambiguous case is rare - it only fires in production. Being precise means confronting each edge (What if it's absent? Concurrent? Negative? Rounds?) at write time, when it's cheap, rather than debugging it later.
- **Smell:** `float`/`double` for money; unchecked results of a lookup that can miss; shared mutable state with no locking; "should always" assumptions about counts, ranges, or nullability.
- **Signal:**
```java
// bad
double total = price * quantity;              // cents drift
Customer c = repo.find(id); c.charge(total);  // c may be null

// good
BigDecimal total = price.multiply(BigDecimal.valueOf(quantity));
repo.find(id).ifPresentOrElse(c -> c.charge(total), () -> reject(id));
```
- **Exceptions:** Precision has a cost - throwaway scripts, prototypes, and clearly-bounded internal inputs don't need `BigDecimal` and exhaustive null handling; spend the rigor where the ambiguous case can actually occur and matter.

### G27. Structure over Convention  [General] · medium
- **Rule:** Enforce design decisions with structures that make violations impossible or obvious, in preference to naming conventions that rely on discipline.
- **Why:** A convention ("all handler methods start with `handle`") is only as strong as everyone's memory of it, and it fails silently the moment someone forgets - nothing checks it. Structure - an abstract method, a required interface, a type - moves the rule into the compiler, so a violation won't build. The subtle failure is that conventions feel enforced because they're written in the style guide, but the guide can't reject code; the type system can. Prefer an abstract `case` that each subclass must implement over a naming rule that hopes each subclass adds one.
- **Smell:** A style rule that "all X must also do Y" with nothing enforcing it; base classes that document required overrides in comments rather than declaring them abstract.
- **Signal:**
```java
// bad
// convention: every subclass must define a doAction() method
abstract class Handler { /* please add doAction(), by agreement */ }

// good
abstract class Handler { abstract void doAction(); } // compiler enforces it
```
- **Exceptions:** When no structural mechanism exists (dynamic languages, cross-service or serialized boundaries, framework-scanned names), a documented and linted convention is the pragmatic tool; don't contort the design to make a trivial rule structural.

### G28. Encapsulate Conditionals  [General] · medium
- **Rule:** Extract compound boolean logic into an intention-revealing predicate function.
- **Why:** Boolean expressions are lower-level than the decisions they encode, so inline conditionals force the reader to re-derive intent from operators every time they pass the branch. A named predicate states the *what* while the body holds the *how*, collapsing three tokens of algebra into one word of domain language. The subtle failure people miss: the same condition gets duplicated across the codebase and then drifts - one site adds a null guard the others lack - producing bugs that only appear on the paths nobody remembered to update.
- **Smell:** `if` / `while` headers containing `&&`, `||`, or negation over more than one term; the same multi-term condition appearing in two or more places.
- **Signal:**
```java
// bad
if (timer.hasExpired() && !timer.isRecurrent()) {
    deleteTimer(timer);
}
// good
if (shouldBeDeleted(timer)) {
    deleteTimer(timer);
}
private boolean shouldBeDeleted(Timer timer) {
    return timer.hasExpired() && !timer.isRecurrent();
}
```
- **Exceptions:** A single trivially readable term (`if (list.isEmpty())`) needs no wrapper - extraction there adds a hop without adding meaning. In hot loops a JIT normally inlines the predicate, but if profiling proves a regression, inline with a comment naming the decision.

### G29. Avoid Negative Conditionals  [General] · low
- **Rule:** Express conditionals in the positive form whenever the logic allows it.
- **Why:** Negatives impose an extra mental inversion: the reader parses the predicate, then flips it, and double negatives (`if (!buffer.shouldNotCompact())`) multiply the cost until comprehension collapses. Positive framing lets the name carry the truth value directly, matching how people reason about the happy path. The failure people miss is that negatives quietly encourage inverted early-returns and mismatched else-branches, so the guard clause protects the wrong case after a later edit.
- **Smell:** `!` applied to a named predicate, especially method names already containing `not`/`no`/`isnt`; nested or chained negations.
- **Signal:**
```java
// bad
if (!buffer.shouldNotCompact()) {
    compact(buffer);
}
// good
if (buffer.shouldCompact()) {
    compact(buffer);
}
```
- **Exceptions:** Guard clauses are legitimately negative by design (`if (input == null) return;`) - the point of a guard is to reject the abnormal case first. When the domain concept itself is inherently negative (`isDisabled`, `isEmpty`), forcing a positive alias (`isEnabled`) can obscure rather than clarify; keep the name the domain uses.

### G30. Functions Should Do One Thing  [General] · high
- **Rule:** Split any function that performs multiple sequential responsibilities into functions that each do one.
- **Why:** A function that does one thing has exactly one reason to change and can be named for that thing without "and"; a function that loops, then formats, then writes has three reasons to change and no honest name. The one-thing test is that every statement sits at a single level of abstraction and you cannot extract a meaningfully-named sub-function from a section (extracting a mere restatement of the code doesn't count). The trap people miss: "one thing" is judged relative to the function's own abstraction level, so a high-level function calling three steps is still one thing - orchestration - while a function mixing a step with its own implementation is not.
- **Smell:** Blank-line-separated paragraphs inside one body; sections a reader mentally captions "first we..., then we...,"; loops whose body could be its own named routine.
- **Signal:**
```java
// bad
public void pay() {
    for (Employee e : employees) {
        if (e.isPayday()) {                // decide
            Money pay = e.calculatePay();  // calculate
            e.deliverPay(pay);             // deliver
        }
    }
}
// good
public void pay() {
    for (Employee e : employees) payIfNecessary(e);
}
private void payIfNecessary(Employee e) {
    if (e.isPayday()) calculateAndDeliverPay(e);
}
private void calculateAndDeliverPay(Employee e) {
    e.deliverPay(e.calculatePay());
}
```
- **Exceptions:** Splitting for its own sake produces shrapnel - a swarm of one-line functions passed the same three arguments is harder to follow than one cohesive body. Stop extracting when the sub-function would only ever have one caller *and* names nothing the caller doesn't already say.

### G31. Hidden Temporal Couplings  [General] · high
- **Rule:** Make required call ordering explicit by passing each step's output as the next step's input.
- **Why:** When methods must be called in a fixed sequence but the signatures don't enforce it, the order lives only in the author's head and the current call site; the compiler will happily let a maintainer reorder or omit a step. Threading a token or result object through the chain converts the temporal dependency into a data dependency the type system checks - you physically cannot call `close` before `open` returns the handle. The failure people miss is that these bugs are invisible in review (the code compiles and the tests that happen to call in order pass) and surface only when a new caller guesses the sequence wrong.
- **Smell:** A method that reads/writes an instance field another method must have set first; setup/teardown pairs with no shared return value; comments like `// must call init() first`.
- **Signal:**
```java
// bad
public class MoogDiver {
    void saturateGradient() { /* uses this.gradient */ }
    void reticulateSplines() { /* uses this.splines, set by saturate */ }
    void diveForMoog() { /* uses this.splines */ }
}
// caller must remember: saturate -> reticulate -> dive
// good
public class MoogDiver {
    Gradient saturateGradient() { ... }
    List<Spline> reticulateSplines(Gradient g) { ... }
    void diveForMoog(List<Spline> s) { ... }
}
// ordering enforced by the arguments
```
- **Exceptions:** Builder and fluent APIs deliberately expose ordered steps for readability - there the return type (`this`) already enforces the chain. Some frameworks mandate lifecycle callbacks (`init`, `start`, `stop`) whose order the container guarantees; you cannot rewrite their signatures, so document the contract and fail fast if invoked out of order.

### G32. Don't Be Arbitrary  [General] · low
- **Rule:** Give every structural choice a rationale the reader can infer, and stay consistent with it.
- **Why:** Code communicates convention as much as behavior; when a class lives in an odd package or a helper is public for no reason, readers assume the placement is meaningful and waste effort hunting for the significance that isn't there. Arbitrariness also invites divergence - once one exception class is nested inside its handler and another sits top-level, the next author flips a coin, and the structure stops predicting anything. The subtle cost is erosion of trust: a codebase whose conventions hold lets you navigate by pattern, and a single unjustified deviation teaches you that you can't.
- **Smell:** One member of a peer group formatted, scoped, or located differently from its siblings; visibility broader than any caller needs; a lone file breaking the package's layout.
- **Signal:**
```java
// bad
public class AliasLinkWidget extends ParentWidget {
    public static class VariableExpandingWidgetRoot { ... } // public, but only used internally
}
// good
public class AliasLinkWidget extends ParentWidget {
    static class VariableExpandingWidgetRoot { ... }        // scoped to match its actual use
}
```
- **Exceptions:** A deviation with a stated reason isn't arbitrary - a `// grouped here because it shares the parser's private state` comment converts an oddity into a documented decision. External constraints (framework-required package names, serialization layouts) can force placements that look arbitrary; note the constraint so the next reader doesn't "fix" it.

### G33. Encapsulate Boundary Conditions  [General] · medium
- **Rule:** Compute a boundary expression once, name it, and reuse the variable instead of repeating the arithmetic.
- **Why:** Off-by-one errors breed where `+1`/`-1` scatter through a function, because each occurrence is an independent chance to get the fencepost wrong and every reader must re-verify the intent of each. Capturing `level + 1` as `nextLevel` states the concept once and gives every use a single source of truth, so the boundary logic is fixed or audited in exactly one place. The failure people miss: duplicated boundary math drifts under maintenance - someone adjusts one `+1` for a new requirement and misses its twin three lines down.
- **Smell:** The same `x + 1`, `len - 1`, or `i + 1` appearing more than once in a scope; index arithmetic inline inside array accesses and loop bounds simultaneously.
- **Signal:**
```java
// bad
if (level + 1 < tags.length) {
    parts = new Parse(body, tags, level + 1, offset + endTag);
    body = null;
}
// good
int nextLevel = level + 1;
if (nextLevel < tags.length) {
    parts = new Parse(body, tags, nextLevel, offset + endTag);
    body = null;
}
```
- **Exceptions:** A boundary expression used exactly once needs no name - introducing `nextLevel` for a single reference just adds a line. When the language offers a boundary-safe idiom (half-open ranges, `Math.floorMod`, iterator/for-each), prefer eliminating the arithmetic entirely over naming it.

### G34. Functions Should Descend Only One Level of Abstraction  [General] · high
- **Rule:** Keep every statement in a function at a single level of abstraction, one step below the function's name.
- **Why:** Mixing high-level intent with low-level detail forces the reader to constantly shift altitude - one line says `assembleReport()`, the next fiddles with a `StringBuffer` and HTML tags - and the mixture hides which lines are essential policy and which are incidental mechanism. Uniform altitude is what makes the Stepdown Rule work: you read top-to-bottom as a narrative, each function a paragraph that defers detail to the one below. The trap people miss is that this is the hardest heuristic to apply and the easiest to violate slightly - a single low-level token (a raw format string, a bit-twiddle) dropped into an otherwise high-level method is enough to break the reading flow, and such leaks accumulate silently.
- **Smell:** A method name at domain level whose body touches primitives, string literals, or byte/format details; conceptually "big" and "small" operations interleaved in one body.
- **Signal:**
```java
// bad
String render() {
    if (isTestPage())
        includeSetupPages();
    StringBuffer b = new StringBuffer();     // low level
    b.append("<hr");                          // low level
    if (size > 0) b.append(" size=\"").append(size).append("\"");
    b.append(">");
    return b.toString();
}
// good
String render() {
    if (isTestPage())
        includeSetupPages();
    return buildHorizontalRule();
}
private String buildHorizontalRule() {
    HtmlTag hr = new HtmlTag("hr");
    if (size > 0) hr.addAttribute("size", "" + size);
    return hr.html();
}
```
- **Exceptions:** The very lowest-level utilities legitimately deal in primitives end-to-end - a byte-buffer packer is *supposed* to live at that altitude, and wrapping every operation would obscure it. Judgment call: "one level" is fuzzy, so aim for a body a reader can caption at a single conceptual tier rather than counting abstraction rungs.

### G35. Keep Configurable Data at High Levels  [General] · medium
- **Rule:** Define configuration constants and defaults at the top level and pass them down as arguments to the low-level code that consumes them.
- **Why:** A magic default buried deep in the call tree is nearly invisible to the people who need to change it, and burying it there also pins the decision to one implementation - the low-level function has silently taken ownership of policy that belongs to the application. Hoisting the value to a high-level, well-known location makes it easy to find, easy to expose as a real config knob later, and keeps the deep code parameterized and reusable across callers with different needs. The failure people miss: two independent features hardcode the same "temporary" default at different depths, and when the value must change under deadline, one copy is updated and the other becomes a latent inconsistency.
- **Smell:** Literal constants (port numbers, timeouts, page names, limits) sitting inside deep helper methods; a default assigned far from where the program is configured.
- **Signal:**
```java
// bad
public class FitNesseExpediter {
    void serve() {
        int timeout = 10_000;                 // buried default deep in request handling
        socket.setSoTimeout(timeout);
    }
}
// good
public class FitNesseExpediter {
    private final int requestTimeout;          // configurable at the top
    FitNesseExpediter(int requestTimeout) { this.requestTimeout = requestTimeout; }
    void serve() {
        socket.setSoTimeout(requestTimeout);
    }
}
```
- **Exceptions:** Genuinely fixed physics or protocol constants (`SECONDS_PER_MINUTE = 60`, an HTTP status code) belong next to the code that uses them - hoisting an unchangeable value adds indirection without adding configurability. A private implementation detail no operator would ever tune is better kept local than promoted into a config surface it doesn't deserve.

### G36. Avoid Transitive Navigation  [General] · medium
- **Rule:** Ask objects only for what you directly need and let them delegate, rather than walking chains of intermediate objects.
- **Why:** A chain like `a.getB().getC().doIt()` hardwires the caller to the entire topology between A and its grandchildren, so any refactor to that structure - inserting a layer, renaming an intermediary - breaks every site that traversed it (this is the Law of Demeter as a design pressure). Depending only on immediate collaborators keeps modules loosely coupled and lets the system's shape evolve without a shotgun edit. The subtle failure people miss: each hop is also an unguarded null and an assumption the intermediate is fully constructed, so long chains multiply the ways a distant, unrelated change can NPE far from its cause.
- **Smell:** Three or more `.` navigations across distinct object types in one expression; "train wreck" getter chains; code that reaches through a returned object to mutate its innards.
- **Signal:**
```java
// bad
Options opts = ctxt.getOptions();
File scratchDir = opts.getScratchDir();
String outputDir = scratchDir.getAbsolutePath();
// good
String outputDir = ctxt.getScratchDirectoryPath();
// ctxt exposes what the caller needs; the traversal stays inside ctxt
```
- **Exceptions:** Fluent builders and stream pipelines chain by design (`stream().filter().map().collect()`) - each call returns the same conceptual object, not a walk across a structure, so Demeter doesn't apply. Pure data-transfer objects and generated protobuf/DTO accessors are legitimately navigated deeply; adding delegating wrappers over structs that exist only to carry data is ceremony without benefit.

## Names, Functions, Comments, Environment (N / F / C / E)

### N1. Choose Descriptive Names  [names] · high
- **Rule:** Pick names that state what a thing is, does, or holds, and change the name the moment its meaning drifts.
- **Why:** Names are the primary documentation of intent; a good one lets a reader skip reading the body. The subtle failure is inertia - a name chosen when the variable meant one thing survives a refactor where it now means another, and every future reader is silently misled. Descriptiveness is contextual: `d` is fine as a loop-local delta over three lines, fatal as a field spanning a class.
- **Smell:** Single-letter or throwaway names (`d`, `tmp`, `data`, `obj`, `res`) outside the tightest scope; names that require a comment to explain them; names that lie because the code moved on.
- **Signal:**
```java
// bad
int d; // elapsed time in days
List<int[]> list = getThem();
// good
int elapsedTimeInDays;
List<Cell> flaggedCells = getFlaggedCells();
```
- **Exceptions:** Conventional loop indices (`i`, `j`), math-domain code that mirrors a published formula (`v`, `dt`), and generic type parameters (`T`, `K`) are clearer terse than verbose. Over-describing a two-line scope adds noise, not information.

### N2. Choose Names at the Appropriate Level of Abstraction  [names] · medium
- **Rule:** Name things for what they mean in the problem domain, not for the current implementation mechanism behind them.
- **Why:** A name that leaks implementation binds callers to a decision you will want to change, and reading it forces the reader down a level of abstraction they did not ask to visit. The subtle miss: the name was accurate when written (`getJdbcConnection`), then the backing store changed and the name became a lie that no compiler catches. Abstract names survive implementation churn.
- **Smell:** Names embedding a concrete technology, data structure, or algorithm the caller shouldn't care about: `getPhoneList`, `modemConnected`, `accountArray`, `xmlPayload` on an interface.
- **Signal:**
```java
// bad
interface Modem { boolean dialConnect(String phoneNumber); }
// good
interface Modem { boolean connect(String connectionLocator); }
```
- **Exceptions:** At the layer that genuinely owns the mechanism (a class literally named `JdbcAccountRepository`), the implementation term is the correct abstraction level and hiding it obscures more than it reveals.

### N3. Use Standard Nomenclature Where Possible  [names] · medium
- **Rule:** Reuse the established vocabulary of your language, framework, and design patterns so a name carries its conventional meaning for free.
- **Why:** Standard names (`toString`, a `Visitor`, a `Factory`, `...Decorator`) let a reader import an entire body of understanding on sight. Inventing a private synonym for a well-known concept forces every reader to learn your dialect and obscures that a familiar pattern is in play. The failure people miss is misusing a loaded term - calling a class `...Factory` when it isn't one actively teaches the reader something false.
- **Smell:** Home-grown names for standard concepts (`ObjectMaker` instead of `...Factory`, `changeToString` instead of `toString`); or pattern suffixes (`Manager`, `Processor`, `Decorator`) attached to classes that don't implement that pattern.
- **Signal:**
```java
// bad
class ShapeMaker { Shape make(String type) { ... } }
// good
class ShapeFactory { Shape create(String type) { ... } }
```
- **Exceptions:** Domain-specific ubiquitous language from the business should win over generic technical nomenclature when they conflict; a term like `Ledger` beats a bland `AccountManager`. Don't bolt on a pattern name to sound sophisticated when no pattern exists.

### N4. Unambiguous Names  [names] · high
- **Rule:** Choose a name that admits exactly one reasonable interpretation, even if it costs more characters.
- **Why:** Ambiguity forces the reader to open the implementation to learn what the name already should have told them, defeating the purpose of naming. The subtle trap is a name that is technically defensible but invites the wrong mental model - `renameFile` that actually copies, or a helper whose name hides that it mutates and returns. Disambiguation is worth verbosity because it is paid once by the writer and saved by every reader.
- **Smell:** Names needing you to read the body to resolve intent; near-homonym siblings (`getActiveAccount`, `getActiveAccounts`, `getActiveAccountInfo`) with no discernible distinction; verbs that under-describe the transformation performed.
- **Signal:**
```java
// bad
private String doRename() { ... } // actually copies to a temp name
// good
private String copyToTempName() { ... }
```
- **Exceptions:** None as a principle - but "unambiguous" is scoped to the reader's context. Within a small, well-understood domain module a shorter name can be locally unambiguous even if it would be vague globally.

### N5. Use Long Names for Long Scopes  [names] · medium
- **Rule:** Scale a name's length to the span over which it lives - tiny scope tolerates tiny names, wide scope demands descriptive ones.
- **Why:** A name's job is to bridge the distance between declaration and use; over a two-line loop the reader still has the declaration in view, but a field referenced across hundreds of lines needs to stand on its own. The inversion is the common mistake: a terse `i` promoted to an instance field, or a bloated `theFullyQualifiedCustomerAccountRecord` used only inside one three-line block, both add friction. Length should track scope, not habit.
- **Smell:** Short cryptic names on class fields, module globals, or public API; verbose ceremonial names on loop counters and short-lived locals.
- **Signal:**
```java
// bad
public class Config { private String u; } // used everywhere
for (int index = 0; index < names.size(); index++) { ... } // trivial loop
// good
public class Config { private String upstreamServiceUrl; }
for (int i = 0; i < names.size(); i++) { ... }
```
- **Exceptions:** Widely-known short names with fixed meaning (`i`, `x`, `id`, `db`) can inhabit larger scopes when the convention is universal in the codebase and unambiguous.

### N6. Avoid Encodings  [names] · medium
- **Rule:** Don't bake type, scope, or membership prefixes into names; let the type system and IDE carry that information.
- **Why:** Encodings like Hungarian notation or `m_` prefixes are redundant with modern tooling and become lies the instant a type changes but the name doesn't. They add mental-decoding tax to every read and clutter the namespace. The subtle failure is decay: `strName` that is refactored to a `Name` value object still says `str`, so the encoding now actively misinforms.
- **Smell:** Type-tag prefixes (`strName`, `iCount`, `lpszFile`), member prefixes (`m_`, `f_`), interface `I`-prefixes (`IShapeFactory`) where the language and tooling make them noise.
- **Signal:**
```java
// bad
private String m_strDescription;
interface IShapeFactory { ... }
// good
private String description;
interface ShapeFactory { ... }
```
- **Exceptions:** A team convention that is consistent, understood, and enforced (some shops keep `I`-prefixes or a leading underscore for fields) is better than a partial migration that leaves the codebase in two styles. Consistency can outrank the ideal.

### N7. Names Should Describe Side-Effects  [names] · high
- **Rule:** Name a function for everything it does, including hidden work like creation, mutation, lazy initialization, or I/O.
- **Why:** A name that advertises only the return value hides the cost and the consequences, so callers invoke it wrongly - repeatedly, in the wrong order, or expecting idempotence it doesn't have. This is more dangerous than a merely vague name because it induces incorrect usage, not just slow reading. `getOos()` that silently creates the stream on first call should say so.
- **Smell:** A `get`/`is`/`calculate` prefix on a method that also mutates state, opens a resource, or caches; query-shaped names that secretly command.
- **Signal:**
```java
// bad
public ObjectOutputStream getOos() throws IOException {
    if (oos == null) oos = new ObjectOutputStream(socket.getOutputStream());
    return oos;
}
// good
public ObjectOutputStream createOrReturnOos() throws IOException { ... }
```
- **Exceptions:** Idiomatic lazy accessors are widely tolerated when the language convention makes the side-effect expected (e.g. a memoized getter). The key is whether the reader is genuinely surprised - benign, conventional laziness may not need the name to spell it out.

### F1. Too Many Arguments  [functions] · high
- **Rule:** Prefer zero, one, or two arguments; treat three as a warning and more than three as needing an extracted parameter object.
- **Why:** Each argument multiplies the reader's burden and the test matrix, and long lists usually signal a function doing too much or a missing concept. The subtle tell is that arguments which always travel together (`x, y` or `startDate, endDate`) are a hidden object begging to be named. Reducing arity often reveals a class you didn't know you needed.
- **Smell:** Method signatures with four-plus positional parameters, especially several of the same type in a row where callers can silently transpose them.
- **Signal:**
```java
// bad
Circle makeCircle(double x, double y, double radius) { ... }
// good
Circle makeCircle(Point center, double radius) { ... }
```
- **Exceptions:** Constructors of genuine value objects (a `Color(r, g, b, a)`) legitimately take several arguments because each is an irreducible component. Variadic APIs (`String.format`) and builder-fed calls also don't fit the count-the-params heuristic.

### F2. Output Arguments  [functions] · medium
- **Rule:** Don't use a parameter as a channel for output; return the result or mutate the object the method belongs to.
- **Why:** Readers expect arguments to flow in and results to flow out via the return value; an output argument inverts that and forces a trip to the signature or body to discover it. It also blocks composition and obscures ownership of the mutated state. The miss people make is thinking a mutating helper reads naturally - `appendFooter(report)` gives no hint whether `report` is the thing changed or the source.
- **Smell:** Methods that take an object solely to fill it in; `void` methods whose real product is a mutated parameter; the caller having to inspect the argument after the call to get the answer.
- **Signal:**
```java
// bad
public void appendFooter(StringBuffer report) { report.append(footer); }
// good
report.appendFooter();      // mutate the receiver, self-evidently
StringBuffer full = withFooter(report);  // or return a new value
```
- **Exceptions:** Performance-critical paths that must avoid allocation (filling a caller-supplied buffer, `System.arraycopy`-style APIs) legitimately use output parameters; the convention is understood and the copy is what you're paying to avoid. Document it clearly.

### F3. Flag Arguments  [functions] · medium
- **Rule:** Don't pass a boolean that selects behavior; split the function into the two operations the flag chooses between.
- **Why:** A boolean argument announces at the call site that the function does more than one thing, and `render(true)` tells the reader nothing about which thing. It also couples two code paths that testing and reading would rather see apart. The subtle cost compounds: flags accrete, and `f(true, false, true)` becomes an unreadable truth table nobody can safely change.
- **Smell:** Call sites with bare boolean literals (`buildReport(true)`); functions whose body is one big `if (flag) {...} else {...}` splitting into two unrelated behaviors.
- **Signal:**
```java
// bad
public void render(boolean isSuite) { if (isSuite) {...} else {...} }
render(true);
// good
public void renderForSuite() { ... }
public void renderForSingleTest() { ... }
```
- **Exceptions:** A boolean that is genuine data configuring one coherent behavior (`new BigDecimal(v, RoundingMode.HALF_UP)`, `setVisible(true)`) is not a flag argument. A named enum or named-argument language feature can also make the intent explicit without splitting the method.

### F4. Dead Function  [functions] · medium
- **Rule:** Delete methods that are never called; recover them from version control if ever needed.
- **Why:** Uncalled code still demands maintenance, still gets read, still misleads people into thinking it matters, and quietly rots because nothing exercises it. Keeping it "just in case" is a false economy - version control already remembers everything. The subtle danger is that dead code can pass review as if live, hiding bugs that only surface when someone resurrects it.
- **Smell:** Private methods with no references; public API kept only for a caller that no longer exists; entire strategy branches nothing constructs.
- **Signal:**
```java
// bad
private String legacyFormat(Record r) { ... } // no callers anywhere
// good
// (deleted; git remembers it if we ever need it back)
```
- **Exceptions:** Published library/API surface may retain seemingly-unused methods because external callers you can't see depend on them; reflection, serialization, and DI frameworks also invoke methods no static analysis sees. Confirm there are truly no dynamic callers before deleting.

### C1. Inappropriate Information  [comments] · low
- **Rule:** Keep comments to what the code itself can't express; put change history, authorship, and ticket metadata in the tools built for them.
- **Why:** A comment should hold design intent and rationale that source can't capture; loading it with data that belongs in version control, the issue tracker, or the changelog dilutes signal and rots fast. The subtle failure is that this metadata looks authoritative long after it's wrong - a stale `@author` or "modified 2019-03" invites false trust. Source-control-owned facts should live in source control.
- **Smell:** Change logs, author lists, last-modified dates, or ticket-status prose embedded in comments; per-file bureaucratic headers that duplicate what the VCS records.
- **Signal:**
```java
// bad
// Modified by J. Smith 2019-03-14 for JIRA-4521, reviewed by K. Lee
public void process() { ... }
// good
// Retry is required here: the upstream gateway drops the first
// connection after an idle period (see incident postmortem).
public void process() { ... }
```
- **Exceptions:** Regulated environments or licenses may mandate specific file headers (copyright, SPDX identifiers); those are required, not clutter. Keep them minimal and generated where possible.

### C2. Obsolete Comment  [comments] · high
- **Rule:** Update a comment the instant the code it describes changes, or delete it.
- **Why:** An out-of-date comment is worse than none: readers trust it, act on it, and are actively misled, and unlike code it is never executed so nothing forces it to stay true. The subtle danger is drift - a comment accurate when written slowly decouples from evolving code until it describes a system that no longer exists. Comments are a maintenance liability priced in future confusion.
- **Smell:** Comments referencing renamed variables, removed parameters, or old algorithms; "TODO: remove after launch" for a launch that shipped years ago; prose describing behavior the code no longer has.
- **Signal:**
```java
// bad
// returns null if the user is not found
public Optional<User> find(String id) { ... } // now returns Optional.empty()
// good
// returns empty if the user is not found
public Optional<User> find(String id) { ... }
```
- **Exceptions:** None - an obsolete comment should always be fixed or removed. The only debate is whether the comment should have existed at all, but once present it must not lie.

### C3. Redundant Comment  [comments] · low
- **Rule:** Don't write a comment that only restates what the code already says plainly.
- **Why:** A comment earns its place by adding information the code can't convey; one that echoes the code doubles the reading and doubles the maintenance, since now two things must be kept in sync. The subtle harm is desensitization - a wall of `// increment i` noise trains readers to skip comments, so the one genuinely important comment gets skipped too. Silence is better than restatement.
- **Smell:** Comments that transliterate the next line (`i++; // add one to i`); Javadoc that merely repeats the method name (`/** the day */ int getDay()`); banner comments over self-evident blocks.
- **Signal:**
```java
// bad
// the day of the month
private int dayOfMonth;
// good
private int dayOfMonth;
```
- **Exceptions:** Public API documentation tools (Javadoc, docstrings) sometimes require a description even when it seems obvious, to generate complete reference docs; and a "redundant"-looking comment that clarifies a non-obvious unit or invariant is not truly redundant.

### C4. Poorly Written Comment  [comments] · low
- **Rule:** If a comment is worth writing, write it well - concise, correct, grammatical, and free of rambling or in-jokes.
- **Why:** A comment is prose you're asking every future reader to parse, so sloppiness taxes them directly; a meandering or cryptic comment can cost more to decode than the code it explains. The subtle point is that effort signals importance - a terse, careful comment reads as load-bearing, while a lazy one reads as skippable even when it matters. Respect the reader's time by editing.
- **Smell:** Long-winded comments burying one useful fact; obscure abbreviations and unexplained jargon; comments that assume context the reader doesn't have; humor that obscures meaning.
- **Signal:**
```java
// bad
// this here does the thing w/ the list, u know the usual, dont touch lol
private void reconcile(List<Entry> entries) { ... }
// good
// Entries must be reconciled in submission order; the ledger
// rejects out-of-sequence adjustments.
private void reconcile(List<Entry> entries) { ... }
```
- **Exceptions:** None on quality itself - but the fix is often to delete the comment and improve the code rather than polish prose that shouldn't exist. Not every bad comment deserves a good rewrite; some deserve removal.

### C5. Commented-Out Code  [comments] · high
- **Rule:** Delete commented-out code on sight; version control preserves it.
- **Why:** Commented-out code is toxic clutter: no one dares delete it because they assume it's there for a reason, so it accumulates indefinitely and rots as the surrounding code evolves past it. It defeats searches, confuses readers about what's live, and its original purpose is forgotten within days. Git already stores every deleted line - the safety it seems to offer is illusory.
- **Smell:** Blocks of code disabled with `//` or `/* */`; "keeping this in case we need it"; stacked alternative implementations one comment-toggle apart.
- **Signal:**
```java
// bad
doThing();
// doOldThing();
// legacyPath(config, true);
// good
doThing();
```
- **Exceptions:** A brief, clearly-labeled example in documentation or a template intentionally shows disabled code as illustration - that's example prose, not dead code. Transient local debugging is fine to comment out while you work, but must not survive into a commit.

### E1. Build Requires More Than One Step  [environment] · medium
- **Rule:** Make a full build achievable with a single trivial command from a clean checkout.
- **Why:** A build that needs a sequence of manual steps, hand-collected files, or tribal knowledge is fragile and hostile to newcomers, and every undocumented step is a place the build silently diverges between machines. The subtle cost is drift: what "works on my machine" encodes local state no one wrote down, so CI and colleagues get different artifacts. One command is the only reliable contract.
- **Smell:** README build sections with many ordered manual steps; "first copy these config files, then set these vars, then run..."; builds that only succeed on one person's box.
- **Signal:**
```bash
# bad
# 1. copy secrets.template to secrets.properties and edit
# 2. run gen-sources.sh
# 3. set BUILD_ENV=local
# 4. mvn compile
# good
./build.sh   # or: mvn install — one command, clean checkout to artifact
```
- **Exceptions:** Genuinely irreducible one-time host setup (installing a language toolchain, provisioning credentials) can live outside the single command, ideally scripted or containerized. The heuristic targets repeatable builds, not first-ever machine bootstrap.

### E2. Tests Require More Than One Step  [environment] · medium
- **Rule:** Make the whole test suite runnable with one command that anyone can invoke from the IDE or a clean shell.
- **Why:** Tests only protect you if they're trivial to run; any friction - manual setup, a running external service, a special environment - means people skip them, and unrun tests provide false confidence while silently rotting. The subtle failure is partial runnability: tests that pass only after undocumented local setup will fail in CI or for a teammate, eroding trust in the suite. Frictionless tests are run tests.
- **Smell:** "To run the integration tests, first start the DB, then seed it, then export these vars, then..."; suites that only pass on one configured machine; test docs longer than a single line.
- **Signal:**
```bash
# bad
# start docker-compose, wait for postgres, run seed.sql, set TEST_DB_URL, then:
# mvn -Pintegration test
# good
mvn test     # spins up its own fixtures; green from a clean checkout
```
- **Exceptions:** Heavy end-to-end suites needing real external infrastructure may reasonably require provisioning, but that setup should be scripted (containers, test-containers, a make target) rather than manual. Fast unit tests should always be one step regardless.

## Tests (T)

### T1. Insufficient Tests  [Tests] · high
- **Rule:** Write enough tests to exercise every condition and behavior that could plausibly break, not just the path you happened to code first.
- **Why:** A suite is judged by what could still break while every test passes, not by how many tests it holds. Happy-path-only coverage produces false confidence, because bugs live in the branches, error returns, and empty inputs nobody bothered to assert. The subtle failure: a green suite lets a reviewer assume "tested" when whole conditions of the method were never entered.
- **Smell:** A method with several branches, guards, or error paths but only one or two tests, all feeding it well-formed nominal input; no assertion touches null, empty, negative, or the failure return.
- **Signal:**
```java
// bad
@Test void parsesValidAmount() {
  assertEquals(1200, Money.parse("12.00").cents());
}
// good
@Test void parsesValidAmount() { assertEquals(1200, Money.parse("12.00").cents()); }
@Test void rejectsNegative()   { assertThrows(BadAmount.class, () -> Money.parse("-1.00")); }
@Test void rejectsNonNumeric() { assertThrows(BadAmount.class, () -> Money.parse("abc")); }
@Test void rejectsEmpty()      { assertThrows(BadAmount.class, () -> Money.parse("")); }
```
- **Exceptions:** Trivial delegations the compiler already checks, generated code, and throwaway spikes don't earn exhaustive tests. "Enough" is about behaviors that can break, not a coverage percentage - don't manufacture tests for conditions the type system already forbids.

### T2. Use a Coverage Tool!  [Tests] · medium
- **Rule:** Run a coverage tool and read its report to find the untested paths your eyes glossed over.
- **Why:** Human intuition about what is tested is unreliable; a tool shows exactly which lines and branches never execute under test, usually highlighted right in the editor. The gap it exposes is cheap to close and the report is objective where memory is not. The subtle failure people miss: assuming a branch is covered because an adjacent, similar-looking branch is.
- **Smell:** No coverage instrumentation wired into the build; review comments guessing "I think that error path is tested" with no way to confirm.
- **Signal:**
```java
// bad — the else is never entered by any test, and nobody noticed
if (user.isActive()) { grant(user); }
else                 { audit.denied(user); }   // 0 hits in coverage report
// good — coverage report shows both arms exercised
@Test void activeUserGranted()   { svc.access(active);   verify(gate).grant(active); }
@Test void inactiveUserAudited() { svc.access(inactive); verify(audit).denied(inactive); }
```
- **Exceptions:** Coverage is a diagnostic, not a goal. Gating merges on a line-coverage number invites assertion-free tests written only to touch lines (Goodhart's law), and 100% line coverage can still miss the input that breaks. Prefer branch coverage as the signal, and treat the report as a map of gaps to reason about, not a score to maximize.

### T3. Don't Skip Trivial Tests  [Tests] · low
- **Rule:** Write the trivial tests too; their documentary value usually exceeds their defect-catching value.
- **Why:** Tests that seem too obvious to write still serve as executable specification of intended behavior, and they catch the regression that arrives the day "trivial" quietly becomes non-trivial. The cost of writing one is minutes; the cost of the undocumented assumption is a future reader guessing. The subtle point: you write these to explain, not primarily to defend.
- **Smell:** A behavior explained only in a prose comment or a PR description with no corresponding assertion; "it's obvious" used as the reason a small rule isn't tested.
- **Signal:**
```java
// bad — behavior documented only in a comment
// empty cart totals to zero
public Money total(Cart c) { ... }
// good — behavior documented as an executable fact
@Test void emptyCartTotalsToZero() {
  assertEquals(Money.ZERO, checkout.total(new Cart()));
}
```
- **Exceptions:** Auto-generated accessors and one-line pass-throughs the compiler validates aren't worth a test. Real tradeoff: an unbounded pile of trivial tests adds maintenance drag and noise, so weigh documentary value against the reader's attention - test the trivial rule that carries intent, skip the tautology.

### T4. An Ignored Test Is a Question about an Ambiguity  [Tests] · low
- **Rule:** Record uncertainty about a requirement as an explicitly disabled test, not as a deleted test or a mental note.
- **Why:** When behavior is genuinely ambiguous or not yet implemented, a disabled test with a reason keeps the open question visible inside the suite, where it will be seen, instead of lost in a backlog. It states "we know this case exists and haven't decided" in the most durable place. The subtle failure: disabled tests silently accumulate and rot, so each one needs a reason and a trigger to revisit.
- **Smell:** A `// TODO: what should happen when...` in prose instead of a test; or a `@Disabled` with no message and no ticket, indistinguishable from something quietly broken.
- **Signal:**
```java
// bad
// TODO figure out what refund() does for a partially-shipped order
// good
@Disabled("PER-1234: refund policy for partially-shipped orders undecided")
@Test void refundOnPartiallyShippedOrder() { /* spec pending */ }
```
- **Exceptions:** Don't use `@Disabled` as a hiding place for flaky or failing tests - that suppresses real signal. An ignore with no documented reason is just dead code; if the question is answered or abandoned, resolve the test rather than leaving it disabled forever.

### T5. Test Boundary Conditions  [Tests] · high
- **Rule:** Test the boundaries explicitly - zero, one, empty, full, max, and the off-by-one ends of every range.
- **Why:** Code that handles typical inputs correctly routinely fails at the edges, because loop bounds, index arithmetic, and capacity checks are where reasoning is hardest. The subtle failure people miss: we instinctively test the middle of the range where our mental model is clearest, but the middle is exactly where code rarely breaks. The edge is under-tested precisely because it is under-thought.
- **Smell:** Every test feeds a comfortable mid-range value (a list of three, a positive integer well below any limit); no case for empty, single-element, at-capacity, or the value one past the limit.
- **Signal:**
```java
// bad
@Test void averageOfThree() { assertEquals(2.0, stats.average(List.of(1,2,3))); }
// good
@Test void averageOfThree() { assertEquals(2.0, stats.average(List.of(1,2,3))); }
@Test void averageOfOne()   { assertEquals(5.0, stats.average(List.of(5))); }
@Test void emptyThrows()    { assertThrows(NoElements.class, () -> stats.average(List.of())); }
@Test void handlesOverflow(){ assertEquals(Long.MAX_VALUE, stats.average(List.of(Long.MAX_VALUE))); }
```
- **Exceptions:** None on the principle - always probe the edges. What varies is which boundaries are real for the domain; don't fabricate impossible edges (a "negative length" that the type or a prior validation makes unreachable) just to add a case.

### T6. Exhaustively Test Near Bugs  [Tests] · medium
- **Rule:** When you find one bug, write a cluster of tests around it, because defects congregate.
- **Why:** Bugs are not uniformly distributed; a region that produced one error usually reflects an author's local misunderstanding that produced several. Fixing only the reported case and leaving its neighbors live is how the same module comes back next sprint. The subtle failure: the single regression test proves the reported input is fixed but says nothing about the three adjacent inputs that share the flawed logic.
- **Smell:** A bug-fix PR that adds exactly one test - the literal reproduction from the ticket - with no probing of the surrounding conditions or the inverse case.
- **Signal:**
```java
// bad — only the reported input
@Test void discountBugReported() { assertEquals(90, price.apply(100, 10)); }
// good — a battery around the flawed region
@Test void discountReported()     { assertEquals(90, price.apply(100, 10)); }
@Test void zeroDiscount()         { assertEquals(100, price.apply(100, 0)); }
@Test void fullDiscount()         { assertEquals(0,  price.apply(100, 100)); }
@Test void overHundredRejected()  { assertThrows(BadDiscount.class, () -> price.apply(100, 101)); }
@Test void negativeRejected()     { assertThrows(BadDiscount.class, () -> price.apply(100, -5)); }
```
- **Exceptions:** A time-boxed production hotfix may ship with just the reproduction test, but file the follow-up to complete the battery. Don't over-apply it to a one-off typo whose neighborhood is genuinely trivial.

### T7. Patterns of Failure Are Revealing  [Tests] · medium
- **Rule:** Read the shape of which tests pass and fail across the suite as a diagnostic, not each red test in isolation.
- **Why:** A comprehensive, well-ordered set of tests turns the pass/fail matrix into a clue: "everything above length 8 fails" or "all even inputs fail" points straight at the cause. The diagnosis lives in the correlation, not in any single failure. The subtle failure: debugging one red test at a time and never stepping back to see that six failures share one boundary.
- **Smell:** Ad-hoc test names and unstructured data that make a common cause invisible; a triage habit of opening the first failure and ignoring the distribution of the rest.
- **Signal:**
```java
// bad — opaque cases; a shared cause can't be seen
@Test void case1() {...} @Test void case2() {...} @Test void case3() {...}
// good — parameterized so the failing pattern is legible
@ParameterizedTest @ValueSource(ints = {1, 4, 7, 8, 9, 15})
void encodes(int n) { assertEquals(ref(n), codec.encode(n)); }
// failures cluster at n >= 8 -> suspect an 8-bit width bug immediately
```
- **Exceptions:** The heuristic needs a reasonably complete, systematically organized suite to work - with a handful of scattered tests there is no pattern to read, and forcing one wastes time.

### T8. Test Coverage Patterns Can Be Revealing  [Tests] · low
- **Rule:** Inspect which code paths the passing tests do and don't execute to help localize why the failing cases fail.
- **Why:** Comparing the lines exercised by green tests against those hit by a failing case narrows the fault to the branch that only the failure touches. Coverage is a debugging instrument here, not a quality score - it tells you where the suspect code is, not how good the suite is. The subtle point: the information is in the passing tests' coverage as much as the failing one's.
- **Smell:** Debugging a failure purely by reading source and adding print statements, without ever consulting which branches the passing versus failing tests actually run.
- **Signal:**
```java
// conceptual
// green tests all execute the fast-path branch; the one red test is the
// only case that enters the cache-miss branch -> the defect is in cache-miss,
// not in the shared logic both paths run.
```
- **Exceptions:** Diminishing returns on simple code where the bug is obvious by inspection; this earns its keep on tangled control flow where the responsible branch isn't apparent from reading alone.

### T9. Tests Should Be Fast  [Tests] · high
- **Rule:** Keep the unit suite fast, because a slow suite gets skipped and a skipped suite rots.
- **Why:** A test's value is proportional to how often it actually runs; every second added trains developers to run it less, until it only executes in CI and stops guarding local changes. Slowness accretes invisibly - a `sleep` here, a real database there - until the whole suite is quarantined. The subtle failure: no single addition feels slow, but the sum crosses the threshold where people stop running it before commit.
- **Smell:** `Thread.sleep` in tests, real network/DB/filesystem access in unit tests, a heavyweight container or Spring context spun up per test class.
- **Signal:**
```java
// bad — wall-clock waits and a real socket in a unit test
@Test void retriesThenSucceeds() throws Exception {
  Thread.sleep(2000);
  assertTrue(client.callRealEndpoint().ok());
}
// good — injected clock and in-memory fake; runs in microseconds
@Test void retriesThenSucceeds() {
  var clock = new MutableClock();
  var client = new Client(fakeTransport, clock);
  clock.advance(Duration.ofSeconds(2));
  assertTrue(client.call().ok());
}
```
- **Exceptions:** Integration and end-to-end tests are legitimately slower and shouldn't be sacrificed for speed - segregate them into a separate tier that runs in CI or on demand, so the fast unit suite stays fast enough to run on every save.
