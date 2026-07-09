# 100 Go Mistakes — full rule detail (100 items)

Synthesized from *100 Go Mistakes and How to Avoid Them* (Teivah), grounded in the book's runnable examples and updated for current Go (1.22 loop vars, 1.25 container-aware GOMAXPROCS, slices/maps, math/rand/v2). Original wording; titles are factual references. One item per book mistake.

## Code & Project Organization

### 1. Variable shadowing  [code-org] · high
- **Rule:** Never redeclare with `:=` inside an inner block a variable you meant to assign in the outer scope; assign to the existing variable instead.
- **Why:** `x, err := f()` inside an `if`/`else` block creates a *new* `x` scoped to that block, leaving the outer `x` at its zero value once the block exits. The code compiles and even reads correctly, so the bug is invisible until the outer variable is used downstream holding `nil`/zero. The classic form is a `var client *http.Client` declared outside a branch, then `client, err := ...` inside each branch — the outer `client` is never assigned. `go vet` does not catch this by default; you need the `shadow` analyzer (`golang.org/x/tools/go/analysis/passes/shadow`).
- **Smell:** A `var x T` at function scope, then `x, err := ...` (colon-equals) inside an `if`/`for`/`switch` block that was supposed to set the outer `x`; the outer variable read after the block.
- **Signal:**
```go
// bad: inner client shadows outer; outer stays nil
var client *http.Client
if tracing {
	client, err := createClientWithTracing() // new client + new err
	if err != nil {
		return err
	}
	log.Println(client)
}
_ = client // always nil here
// good: declare err too, use = so the outer client is assigned
var client *http.Client
var err error
if tracing {
	client, err = createClientWithTracing()
} else {
	client, err = createDefaultClient()
}
if err != nil {
	return err
}
```
- **Exceptions:** Shadowing is fine and idiomatic when the inner variable is genuinely local to the block (e.g. a per-iteration `err` you handle inside the loop, or a short-lived temp that never needs to escape). The rule targets redeclaring a name whose outer binding you still rely on.

### 2. Unnecessary nesting  [code-org] · medium
- **Rule:** Flatten happy-path code by returning early on error/edge conditions instead of wrapping the success case in `else` blocks.
- **Why:** Each nesting level adds mental state the reader must hold; deeply nested `if/else` chains force you to track which branch you are in and scan to the bottom to find the normal outcome. The mechanical fix - handle the deviation, `return`, and let the mainline stay at the leftmost column - means the "happy path" reads top-to-bottom with no indentation. An `else` after an `if` that ends in `return` is always removable, and Go's linters (`gofmt`/`golint`/`revive`'s `indent-error-flow`) call it out.
- **Smell:** `if err != nil { return } else { ... }`; arrow-shaped code where the meaningful logic sits 4+ tabs deep; a function whose final `return` is buried inside nested `else` branches.
- **Signal:**
```go
// bad: arrow anti-pattern
func join(s1, s2 string, max int) (string, error) {
	if s1 == "" {
		return "", errors.New("s1 is empty")
	} else {
		if s2 == "" {
			return "", errors.New("s2 is empty")
		} else {
			// ... deeper still
		}
	}
}
// good: guard clauses, mainline unindented
func join(s1, s2 string, max int) (string, error) {
	if s1 == "" {
		return "", errors.New("s1 is empty")
	}
	if s2 == "" {
		return "", errors.New("s2 is empty")
	}
	concat, err := concatenate(s1, s2)
	if err != nil {
		return "", err
	}
	if len(concat) > max {
		return concat[:max], nil
	}
	return concat, nil
}
```
- **Exceptions:** When both branches do substantive, symmetric work (neither is an early exit), an explicit `if/else` is clearer than contorting one side into a guard. Flattening is about removing *dead* `else` blocks after a terminating statement, not banning `else`.

### 3. Misusing init()  [code-org] · high
- **Rule:** Prefer explicit initialization functions that return an error over `init()`; reserve `init` for setup that genuinely cannot fail and needs no configuration.
- **Why:** `init` has three traps. It cannot return an error, so failures must `panic`/`log.Fatal`, taking down the whole program and making the dependency untestable. It runs implicitly at package import - side effects fire merely because someone imported the package (a footgun with blank imports), and ordering across files/packages is compiler-controlled, not obvious. And global state set in `init` (a package-level `*sql.DB`) can't be swapped in tests or configured per-caller. An explicit `func NewClient(dsn string) (*sql.DB, error)` returns errors, defers side effects to the caller's choosing, and is trivially mockable.
- **Smell:** `func init()` that opens a DB/connection, reads env vars, or does I/O that can fail; a package-level `var db *sql.DB` populated by `init`; `log.Panic`/`log.Fatal` inside `init`.
- **Signal:**
```go
// bad: fails via panic, sets untestable global, runs on import
var db *sql.DB
func init() {
	d, err := sql.Open("mysql", os.Getenv("MYSQL_DATA_SOURCE_NAME"))
	if err != nil {
		log.Panic(err)
	}
	if err = d.Ping(); err != nil {
		log.Panic(err)
	}
	db = d
}
// good: explicit, error-returning, caller owns lifecycle
func createClient(dsn string) (*sql.DB, error) {
	db, err := sql.Open("mysql", dsn)
	if err != nil {
		return nil, err
	}
	if err := db.Ping(); err != nil {
		return nil, err
	}
	return db, nil
}
```
- **Exceptions:** `init` is appropriate for pure, infallible registration - populating a static lookup table, registering a `database/sql` driver or `image` decoder, or compiling a `regexp.MustCompile` package var. These have no config, cannot meaningfully fail, and benefit from running exactly once at import.

### 4. Overusing getters/setters  [code-org] · low
- **Rule:** Expose struct fields directly; add a getter/setter only when the method adds behavior (validation, computation, synchronization, interface satisfaction).
- **Why:** Go has no convention mandating encapsulation-by-accessor the way Java does; `foo.Balance` is idiomatic and the community does not expect `foo.GetBalance()`. Reflexively wrapping every field in `Get`/`Set` pairs adds boilerplate and noise without protecting any invariant - the setter that just does `c.value = v` buys nothing over an exported field. Accessors earn their place when they enforce a bound, lazily compute, guard with a mutex, or let the type satisfy an interface. Note Go's idiom drops the `Get` prefix: the getter for `value` is `Value()`, not `GetValue()`.
- **Smell:** `func (c *T) GetX() X { return c.x }` and `func (c *T) SetX(x X) { c.x = x }` with no logic; a `Get`-prefixed getter; every unexported field mirrored by a trivial accessor pair.
- **Signal:**
```go
// bad: ceremony with no behavior
type IntConfig struct{ value int }
func (c *IntConfig) Get() int      { return c.value }
func (c *IntConfig) Set(v int)     { c.value = v }
// good: a method only where it enforces an invariant
type IntConfig struct{ Value int } // just export it
func (c *IntConfig) SetPort(p int) error {
	if p < 0 {
		return errors.New("port must be non-negative")
	}
	c.Value = p
	return nil
}
```
- **Exceptions:** Use accessors when you must keep future flexibility in a public API (adding logic later without a breaking change), enforce validation/bounds, guard concurrent access, expose a read-only view of an unexported field, or satisfy an interface like `intConfigGetter{ Get() int }`.

### 5. Interface on producer side  [code-org] · medium
- **Rule:** Define an interface in the package that *consumes* it, scoped to the exact methods that consumer needs - not in the package that implements it.
- **Why:** An interface declared alongside its implementation (producer side) forces every consumer to depend on the producer's chosen abstraction, and it tempts the producer to enumerate every method a concrete type offers. That fat, producer-owned interface couples callers to methods they don't use and makes the concrete type harder to evolve. When the *consumer* declares a minimal interface (`customersGetter{ GetAllCustomers() ... }`), coupling is minimized, the abstraction is discovered from real need rather than speculation, and any type with that one method satisfies it implicitly. Go's implicit satisfaction is what makes this work - the producer needn't know the interface exists.
- **Smell:** A `store` package exporting a 6-method `CustomerStorage` interface next to its concrete `Store`; consumers importing that interface wholesale; an interface whose method set mirrors a struct's entire public surface.
- **Signal:**
```go
// bad: producer package defines a fat interface for everyone
package store
type CustomerStorage interface {
	StoreCustomer(Customer) error
	GetCustomer(id string) (Customer, error)
	UpdateCustomer(Customer) error
	GetAllCustomers() ([]Customer, error)
	// ...more
}
// good: consumer defines just what it uses
package client
type customersGetter interface {
	GetAllCustomers() ([]store.Customer, error)
}
```
- **Exceptions:** Producer-side interfaces are justified when the abstraction is the package's whole purpose and it is known upfront that clients must conform (e.g. `io.Reader`/`io.Writer`, `database/sql/driver`, `encoding.BinaryMarshaler`). These are stable, minimal contracts many implementations target - the opposite of a speculative fat interface.

### 6. Returning interfaces  [code-org] · medium
- **Rule:** Return concrete types from constructors and accept interfaces as parameters; don't return an interface just to seem abstract.
- **Why:** "Be conservative in what you return, liberal in what you accept." Returning a concrete type gives callers the full API and lets *them* decide which minimal interface to depend on; returning an interface strips capabilities and, worse, can create an import cycle - the returning package must define or import the interface, and consumers must import that package, so the abstraction pulls dependencies the wrong direction. Accepting interfaces at the parameter side is where flexibility actually belongs. A returned interface also invites the nil-interface trap: a `(*T)(nil)` wrapped in an interface is non-nil, so `if err != nil` misfires.
- **Smell:** `func New() SomeInterface { return &concrete{} }`; constructors advertising an interface return type; a package that both defines an interface and returns it from its own constructor.
- **Signal:**
```go
// bad: hides the concrete API, risks coupling/cycles
func NewStore() Storer { return &store{} }
// good: return concrete, accept interface
func NewStore() *Store { return &Store{} }
func Copy(src io.Reader, dst io.Writer) error { /* accept interfaces */ }
```
- **Exceptions:** Returning an interface is right when the concrete type must stay unexported (returning `error`, which is always an interface, is the canonical case), when a factory legitimately produces one of several implementations chosen at runtime, or for standard-library patterns where the interface *is* the contract.

### 7. `any` says nothing  [code-org] · high
- **Rule:** Prefer concrete types or narrow, meaningful interfaces over `any` (`interface{}`); reach for `any` only when you truly cannot constrain the type at compile time.
- **Why:** `any` erases all compile-time type information: a `Get(id) (any, error)` / `Set(id, v any)` store lets a caller store a `Customer` and retrieve it as a `Contract` with no compiler complaint, pushing every check to a runtime type assertion that can panic or silently mis-handle. Explicit method signatures (`GetCustomer`/`SetContract`) document intent, let the compiler catch misuse, and need no assertions. Since Go 1.18, generics remove most of the remaining "but I need to be type-agnostic" cases - a generic function keeps type safety where `any` throws it away. `any` is a type alias for `interface{}` (Go 1.18+); switching spelling changes nothing about the underlying erasure.
- **Smell:** Function signatures taking or returning `any`/`interface{}` for domain data; `switch v := x.(type)` fanning out over concrete types the API could have named; a generic-looking container built on `map[string]any`.
- **Signal:**
```go
// bad: no compile-time safety, caller must assert
type Store struct{}
func (s *Store) Get(id string) (any, error)      { /* ... */ }
func (s *Store) Set(id string, v any) error      { /* ... */ }
// good: explicit per-type methods (or generics)
func (s *Store) GetCustomer(id string) (Customer, error) { /* ... */ }
func (s *Store) SetContract(id string, c Contract) error { /* ... */ }
```
- **Exceptions:** `any` is legitimate when the code genuinely operates on unconstrained values - `fmt.Println(...any)`, `json.Unmarshal(data, any)`, `encoding/gob`, a marshaler, or a container that by design holds heterogeneous values. The test: does the function actually need to know nothing about the type? If it does need to know, name it.

### 8. Generics  [code-org] · medium
- **Rule:** Use type parameters to remove real, repeated duplication across types; don't generify code that has a single concrete call-site or where a concrete type is clearer.
- **Why:** Generics (Go 1.18+) shine for type-agnostic *data structures* (linked lists, trees, channels, pools) and for functions that work uniformly over element types (`getKeys[K comparable, V any](map[K]V) []K` replaces per-type `any`-based type switches). But premature generification is a real cost: it adds `[T constraint]` noise, harder-to-read signatures, and worse error messages for a factoring that only ever serves one type. The book's guidance - wait until you actually see duplication - still holds. Modern Go also ships generic helpers you should reach for before rolling your own: the `slices` and `maps` packages (stdlib since 1.21) and `sync.OnceFunc`/`OnceValue`.
- **Smell:** A `[T any]` function with exactly one instantiation; a constraint that could just be a concrete type; hand-written generic `Map`/`Filter`/`Keys`/`Contains` that duplicate `slices`/`maps`; generics used where an interface parameter would read better.
- **Signal:**
```go
// bad: type switch over any, one behavior per type, no safety
func getKeys(m any) ([]any, error) {
	switch t := m.(type) {
	case map[string]int: /* ... */
	case map[int]string: /* ... */
	default:
		return nil, fmt.Errorf("unknown type: %T", t)
	}
}
// good: one type-safe generic version
// (or slices.Collect(maps.Keys(m)) - stdlib maps.Keys returns iter.Seq[K] since 1.23)
func getKeys[K comparable, V any](m map[K]V) []K {
	keys := make([]K, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	return keys
}
```
- **Exceptions:** Skip generics when a plain interface expresses the behavior (methods, not element types), when there is exactly one type in play, or when a concrete signature is materially clearer. Also note method-level type parameters are not allowed - if a method needs its own type parameter, the type parameter belongs on the struct.

### 9. Embedding confusion  [code-org] · medium
- **Rule:** Embed a type only when you deliberately want its exported methods promoted as part of your own API; otherwise use a named field.
- **Why:** Embedding promotes the inner type's methods and fields to the outer type, but it does *not* create an is-a relationship or preserve identity - the outer type is not a subtype of the inner. The subtle failure is accidental promotion: embedding `sync.Mutex` in an *exported* struct promotes `Lock`/`Unlock` into the public API, letting external callers lock your internal mutex; embedding a type leaks methods you never intended to expose, and later changes to the inner type silently change your surface. Use a named field (`mu sync.Mutex`, `writeCloser io.WriteCloser`) when you only want to *use* the inner type, forwarding just the methods you choose.
- **Smell:** `sync.Mutex` (or any locking/internal type) embedded in an exported struct; embedding done to save typing a field name rather than to promote an API; an embedded field whose promoted methods you then have to document around or hide.
- **Signal:**
```go
// bad: promotes Lock/Unlock into InMem's public API
type InMem struct {
	sync.Mutex
	m map[string]int
}
// good: named field; mutex stays an implementation detail
type InMem struct {
	mu sync.Mutex
	m  map[string]int
}
func (i *InMem) Get(k string) (int, bool) {
	i.mu.Lock()
	defer i.mu.Unlock()
	v, ok := i.m[k]
	return v, ok
}
```
- **Exceptions:** Embedding is the right tool when promoting the inner API is exactly the intent - e.g. a `Logger` embedding an `io.WriteCloser` to expose `Write`/`Close`, wrapping a `sync.Mutex` in an *unexported* struct, or composing interfaces (`io.ReadWriteCloser`). The question to ask: do I want callers to see the promoted methods as mine?

### 10. Functional options  [code-org] · medium
- **Rule:** For APIs with a growing or largely-optional configuration set, use the functional options pattern (`...Option` where `Option func(*options) error`); keep genuinely required parameters as positional constructor arguments.
- **Why:** A plain config struct can't distinguish "unset" from "zero" (is `Port: 0` a request for a random port or an untouched field?), forces callers to pass an empty struct even when they want all defaults, and can't validate on set. Builders add ceremony and an error-handling seam (`Build()`) that's easy to forget. Functional options make each option self-contained (it can validate and return an error), let callers pass only what they want, keep the API extensible without breaking existing callers, and use pointer fields internally to tell "absent" from "zero". The cost is more boilerplate, so reserve it for real optionality - required inputs stay in the signature.
- **Smell:** A constructor taking a large config struct where most fields are optional; `Port: 0` ambiguity between "default" and "explicitly zero"; a builder whose only job is to hold optional fields; adding a parameter to a constructor forcing every call-site to change.
- **Signal:**
```go
// bad: struct can't tell unset from zero, no per-field validation
func NewServer(addr string, cfg Config) { /* Port 0 == default? or random? */ }
NewServer("localhost", Config{})
// good: options validate, callers pass only what they set
type Option func(*options) error
func WithPort(port int) Option {
	return func(o *options) error {
		if port < 0 {
			return errors.New("port should be positive")
		}
		o.port = &port // pointer distinguishes absent from zero
		return nil
	}
}
func NewServer(addr string, opts ...Option) (*http.Server, error) { /* ... */ }
NewServer("localhost", WithPort(8080))
```
- **Exceptions:** Don't reach for functional options when configuration is small and mostly required - a couple of positional args or a simple config struct is clearer and lighter. The pattern pays off with many options, most optional, especially in a library API you must extend without breaking callers.

## Data Types

### 11. Octal literals  [data-types] · low
- **Rule:** Write octal constants with the explicit `0o` prefix (`0o755`), never the bare leading-zero form (`0755`).
- **Why:** A leading `0` silently marks the literal as octal, so `100 + 010` is `100 + 8 = 108`, not `110`. The value is correct Go and compiles clean; the bug is purely in the reader's head, which is exactly why it survives review. File modes, and any constant a human reads as decimal, are the usual victims. Go 1.13 added the `0o`/`0O` prefix precisely to make the base unmissable.
- **Smell:** Integer literals with a leading zero and more than one digit (`0700`, `0640`) outside an obvious octal context, or arithmetic mixing `0`-prefixed and plain literals.
- **Signal:**
```go
// bad
sum := 100 + 010        // 108, not 110 — 010 is octal 8
os.Chmod(p, 0755)       // works, but the base is implicit
// good
sum := 100 + 0o10       // reads unambiguously as octal 8
os.Chmod(p, 0o755)      // explicit octal file mode
```
- **Exceptions:** None worth keeping. The legacy `0` form still compiles for backward compatibility, but there is no reason to write new code with it.

### 12. Integer overflow  [data-types] · high
- **Rule:** Check for overflow *before* performing integer arithmetic that can exceed the type's range; do not rely on any runtime signal.
- **Why:** Go integer overflow is silent two's-complement wrap-around at compile-time-known and runtime alike — no panic, no error, `math.MaxInt32 + 1` becomes `math.MinInt32`. (Only *constant* expressions that overflow are rejected at compile time.) The subtle failure is that the wrapped value is a plausible-looking number that flows downstream into indexing, sizing, or accounting logic. Detection must be explicit: for addition test `a > math.MaxInt-b`; for multiplication divide the result back (`result/b != a`) and special-case `0`, `1`, and `math.MinInt`.
- **Smell:** `counter++`, `a + b`, `a * b` on `int32`/`uint`/`int` where inputs are attacker- or accumulation-driven, with no guard; casting a wider type down (`int32(x)`) without a range check.
- **Signal:**
```go
// bad
func Inc32(c int32) int32 { return c + 1 } // wraps to MinInt32 at the ceiling
// good
func Inc32(c int32) int32 {
    if c == math.MaxInt32 {
        panic("int32 overflow")
    }
    return c + 1
}
func AddInt(a, b int) int {
    if a > math.MaxInt-b {
        panic("int overflow")
    }
    return a + b
}
```
- **Exceptions:** Wrap-around is intentional and fine for hashing, ring buffers, checksums, and counters you explicitly want to be modular. `math/bits.Add64`/`Mul64` give the carry/hi bits directly when you need them.

### 13. Float precision  [data-types] · high
- **Rule:** Never use `float32`/`float64` for money or exact decimal arithmetic; for accumulation, control the order of operations and prefer integer minor units or `math/big`.
- **Why:** IEEE-754 floats are base-2 approximations, so values like `0.1` and `1.0001` are not represented exactly and error compounds per operation. Crucially, float addition is not associative: summing many small terms and *then* adding a large one (`sum + 10000.`) preserves more precision than seeding with the large one first, so two mathematically identical loops return different results. `float32` has only ~24 mantissa bits (~7 decimal digits), so large integers like Unix timestamps lose resolution. Division by zero yields `±Inf`; `0.0/0.0` yields `NaN`, and `NaN != NaN`, which quietly breaks equality and sort logic.
- **Smell:** `float64` fields named `price`, `amount`, `balance`; equality comparisons on floats; `float32` holding IDs or timestamps; summing a slice of floats in arbitrary order and comparing the total.
- **Signal:**
```go
// bad
var price float64 = 0.1
total := price * 3           // 0.30000000000000004
// good
cents := int64(10)           // store money as integer minor units
total := cents * 3           // exact
// for high-precision decimals:
d := new(big.Float).SetPrec(200)
```
- **Exceptions:** Floats are the right tool for scientific/statistical work where relative error is acceptable. When you must compare floats, test `math.Abs(a-b) < epsilon` (and handle `NaN`/`Inf` explicitly).

### 14. Slice length vs capacity  [data-types] · medium
- **Rule:** Keep `len` (elements addressable now) and `cap` (elements the backing array can hold) distinct in your head, and preallocate capacity with `make([]T, 0, n)` when the final size is known.
- **Why:** `make([]int, 3, 6)` gives a length-3, capacity-6 slice; indexing past `len` panics even though the capacity exists, and `append` fills the spare capacity in place before it reallocates. When capacity is exhausted, `append` allocates a new, larger backing array (historically ~2x for small slices, ~1.25x for large ones — the exact factor is an unspecified implementation detail, retuned in Go 1.18) and copies, so the returned slice no longer shares memory with the original. The subtle bug: a reslice like `s2 := s1[1:3]` shares `s1`'s backing array, so writes through one are visible in the other *until* an `append` triggers reallocation and silently decouples them.
- **Smell:** `make([]T, 0)` followed by a known-count `append` loop; assuming two reslices stay aliased after `append`; indexing a slice in `[len, cap)` and expecting valid data.
- **Signal:**
```go
// bad
bars := make([]Bar, 0)          // reallocates repeatedly as it grows
for _, f := range foos { bars = append(bars, conv(f)) }
// good
bars := make([]Bar, 0, len(foos)) // one allocation, capacity reserved
for _, f := range foos { bars = append(bars, conv(f)) }
```
- **Exceptions:** When the final count is genuinely unknown, plain `append` growth is fine — do not guess a capacity you can't justify. If every element is written by index (not appended), `make([]T, n)` + `bars[i] = ...` is marginally faster than the `0, n` form.

### 15. nil vs empty slice  [data-types] · medium
- **Rule:** Return a `nil` slice (not `[]T{}` / `make([]T, 0)`) to signal "no elements," and test emptiness with `len(s) == 0`, never `s != nil`.
- **Why:** A `nil` slice and a non-nil empty slice behave identically for `len`, `cap`, `range`, and `append` — the only observable differences are `s == nil` and JSON marshaling, where a `nil` slice encodes as `null` and an empty slice as `[]`. Checking `operations != nil` to decide whether to process is a bug: `make([]float32, 0)` is non-nil but empty, so the guard passes and you process zero elements (or worse, the semantics diverge from a genuine `nil`). `len(s) == 0` is the single check that is correct for both representations.
- **Smell:** `if s != nil` used as an "is there data" test; `return []T{}` in a hot path where `nil` would do; inconsistent init (`var s []T` in one branch, `make([]T,0)` in another) feeding the same JSON response.
- **Signal:**
```go
// bad
if operations != nil { handle(operations) }   // true even for make([]T,0)
// good
if len(operations) != 0 { handle(operations) } // correct for nil and empty
// return nil, not []T{}, when there is nothing:
func find() []int { return nil }
```
- **Exceptions:** When an external API contract requires `[]` rather than `null` (some JSON consumers reject `null`), deliberately return `[]T{}`. Some ORMs/serializers distinguish nil from empty on purpose; honor that contract explicitly.

### 16. copy() semantics  [data-types] · medium
- **Rule:** Size the destination with `make([]T, len(src))` before `copy(dst, src)`; the number of elements copied is `min(len(dst), len(src))`, not `len(src)`.
- **Why:** `copy` is bounded by the *length* of the destination, not its capacity and not the source length. Copying into a `nil` or zero-length `dst` copies zero elements and returns `0`, leaving `dst` empty with no error — a classic "it printed `[]`" bug. `make([]T, 0, n)` is also wrong here because `len` is still `0`. Since Go 1.21, `slices.Clone(src)` does the allocate-and-copy in one call and is the idiomatic replacement for the manual pattern.
- **Smell:** `var dst []T; copy(dst, src)`; `dst := make([]T, 0, len(src)); copy(dst, src)`; ignoring `copy`'s returned count when a full copy is assumed.
- **Signal:**
```go
// bad
var dst []int
copy(dst, src)              // copies 0 elements; dst stays empty
// good
dst := make([]int, len(src))
copy(dst, src)
// or, Go 1.21+:
dst := slices.Clone(src)
```
- **Exceptions:** A short `dst` is intentional when you deliberately want only a prefix. `copy` also legitimately copies from a `string` into a `[]byte`, and overlapping src/dst slices are handled correctly.

### 17. Slice append aliasing  [data-types] · high
- **Rule:** Before handing a sub-slice to code that may `append`, cap it with the full three-index expression `s[low:high:high]` so a subsequent append reallocates instead of overwriting the parent's backing array.
- **Why:** `s[:2]` shares `s`'s backing array *and* its spare capacity, so `append` inside a callee writes into `s[2]` — a spooky mutation of a variable the callee never named. The three-index slice `s[:2:2]` sets capacity equal to length, so the very next `append` is forced to allocate a fresh array, isolating the callee. This also drives the related memory-leak case: returning `s[:2]` from a huge slice keeps the entire backing array (and any pointers/`[]byte` it holds) alive; copy out or nil the tail to release it.
- **Smell:** Passing `s[:n]` or `s[i:j]` into a function that appends; returning a small reslice of a large slice from a long-lived function; `append` to a slice parameter whose backing array the caller still uses.
- **Signal:**
```go
// bad
func f(s []int) { _ = append(s, 10) }
s := []int{1, 2, 3}
f(s[:2])           // clobbers s[2] -> [1 2 10]
// good
f(s[:2:2])         // cap==len forces append to reallocate; s stays [1 2 3]
// leak-safe extract:
res := make([]Foo, 2); copy(res, foos)   // don't return foos[:2]
```
- **Exceptions:** Sharing the backing array on purpose (in-place filtering `s = s[:0]` then re-appending, or a buffer pool) is a valid, allocation-free idiom — just document that the aliasing is intended.

### 18. Uninitialized map  [data-types] · high
- **Rule:** Initialize every map with `make(map[K]V)` or a literal before writing; supply a size hint (`make(map[K]V, n)`) when the cardinality is known.
- **Why:** The zero value of a map is `nil`. Reads and `len` on a `nil` map are safe (they return the zero value / `0`), but any *write* panics with "assignment to entry in nil map" — a runtime crash, not a compile error, so it slips through until the write path executes. A `struct` field of map type is `nil` until explicitly made, which is where this most often bites. Preallocating with a size hint avoids repeated rehash/grow as the map fills. Note the flip side: Go maps grow their bucket count but never shrink it, so a map that peaked at millions of entries still holds that memory after `delete`s — rebuild into a fresh map to reclaim it.
- **Smell:** `var m map[K]V` followed by `m[k] = v`; a struct with a map field written without a constructor that `make`s it; delete-heavy long-lived maps expected to release memory.
- **Signal:**
```go
// bad
var m map[string]int
m["a"] = 1                 // panic: assignment to entry in nil map
// good
m := make(map[string]int)  // or map[string]int{}
m["a"] = 1
big := make(map[int]struct{}, 1_000_000) // size hint avoids regrows
```
- **Exceptions:** Leaving a map `nil` is fine when it is read-only until assigned wholesale, or as a deliberate "absent" sentinel you only ever read from.

### 19. Map zero-value reads  [data-types] · medium
- **Rule:** Use the comma-ok form `v, ok := m[k]` whenever "key absent" and "key present with the zero value" must be distinguished.
- **Why:** Indexing a missing key returns the value type's zero value with no error and no signal, so `count := m[k]` cannot tell an absent key from one explicitly set to `0` (or `""`, or `nil`). This silently corrupts presence checks, reference counts, and set membership built on `map[K]bool`. The comma-ok read returns a second boolean that is the *only* reliable existence test. `delete(m, k)` on an absent key is a safe no-op, so guard the read, not the delete.
- **Smell:** `if m[k] != 0`/`if m[k] == ""` used as an existence check; treating `map[K]V` lookups as "found or not" without the ok bool; presence logic on a map whose zero value is a legal stored value.
- **Signal:**
```go
// bad
if users[id] != "" { ... }      // can't tell absent from stored ""
// good
if name, ok := users[id]; ok {  // ok is the real existence test
    _ = name
}
```
- **Exceptions:** Dropping the ok bool is fine when the zero value is a genuinely valid default you want on a miss — e.g. accumulating `counts[k]++` (missing key reads as `0`, then increments), which is idiomatic and correct.

### 20. Comparing slices/maps  [data-types] · medium
- **Rule:** Never compare slices or maps with `==`; use `slices.Equal` / `maps.Equal` (Go 1.21+) for comparable elements, and `reflect.DeepEqual` only as a last resort.
- **Why:** `==` is defined only for comparable types; slices, maps, and functions are not comparable. A struct that embeds one of them makes the whole struct non-comparable, and `cust1 == cust2` fails to compile. The dangerous variant: assign such a value into an `any`/interface and `==` now compiles — then *panics at runtime* ("comparing uncomparable type"). `reflect.DeepEqual` works on anything but is slow, allocates, and treats a `nil` slice as unequal to an empty one. `slices.Equal`/`maps.Equal` are typed, fast, allocation-free, and express intent — they postdate the book, which predom­inantly reached for `reflect.DeepEqual`.
- **Smell:** `==` on values whose type contains a slice/map field once boxed in `any`; `reflect.DeepEqual` in a hot loop; hand-rolled element-by-element equality methods that `slices.Equal` would replace.
- **Signal:**
```go
// bad
var a, b any = mySliceStruct{...}, mySliceStruct{...}
fmt.Println(a == b)              // compiles, panics at runtime
reflect.DeepEqual(s1, s2)        // slow; nil != empty
// good
slices.Equal(s1, s2)             // typed, fast (Go 1.21+)
maps.Equal(m1, m2)
```
- **Exceptions:** `==` is correct and fast for structs of only comparable fields (strings, numbers, arrays, pointers). `reflect.DeepEqual` is still the pragmatic choice in tests and for deeply nested, mixed-type structures where writing a typed comparator is not worth it.

## Control Structures

### 21. Range loop variable reuse  [control] · high
- **Rule:** Never keep a pointer to (or close over) a range loop variable across iterations unless you build with Go 1.22+; on older toolchains copy it into a fresh variable first.
- **Why:** Before Go 1.22 the loop variable is a single storage location reused every iteration, so `&v` (or a closure capturing `v`) captures that one address; after the loop all pointers observe the final element and every goroutine sees the same value. Go 1.22 changed the spec so each iteration gets a new instance, which silently fixes the classic bug — but a `go.mod` declaring an older Go version, or vendored code, still runs the old semantics. The failure is invisible in single-iteration tests and only surfaces with 2+ elements.
- **Smell:** `s.m[c.ID] = &c` or `go func(){ use(v) }()` where `c`/`v` is the range variable, with no per-iteration copy.
- **Signal:**
```go
// bad (pre-1.22 semantics: every entry points at the last customer)
for _, customer := range customers {
    s.m[customer.ID] = &customer
}
// good (explicit per-iteration copy — correct on every Go version)
for i := range customers {
    c := &customers[i]        // address of the slice element, distinct per index
    s.m[c.ID] = c
}
```
- **Exceptions:** If the module targets Go 1.22+ (`go 1.22` or later in `go.mod`) the per-iteration copy is automatic and taking `&v` is safe; the explicit copy is then only defensive documentation.

### 22. Range on a nil channel  [control] · high
- **Rule:** Guarantee a channel is non-nil before you `range` over it, and remember the range expression is evaluated exactly once at loop entry.
- **Why:** A receive on a nil channel blocks forever, so `for range nilCh` deadlocks the goroutine with no panic and no error — a leaked goroutine that a monitor only catches as rising memory or a stuck worker. The nil channel usually comes from a declared-but-never-`make`d field or a failed constructor path. Separately, because `range ch` evaluates `ch` once, reassigning the variable inside the loop body does not switch which channel is drained; the loop keeps reading the original.
- **Smell:** `var ch chan T` (or a struct field) used in `range` without a `make`/nil guard; or reassigning the ranged channel inside the loop expecting it to take effect.
- **Signal:**
```go
// bad (ch is nil -> blocks forever; also reassigning ch has no effect on the range)
var ch chan int
for v := range ch {          // deadlock: never receives, never exits
    _ = v
}
// good (only range a channel you know is initialized and will be closed)
ch := make(chan int)
go produce(ch)               // must close(ch) when done, or range still blocks
for v := range ch {
    _ = v
}
```
- **Exceptions:** In a `select`, a deliberately nil channel is idiomatic — it disables that case so the `select` waits only on the others. That is intentional and different from `range`.

### 23. Map iteration order  [control] · high
- **Rule:** Never depend on map iteration order; collect the keys, sort them, then iterate the sorted keys when order matters, and never mutate a map while ranging it.
- **Why:** Go deliberately randomizes map iteration order per run to stop code from accreting an accidental dependency, so ordered output, priority selection, or reproducible hashing built on `for k := range m` is a latent flake that passes locally and diverges in CI or prod. Worse, adding keys during iteration is explicitly undefined: entries created mid-range may or may not be produced, so a loop that inserts derived keys can process a nondeterministic subset. Iterate over a snapshot when you must both read and grow.
- **Smell:** `for k, v := range m` feeding ordering, first-match, or serialization logic; or `m[newKey] = ...` inside a `range m` over the same map.
- **Signal:**
```go
// bad (random order; and inserting during iteration is undefined)
for k, v := range m {
    if v { m[10+k] = true }          // may or may not be visited
}
// good (deterministic order via sorted keys; grow a copy, not the map you range)
keys := make([]int, 0, len(m))
for k := range m { keys = append(keys, k) }
slices.Sort(keys)                    // Go 1.21+ slices pkg; or sort.Ints
for _, k := range keys {
    process(k, m[k])
}
```
- **Exceptions:** Order-insensitive work (summing values, building an independent copy, membership set-up) is fine to range directly. Deleting the current or not-yet-visited keys during iteration is permitted by the spec; only insertion is undefined.

### 24. break in switch/select  [control] · medium
- **Rule:** Use a labeled `break` (or `continue`) when you intend to exit the enclosing `for`; a bare `break` inside a `switch` or `select` only leaves that `switch`/`select`.
- **Why:** `break` targets the innermost `for`, `switch`, or `select`, so a `break` written to stop the loop from inside a `select` case merely ends the case and the loop spins again — a busy loop or a handler that ignores `ctx.Done()` and never shuts down. It compiles cleanly and reads as correct, which is why it survives review. A label on the loop makes the target unambiguous.
- **Smell:** `break` inside a `case` of a `switch`/`select` that is nested in a `for`, where the author clearly meant to terminate the loop (especially a `<-ctx.Done()` case).
- **Signal:**
```go
// bad (break exits the select, not the for -> loop never stops on cancellation)
for {
    select {
    case <-ch:
        // work
    case <-ctx.Done():
        break            // leaves the select; for {} keeps running
    }
}
// good (labeled break exits the loop)
loop:
for {
    select {
    case <-ch:
        // work
    case <-ctx.Done():
        break loop
    }
}
```
- **Exceptions:** When you genuinely want to fall out of just the `switch`/`select` (e.g. early-exit a case before more statements), the bare `break` is correct — that is its normal use. Often `return` from the function is clearer than a labeled break.

### 25. defer inside a loop  [control] · medium
- **Rule:** Do not `defer` a per-iteration cleanup directly in a loop body; wrap the body in a function so the deferred call fires each iteration.
- **Why:** `defer` schedules the call for surrounding-*function* return, not block end, so deferring `file.Close()` inside a loop accumulates one deferred call per iteration and releases nothing until the whole function returns. Over a long or unbounded channel/range this leaks file descriptors, connections, or locks and can exhaust the FD limit mid-run — a slow resource leak that only bites at scale. Extracting the body to a helper (or an inline closure) scopes the `defer` to a single iteration.
- **Smell:** `defer x.Close()` / `defer mu.Unlock()` inside a `for` whose iteration count is large or unbounded.
- **Signal:**
```go
// bad (every file stays open until readFiles returns)
for path := range ch {
    file, err := os.Open(path)
    if err != nil { return err }
    defer file.Close()
    // use file
}
// good (defer scoped to each iteration via a helper)
for path := range ch {
    if err := readFile(path); err != nil { return err }
}
func readFile(path string) error {
    file, err := os.Open(path)
    if err != nil { return err }
    defer file.Close()
    // use file
    return nil
}
```
- **Exceptions:** A short, bounded loop where releasing everything at function return is acceptable, or a genuinely non-releasable resource whose lifetime should match the function. When the pattern is hot, calling `Close()` explicitly (no `defer`) is also valid.

### 26. Three-index slice expression  [control] · medium
- **Rule:** Use the full three-index slice `s[low:high:max]` to cap capacity when you hand a sub-slice to code that may `append`, so the append reallocates instead of overwriting the shared backing array.
- **Why:** A two-index slice `s[:2]` keeps the original capacity, so a later `append` on it writes into the parent's backing array and silently clobbers elements the caller still relies on — a data-corruption bug across an API boundary that no type check catches. Setting `max == high` forces `len == cap` on the sub-slice, so the next `append` allocates a fresh array and leaves the parent untouched. It is the cheapest defense when exposing internal slices.
- **Smell:** Passing `s[i:j]` of an internal/shared slice to a callee that appends, or returning `big[:n]` from a getter without capping capacity.
- **Signal:**
```go
// bad (append into the sub-slice overwrites s[2])
s := []int{1, 2, 3}
f(s[:2])                 // f does append(arg, 10); s becomes [1 2 10]
// good (capacity capped -> append copies, s untouched)
s := []int{1, 2, 3}
f(s[:2:2])               // append(arg, 10) reallocates; s stays [1 2 3]
```
- **Exceptions:** When the callee never appends, or when sharing the backing array is the intended contract (in-place windowing over a buffer you own), the plain two-index slice is correct and avoids the extra allocation.

### 27. Ranging a string yields runes, not bytes  [control] · medium
- **Rule:** Treat `for i, r := range s` as producing rune values at byte offsets; do not use the index `i` as a sequential position or read `s[i]` when you actually want the decoded character.
- **Why:** Ranging a string decodes UTF-8: `r` is a `rune` (code point) and `i` is the *byte* offset where that rune starts, so for multi-byte characters `i` jumps (0, 1, 3, ...) and `s[i]` is a single raw byte, not the character. Code that mixes `range` order with `s[i]` indexing prints mojibake or splits multi-byte runes, and off-by-one "character count" logic built on byte indices is wrong for any non-ASCII input. Decide up front whether you are iterating characters or bytes.
- **Smell:** `for i := range s { use(s[i]) }` intending characters; or using the range byte index `i` as a 0..n-1 character counter.
- **Signal:**
```go
// bad (s[i] is a byte; i is a byte offset -> wrong for "hêllo")
for i := range s {
    fmt.Printf("%c", s[i])   // prints the raw byte at offset i, not the rune
}
// good (r is the decoded rune)
for _, r := range s {
    fmt.Printf("%c", r)
}
// or index characters explicitly:
runes := []rune(s)           // decode once; runes[i] is the i-th character
```
- **Exceptions:** When you truly want byte-by-byte processing (hashing, binary framing, ASCII-only protocols), index `s[i]` in a classic `for i := 0; i < len(s); i++` loop — that is the correct tool, just not "iterate characters."

### 28. Rune count vs byte length  [control] · medium
- **Rule:** Use `utf8.RuneCountInString(s)` (or `len([]rune(s))`) when you need the number of characters; `len(s)` returns bytes.
- **Why:** `len(s)` is the byte length of the UTF-8 encoding, so a string of one CJK character reports length 3 and any "max N characters" validation, column alignment, or truncation built on `len(s)` is wrong for non-ASCII input — and truncating by byte offset can slice a multi-byte rune in half, yielding invalid UTF-8. Rune-aware counting fixes the count; correct truncation still needs rune boundaries. (Even a rune count is not the same as user-perceived glyphs once combining marks or emoji sequences appear — reach for `golang.org/x/text` there.)
- **Smell:** `len(s)` used as a character/length limit, or `s[:n]` truncation on user text without checking rune boundaries.
- **Signal:**
```go
// bad (byte length, not characters)
if len(name) > maxChars { reject() }   // "汉字" is 6 bytes, 2 chars
// good
if utf8.RuneCountInString(name) > maxChars { reject() }
```
- **Exceptions:** Buffer sizing, byte-budget limits (payload/DB column measured in bytes), and ASCII-guaranteed data legitimately want `len(s)` — it is the byte count you actually need there.

### 29. Named returns mutated by defer  [control] · medium
- **Rule:** When a deferred closure must observe or overwrite the function's result (rollback, wrapping a close error), give the return values names; a `defer` can only touch a return value that is named.
- **Why:** A deferred function runs after the `return` statement sets the result but before the caller receives it, and it can read and reassign named return variables — the idiomatic way to promote a `Close`/`Commit` error or roll back on failure. The trap is asymmetry: if the returns are unnamed, the `defer` cannot affect them, so a "we handle close errors" closure silently does nothing; conversely an accidental assignment to a named return in a `defer` can mask the real error. Make the intent explicit and check the primary error before overwriting it.
- **Smell:** A `defer func(){ ... }()` that inspects/sets `err` while the signature returns bare `(T, error)`; or a defer that unconditionally does `err = closeErr`, clobbering an earlier failure.
- **Signal:**
```go
// bad (unnamed return: defer cannot surface the close error)
func getBalance(db *sql.DB, id string) (float32, error) {
    rows, err := db.Query(q, id)
    if err != nil { return 0, err }
    defer func() { _ = rows.Close() }()   // close error is dropped
    // ...
}
// good (named returns: promote close error only if the body succeeded)
func getBalance(db *sql.DB, id string) (balance float32, err error) {
    rows, err := db.Query(q, id)
    if err != nil { return 0, err }
    defer func() {
        closeErr := rows.Close()
        if err == nil {          // don't clobber the real error
            err = closeErr
        }
    }()
    // ...
}
```
- **Exceptions:** If the deferred cleanup genuinely cannot fail or its error is irrelevant, unnamed returns plus `defer x.Close()` are cleaner — naming returns solely to shorten `return` statements is a readability anti-pattern.

## Strings

### 30. Immutable conversions  [strings] · medium
- **Rule:** Treat every `string([]byte)` and `[]byte(string)` as an allocating copy, and never round-trip across the boundary in a hot path.
- **Why:** Go strings are immutable, so the runtime cannot alias a string over a mutable `[]byte`; each conversion allocates fresh memory and copies the bytes (a handful of read-only patterns are compiler-optimized, but the general case is not). A function that reads bytes, converts to `string` to call one `strings` helper, then converts back pays two full copies per call. This never shows up as a logic bug - it surfaces as GC pressure and `runtime.mallocgc` in a CPU profile, so it hides until throughput matters.
- **Smell:** `[]byte(someHelper(string(b)))`; alternating `string(...)` / `[]byte(...)` inside one function.
- **Signal:**
```go
// bad
func getBytes(r io.Reader) ([]byte, error) {
    b, _ := io.ReadAll(r)
    return []byte(strings.TrimSpace(string(b))), nil // two copies per call
}
// good
func getBytes(r io.Reader) ([]byte, error) {
    b, _ := io.ReadAll(r)
    return bytes.TrimSpace(b), nil // stay in []byte, zero copies
}
```
- **Exceptions:** A single conversion at an API boundary is unavoidable and cheap; small, cold-path strings don't warrant contorting the code to save an allocation.

### 31. Substring memory leak  [strings] · high
- **Rule:** When you retain a small substring cut from a large string, copy it with `strings.Clone(s[lo:hi])` so the large backing array can be collected.
- **Why:** `s[lo:hi]` does not copy - the substring shares the source's backing array and only adjusts a pointer and length. Store a 36-byte slice of a multi-megabyte log line in a long-lived map and the entire megabyte stays reachable forever. The leak is invisible in review because the retained value "looks" tiny; it manifests as unbounded heap growth under sustained input. `strings.Clone` (Go 1.18+) is the idiomatic fix and allocates exactly the needed bytes - prefer it over the older `string([]byte(sub))` idiom.
- **Smell:** storing `log[:n]` / `s[a:b]` into a struct field, map, slice, or channel that outlives the source string.
- **Signal:**
```go
// bad
uuid := log[:36]            // aliases the whole multi-MB log
s.store(uuid)               // source can never be freed
// good
uuid := strings.Clone(log[:36]) // copies 36 bytes; source is now collectable
s.store(uuid)
```
- **Exceptions:** If the substring's lifetime is <= the source's (transient, same scope), the alias is correct and cloning is pure waste. The identical leak applies to `[]byte` subslices - use `bytes.Clone` there.

### 32. Unicode manipulation  [strings] · medium
- **Rule:** Manipulate text through `[]rune`, `unicode/utf8`, `strings`, and `unicode`, and know cutset-trim versus affix-trim. (For rune-vs-byte iteration see item 27; for rune count vs byte length see item 28.)
- **Why:** Beyond the rune/byte iteration trap (item 27), the `strings` trim family hides a second, subtler footgun: `TrimLeft`/`TrimRight`/`Trim` strip a *cutset* — any of the runes in the argument, in any order — whereas `TrimPrefix`/`TrimSuffix` strip one literal affix. Reaching for `TrimRight` to remove a file extension silently over-strips: `strings.TrimRight("data.js", ".json")` peels every trailing char in the set `{.,j,s,o,n}` and returns `"data"`, not `"data.js"`. It passes on inputs whose last chars happen not to be in the set and corrupts the rest.
- **Smell:** `TrimRight`/`TrimLeft` used where a suffix/prefix was meant; `Trim(s, someWord)` expecting whole-word removal.
- **Signal:**
```go
// bad: cutset trim strips ANY of the runes {., j, s, o, n}
name = strings.TrimRight("data.js", ".json") // -> "data"  (!)
// good: affix trim removes the literal suffix once
name = strings.TrimSuffix("data.js", ".json") // -> "data.js" (no suffix match, unchanged)
```
- **Exceptions:** Cutset trimming is exactly right when you genuinely want to strip a *set* of characters (e.g. `strings.Trim(s, " \t\n")` to strip surrounding whitespace) — the mistake is only using it where an affix was meant.

### 33. `+` in loops  [strings] · medium
- **Rule:** Build strings from many pieces with `strings.Builder` (and `Grow` when the total size is known), not `+=` in a loop.
- **Why:** Strings are immutable, so `s += value` allocates a brand-new string and copies the entire accumulated content every iteration - O(n²) bytes copied for n fragments. `strings.Builder` (Go 1.10+) writes into a growable byte buffer and returns the final string with no extra copy, making it O(n); a single `sb.Grow(total)` up front eliminates the intermediate reallocations entirely. On a few thousand fragments this is the difference between microseconds and milliseconds.
- **Smell:** `s := ""` followed by `s += x` inside a `for`; any `+` concatenation whose left operand is reassigned each iteration.
- **Signal:**
```go
// bad
s := ""
for _, v := range values {
    s += v // reallocates and copies all prior bytes each time
}
// good
var sb strings.Builder
sb.Grow(total) // total = sum of len(v); optional but removes regrows
for _, v := range values {
    sb.WriteString(v)
}
return sb.String()
```
- **Exceptions:** A fixed, small number of concatenations (two or three literals) is clearer with `+` and the compiler handles it; `strings.Join` is the better one-shot when you already hold the slice.

### 34. `fmt.Sprintf` vs `strconv`  [strings] · low
- **Rule:** Convert scalars to strings with `strconv` (`Itoa`, `FormatInt`, `FormatFloat`) rather than `fmt.Sprintf("%d", ...)` on hot paths.
- **Why:** `fmt.Sprintf` routes through the reflection-based formatter, boxes its argument into an `interface{}` (a heap escape), and parses the verb string at runtime. `strconv.Itoa`/`FormatInt` are specialized, allocation-light, and several times faster. For a single log line the gap is noise; in a per-request serializer or tight loop it is measurable CPU and garbage.
- **Smell:** `fmt.Sprintf("%d", n)`; `fmt.Sprintf("%s", str)` (pure waste - the value already is a string); `fmt.Sprintf` used only to stringify one number.
- **Signal:**
```go
// bad
id := fmt.Sprintf("%d", userID)
// good
id := strconv.FormatInt(userID, 10) // or strconv.Itoa(n) for int
```
- **Exceptions:** When you are actually assembling a template with multiple fields or non-trivial verbs, `fmt` is the right tool; on a cold path readability outweighs the micro-optimization.

### 35. Unnecessary `[]byte` → `string`  [strings] · low
- **Rule:** Don't convert `[]byte` to `string` (or back) just to reuse a helper - use the parallel `bytes` package, and rely on the compiler's no-copy fast paths for map keys and comparisons.
- **Why:** Converting `[]byte` to `string` only to call `strings.TrimSpace` when `bytes.TrimSpace` exists is two copies for zero benefit; the `bytes` package mirrors `strings` almost one-for-one. The often-repeated claim that `m[string(b)]` "forces an allocation" is outdated: the compiler special-cases map lookups, comparisons, and `switch` on `string(b)` so no allocation happens - the real cost appears only when the converted string *escapes* (is stored, returned, or passed to a function that retains it).
- **Smell:** `[]byte(strings.X(string(b)))`; converting a byte slice to string solely to feed a `strings.*` call that has a `bytes.*` twin.
- **Signal:**
```go
// bad
return []byte(strings.TrimSpace(string(b)))
// good
return bytes.TrimSpace(b)
// also fine - the compiler elides the alloc here:
if count, ok := m[string(b)]; ok { ... }
```
- **Exceptions:** If downstream genuinely needs a `string` (or `[]byte`), convert once at that boundary; `m[string(b)]` lookups need no rewrite since they already don't allocate.

### 36. String as byte collection  [strings] · low
- **Rule:** To mutate string contents, convert to `[]byte` (or `[]rune`) once, edit in place, and convert back once - never expect to assign into a string index.
- **Why:** Strings are immutable: `s[i] = 'x'` does not compile, and rebuilding a string per character change is the O(n²) trap from item 33. The correct model is one `[]byte(s)` copy, all edits on the mutable slice, then a single `string(buf)` to produce the result. Reach for `[]rune` instead of `[]byte` when edits are per-character on multi-byte text, since editing at an arbitrary byte offset can split a rune and corrupt the encoding.
- **Smell:** an attempt to index-assign a string; converting to `[]byte`, changing one byte, converting back, repeated inside a loop.
- **Signal:**
```go
// bad
out := ""
for i := range s {
    out += string(toUpper(s[i])) // rebuilds the whole string each step
}
// good
b := []byte(s)
for i := range b {
    b[i] = toUpper(b[i]) // in place, ASCII-safe
}
return string(b)
```
- **Exceptions:** `strings.Map`, `strings.ReplaceAll`, and `strings.Builder` cover most transforms without manual byte surgery - prefer them; drop to `[]byte`/`[]rune` only for genuine in-place or performance-critical edits.

## Functions and Methods

### 37. Value vs pointer receiver  [func-methods] · medium
- **Rule:** Use a pointer receiver when the method mutates the receiver or the struct is large/uncopyable, and pick one receiver kind and use it for every method on the type.
- **Why:** A value receiver operates on a copy, so field assignments vanish when the method returns (the balance stays 100.00, not 150.00). Even a value receiver whose struct holds a pointer field mutates shared data through that pointer, so "value receiver" does not mean "immutable." Mixing receiver kinds on one type also splits its method set: pointer-receiver methods are absent from the value's method set, so a value can silently fail to satisfy an interface, and `go vet`'s copylocks flags a value receiver on any type embedding `sync.Mutex`.
- **Smell:** `func (c customer) add(...)` that assigns to `c.field`; a single type carrying a mix of `(t T)` and `(t *T)` methods.
- **Signal:**
```go
// bad
func (c customer) add(v float64) { c.balance += v } // mutates a copy; caller sees no change
// good
func (c *customer) add(v float64) { c.balance += v }
```
- **Exceptions:** Value receivers are correct for small, immutable value types (basic wrappers, small structs, `time.Time`-style types) and when you deliberately want copy-on-call semantics; slices/maps/channels are already reference-like, so a value receiver over them still shares the underlying data.

### 38. Named return values  [func-methods] · low
- **Rule:** Name result parameters only when they document otherwise-ambiguous returns or a deferred closure must touch them, not merely to enable a naked `return`.
- **Why:** `(lat, lng float32, err error)` tells the caller what the two float32s mean where `(float32, float32, error)` does not, and interface declarations especially benefit from the labels. But a naked `return` in a long body forces the reader to scan upward to learn what is returned, and a named result silently starts at its zero value, so a forgotten assignment returns a zero with no compile error. The payoff is documentation and defer-based mutation, never brevity.
- **Smell:** named results on a short function whose meaning is already obvious; a naked `return` many lines below the signature.
- **Signal:**
```go
// bad
func split(sum int) (x, y int) { x = sum * 4 / 9; y = sum - x; return } // named only to skip typing
// good
func (l loc) getCoordinates(addr string) (lat, lng float32, err error) { /* labels disambiguate two float32s */ }
```
- **Exceptions:** The `io.ReadFull`-style loop that accumulates into a named `(n int, err error)` and ends with a naked `return`, and any function whose deferred closure must read or rewrite the result (the error-rollback idiom), are legitimate uses.

### 39. nil interface trap  [func-methods] · high
- **Rule:** Never return a typed nil pointer through an interface return type; return the interface's literal `nil` on the success path.
- **Why:** An interface value is a (type, value) pair and is nil only when both halves are nil. Assigning a nil `*MultiError` to an `error` return yields an interface whose type half is `*MultiError` and whose value half is nil - non-nil as a whole - so every `if err != nil` at the call site fires even when nothing failed, and the printed error is a useless `<nil>`. The bug hides because the function reads as though it returns nil.
- **Smell:** `var e *MyError; ...; return e` where the signature returns `error`; any concrete pointer declared then returned as an interface without an explicit nil guard.
- **Signal:**
```go
// bad
func (c Customer) Validate() error {
    var m *MultiError
    // ... m may never be assigned
    return m // *MultiError(nil) boxed in error → interface != nil
}
// good
func (c Customer) Validate() error {
    var m *MultiError
    // ...
    if m != nil { return m }
    return nil
}
```
- **Exceptions:** None - this is always a defect. `errors.Is`/`errors.As` do not rescue it, because the interface is already non-nil before any comparison runs.

### 40. Function type parameter  [func-methods] · low
- **Rule:** Accept a `func(...)` parameter for a single-behavior callback; accept an interface only when the caller must supply a bundle of related behaviors or carry state.
- **Why:** A function type is the lightest abstraction for one operation - a comparator, a visitor, an `http.HandlerFunc` - and lets callers pass a bare closure or method value with no wrapper type. An interface earns its weight only when you need several methods, named documentation of each, or an implementation that holds fields; forcing callers to declare a one-method interface for a single callback is pure ceremony. Conversely, taking a broad interface like `io.Reader` instead of a concrete `filename string` keeps the function unit-testable with `strings.NewReader` and composable with any source.
- **Smell:** a one-method interface defined solely to pass one callback; a function that takes a `filename string` and opens the file itself instead of accepting `io.Reader`.
- **Signal:**
```go
// bad
type Comparator interface{ Compare(a, b int) bool }
func Sort(data []int, c Comparator) { /* caller must declare a named type */ }
// good
func Sort(data []int, less func(a, b int) bool) { /* pass a closure directly */ }
func countLines(r io.Reader) (int, error) { /* not (filename string) */ }
```
- **Exceptions:** Prefer an interface when the same abstraction bundles multiple operations, when a well-known named interface already fits (`sort.Interface`, `io.ReadWriteCloser`), or when implementations must carry configuration between calls.

### 41. defer argument evaluation  [func-methods] · high
- **Rule:** Remember that `defer f(x)` snapshots `x` at the defer statement; pass a pointer or wrap the call in a closure when the deferred call must see the value as it will be at return time.
- **Why:** Arguments to a deferred call - and a value receiver - are evaluated when `defer` executes, not when the function returns, so `defer notify(status)` captures the empty initial `status` and later assignments are invisible to it. A pointer receiver captures only the pointer, so its fields are read at return time (`defer s.print()` prints `bar`); a value receiver copies the whole struct at the defer line (prints `foo`). This is the mechanism behind "my deferred log/metric recorded the wrong status."
- **Smell:** `defer log(status)` / `defer metric(code)` where the argument is assigned later in the body; a deferred value-receiver method expected to observe later mutation.
- **Signal:**
```go
// bad
var status string
defer notify(status)      // captures "" now
status = compute()        // deferred call never sees this
// good
var status string
defer func() { notify(status) }() // reads status at return time
status = compute()
```
- **Exceptions:** Eager snapshotting is exactly what you want when you must record the value as it was at defer time (e.g., `defer func(start time.Time){ record(time.Since(start)) }(time.Now())`). Note: Go 1.22's per-iteration loop variables fix a different footgun (closures capturing a shared loop var); they do not change when deferred arguments are evaluated.

### 42. Variadic spread  [func-methods] · medium
- **Rule:** Spread an existing slice into a variadic parameter with `slice...`; passing the slice bare wraps it in a new one-element slice or fails to compile.
- **Why:** `f(args...)` forwards the slice's elements as the variadic arguments, whereas `f(args)` treats the slice as a single argument - for a `...any` parameter that silently builds `[]any{args}` (one element that is the whole slice), so `fmt.Println(args)` prints `[a b c]` while `fmt.Println(args...)` prints `a b c`. The subtle footgun: `f(s...)` does not copy - the callee's variadic parameter aliases the caller's backing array, so a variadic function that mutates its params or `append`s into them can clobber the caller's slice.
- **Smell:** `fmt.Println(slice)` where per-element output was intended; `append`-into-variadic-param inside a `func(vs ...T)`; forwarding `os.Args` or a `[]any` without `...`.
- **Signal:**
```go
// bad
func sum(nums ...int) int { /* ... */ }
xs := []int{1, 2, 3}
_ = sum(xs)      // compile error: []int is not int
// good
_ = sum(xs...)   // spreads to sum(1, 2, 3)
```
- **Exceptions:** Omit `...` when you genuinely want the slice itself as one argument (e.g., logging it via `%v`). When you need spread-and-copy without the aliasing risk, reach for `slices.Clone` (Go 1.21+) or `slices.Concat` (Go 1.22+) rather than forwarding the backing array directly.

## Error Management

### 43. Sentinel errors  [err-mgmt] · high
- **Rule:** Compare errors with `errors.Is` (for sentinel values) and `errors.As` (for error types), never with `==` or a naked type switch.
- **Why:** Since Go 1.13, `fmt.Errorf("...: %w", err)` wraps errors, so the value a caller receives is often a wrapper, not the original. `err == sql.ErrNoRows` and `switch err.(type) { case transientError }` only inspect the top layer, so the moment any intermediate function wraps the error the check silently returns false and the wrong branch runs - a status-code or retry decision that flips with no compile error. `errors.Is`/`errors.As` walk the whole `Unwrap` chain, so they keep working regardless of how deep the match sits.
- **Smell:** `if err == ErrFoo`, `err == io.EOF` outside a direct read loop, `switch e := err.(type)`, `if e, ok := err.(*MyErr); ok`; or `errors.As(err, &myType{})` passing a throwaway pointer whose extracted fields are then unread.
- **Signal:**
```go
// bad: breaks the instant err is wrapped upstream; type switch can't see through %w
if err == sql.ErrNoRows { /* ... */ }
switch e := err.(type) {
case transientError:
    http.Error(w, e.Error(), http.StatusServiceUnavailable)
}
// good: walks the Unwrap chain; As also populates the target so you can read it
if errors.Is(err, sql.ErrNoRows) { /* ... */ }
var te transientError
if errors.As(err, &te) { // te is now the matched value, fields readable
    http.Error(w, te.Error(), http.StatusServiceUnavailable)
}
```
- **Exceptions:** `io.EOF` compared with `==` inside a direct `Read` loop is idiomatic because the standard library guarantees it is returned unwrapped. `==` is also fine when you own both the producer and consumer and can prove no wrapping happens in between - but that invariant is fragile, so prefer `errors.Is` anyway.

### 44. Wrapping errors  [err-mgmt] · medium
- **Rule:** Wrap with `fmt.Errorf("context: %w", err)` when a caller may need to inspect the source, and never destroy the chain with string concatenation.
- **Why:** `%w` records the original error so `errors.Is`/`errors.As` can find it later; `"..." + err.Error()` and a custom type that never exposes `Unwrap() error` flatten it into an opaque string that can never be matched again. The subtlety people miss is that a custom wrapper type must expose `Unwrap() error` (or wrap via `%w`) or the chain is still broken even though you "kept" the error. Wrap with `%w` only where a caller genuinely needs to inspect the source; the `%w`-vs-`%v` API-coupling tradeoff is item 49.
- **Smell:** `errors.New("prefix: " + err.Error())`, `fmt.Errorf("prefix: %s", err)` when downstream code later calls `errors.Is` on it, a custom error struct holding an inner `err` but with no `Unwrap` method, or `%w` sprayed on every single return regardless of whether anyone unwraps it.
- **Signal:**
```go
// bad: concatenation flattens the error - errors.Is/As can never recover it
return errors.New("bar failed: " + err.Error())
// bad: custom wrapper with no Unwrap() - source is unreachable
type BarError struct{ Err error }
func (b BarError) Error() string { return "bar failed:" + b.Err.Error() }
// good: %w preserves the chain when callers must inspect the source
return fmt.Errorf("query %s: %w", id, err)
```
- **Exceptions:** If the source error is an implementation detail you explicitly want to hide from callers, use `%v` instead of `%w` (see item 49). Go 1.20+ allows several `%w` verbs in one `fmt.Errorf` and adds `errors.Join` for combining independent errors - reach for those instead of hand-rolling multi-error wrappers.

### 45. Error string format  [err-mgmt] · low
- **Rule:** Write error strings lowercase and without trailing punctuation.
- **Why:** Error messages are routinely wrapped, so yours appears mid-sentence: `fmt.Errorf("query failed: %w", err)` around your `"Connection Refused."` yields `query failed: Connection Refused.` - a capital letter and a period stranded in the middle of a log line. Lowercase, punctuation-free strings compose cleanly at every nesting depth. This is a linted Go convention (staticcheck ST1005), not personal taste, so it is easy to enforce mechanically rather than in review.
- **Smell:** `errors.New("Failed to connect.")`, `fmt.Errorf("Invalid ID!")`, any error string starting with a capital (that is not a proper noun/initialism) or ending in `.`/`!`.
- **Signal:**
```go
// bad
return errors.New("Failed to notify.")
return fmt.Errorf("Invalid latitude: %f.", lat)
// good
return errors.New("failed to notify")
return fmt.Errorf("invalid latitude: %f", lat)
```
- **Exceptions:** Proper nouns and initialisms stay capitalized (`"HTTP request failed"`, `"JSON decode: %w"`). Top-level messages that are the final thing printed to a user (never wrapped) can reasonably use sentence case, but even then consistency with the lowercase convention is the safer default.

### 46. defer + named return rollback  [err-mgmt] · medium
- **Rule:** Use a deferred closure that assigns to a named error return to surface cleanup failures (Close/Commit) and to drive transactional rollback.
- **Why:** `defer rows.Close()` and `defer func(){ _ = rows.Close() }()` discard the close error entirely - a failed flush on a write path can silently lose data with the function still returning `nil`. A deferred closure can read and write the named `err` return, letting cleanup either promote its own error or trigger a rollback. The trap is clobbering: if the body already failed, an unconditional `err = closeErr` overwrites the real cause, so you must only set `err` when it is still `nil` (and log the close error otherwise).
- **Smell:** `defer rows.Close()` / `defer f.Close()` on a writable resource, `defer func(){ _ = tx.Rollback() }()` not tied to the return value, `defer tx.Rollback()` with no commit/rollback branching, unnamed returns on a function that opens a closeable resource.
- **Signal:**
```go
// bad: close error dropped; function reports success even if the flush failed
defer func() { _ = rows.Close() }()

// good: named return; promote closeErr only when the body itself succeeded
func getBalance(db *sql.DB, id string) (balance float32, err error) {
    rows, err := db.Query(query, id)
    if err != nil {
        return 0, err
    }
    defer func() {
        closeErr := rows.Close()
        if err != nil { // body already failed - keep its error, log the close
            if closeErr != nil {
                log.Printf("failed to close rows: %v", closeErr)
            }
            return
        }
        err = closeErr
    }()
    // ... use rows ...
    return balance, nil
}
```
- **Exceptions:** Read-only resources where a close error is genuinely meaningless can keep `defer x.Close()` for brevity. On Go 1.20+, when you want to preserve both the body error and the close error rather than choosing one, `err = errors.Join(err, closeErr)` replaces the clobber-guard dance.

### 47. Ignoring errors  [err-mgmt] · high
- **Rule:** Never drop a returned error implicitly; make any intentional ignore explicit with `_ =` and a comment stating why it is safe.
- **Why:** Calling `notify()` and ignoring its `error` result reads exactly like calling a function that cannot fail, so a real failure vanishes with no log, no metric, and no trace. Writing `_ = notify()` costs one token and converts an invisible bug into a documented decision the linter (`errcheck`) and the next reader can both see. The nuance: the fix is not "always handle" - some calls are legitimately best-effort - it is "always be explicit," so a reviewer can tell a deliberate ignore from a forgotten one.
- **Smell:** A bare statement-form call to a function whose signature returns `error` (`notify()`, `w.Write(b)`, `f.Close()` on a reader with no `_ =`); `//nolint:errcheck` with no justification.
- **Signal:**
```go
// bad: error silently discarded; looks infallible
notify()
// good: explicit and justified - the intent is documented
// Notifications are best-effort; missing one on error is acceptable.
_ = notify()
```
- **Exceptions:** Genuinely best-effort side effects (metrics, cache warmups, best-effort notifications) may be ignored - but explicitly, with the comment. Note the index gloss "at minimum log them" is stricter than the book and current Go convention: for a true best-effort call an explicit `_ =` plus comment is sufficient; logging is only required when the failure is actionable.

### 48. Handling errors twice  [err-mgmt] · medium
- **Rule:** Handle each error exactly once - either log it (and stop) or return it (adding context), never both.
- **Why:** Logging an error and then also returning it means every layer up the stack logs the same failure, so one root cause produces a cascade of near-identical log lines that are hard to correlate and inflate error-rate dashboards and alerts. Returning with added context via `%w` moves the information into the error itself, so the single log call at the top of the stack carries the full chain. Logging is a form of handling; once you have logged, you have consumed the error and should not re-propagate it unchanged.
- **Smell:** `log.Println(...)` / `logger.Error(...)` immediately followed by `return err` in the same block; the same error string appearing at multiple stack depths in logs; a validate/parse helper that both logs and returns its own error.
- **Signal:**
```go
// bad: logged here, then logged again by every caller that also logs+returns
if err != nil {
    log.Println("failed to validate source coordinates")
    return err
}
// good: attach context and return once; log a single time at the top
if err != nil {
    return fmt.Errorf("validate source coordinates: %w", err)
}
```
- **Exceptions:** At the outermost boundary (an HTTP handler, a `main`, a top-level goroutine) you log and stop - there is nobody left to return to, so that single log is the one handling. A deliberate observability tap (metric increment or debug trace) plus a return is fine as long as exactly one human-facing log records the failure.

### 49. Wrapping vs context string  [err-mgmt] · medium
- **Rule:** Choose `%w` to expose the source error to callers and `%v` to add context while decoupling from it; either way, add context that a bare `return err` lacks.
- **Why:** `%w` and `%v` produce identical message text but opposite contracts: `%w` keeps the source reachable via `errors.Is`/`errors.As` (and makes it part of your API), while `%v` transforms it into an opaque string callers cannot match. Returning `err` untouched is the third option and is usually wrong at a layer boundary - it forces the top of the stack to guess where the failure originated. Pick `%v` precisely when you do not want callers coupling to a dependency's error type, and `%w` when detecting that error is part of the contract; never pick `%w` by reflex just because it looks like the "modern" verb.
- **Smell:** `return err` with no context at a boundary that spans subsystems; `%w` used where the wrapped type is an internal detail you never want callers to `errors.Is`; `%v` used where downstream code nonetheless tries `errors.Is`/`errors.As` on the result (it will always fail).
- **Signal:**
```go
// bad: no context - caller can't tell which call failed
return err
// good (expose): callers may need to detect the underlying error
return fmt.Errorf("get transaction %s: %w", id, err)
// good (decouple): add context but hide the source type from callers
return fmt.Errorf("get transaction %s: %v", id, err)
```
- **Exceptions:** When the wrapped error carries no useful discriminator and the caller only ever renders the message, `%v` and `%w` are interchangeable in practice - default to `%v` to avoid the accidental coupling. Returning `err` unchanged is acceptable inside a single tight helper where the immediate caller already has full context.

## Concurrency Foundations

### 50. Copying a sync type (Mutex/WaitGroup)  [concurrency-foundations] · high
- **Rule:** Never copy a value that contains a `sync` primitive; guard it behind a pointer, or give the enclosing struct pointer receivers.
- **Why:** `sync.Mutex`, `sync.WaitGroup`, `sync.Once`, etc. carry internal state (lock word, waiter count). Copying the value copies that state, so the copy and the original protect nothing in common - two goroutines "lock" independent mutexes and race freely, or a copied `WaitGroup` loses its counter. The trap is silent: a value receiver or a struct passed by value duplicates the embedded mutex with no error. `go vet`'s `copylocks` pass catches it, but only if you run it.
- **Smell:** a method with a value receiver `func (c Counter)` that calls `c.mu.Lock()`; passing or returning a struct by value that embeds a `sync.Mutex`; a `sync.WaitGroup` passed to a function by value.
- **Signal:**
```go
// bad
type Counter struct {
	mu sync.Mutex
	n  map[string]int
}
func (c Counter) Inc(k string) { c.mu.Lock(); defer c.mu.Unlock(); c.n[k]++ } // locks a copy
// good
func (c *Counter) Inc(k string) { c.mu.Lock(); defer c.mu.Unlock(); c.n[k]++ } // pointer receiver
// or hold the lock behind a pointer field: mu *sync.Mutex, set in the constructor
```
- **Exceptions:** Copying the zero value before first use is fine (a struct field assigned once at construction, before any `Lock`). A struct embedding a mutex may still be copied if the copy provably happens-before any lock is taken.

### 51. Start a goroutine only when you know how it stops  [concurrency-foundations] · high
- **Rule:** Give every goroutine a defined termination path - a cancelled context, a closed channel, or a bounded loop - before you launch it.
- **Why:** A goroutine blocked forever on a send/receive is never garbage-collected; its stack and everything it transitively references leaks. This compounds under load: one leaked goroutine per request becomes millions. The classic case is a background worker spawned in a constructor with no shutdown hook, or a producer that returns before its consumer drains. Leaks stay invisible until OOM or a `runtime.NumGoroutine` graph that climbs without bound.
- **Smell:** `go w.watch()` with no ctx/stop parameter; a constructor that spawns a goroutine but returns no `Close`/`cancel`; a `go func()` sending on a channel nobody is guaranteed to receive from.
- **Signal:**
```go
// bad
func newWatcher() { w := watcher{}; go w.watch() } // no way to stop it
// good
func newWatcher(ctx context.Context) { w := watcher{}; go w.watch(ctx) } // ctx.Done() stops it
// or return a value whose close()/cancel the caller defers
```
- **Exceptions:** Goroutines whose lifetime provably equals the process (a top-level accept loop in `main`) need no explicit teardown - though a clean shutdown path still helps tests and graceful drain.

### 52. Use directional channel types in signatures  [concurrency-foundations] · medium
- **Rule:** Declare channel parameters as send-only (`chan<- T`) or receive-only (`<-chan T`) to encode who may send, who may receive, and who may close.
- **Why:** A bidirectional `chan T` parameter lets any collaborator both send and receive and - worse - close a channel it doesn't own. Encoding direction in the type turns misuse into a compile error instead of a runtime deadlock or a "close of closed channel" panic. A producer that returns `<-chan T` also documents ownership: the caller only reads, the producer closes.
- **Smell:** exported or internal functions taking a plain `chan T` when they only send or only receive; a "consumer" function that could accidentally `close(ch)`.
- **Signal:**
```go
// bad
func worker(ch chan int) { for v := range ch { _ = v } } // could also send or close
// good
func worker(ch <-chan int) { for v := range ch { _ = v } } // receive-only
func produce() <-chan int {
	ch := make(chan int)
	go func() { defer close(ch); /* ... */ }()
	return ch // caller can only read
}
```
- **Exceptions:** A function that genuinely both sends and receives and owns the channel end-to-end (e.g. an internal merge) keeps the bidirectional type. Conversion is one-way - you can pass a `chan T` where a directional type is expected, never the reverse.

### 53. Choose unbuffered vs buffered deliberately  [concurrency-foundations] · high
- **Rule:** Use unbuffered channels when you need a synchronization/happens-before guarantee; buffer only when you can justify the exact capacity, and never lean on a buffered send for ordering.
- **Why:** An unbuffered send blocks until a receiver takes the value, so the send establishes a happens-before edge - everything the sender wrote beforehand is visible to the receiver. A buffered send with free capacity returns immediately and establishes no such edge, so a value written just before a buffered send can be read stale or raced. The book's memory-model example makes this concrete: writing `i = 1` then sending on a size-1 buffered channel while another goroutine reads `i` is a data race; the unbuffered version is correct. Separately, buffer sizes are magic numbers - a capacity you can't reason about (why 10? why 1024?) hides backpressure bugs.
- **Smell:** `make(chan T, N)` with an unexplained `N`; relying on a buffered send to "publish" data written just before it; buffering purely so a send "won't block".
- **Signal:**
```go
// bad: buffered send provides no happens-before; data race on i
ch := make(chan struct{}, 1)
go func() { i = 1; <-ch }()
ch <- struct{}{}
fmt.Println(i) // may print 0
// good: unbuffered send synchronizes; i = 1 is guaranteed visible
ch := make(chan struct{})
go func() { i = 1; <-ch }()
ch <- struct{}{}
fmt.Println(i) // prints 1
```
- **Exceptions:** Buffering is right when capacity maps to a real quantity - a fan-out sized to the worker count, or a single slot for one known pending signal. Justify the number in a comment or a named constant.

### 54. Disable a select case by nilifying its channel  [concurrency-foundations] · high
- **Rule:** When a channel closes inside a `select` loop, set its variable to `nil` so its case blocks forever, instead of spinning on the closed channel.
- **Why:** A receive from a closed channel returns immediately with the zero value and `ok == false`, forever. In a `for { select {...} }` that merges channels, a closed-but-still-selected channel makes the loop busy-spin at 100% CPU and can even close the output twice. A `nil` channel blocks permanently, so its case is effectively removed from the select - the loop then serves only the still-open channels and exits cleanly once all are `nil`.
- **Smell:** a `select` over multiple channels driven by per-channel `bool` "closed" flags; a `for` loop that never advances because a closed channel keeps firing; `break` inside a select case expected to exit the loop (it exits only the `select`).
- **Signal:**
```go
// bad: bookkeeping flags, easy to get the exit condition wrong (and busy-spins)
for {
	select {
	case v, open := <-ch1: if !open { ch1Closed = true; break }; ch <- v
	case v, open := <-ch2: if !open { ch2Closed = true; break }; ch <- v
	}
	if ch1Closed && ch2Closed { close(ch); return }
}
// good: nil out the closed channel; loop ends when both are nil
for ch1 != nil || ch2 != nil {
	select {
	case v, open := <-ch1: if !open { ch1 = nil; break }; ch <- v
	case v, open := <-ch2: if !open { ch2 = nil; break }; ch <- v
	}
}
close(ch)
```
- **Exceptions:** If you never `select`/`range` past a channel's close (a single consumer that returns on the first close), you don't need this - the simpler form is clearer.

### 55. Use chan struct{} for signals, close to broadcast  [concurrency-foundations] · medium
- **Rule:** Model "an event happened / done" with `chan struct{}`, and broadcast one-to-many by `close`ing the channel rather than sending N values.
- **Why:** `struct{}` is zero-width, so `chan struct{}` states in the type that the payload is meaningless - the signal *is* the message. `chan bool` invites the reader to wonder what `false` is supposed to mean. A single `close(ch)` unblocks every goroutine receiving on it at once (each gets the zero value with `ok == false`), which is the idiomatic broadcast; sending one value wakes only one receiver. Closing is also one-shot and safe to observe repeatedly.
- **Smell:** `chan bool` used purely as a "done" trigger; sending one value per waiter to fan out a stop signal; a `chan struct{}` sent-to and received-once where a `close` would serve many waiters.
- **Signal:**
```go
// bad
done := make(chan bool)
done <- true // wakes exactly one receiver; and what does the bool mean?
// good
done := make(chan struct{})
close(done) // broadcasts to all receivers; struct{} says "no data, just the signal"
```
- **Exceptions:** If the signal genuinely carries data (a result, an error, a count), use a typed channel. If exactly one receiver must wake once, a single send is fine - but `context.Context.Done()` (itself a `<-chan struct{}`) is usually the better tool.

### 56. Pass context as the first arg; don't store or misplace it  [concurrency-foundations] · high
- **Rule:** Thread `ctx context.Context` as the first parameter through the call chain; never stash it in a struct field, and never hand a request-scoped context to work that must outlive the request.
- **Why:** A context stored in a struct outlives the call it was created for and gets reused across unrelated operations, so its deadline/cancellation apply to the wrong work. The mirror failure: launching a background goroutine with the handler's `r.Context()` - when the handler returns, that context is cancelled and the background task dies mid-flight. You must decouple: keep the values but drop the cancellation. The book hand-rolls a `detach` type that forwards `Value` but returns a nil `Done()`; **Go 1.21 (Aug 2023) made that obsolete with `context.WithoutCancel`** (and added `context.AfterFunc`, `WithDeadlineCause`).
- **Smell:** a struct field `ctx context.Context`; `go func(){ publish(r.Context(), ...) }()` firing off work that outlives the handler; a custom type re-implementing `context.Context` just to strip cancellation.
- **Signal:**
```go
// bad: background goroutine dies when the request ctx is cancelled
go func() { publish(r.Context(), response) }()
// good (Go 1.21+): keep the values, drop the deadline/cancellation
go func() { publish(context.WithoutCancel(r.Context()), response) }()
// pre-1.21 book workaround: a detach{ctx} type whose Done() returns nil, Value() forwards
```
- **Exceptions:** The rare, documented case where a type legitimately holds a context (e.g. `http.Request` internals) - but application code should pass it explicitly as the first argument.

### 57. Put only request-scoped data in context values  [concurrency-foundations] · medium
- **Rule:** Use `context.WithValue` for data that rides along with a request (trace/correlation ID, auth token, request-scoped logger), never for required parameters or optional configuration.
- **Why:** Context values are an untyped `any`→`any` map resolved at runtime, so nothing checks that a key is present or the right type - a missing value silently returns `nil` and the bug surfaces far from its cause. Smuggling parameters through context hides a function's real dependencies from its signature and defeats the compiler. Keys must also be an unexported custom type, not a bare string, or two packages collide on the same key.
- **Smell:** `ctx.Value("timeout")` / `ctx.Value("pageSize")` carrying config; `context.WithValue` keyed by a plain string; a function whose behavior depends on values it never names as parameters.
- **Signal:**
```go
// bad: business parameter smuggled through context, string key, no type safety
ctx = context.WithValue(ctx, "limit", 100)
limit := ctx.Value("limit").(int) // panics or wrong if absent/mistyped
// good: explicit parameter; context carries only request-scoped metadata
func list(ctx context.Context, limit int) { /* ... */ }
type ctxKey string
const traceIDKey ctxKey = "traceID"
ctx = context.WithValue(ctx, traceIDKey, id)
```
- **Exceptions:** Cross-cutting, request-scoped values that every layer may need but shouldn't be plumbed through every signature (trace IDs, auth principals) are the legitimate use - keep them read-only and keyed by an unexported type.

## Concurrency Practice

### 58. Goroutine cost  [conc-practice] · medium
- **Rule:** Treat goroutine creation as cheap and spawn one per unit of work; only introduce a worker pool or `sync.Pool` after a benchmark shows goroutine/scheduling cost actually dominates.
- **Why:** A goroutine starts with a ~2KB stack that grows on demand and is multiplexed by the runtime onto `GOMAXPROCS` OS threads, so launching thousands is normal and fast. The mistake people make is porting a thread-pool mindset from other languages: they build a fixed pool of N workers plus a job channel to "avoid the cost of creating goroutines," which adds queueing latency, backpressure bugs, and lifecycle code for savings that usually don't exist. A pool is justified only to *bound* concurrency (protect a downstream resource), not to recycle goroutines.
- **Smell:** A hand-rolled worker pool with a hardcoded `numWorkers` and a `jobs chan` wrapping trivial CPU work; a `sync.Pool` of goroutines; comments like "reuse goroutines to avoid allocation."
- **Signal:**
```go
// bad: fixed pool to "recycle" goroutines for cheap tasks
jobs := make(chan Task, len(tasks))
for w := 0; w < 100; w++ { // arbitrary count, no downstream limit
	go worker(jobs)
}
// good: one goroutine per task; bound only when a resource needs protecting
g, ctx := errgroup.WithContext(ctx)
g.SetLimit(runtime.GOMAXPROCS(0)) // Go 1.25: this now respects cgroup CPU limits
for _, t := range tasks {
	g.Go(func() error { return t.Run(ctx) })
}
```
- **Exceptions:** A bounded pool is correct when the goroutines contend for a scarce external resource (DB connections, an API rate limit) - there the cap is the point, not goroutine recycling. Size it from `runtime.GOMAXPROCS(0)`, which as of Go 1.25 is container-aware, rather than a magic constant.

### 59. Concurrency isn't free  [conc-practice] · medium
- **Rule:** Benchmark the sequential version first and only parallelize when the per-unit work is large enough to outweigh goroutine, scheduling, and memory-synchronization overhead - usually gated behind a size threshold.
- **Why:** Every cross-goroutine handoff (channel send, mutex, atomic) forces a happens-before synchronization that flushes CPU caches and costs far more than the arithmetic it protects. For small inputs the parallel version is slower than the sequential one because coordination dominates; the classic example is a parallel merge sort that beats sequential only above a threshold and loses badly below it. People "go concurrent" for a speedup and ship a regression that only shows up under real input sizes.
- **Smell:** Spawning a goroutine per element of a tiny slice; a parallel divide-and-conquer with no base-case threshold; concurrency added without a `testing.B` comparison against the serial path.
- **Signal:**
```go
// bad: goroutine per element - sync cost swamps the work
func sum(v []int) int {
	ch := make(chan int)
	for _, n := range v { go func() { ch <- n }() }
	// ... collect
}
// good: parallelize only above a measured threshold, else run inline
func parallelMergeSort(s []int) {
	if len(s) < threshold { // tune via benchmark; below this, serial wins
		sequentialSort(s)
		return
	}
	// ... split, recurse in goroutines
}
```
- **Exceptions:** Genuinely CPU-bound work over large datasets, or I/O-bound fan-out where goroutines mostly block on the network, both benefit immediately - there the work per goroutine dwarfs the sync cost. Always confirm with `go test -bench` and validate correctness with `-race`.

### 60. Busy waiting  [conc-practice] · medium
- **Rule:** Never spin on a shared condition in a loop; block on a channel receive, `sync.Cond.Wait`, or a `select` with a ticker so the goroutine parks instead of burning a core.
- **Why:** A `for shared < goal {}` spin (or the lock/unlock churn `RLock; for cond { RUnlock; RLock }`) pegs a CPU at 100%, steals scheduler time from the goroutine that would actually make progress, and on a single-P setup can livelock. Blocking primitives hand the core back to the runtime and wake the goroutine precisely when the state changes. The subtle failure is that busy-waiting *looks* like it works in a benchmark with spare cores, then starves the producer under load.
- **Smell:** An empty-bodied `for x != want {}`; a `for { if done { break }; }` with no blocking call inside; polling a shared field in a tight loop; repeated `RLock`/`RUnlock` to re-read a value.
- **Signal:**
```go
// bad: spin-poll a shared balance (book listing1) - pegs a core, starves the writer
donation.mu.RLock()
for donation.balance < goal {
	donation.mu.RUnlock()
	donation.mu.RLock()
}
// good: block until notified, re-check predicate under the lock
donation.cond.L.Lock()
for donation.balance < goal {
	donation.cond.Wait()
}
donation.cond.L.Unlock()
```
- **Exceptions:** Extremely short, bounded spins in lock-free code - e.g. a spin-lock that calls `runtime.Gosched()` and expects to succeed within a few iterations under sub-microsecond contention. This is the domain of the runtime and lock-free data structures, not application logic.

### 61. Mutex vs channel  [conc-practice] · medium
- **Rule:** Use a mutex to guard shared state mutated in place; use a channel to transfer ownership of data or to coordinate/signal between stages. Pick by whether goroutines *share* state or *pass* it.
- **Why:** "Share memory by communicating" is a guideline, not an absolute. Parallel goroutines touching the same fine-grained field (a counter, a cache map) are simplest and fastest behind a mutex; forcing that through a channel adds a serialization goroutine, latency, and more moving parts. Conversely, coordinating pipeline stages or fan-in/fan-out through a shared mutex is awkward and deadlock-prone where a channel expresses the handoff directly. Choosing the wrong primitive produces code that works but is harder to reason about and easy to deadlock.
- **Smell:** A buffered channel of capacity 1 used as a lock around a map write; a mutex held across a produce/consume handoff; a `chan struct{}` semaphore emulating mutual exclusion over a single variable.
- **Signal:**
```go
// bad: channel used as a lock around shared state
lock := make(chan struct{}, 1)
lock <- struct{}{}
m[key]++          // in-place mutation of shared state
<-lock
// good: mutex guards shared state; channel transfers ownership between stages
mu.Lock(); m[key]++; mu.Unlock()          // shared, mutated in place -> mutex
out <- computeResult(job)                 // hand a value to the next stage -> channel
```
- **Exceptions:** When you need `select` (timeout, cancellation, multiplexing) around access, a channel wins even for state, because a mutex can't participate in `select`. And a single-owner-goroutine design that serializes all access via one channel is a legitimate way to avoid locks entirely.

### 62. WaitGroup.Add timing  [conc-practice] · high
- **Rule:** Call `wg.Add` on the goroutine that *launches* the work, before the `go` statement (or `wg.Add(n)` once before the loop) - never inside the spawned goroutine.
- **Why:** If `Add(1)` runs inside the goroutine, there is a race between it and `Wait`: the parent may reach `Wait` before the runtime has even scheduled the goroutine, so the counter is still 0, `Wait` returns immediately, and you read results that haven't been produced. The book's listing1 does exactly this and prints a nondeterministic 0/1/2/3. The bug is invisible on a fast machine and surfaces as flaky, undercounted results under scheduling pressure.
- **Smell:** `go func(){ wg.Add(1); ...; wg.Done() }()`; any `wg.Add` textually inside a goroutine body; `Add` and `Wait` reachable without a happens-before edge between them.
- **Signal:**
```go
// bad: Add races with Wait - counter may still be 0 when Wait returns
for i := 0; i < 3; i++ {
	go func() { wg.Add(1); atomic.AddUint64(&v, 1); wg.Done() }()
}
// good: Add before launching (or wg.Add(3) once before the loop)
for i := 0; i < 3; i++ {
	wg.Add(1)
	go func() { defer wg.Done(); atomic.AddUint64(&v, 1) }()
}
```
- **Exceptions:** As of Go 1.25, prefer `wg.Go(func(){ ... })`, which performs the `Add(1)` and `defer Done()` for you and makes the ordering bug structurally impossible - the manual `Add`/`go`/`Done` dance is now legacy. There is no legitimate case for calling `Add` from inside the goroutine it counts.

### 63. sync.Cond  [conc-practice] · medium
- **Rule:** Use `sync.Cond` when multiple goroutines must be woken on each change to shared state - `Broadcast` wakes all waiters repeatedly - and always re-check the predicate in a `for` loop while holding `cond.L`.
- **Why:** A channel can signal, but its broadcast story is one-shot: `close(ch)` wakes every receiver exactly once and can't be reused, and a single send wakes only one receiver. When state changes repeatedly and several goroutines each wait for their own threshold, `Cond.Broadcast` on every update is the right fit. The trap is using `if` instead of `for` around `Wait`: `Wait` releases the lock, blocks, then reacquires, and by the time it returns the predicate may no longer hold (another waiter consumed the change), so the condition must be rechecked in a loop.
- **Smell:** Repeatedly closing/recreating a channel to "re-broadcast"; an `if` (not `for`) guarding `cond.Wait()`; busy-wait loops that a broadcast would replace.
- **Signal:**
```go
// bad: if-guarded Wait - predicate may be false after Wait returns
donation.cond.L.Lock()
if donation.balance < goal { donation.cond.Wait() }
// good: for-guarded Wait under the lock; updater Broadcasts on each change
donation.cond.L.Lock()
for donation.balance < goal { donation.cond.Wait() }
fmt.Printf("%d$ goal reached\n", donation.balance)
donation.cond.L.Unlock()
// updater: Lock(); balance++; Unlock(); cond.Broadcast()
```
- **Exceptions:** For a single one-shot fan-out signal, `close(chan struct{})` is simpler and idiomatic. `Cond` also can't participate in `select` and has no context/cancellation support, so if you need timeouts or `ctx` cancellation, use channels instead.

### 64. errgroup  [conc-practice] · medium
- **Rule:** For fan-out goroutines that can fail, use `golang.org/x/sync/errgroup` instead of a bare `WaitGroup` - it collects the first non-nil error, cancels its derived context to stop siblings, and returns that error from `Wait`.
- **Why:** A plain `WaitGroup` gives you no channel for errors and no cancellation, so error handling degenerates into an empty `if err != nil {}` (the book's handler1 literally drops the error) and failed work keeps every sibling running to completion. `errgroup.WithContext` derives a `ctx` it cancels on the first error, so well-behaved children observing `ctx.Done()` stop early, and `g.Wait()` surfaces the error to the caller - all without manual channels or atomics.
- **Smell:** `sync.WaitGroup` + a goroutine that computes an `err` which is then ignored or stuffed into a shared slice; hand-rolled "first error wins" logic with a mutex; fan-out with no cancellation on failure.
- **Signal:**
```go
// bad: manual WaitGroup drops the error and never cancels siblings
wg.Add(len(circles))
for i, circle := range circles {
	go func() {
		defer wg.Done()
		result, err := foo(ctx, circle)
		if err != nil { } // dropped
		results[i] = result
	}()
}
// good: errgroup propagates the first error and cancels via derived ctx
g, ctx := errgroup.WithContext(ctx)
for i, circle := range circles {
	g.Go(func() error {
		result, err := foo(ctx, circle)
		if err != nil { return err }
		results[i] = result
		return nil
	})
}
if err := g.Wait(); err != nil { return nil, err }
```
- **Exceptions:** Use `g.SetLimit(n)` when the fan-out must be bounded (protecting a downstream); use a plain `WaitGroup` (or Go 1.25's `wg.Go`) when the goroutines genuinely cannot fail. Note the source's `i := i` / `circle := circle` copies are unnecessary as of Go 1.22, where each loop iteration gets fresh variables.

### 65. sync.Map use case  [conc-practice] · medium
- **Rule:** Reach for `sync.Map` only for its two tuned patterns - a write-once/read-many cache with stable keys, or goroutines operating on disjoint key sets - and otherwise use a plain `map` guarded by `sync.RWMutex`.
- **Why:** `sync.Map` avoids lock contention for those specific access patterns, but it pays for it with an untyped `any` API (every read is a type assertion) and worse performance than a mutex-guarded map when keys churn or writes are frequent. People adopt it as a generic "concurrent map" and get slower, less type-safe code. A `struct{ mu sync.RWMutex; m map[K]V }` is clearer, statically typed, and faster for the common read-write-mixed case.
- **Smell:** `sync.Map` guarding a small map with frequent overwrites/deletes; type assertions on every `Load`; `sync.Map` chosen without matching either documented access pattern.
- **Signal:**
```go
// bad: sync.Map as a general concurrent map - untyped, slower under churn
var m sync.Map
m.Store(id, balance)
v, _ := m.Load(id)
bal := v.(float64) // assertion on every read
// good: typed map behind an RWMutex
type Cache struct {
	mu sync.RWMutex
	m  map[string]float64
}
func (c *Cache) Get(id string) (float64, bool) {
	c.mu.RLock(); defer c.mu.RUnlock()
	v, ok := c.m[id]; return v, ok
}
```
- **Exceptions:** The two patterns `sync.Map` documents - entries written once then read many times, or each key touched by only one goroutine - are its home turf; use it there. Go 1.24 reimplemented `sync.Map` internally (a hash-trie) for better scalability, but the usage guidance is unchanged.

### 66. sync.Once  [conc-practice] · medium
- **Rule:** Use `sync.Once` (or Go 1.21's `sync.OnceFunc`/`OnceValue`/`OnceValues`) for one-time initialization shared across goroutines; never guard init with a plain `bool` flag.
- **Why:** A `if !inited { init(); inited = true }` check is a data race and can run `init` twice if two goroutines interleave; `Once.Do` serializes callers and establishes a happens-before edge so the initialized value is visible to every goroutine that observes `Do` returning. The subtle footgun: if `f` panics inside `Do`, the `Once` is still marked done - the guard is consumed, later `Do` calls are no-ops, and the value stays half-initialized. Initialization that can fail must return the error and be retried through a different mechanism, not silently swallowed by `Once`.
- **Smell:** A `bool`/`int32` "initialized" flag double-checked without synchronization; `Once.Do` wrapping fallible init whose error is discarded; lazy singletons behind a naked flag.
- **Signal:**
```go
// bad: racy flag; may init twice, no visibility guarantee
if !inited {
	conn = dial()
	inited = true
}
// good: exactly-once, race-free, value published safely (Go 1.21+)
var getConn = sync.OnceValue(func() *Conn { return dial() })
c := getConn()
```
- **Exceptions:** If initialization can legitimately fail and must be retried, `Once` is the wrong tool - it will lock in a bad state after a panic/error; use an explicit lock plus a retry-able error return, or `OnceValues` only if a failed value is acceptable to cache.

### 67. Atomic operations  [conc-practice] · high
- **Rule:** Use `sync/atomic` for simple counters and flags, and route *every* access to that variable through atomic operations - never mix an atomic write with a plain read (or vice versa) of the same variable.
- **Why:** Atomics give lock-free, race-free updates, but atomicity is a property of the *access*, not the variable: a plain `x` read while another goroutine does `atomic.AddInt64(&x, 1)` is still a data race, permitting torn or stale reads and compiler/CPU reorderings. The `-race` detector will flag it, but only if that interleaving is exercised. Consistency requires all readers and writers to use `Load`/`Store`/`Add`/`CompareAndSwap`.
- **Smell:** `atomic.AddInt64(&c, 1)` in one place and `c++` or `_ = c` elsewhere; a bare `int64`/`bool` field updated atomically in some paths and read directly in others; `atomic` mixed with a mutex on the same field.
- **Signal:**
```go
// bad: atomic write, plain read - data race, torn/stale value
atomic.AddInt64(&counter, 1)
if counter > limit { ... }   // non-atomic read of an atomically-written var
// good: typed atomic (Go 1.19+) makes non-atomic access impossible
var counter atomic.Int64
counter.Add(1)
if counter.Load() > limit { ... }
```
- **Exceptions:** None for correctness - if any goroutine can observe the variable concurrently, all accesses must be atomic. Prefer the Go 1.19 typed atomics (`atomic.Int64`, `atomic.Bool`, `atomic.Pointer[T]`) over the free functions on raw values, since the type mechanically prevents an accidental plain access. For anything beyond a single word (invariants across multiple fields), use a mutex.

### 68. Timer.Reset race  [conc-practice] · high
- **Rule:** On Go 1.23+, call `t.Reset(d)` directly - the timer channel is synchronous and no drain is needed; do *not* carry over the pre-1.23 `if !t.Stop() { <-t.C }` drain, which can now deadlock.
- **Why:** Before Go 1.23, timer channels were buffered (capacity 1), so a timer that fired without being received left a stale value; the documented workaround was to `Stop` and drain before `Reset`. But a bare `<-t.C` drain races the timer's own send goroutine: if the timer hasn't sent yet, the receive blocks forever. As of Go 1.23 the channel is unbuffered and `Stop`/`Reset` guarantee no stale value is ever delivered, so the drain is unnecessary - and because there is nothing buffered to drain, the old blocking receive hangs. This is the concurrency item most changed by a recent Go release.
- **Smell:** `if !t.Stop() { <-t.C }` before `Reset`; any unconditional `<-t.C` used to "clear" a timer; hand-written drain logic around `time.Timer`.
- **Signal:**
```go
// bad: pre-1.23 drain - blocks forever on 1.23+ (nothing buffered to receive)
if !t.Stop() {
	<-t.C
}
t.Reset(d)
// good: on Go 1.23+ just reset; Stop/Reset guarantee no stale value
t.Reset(d)
```
- **Exceptions:** Code that must build on toolchains older than Go 1.23 still needs the guard, but use a *non-blocking* drain (`if !t.Stop() { select { case <-t.C: default: } }`), never a bare `<-t.C`. Setting `GODEBUG=asynctimerchan=1` restores the old buffered behavior for legacy code, but that knob is slated for removal around Go 1.27.

## Standard Library

### 69. http.Client no timeout  [stdlib] · high
- **Rule:** Never issue requests through `http.DefaultClient` (or `http.Get`/`http.Post`) in production; construct an `http.Client` with an explicit `Timeout` and per-phase timeouts on its `Transport`.
- **Why:** The zero-value `http.Client` and the package-level `DefaultClient` have `Timeout == 0`, meaning *no* deadline on the whole request lifecycle. A slow or malicious peer can hold the connection open indefinitely; the calling goroutine blocks forever and its `resp.Body` connection is never returned to the pool, so under load you leak goroutines and file descriptors until the process dies. `Client.Timeout` covers dial + TLS + headers + body read, but layering `Transport.DialContext` timeout, `TLSHandshakeTimeout`, and `ResponseHeaderTimeout` lets you fail fast on a stuck phase instead of waiting out the whole budget.
- **Smell:** `http.Get(`, `http.DefaultClient`, or `&http.Client{}` / `http.Client{Transport: ...}` with no `Timeout` field set.
- **Signal:**
```go
// bad
resp, err := http.Get(url) // DefaultClient: no timeout, hangs forever on a slow peer

// good
client := &http.Client{
	Timeout: 5 * time.Second,
	Transport: &http.Transport{
		DialContext:           (&net.Dialer{Timeout: time.Second}).DialContext,
		TLSHandshakeTimeout:   time.Second,
		ResponseHeaderTimeout: time.Second,
	},
}
resp, err := client.Do(req.WithContext(ctx))
```
- **Exceptions:** Throwaway scripts and tests where the process is short-lived. Prefer a per-request `context.WithTimeout` over `Client.Timeout` when different endpoints need different budgets from one shared client, but still set one of the two.

### 70. http.Server no timeouts  [stdlib] · high
- **Rule:** Never expose a server via `http.ListenAndServe(addr, handler)`; build an `http.Server` with `ReadHeaderTimeout`, `ReadTimeout`, `WriteTimeout`, and `IdleTimeout` set.
- **Why:** `http.ListenAndServe` and the zero-value `http.Server` have every timeout at 0, so a client that opens a connection and sends one byte per second (a Slowloris attack) ties up a goroutine and a socket indefinitely; enough such connections exhaust the server with no error. `ReadHeaderTimeout` bounds the time to receive request headers (the cheapest defense and the one you almost always want), `ReadTimeout`/`WriteTimeout` bound the full body read/response write, and `IdleTimeout` reaps kept-alive connections. For per-handler request budgets wrap with `http.TimeoutHandler`, which enforces a deadline on handler execution and writes a 503 if exceeded.
- **Smell:** `http.ListenAndServe(`, `http.ListenAndServeTLS(`, or `&http.Server{Addr: ...}` with no `*Timeout` fields.
- **Signal:**
```go
// bad
http.ListenAndServe(":8080", handler) // no timeouts: one Slowloris client per goroutine, forever

// good
s := &http.Server{
	Addr:              ":8080",
	ReadHeaderTimeout: 500 * time.Millisecond,
	ReadTimeout:       500 * time.Millisecond,
	WriteTimeout:      time.Second,
	IdleTimeout:       30 * time.Second,
	Handler:           http.TimeoutHandler(handler{}, time.Second, "timeout"),
}
log.Fatal(s.ListenAndServe())
```
- **Exceptions:** `WriteTimeout` must be loose or unset for legitimately long responses (streaming, SSE, large downloads); bound those with `TimeoutHandler` or request context instead. Keep `ReadHeaderTimeout` set regardless.

### 71. Default mux is global  [stdlib] · medium
- **Rule:** Register routes on a dedicated `http.NewServeMux()` you own, not on the package-global `http.DefaultServeMux` via `http.HandleFunc`/`http.Handle`.
- **Why:** `http.HandleFunc` mutates a single process-wide `DefaultServeMux`, and passing `nil` as the server handler serves from it. Any imported package can register on it too - importing `net/http/pprof` or `expvar` for their side effects silently attaches `/debug/pprof/*` and `/debug/vars` to your public listener, exposing profiling and internal state. A global mux also makes routes untestable in isolation and order-dependent across `init` funcs. Owning the mux makes the route set explicit, auditable, and injectable.
- **Smell:** `http.HandleFunc(`, `http.Handle(`, `ListenAndServe(addr, nil)`, or a blank import of `net/http/pprof` in a binary that also serves public traffic.
- **Signal:**
```go
// bad
import _ "net/http/pprof" // silently binds /debug/pprof to DefaultServeMux
http.HandleFunc("/api", apiHandler)
http.ListenAndServe(":8080", nil) // serves pprof too

// good
mux := http.NewServeMux()
mux.HandleFunc("GET /api/{id}", apiHandler) // Go 1.22+ method + wildcard patterns
server := &http.Server{Addr: ":8080", Handler: mux, ReadHeaderTimeout: time.Second}
```
- **Updated by newer Go:** Go 1.22 gave `ServeMux` method-aware patterns (`GET /items/{id}`) and path wildcards, so the default excuse for reaching for a third-party router is largely gone - a custom `ServeMux` now covers most routing needs while staying non-global.
- **Exceptions:** Tiny internal tools and examples. If you do want pprof, mount it on a separate mux/listener bound to localhost or an admin port, never the public one.

### 72. json unknown fields  [stdlib] · medium
- **Rule:** In strict-input contexts, decode with `json.Decoder` and call `DisallowUnknownFields()` rather than tolerating `json.Unmarshal`'s silent drop of unrecognized keys.
- **Why:** `json.Unmarshal` (and a plain `Decoder.Decode`) ignore any JSON member with no matching struct field, so a typo like `"amont"` for `"amount"` decodes to the zero value with no error - the request looks valid and you process garbage. `DisallowUnknownFields()` turns an unexpected member into a decode error, catching client typos, schema drift, and mass-assignment probes at the boundary. Note the mirror image: unmarshalling into `map[string]any` never errors on shape and buries every value behind a type assertion (numbers become `float64`), so prefer typed structs when the schema is known.
- **Smell:** `json.Unmarshal(body, &v)` on request payloads; `var m map[string]any` for a known schema; no `DisallowUnknownFields()` anywhere near an input decoder.
- **Signal:**
```go
// bad
var req CreateReq
json.Unmarshal(body, &req) // {"amont": 5} -> req.Amount == 0, no error

// good
dec := json.NewDecoder(r.Body)
dec.DisallowUnknownFields()
if err := dec.Decode(&req); err != nil { // rejects "amont"
	return err
}
```
- **Updated by newer Go:** Go 1.25 ships `encoding/json/v2` (opt-in via `GOEXPERIMENT=jsonv2`), where strictness is an unmarshal option (`RejectUnknownMembers`) and the v1 defaults are reconsidered; if you adopt v2, set the option there instead of `DisallowUnknownFields`.
- **Exceptions:** Forward-compatible consumers that must accept fields added by newer producers (public webhooks, event buses) should stay lenient. Also lenient: partial-update PATCH bodies where absent-vs-present matters more than unknown keys.

### 73. sql rows.Close  [stdlib] · high
- **Rule:** After `db.Query`, immediately `defer rows.Close()` and check `rows.Err()` once the `for rows.Next()` loop ends.
- **Why:** `Rows` holds a connection from the pool for its entire lifetime; if you forget `Close`, that connection is never returned. `Next` auto-closes only when it reaches the last row, so any early `return`, error, or partial read inside the loop leaks the connection - do it a few times and the pool is exhausted, and every subsequent query blocks. Separately, `rows.Next()` returning `false` is ambiguous: it means either "no more rows" *or* "iteration failed"; only `rows.Err()` distinguishes them, so without it a mid-stream network error silently looks like a clean, short result set.
- **Smell:** `db.Query(` with no adjacent `defer rows.Close()`; a `for rows.Next()` loop with no `rows.Err()` check after it; `return` inside the loop before `Close` is deferred.
- **Signal:**
```go
// bad
rows, _ := db.Query("SELECT dep, age FROM emp WHERE id = ?", id)
for rows.Next() { // leaks the conn on early return; missing rows.Err()
	rows.Scan(&dep, &age)
}

// good
rows, err := db.QueryContext(ctx, "SELECT dep, age FROM emp WHERE id = ?", id)
if err != nil { return err }
defer func() { _ = rows.Close() }()
for rows.Next() {
	if err := rows.Scan(&dep, &age); err != nil { return err }
}
return rows.Err() // distinguishes "done" from "iteration failed"
```
- **Exceptions:** `db.QueryRow` returns a single `*Row` that closes itself inside `Scan`, so no explicit `Close` is needed there - the rule is specifically about `Query`/`QueryContext`. Same closing discipline applies to `http.Response.Body`, `os.File`, and any transient resource.

### 74. HTTP retries  [stdlib] · medium
- **Rule:** Retry only idempotent requests, only on 5xx and transient network errors, with capped exponential backoff plus jitter - never blind-retry every failure.
- **Why:** Retrying a 4xx is pointless (the request is malformed or unauthorized; it will fail identically) and retrying a non-idempotent `POST` that actually succeeded server-side but failed on the response path duplicates the side effect - a double charge, a double insert. Fixed-interval retries across many clients synchronize into a retry storm that amplifies the outage that triggered them; exponential backoff with random jitter de-correlates clients. Always honor a `Retry-After` header, cap total attempts, and thread `context` so retries stop when the caller's deadline passes. Drain and close `resp.Body` between attempts or you leak the connection you meant to reuse.
- **Smell:** `for i := 0; i < n; i++` retry loops with a constant `time.Sleep`; retrying without inspecting `resp.StatusCode`; retrying `POST`/`PATCH` without an idempotency key; ignoring `ctx.Done()` inside the retry loop.
- **Signal:**
```go
// bad
for i := 0; i < 3; i++ {
	resp, err := client.Do(req) // retries 400s and duplicate POSTs; fixed sleep -> retry storm
	if err == nil && resp.StatusCode < 500 { return resp, nil }
	time.Sleep(time.Second)
}

// good
for attempt := 0; attempt < maxAttempts; attempt++ {
	resp, err := client.Do(req.WithContext(ctx))
	if err == nil && resp.StatusCode < 500 { return resp, nil } // don't retry 4xx
	if resp != nil { io.Copy(io.Discard, resp.Body); resp.Body.Close() }
	backoff := time.Duration(1<<attempt) * base
	jitter := time.Duration(rand.Int64N(int64(backoff)))
	select {
	case <-time.After(backoff/2 + jitter):
	case <-ctx.Done():
		return nil, ctx.Err()
	}
}
```
- **Exceptions:** Non-idempotent writes become safely retryable behind a server-honored idempotency key. This item is an operational discipline, not a stdlib API - the standard `http.Client` does not retry for you, so either implement the above or use a vetted retrying transport.

### 75. Buffer reuse trap  [stdlib] · high
- **Rule:** Copy bytes out of a reused read buffer before retaining them; a `[]byte` handed back by `io.Reader.Read`, `bufio.Scanner.Bytes`, or `csv.Reader` with `ReuseRecord` is only valid until the next read.
- **Why:** These APIs return a slice that aliases an internal buffer they overwrite on the next call, for zero-allocation streaming. If you append that slice to a collection, store it in a struct, or launch a goroutine that reads it later, every retained reference ends up pointing at the *last* chunk read - the classic symptom is a slice of "distinct" records that are all identical, or garbled data under concurrency. The aliasing is invisible: the code compiles, single-iteration tests pass, and corruption only appears once a second `Read`/`Scan` runs. `Read` filling only part of the buffer compounds it - you must slice to the returned `n` (`buf[:n]`), not reuse the whole capacity.
- **Smell:** `append(out, scanner.Bytes()...)` versus storing `scanner.Bytes()` directly; keeping `buf` after `n, _ := r.Read(buf)` without `buf[:n]`; passing `scanner.Bytes()` to another goroutine; storing `csv.Reader` records when `ReuseRecord` is true.
- **Signal:**
```go
// bad
var lines [][]byte
for scanner.Scan() {
	lines = append(lines, scanner.Bytes()) // all entries alias the same buffer -> all equal to the last line
}

// good
for scanner.Scan() {
	line := append([]byte(nil), scanner.Bytes()...) // copy before retaining
	lines = append(lines, line)
}
// or, when you only need strings, string(scanner.Bytes()) copies implicitly
```
- **Exceptions:** No copy is needed when you fully consume the bytes inside the same iteration before the next `Read`/`Scan` (parse the number, write to a hasher, print it). `bufio.Scanner.Text()` and `string(b)` already allocate a fresh copy, so retaining those is safe.

## Testing

### 76. Test categories  [test-cat] · medium
- **Rule:** Keep unit tests hermetic and fast, and gate anything that touches real infrastructure behind an explicit opt-in (short mode or a build tag) so `go test ./...` stays reliable and quick.
- **Why:** A test suite that silently mixes a 5ms pure-function test with a 30s test that dials a real MySQL is unrunnable in CI's fast lane and flaky in the slow one. `testing.Short()` lets `go test -short` skip long tests while `go test` runs everything, giving one binary two speeds without duplicating code. The failure mode people miss: without categorization, one integration test that needs a network no one has provisioned turns the entire package red, and developers learn to ignore the whole suite.
- **Smell:** A `TestFoo` that opens a socket, DB connection, or Docker container with no `testing.Short()` guard and no build tag; CI that runs the same `go test ./...` locally and in the pipeline with wildly different pass rates.
- **Signal:**
```go
// bad
func TestLongRunning(t *testing.T) {
	db := openRealMySQL(t) // always runs, always slow
	// ...
}
// good
func TestLongRunning(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping long-running test")
	}
	db := openRealMySQL(t)
	// ...
}
```
- **Exceptions:** A repo whose every test is genuinely a fast unit test needs no gating; and a package that is exclusively an integration suite is better isolated by a build tag (see item 80) than by `-short`.

### 77. t.Parallel() in subtests  [test-parallel] · medium
- **Rule:** Call `t.Parallel()` at the top of each subtest you want to run concurrently; on Go < 1.22 also copy the range variable (`tt := tt`) before the closure, but on 1.22+ that copy is dead code.
- **Why:** Parallel subtests only start running against each other after their parent returns, so a table-driven loop that launches N parallel subtests overlaps their I/O and shortens wall-clock time. The classic bug is the loop-variable capture: pre-1.22 the single `tt` was shared, so every deferred parallel closure read whichever value `tt` held after the loop finished, and all subtests tested the last case. Go 1.22 gave each iteration its own variable, so the `tt := tt` line the book shows is now a no-op that a reviewer should delete, not add.
- **Smell:** A parallel subtest closure referencing the range variable directly with a `//go:build` or `go.mod` line of `go 1.22`+ (safe, drop the shadow); or the same reference on an older module (latent bug, all cases test the last row).
- **Signal:**
```go
// bad (pre-1.22: every subtest sees the final row)
for _, tt := range tests {
	t.Run(tt.name, func(t *testing.T) {
		t.Parallel()
		got := f(tt.input) // tt is shared across iterations
	})
}
// good
for _, tt := range tests { // go 1.22+: tt is per-iteration; no shadow needed
	t.Run(tt.name, func(t *testing.T) {
		t.Parallel()
		got := f(tt.input)
		if got != tt.want { t.Errorf("got %v want %v", got, tt.want) }
	})
}
```
- **Exceptions:** Don't parallelize subtests that share mutable state without synchronization, depend on ordering, or mutate process-global state (env vars, working directory) - the concurrency will corrupt them. Setting `t.Setenv` in a test in fact forbids `t.Parallel()` and the runtime will panic.

### 78. testdata/ for fixtures  [test-features] · low
- **Rule:** Put file fixtures in a `testdata/` directory beside the test and open them with relative paths, relying on the fact that `go test` runs with the working directory set to the package's source directory.
- **Why:** The Go tool special-cases `testdata`: it is ignored by the build and by `go` package resolution, so it never becomes an importable package and never ships in a binary. Because the test binary's cwd is the package directory (not wherever `go test ./...` was invoked), `os.ReadFile("testdata/input.json")` resolves deterministically regardless of the caller's shell location. The subtle failure is hardcoding an absolute path or reaching `../../fixtures`, which breaks the moment the repo is checked out elsewhere or the package moves.
- **Smell:** `os.Open("/Users/me/proj/fixtures/x")`, `filepath.Join(os.Getenv("PWD"), ...)`, or `../testdata` climbing out of the package dir.
- **Signal:**
```go
// bad
b, err := os.ReadFile("/abs/path/to/fixtures/sample.json")
// good
b, err := os.ReadFile(filepath.Join("testdata", "sample.json"))
```
- **Exceptions:** Fixtures generated at runtime belong in `t.TempDir()` (auto-cleaned), not `testdata/`; and truly enormous binary fixtures may warrant `go:embed` or external storage instead of bloating the repo.

### 79. Golden files  [test-features] · low
- **Rule:** For assertions on large expected output, store the expected bytes in a golden file under `testdata/` and regenerate it via an `-update` flag rather than pasting the blob into the test source.
- **Why:** Inlining a 200-line expected JSON or rendered template makes the diff on every intentional change unreadable and tempts people to eyeball-edit the literal, introducing typos that make the test assert the wrong thing. A golden-file test reads the file as `want`, compares, and when run with `go test -update` rewrites the file from actual output, so intentional changes are reviewed as a file diff and accidental changes fail loudly. The trap: never write the file inside the assertion path unconditionally - that makes the test tautologically pass.
- **Smell:** A multi-hundred-byte string literal as `expected`; a test that writes its own golden file every run with no flag guard.
- **Signal:**
```go
// bad
want := "line1\nline2\n...200 more lines..." // hand-maintained blob
// good
var update = flag.Bool("update", false, "update golden files")
golden := filepath.Join("testdata", "out.golden")
if *update { os.WriteFile(golden, got, 0o644) }
want, _ := os.ReadFile(golden)
if !bytes.Equal(got, want) { t.Errorf("output mismatch; run -update if intended") }
```
- **Exceptions:** Small, self-evident expected values (a bool, an int, a one-line string) are clearer inline; golden files only pay off past the point where a human can no longer verify the literal by reading it.

### 80. Build tags for environments  [test-cat] · medium
- **Rule:** Gate tests that require real infrastructure behind a `//go:build integration` constraint so they compile and run only when the tag is explicitly requested (`go test -tags=integration`).
- **Why:** A build tag excludes the file from compilation entirely unless the tag is set, which is stronger than a runtime `t.Skip`: the integration dependencies (a DB driver, a cloud SDK) aren't even linked into the default test binary, so `go test ./...` stays fast and has no way to accidentally hit the network. The syntax gotcha the book flags: the tag comment must be the new `//go:build integration` form (the old `// +build` line is legacy) and must be followed by a blank line before `package`, or the compiler treats it as an ordinary comment and the constraint silently does nothing.
- **Smell:** A `//go:build integration` line glued directly to `package foo` with no blank line; or an integration test file with no tag that only guards with an env-var check inside each function.
- **Signal:**
```go
// bad - no blank line: constraint ignored, file always compiles
//go:build integration
package db
// good
//go:build integration

package db
```
- **Exceptions:** For a single slow test inside an otherwise-fast file, `testing.Short()` (item 76) is lighter than splitting the file; build tags shine when an entire file's imports are infrastructure-only.

### 81. httptest for HTTP handlers and clients  [test-httptest] · medium
- **Rule:** Test `http.Handler`s with `httptest.NewRecorder` and test HTTP clients against `httptest.NewServer`, instead of standing up a real listener or pointing at a live endpoint.
- **Why:** `httptest.NewRecorder` captures status, headers, and body from a handler with no socket at all, and `httptest.NewServer` gives a real loopback server on an ephemeral port whose `.URL` you feed to the client under test - so you exercise the actual `net/http` round-trip (marshaling, headers, status parsing) without external flakiness or fixed ports. The failure mode this prevents: tests that bind `:8080`, collide in CI, and leak goroutines because nothing calls `srv.Close()`. Always `defer srv.Close()`.
- **Smell:** `http.ListenAndServe` inside a test, a hardcoded port, or a client test whose URL is a real external host.
- **Signal:**
```go
// bad
go http.ListenAndServe(":8080", h) // real port, races, leaks
resp, _ := http.Get("http://localhost:8080/x")
// good
srv := httptest.NewServer(http.HandlerFunc(handler))
defer srv.Close()
resp, err := client.GetDuration(srv.URL, ...) // srv.URL is an ephemeral loopback port
```
- **Exceptions:** End-to-end tests that intentionally validate a deployed service or TLS/cert-pinning behavior against a real endpoint are a different (integration) category - gate those per items 76/80.

### 82. t.Helper() in test helpers  [test-features] · medium
- **Rule:** In any test utility that takes `*testing.T` and calls `t.Fatal`/`t.Error`, call `t.Helper()` as the first line so a failure is reported at the caller's line, not inside the helper.
- **Why:** Without `t.Helper()`, every failure funneled through a shared `mustCreateCustomer(t, ...)` helper points the file:line at the `t.Fatal` inside the helper, so ten different failing call sites all report the same useless location. `t.Helper()` marks the function as a helper and the testing framework walks past it to the caller's stack frame. The book's own utility-function example passes `t` into `createCustomer2` but omits `t.Helper()` - modern practice is to add it. This is the mechanism the team's clock-injection and stub helpers rely on for legible failures.
- **Smell:** A function with signature `func(t *testing.T, ...)` that calls `t.Fatal` but never calls `t.Helper()`; failures whose file:line all point into a shared assertion helper.
- **Signal:**
```go
// bad
func createCustomer(t *testing.T, arg string) Customer {
	c, err := customerFactory(arg)
	if err != nil { t.Fatal(err) } // failure blamed on this line for every caller
	return c
}
// good
func createCustomer(t *testing.T, arg string) Customer {
	t.Helper()
	c, err := customerFactory(arg)
	if err != nil { t.Fatal(err) } // failure blamed on the caller's line
	return c
}
```
- **Exceptions:** A helper that never fails the test (pure setup returning `(value, error)` for the caller to check) doesn't need `t.Helper()`; it only matters on functions that call `t.Fatal`/`t.Error`/`t.Fatalf` themselves.

### 83. Run with the race detector  [test-race] · high
- **Rule:** Run `go test -race` in CI (and locally on concurrent code); accept the ~2-10x slowdown and higher memory as the price of catching data races before production.
- **Why:** The race detector instruments memory accesses at runtime and reports when two goroutines touch the same address without a happens-before relationship and at least one writes. It only flags races that actually execute, so it must run against realistic tests - a race in a code path no test exercises stays invisible. The subtle point: a passing `go test` proves nothing about concurrency safety; the mock in the book's sleeping example needs a mutex specifically because `-race` would otherwise flag the goroutine's `Publish` writing `got` while the test reads it. Races are not deterministic, so "it passed 100 times" is not evidence of safety - only `-race` is.
- **Smell:** A CI config that runs `go test` but never `go test -race`; concurrent code (goroutines, shared maps, channels) with no race-enabled test run.
- **Signal:**
```go
// bad
go test ./...            # green, but a write/read race goes undetected
// good
go test -race ./...      # flags the unsynchronized shared access at the offending line
```
- **Exceptions:** The detector can't run under some constrained/cross-compiled targets and roughly 10x's memory, so extremely large suites sometimes run `-race` on a nightly job or on concurrency-touching packages only rather than every package on every commit - but never drop it entirely.

### 84. Test execution modes: parallel and shuffle  [test-exec] · low
- **Rule:** Use `-parallel N` to cap concurrent parallel tests and `-shuffle=on` to randomize execution order, surfacing tests that secretly depend on running order.
- **Why:** `-parallel` bounds how many `t.Parallel()` tests run at once (default `GOMAXPROCS`), which matters now that Go 1.25 makes `GOMAXPROCS` container-CPU-aware - the parallel-test count auto-scales to the cgroup quota rather than the host's core count, so tuning may differ from older Go. `-shuffle=on` reorders tests and subtests and prints the seed so a failure is reproducible with `-shuffle=<seed>`; it catches the insidious bug where test A only passes because test B ran first and left global state (a populated cache, a registered handler) behind. Order dependence is a latent flake that stays hidden until someone adds, removes, or parallelizes a test.
- **Smell:** A suite that passes in file order but fails when a test is added or moved; tests that mutate package-level vars and rely on declaration order.
- **Signal:**
```go
// bad
go test ./...                     # fixed order hides A-depends-on-B coupling
// good
go test -shuffle=on -race ./...   # prints seed; reproduce with -shuffle=<seed>
```
- **Exceptions:** Tests that legitimately share expensive setup via `TestMain` run once for the package regardless of shuffle; and a genuinely serial suite (each test tears down its own state) gains little from `-parallel` but still benefits from `-shuffle`.

### 85. Table-driven tests  [test-table] · low
- **Rule:** Collect variations of the same logic into a table of `{name, input, want}` cases iterated with `t.Run`, instead of copy-pasting one near-identical test function per case.
- **Why:** N hand-written `TestFoo_CaseA`, `TestFoo_CaseB` functions drift: someone fixes an assertion in one and forgets the others, or copy-pastes a case and forgets to change the expected value (the book's own example has a `_EndingWithoutNewLine` test that actually passes `"a\n"`, a copy-paste slip a table makes obvious). A table centralizes the logic once, names each case for readable failure output via `t.Run`, and makes adding a case a one-line data edit. Prefer a slice of structs over a map when order matters, since map iteration is randomized (item 23).
- **Smell:** Multiple test functions that differ only in the literal input and expected output; a case added by duplicating a function body.
- **Signal:**
```go
// bad
func TestTrim_A(t *testing.T) { if got := f("a\n"); got != "a" { t.Error(got) } }
func TestTrim_B(t *testing.T) { if got := f("a\r\n"); got != "a" { t.Error(got) } }
// good
tests := []struct{ name, in, want string }{
	{"newline", "a\n", "a"},
	{"crlf", "a\r\n", "a"},
}
for _, tt := range tests {
	t.Run(tt.name, func(t *testing.T) {
		if got := f(tt.in); got != tt.want { t.Errorf("got %q want %q", got, tt.want) }
	})
}
```
- **Exceptions:** When each case needs materially different setup, mocks, or assertions, forcing them into one table with a pile of optional fields is less clear than separate tests - tables win only when the cases are genuinely the same shape.

### 86. Never sleep to synchronize a test  [test-sleep] · high
- **Rule:** Never `time.Sleep` to wait for an asynchronous result; synchronize deterministically with a channel, or if you must poll, retry an assertion with a bounded timeout.
- **Why:** A fixed sleep encodes a guess about how long an operation takes: too short and the test flakes under CI load, too long and the suite crawls - and it is wrong on both axes simultaneously on a busy machine. The deterministic fix is to have the code publish completion on a channel the test blocks on (`<-mock.ch`), so the test proceeds the instant the work is done and hangs (a clear failure) if it never completes. When you can't add a channel, a retry-with-timeout helper (`assert(t, cond, maxRetry, wait)`) polls and fails only after the budget expires, which is strictly better than a single blind sleep. Sleeps are the number-one source of "passes on my machine" flakes.
- **Smell:** `time.Sleep(...)` between an async trigger and the assertion that reads its result; magic millisecond constants tuned until CI went green.
- **Signal:**
```go
// bad
h.getBestFoo(42)
time.Sleep(10 * time.Millisecond) // guess; flakes under load
published := mock.Get()
// good  (mock.Publish sends on ch)
h.getBestFoo(42)
if v := len(<-mock.ch); v != 2 { // blocks until the goroutine publishes
	t.Fatalf("expected 2, got %d", v)
}
```
- **Exceptions:** Testing genuinely time-dependent behavior (a rate limiter, a debounce window) may need controlled time - but inject a fake clock (item 87) or, on Go 1.24+, use `testing/synctest` to fast-forward a fake clock deterministically rather than sleeping real wall-clock time.

### 87. Inject the clock; don't call time.Now()  [test-time] · medium
- **Rule:** Don't call `time.Now()` directly in logic you need to test; make the current time an input - a function parameter, an injected `clock`, or a `now func() time.Time` field defaulted to `time.Now`.
- **Why:** Code that reads `time.Now()` internally is untestable except by constructing inputs relative to "now" (`time.Now().Add(-20*time.Millisecond)`), which reintroduces the wall-clock dependence and second-boundary flakiness you were trying to avoid. The book shows the progression: hide `time.Now` behind a `now` field, or - cleanest - pass the time in as a parameter so the test hands over a fixed `parseTime(t, "2020-01-01T12:00:00.06Z")` and asserts an exact result. Passing time as an argument is simpler than a struct field when the function is otherwise stateless. In this codebase the standard is `github.com/benbjohnson/clock` injected as a struct field (`nil` -> `clock.New()`, tests pass `clock.NewMock()`); on Go 1.24+ `testing/synctest` is the newer alternative for whole-goroutine fake-time control.
- **Smell:** `time.Now()` inside a method whose behavior depends on it; a test that builds expected values with `time.Now().Add(...)` and compares counts.
- **Signal:**
```go
// bad
func (c *Cache) TrimOlderThan(since time.Duration) {
	t := time.Now().Add(-since) // untestable; test must anchor to real now
	// ...
}
// good
func (c *Cache) TrimOlderThan(now time.Time, since time.Duration) {
	t := now.Add(-since) // test passes a fixed instant
	// ...
}
```
- **Exceptions:** A field/injected clock is warranted when the time source is used across many methods or must advance during the test; for a single stateless function, a plain `time.Time` parameter is simpler and preferable to a whole clock abstraction.

### 88. iotest for Reader/Writer error paths  [test-iotest] · medium
- **Rule:** Use `testing/iotest` to exercise `io.Reader`/`io.Writer` implementations and their consumers - `iotest.TestReader` to validate a reader, and `iotest.ErrReader`/`TimeoutReader`/`HalfReader` to drive the error and short-read branches that a happy-path `strings.NewReader` never hits.
- **Why:** Most reader-consuming code has an untested `if err != nil` branch and an unhandled "Read returned fewer bytes than requested" case, because a normal in-memory reader returns everything in one call with no error. `iotest.TimeoutReader` returns `iotest.ErrTimeout` after the first read, and `iotest.ErrReader` fails immediately, forcing those branches to execute; `iotest.TestReader` asserts a reader obeys the `io.Reader` contract (correct byte counts, EOF handling). The book's example uses `TimeoutReader` to prove `foo2`'s retry loop survives a transient error that `foo1` mishandles - a bug invisible without the fault-injecting reader.
- **Smell:** Reader/Writer code whose only test feeds `strings.NewReader`/`bytes.Buffer`; an error branch in a `Read` loop with no test that makes `Read` fail.
- **Signal:**
```go
// bad
func TestFoo(t *testing.T) {
	err := foo(strings.NewReader("data")) // never triggers the error branch
	if err != nil { t.Fatal(err) }
}
// good
func TestFoo_Retries(t *testing.T) {
	err := foo(iotest.TimeoutReader(strings.NewReader(randomString(1024))))
	if err != nil { t.Fatal(err) } // proves the retry path handles ErrTimeout
}
```
- **Exceptions:** Code that never consumes an arbitrary `io.Reader` (it owns a concrete in-memory buffer) has no error path to inject; `iotest` matters specifically at boundaries that read from the network, files, or caller-supplied streams.

### 89. Write accurate benchmarks  [test-bench] · medium
- **Rule:** Reset the timer after setup (`b.ResetTimer`), keep per-iteration setup out of the timed region (`b.StopTimer`/`b.StartTimer`), and consume the result into a package-level variable so the compiler can't eliminate the code you're measuring.
- **Why:** Three independent ways a benchmark lies: (1) expensive setup before the loop is counted unless you `ResetTimer`, inflating ns/op; (2) if the result is never used, the optimizer deletes the call entirely and you benchmark an empty loop - assigning to a `var global` defeats dead-code elimination; (3) `StopTimer`/`StartTimer` inside a hot, cheap loop adds so much bookkeeping overhead (the observer effect) that per-iteration setup distorts the number, so hoist setup out of the loop when possible. The book also warns that micro-benchmarks like atomic int32-vs-int64 measure noise and mislead architecture decisions. On Go 1.24+, `for b.Loop()` replaces `for i := 0; i < b.N; i++`, and it keeps the benched arguments/results alive automatically, removing the manual `global` sink for many cases.
- **Smell:** Setup inside `for i := 0; i < b.N; i++`; a benchmark whose result is discarded; `StopTimer`/`StartTimer` in the body of a nanosecond-scale loop.
- **Signal:**
```go
// bad
func BenchmarkPopcnt(b *testing.B) {
	for i := 0; i < b.N; i++ {
		popcnt(uint64(i)) // result unused -> whole call may be optimized away
	}
}
// good
var global uint64
func BenchmarkPopcnt(b *testing.B) {
	var v uint64
	s := expensiveSetup()
	b.ResetTimer()          // exclude setup
	for i := 0; i < b.N; i++ {
		v = popcnt(uint64(i))
	}
	global = v               // sink defeats dead-code elimination
	_ = s
}
```
- **Exceptions:** When per-iteration state genuinely must be rebuilt (each iteration mutates its input), `StopTimer`/`StartTimer` around the rebuild is correct despite the overhead - just be aware the reported ns/op carries that noise for very cheap operations.

### 90. Black-box tests via package foo_test  [test-features] · low
- **Rule:** Put tests in an external `package foo_test` (same directory, `_test` suffix) when you want to test only the exported API and prove the public surface is usable as a real client would use it.
- **Why:** An internal `package foo` test can reach unexported identifiers, which is handy for white-box coverage but lets tests couple to internals and, worse, lets them pass while the exported API is unusable. A `package foo_test` file can import only the public API, so it doubles as executable documentation and catches export-visibility mistakes (a type returned by a public function but itself unexported). It also breaks import cycles: a test that needs to import a package that imports `foo` can't live in `package foo`. Go uniquely allows both `foo` and `foo_test` files in the same directory for exactly this split.
- **Smell:** Tests reaching unexported helpers to assert internal state that the public API already exposes; an inability to write a test because importing a helper would cycle back to the package under test.
- **Signal:**
```go
// bad - white-box: couples to internals, hides export gaps
package counter
func TestCount(t *testing.T) { if Inc() != 1 { t.Error("expected 1") } }
// good - black-box: exercises only the exported surface
package counter_test
import counter "example.com/counter"
func TestCount(t *testing.T) { if counter.Inc() != 1 { t.Errorf("expected 1") } }
```
- **Exceptions:** Testing genuinely internal invariants (an unexported algorithm, a private state machine) legitimately needs `package foo`; many packages carry both files - white-box for internals, black-box for the public contract.

## Optimizations

### 91. CPU cache locality  [optim] · low
- **Rule:** Lay out hot data so the loop walks memory sequentially and every loaded cache line is fully used - prefer struct-of-slices over slice-of-structs when a loop touches only some fields.
- **Why:** The CPU fetches memory 64 bytes at a time (one cache line). Summing only field `a` of `[]Foo{a, b int64}` loads 4 structs per line but reads half of each, wasting 50% of memory bandwidth; splitting into `Bar{a, b []int64}` packs the `a` values contiguously so each line is fully consumed. Sequential access also lets the hardware prefetcher predict the next line, which is why a `[]int64` beats a pointer-chasing linked list even at equal element count - the prefetcher can't follow `next` pointers.
- **Smell:** hot loop iterating `[]BigStruct` but reading one field; pointer-chasing (`node.next`) in a summation; large stride (`i += 8`) that touches one element per line.
- **Signal:**
```go
// bad - each 64B line holds 4 Foos, only field a is read -> half the bytes wasted
type Foo struct{ a, b int64 }
func sum(foos []Foo) (t int64) {
	for i := range foos {
		t += foos[i].a
	}
	return
}
// good - a values are contiguous, every cache line fully used
type Bar struct{ a, b []int64 }
func sum(bar Bar) (t int64) {
	for i := range bar.a {
		t += bar.a[i]
	}
	return
}
```
- **Exceptions:** Only worth it in a profiled hot loop over large data. For small slices, or when you always read the whole struct, slice-of-structs is simpler and equally fast - and it keeps related fields together for the write path.

### 92. False sharing  [optim] · medium
- **Rule:** When separate goroutines each write their own variable, ensure those variables land on different 64-byte cache lines; pad the struct between them if they're adjacent.
- **Why:** Cache coherence operates at cache-line granularity, not variable granularity. If `sumA` and `sumB` sit in the same line and two cores each write one of them, every write invalidates the other core's copy of the whole line, forcing a coherence round-trip - the cores serialize despite touching logically independent data. Padding `sumA` out to a full line (`_ [56]byte` after an `int64`) puts `sumB` on the next line, eliminating the ping-pong. This is invisible in correctness tests and only shows up as concurrency that refuses to scale.
- **Smell:** a shared result struct with adjacent counters each written by a different goroutine; per-worker accumulators in a slice indexed by worker id (`counts[workerID]++`); no padding between fields under contention.
- **Signal:**
```go
// bad - sumA and sumB share one cache line; the two goroutines fight over it
type Result struct{ sumA, sumB int64 } // 16 bytes, one line
// good - pad so each counter owns its own 64-byte line
type Result struct {
	sumA int64
	_    [56]byte // 8 (int64) + 56 = 64 -> sumB starts on the next line
	sumB int64
}
```
- **Exceptions:** Pointless without real cross-core write contention - padding wastes memory otherwise. If the variables are read-mostly, or each goroutine accumulates into a local and writes back once at the end, there's no sharing to eliminate. Prefer the local-accumulator pattern first; padding is the fallback when the writes must stay in a shared struct.

### 93. Instruction-level parallelism  [optim] · low
- **Rule:** In a tight loop, break data dependencies so independent operations can issue in parallel - read a value once into a local instead of re-reading a location you just wrote.
- **Why:** A superscalar CPU executes multiple instructions per cycle only when they don't depend on each other's results. Writing `s[0]++` and then branching on `s[0]%2` forces the branch to wait for the store to complete (a read-after-write hazard), serializing the pipeline. Capturing `v := s[0]` first, then computing `s[0] = v+1` and branching on `v%2`, lets the increment and the branch test run concurrently because both read the already-available `v`. Same result, shorter dependency chain.
- **Smell:** re-reading a variable/element immediately after mutating it inside a hot loop; a conditional that depends on the just-updated value rather than the pre-update value.
- **Signal:**
```go
// bad - the %2 test depends on the store to s[0], stalling the pipeline
for i := 0; i < n; i++ {
	s[0]++
	if s[0]%2 == 0 {
		s[1]++
	}
}
// good - branch tests the old value v; increment and test are independent
for i := 0; i < n; i++ {
	v := s[0]
	s[0] = v + 1
	if v%2 != 0 {
		s[1]++
	}
}
```
- **Exceptions:** A last-resort micro-optimization for a profiled inner loop. The compiler and CPU already reorder aggressively, so gains are small and easily erased by a bounds check or an inlining change - verify with a benchmark, and don't contort readable code for it elsewhere.

### 94. Data alignment  [optim] · low
- **Rule:** Order struct fields largest-to-smallest so the compiler's alignment padding is minimized and the struct stays compact.
- **Why:** Each field must sit at an offset that's a multiple of its own size (an `int64` on an 8-byte boundary), so the compiler inserts invisible padding between mismatched neighbors. `struct{ b1 byte; i int64; b2 byte }` pads to 24 bytes; reordering to `struct{ i int64; b1 byte; b2 byte }` is 16 - a 33% cut. Smaller structs mean more elements per cache line and fewer bytes to move, which compounds with cache-locality wins in large slices. The padding is silent: `unsafe.Sizeof` is the only way you'll notice.
- **Smell:** structs interleaving `byte`/`bool`/`int32` between `int64`/pointer/`float64` fields; a large `[]Struct` where field order looks arbitrary; `fieldalignment` vet check flags it.
- **Signal:**
```go
// bad - 24 bytes: b1(1)+pad(7), i(8), b2(1)+pad(7)
type Foo struct {
	b1 byte
	i  int64
	b2 byte
}
// good - 16 bytes: i(8), b1(1), b2(1)+pad(6)
type Foo struct {
	i  int64
	b1 byte
	b2 byte
}
```
- **Exceptions:** Only matters for structs allocated in bulk or held in the millions; a handful of instances isn't worth reordering. Never reorder if a logical/grouped field order aids readability of a rarely-allocated config struct, and don't hand-tune when the field order is dictated by a wire/serialization layout. Run `go vet -vettool=$(which fieldalignment)` rather than eyeballing.

### 95. Stack vs heap allocation  [optim] · medium
- **Rule:** Design functions so values don't escape to the heap - "share down" (pass pointers into callees) rather than "share up" (return pointers to locals).
- **Why:** A value the compiler can prove doesn't outlive its function is stack-allocated and freed for free when the frame pops; anything that escapes goes on the heap and adds GC pressure. Returning `&z` where `z` is a local forces `z` to the heap ("moved to heap: z" under `-gcflags=-m`), because the pointer outlives the frame. Passing `&a` down into a function that only reads it does not escape - the callee's use ends before the caller's frame does. Reducing escapes cuts allocation count, which is usually a bigger win than shaving CPU in allocation-heavy code.
- **Smell:** constructors returning `*T` for small short-lived values; a local whose address is returned; `-gcflags="-m"` printing "moved to heap"; high `allocs/op` in `-benchmem`.
- **Signal:**
```go
// bad - z escapes: returning its address forces a heap allocation
func sumPtr(x, y int) *int {
	z := x + y
	return &z
}
// good - value return stays on the stack; pointers only flow downward
func sumValue(x, y int) int {
	z := x + y
	return z
}
func sum(x, y *int) int { return *x + *y } // args don't escape - read-only, share down
```
- **Exceptions:** Large structs are cheaper to pass by pointer than to copy, even if that means an escape; sharing up is unavoidable for genuinely long-lived objects (caches, returned builders). Confirm with escape analysis and a benchmark before restructuring - escape decisions are subtle and change across Go releases, so intuition is unreliable.

### 96. Reduce allocations  [optim] · medium
- **Rule:** Cut heap allocations in hot paths by reusing buffers via `sync.Pool`, avoiding value-to-heap escapes, and exploiting compiler special-cases like inline `map[string(bytes)]` lookups.
- **Why:** Fewer allocations means less GC work, which often dominates throughput in serving code. The compiler elides the `[]byte`->`string` copy only when the conversion is used directly as a map key in the same expression (`c.m[string(bytes)]`); assigning `key := string(bytes)` first defeats it and allocates. `sync.Pool` recycles short-lived objects across goroutines, but it has two footguns: pooled objects can be reclaimed by the GC at any time (never assume an item survives), and you must reset state before reuse or you leak stale data into the next caller. Retaining a reference to a buffer after `Put` is a data race.
- **Smell:** `key := string(b); m[key]` instead of `m[string(b)]`; `make([]byte, n)` per request in a hot handler; `sync.Pool` usage that doesn't reset the object on `Put`; holding a pooled slice past the `defer Put`.
- **Signal:**
```go
// bad - the intermediate string forces an allocation on every lookup
func (c *cache) get(b []byte) (int, bool) {
	key := string(b)
	v, ok := c.m[key]
	return v, ok
}
// good - compiler recognizes the pattern and skips the conversion copy
func (c *cache) get(b []byte) (int, bool) {
	v, ok := c.m[string(b)]
	return v, ok
}

var pool = sync.Pool{New: func() any { b := make([]byte, 1024); return &b }}
func write(w io.Writer) {
	bp := pool.Get().(*[]byte)
	defer func() { *bp = (*bp)[:0]; pool.Put(bp) }() // reset length before returning
	b := *bp
	getResponse(b)
	_, _ = w.Write(b)
}
```
- **Exceptions:** Don't pool objects that aren't hot or aren't uniformly sized - `sync.Pool` adds complexity and can hurt if entries are large and rarely reused. This is a profile-driven optimization (mistake 98): premature pooling and buffer reuse are a classic source of aliasing bugs, so measure `allocs/op` first and only reach for pools where the allocation actually shows up.

### 97. Rely on inlining, keep hot functions small  [optim] · low
- **Rule:** Let the compiler inline hot leaf functions by keeping them under the inlining budget instead of hand-inlining them yourself; don't bloat a small hot function past the threshold.
- **Why:** Inlining removes call overhead and, more importantly, exposes the callee's body to escape analysis, bounds-check elimination, and constant folding at the call site - so an inlined helper can turn a heap allocation into a stack one. Go uses a cost budget (roughly 80 nodes) and mid-stack inlining; a function that grows too large, or historically contained certain constructs, silently stops being inlined and its callers regress. `-gcflags="-m"` prints "can inline f" / "cannot inline f: function too complex". The failure mode is a perf regression from an innocuous refactor that pushed a hot function over the budget.
- **Smell:** copy-pasting a helper's body inline "for speed"; a hot leaf function that keeps accreting logging/validation; `//go:noinline` left on a hot path; assuming a call is inlined without checking `-m`.
- **Signal:**
```go
// bad - manually inlined for "speed", now duplicated and unmaintainable
total += (foos[i].a*2 + foos[i].b) / 2 // repeated at every call site
// good - small helper the compiler inlines; check with go build -gcflags=-m
func score(f Foo) int64 { return (f.a*2 + f.b) / 2 } // "can inline score"
total += score(foos[i])
```
- **Exceptions:** Inlining is a compiler concern, not a design driver - never distort an API to chase it. Large functions, functions with heavy loops, and cold paths shouldn't be forced small. Only care in a profiled hot path, and verify with `-m` rather than guessing.

### 98. Profile before optimizing  [optim] · medium
- **Rule:** Find the real bottleneck with `pprof` (CPU, heap, block, mutex) and the execution tracer before changing any code for performance; never optimize by intuition.
- **Why:** Intuition about where Go programs spend time is usually wrong - the cost is often in allocation/GC, lock contention, or syscalls rather than the arithmetic you'd stare at. `runtime/pprof` and `net/http/pprof` expose CPU and heap profiles; the block and mutex profiles surface contention that a CPU profile hides; `runtime/trace` (`go tool trace`) shows goroutine scheduling, GC pauses, and syscall latency that no profile captures. Optimizing an un-profiled hot spot wastes effort and often adds bugs (see the aliasing traps in mistakes 92 and 96) while the actual bottleneck stays untouched.
- **Smell:** a "performance" PR with no benchmark or profile attached; micro-optimizations justified by reasoning alone; adding `sync.Pool`/unsafe/padding before measuring `allocs/op`; benchmarks without `benchstat` comparison.
- **Signal:**
```go
// bad - guessing, no measurement
// "this loop looks slow, let me rewrite it with unsafe"
// good - benchmark, profile, then target what the profile shows
// go test -bench=. -cpuprofile=cpu.out -memprofile=mem.out
// go tool pprof cpu.out   ; go tool trace trace.out
b.ReportAllocs()
b.ResetTimer()
for i := 0; i < b.N; i++ { result = hotPath(input) }
```
- **Exceptions:** None for a real optimization effort - measurement is the whole discipline. Obvious algorithmic fixes (O(n^2) -> O(n), a query in a loop) don't need a profiler to justify, but you still confirm the win with a benchmark afterward.

### 99. GC tuning with GOGC and GOMEMLIMIT  [optim] · medium
- **Rule:** Tune GC with `GOGC` for the pause/throughput tradeoff and set `GOMEMLIMIT` (Go 1.19+) as a soft memory ceiling to prevent OOM - don't set the memory limit so low that the collector thrashes.
- **Why:** `GOGC` (default 100) triggers a cycle when the live heap grows by that percentage; raising it trades memory for fewer GC cycles (throughput), lowering it does the reverse. `GOMEMLIMIT` makes the GC run progressively harder as the heap approaches the limit, which caps memory even under allocation spikes - but if the limit is near the live-set size, the collector runs almost continuously ("GC death spiral"), burning CPU while never freeing enough. The recommended pattern is to keep `GOGC` on and set `GOMEMLIMIT` slightly below the container's memory limit as a safety valve, not as the primary knob.
- **Smell:** `GOGC=off` with no memory limit; `GOMEMLIMIT` set equal to or barely above the steady-state live heap; tuning these by guesswork instead of from heap-profile data; no memory limit at all in a memory-capped container (see mistake 100).
- **Signal:**
```go
// bad - disables GC entirely; one allocation spike OOM-kills the process
// GOGC=off
// good - keep GOGC default, cap memory just under the container limit as a backstop
// GOMEMLIMIT=1750MiB  (container limit 2GiB)  GOGC=100
import "runtime/debug"
debug.SetMemoryLimit(1750 << 20) // programmatic equivalent
```
- **Exceptions:** Most services need no GC tuning - leave the defaults until a heap profile or GC-trace (`GODEBUG=gctrace=1`) shows a real pause or memory problem. Latency-critical services may lower `GOGC` deliberately; batch jobs may raise it. `GOMEMLIMIT` is the one setting worth adding by default in any memory-capped container.

### 100. Container-aware CPU and GOMAXPROCS  [optim] · medium
- **Rule:** Ensure `GOMAXPROCS` matches the container's CPU quota, not the host core count - on Go 1.25+ this is automatic, but pin it explicitly (or use `automaxprocs`) on older runtimes.
- **Why:** Before Go 1.25, `GOMAXPROCS` defaulted to `runtime.NumCPU()`, which reports the host's logical CPUs and ignores the cgroup CFS quota. A pod limited to 2 CPUs on a 64-core node ran with `GOMAXPROCS=64`, spawning far too many OS threads and GC workers, causing excessive context switching, CFS throttling, and latency spikes under load. Go 1.25 makes the default container-aware: it reads the cgroup CPU bandwidth limit and adjusts `GOMAXPROCS` dynamically. On 1.24 and earlier the mismatch is silent - correctness is fine, only tail latency and CPU efficiency degrade.
- **Smell:** Go < 1.25 in Kubernetes/ECS with CPU limits and no `automaxprocs` import and no `GOMAXPROCS` env; assuming `runtime.NumCPU()` reflects the quota; worker-pool sizing derived from `NumCPU()` in a container.
- **Signal:**
```go
// bad (Go <=1.24) - GOMAXPROCS defaults to host cores, ignoring the 2-CPU limit
// nothing set

// good (Go <=1.24) - align GOMAXPROCS to the cgroup quota at startup
import _ "go.uber.org/automaxprocs" // sets GOMAXPROCS from the cgroup limit
// good (Go 1.25+) - automatic; override only for a measured reason
// GOMAXPROCS=2
```
- **Exceptions:** No adjustment needed on Go 1.25+ (the runtime handles it) or outside containers where host cores are the real limit. If you've measured that a specific `GOMAXPROCS` beats the auto value for your workload, pin it explicitly - the automatic default is a good baseline, not a mandate.
