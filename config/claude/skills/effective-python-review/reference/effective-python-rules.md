# Effective Python — full rule detail (127 items)

Each item: rule · why · smell · signal · exceptions · severity. ⚠ on a signal = the adversarial verifier flagged it; treat as illustrative, not authoritative.


## Pythonic Thinking


### 1. Know Which Version of Python You're Using  [2nd,3rd] · medium
- **Rule:** Pin and verify the interpreter version at runtime and in tooling config; never assume the environment runs the Python you developed against.
- **Why:** `python` on a host may still resolve to a Python 2 or an older Python 3 than the syntax/stdlib features the code relies on (walrus, match, f-strings, typing generics). The mistake people make is assuming their local interpreter equals CI's and prod's; version skew surfaces as import-time SyntaxErrors or silently different behavior, not a clear message.
- **Smell:** Code uses 3.10+ syntax (`match`, `int | None`, `list[str]` annotations) while the project declares `python_requires>=3.7`; shebang says `python` instead of `python3`; no runtime version assertion and no pinned version in CI/pyproject.
- **Signal:**
```python
# bad: silently relies on features not guaranteed by the env
import sys  # nothing enforces a floor

# good: fail loudly and early at startup
if sys.version_info < (3, 10):
    raise RuntimeError(f"Requires Python 3.10+, got {sys.version}")
# also: pin in pyproject.toml -> requires-python = ">=3.10"
```
- **Exceptions:** A truly version-agnostic library targeting a wide range may skip a hard runtime gate, but it still must declare `requires-python` and test the full matrix in CI.

### 2. Follow the PEP 8 Style Guide  [2nd,3rd] · low
- **Rule:** Enforce PEP 8 mechanically via a formatter/linter in CI rather than debating style in review comments.
- **Why:** PEP 8 is about consistency that lowers cognitive load, not aesthetics. The common error is treating it as optional taste or hand-checking it in review; the right move is to let a tool (black/ruff) own formatting so reviewers spend attention on naming conventions and semantics the tool can't judge (e.g. `snake_case` functions, `CapWords` classes, `_protected` leading underscore, `is None` not `== None`).
- **Smell:** Mixed naming conventions (camelCase functions next to snake_case), `if x == None`, comparing booleans with `== True`, `l`/`O`/`I` single-char names, two-space indents, no linter in CI, manual nit comments about whitespace.
- **Signal:**
```python
# bad
def getUserData(l):
    if l == None: return
# good
def get_user_data(items):
    if items is None:
        return
# and: ruff/black wired into pre-commit + CI so this never reaches review
```
- **Exceptions:** A team may codify documented deviations (e.g. line length 100) in the tool config; the rule is consistency with the configured standard, not blind adherence to every default. Generated code is exempt.

### 3. Write Helper Functions Instead of Complex Expressions  [2nd,3rd] · medium
- **Rule:** Extract any multi-step or repeated expression into a named helper function instead of cramming logic into one dense line.
- **Why:** Python's terseness (chained `or`, nested ternaries, dict.get with boolean coercion) tempts one-liners, but density is not the same as clarity and not free of bugs. The nuance people miss: a clever expression that's reused even twice should become a function — the name documents intent, the logic is testable, and edge cases (empty string vs missing key vs '0') are handled in one place.
- **Smell:** Deeply nested conditional expressions, `int(value or default)` style coercion chains repeated across the file, a comprehension with three clauses plus a conditional, or the same gnarly expression copy-pasted in multiple branches.
- **Signal:**
```python
# bad: subtle '' vs missing handling, repeated
red = int(params.get('red', [''])[0] or 0)
green = int(params.get('green', [''])[0] or 0)
# good
def get_first_int(params, key, default=0):
    found = params.get(key, [''])
    return int(found[0]) if found[0] else default
red = get_first_int(params, 'red')
```
- **Exceptions:** A single, genuinely simple expression used once doesn't need extraction — over-decomposing trivial logic into one-call helpers adds indirection without payoff. The trigger is complexity or repetition, not line count alone.

### 4. Prefer Multiple-Assignment Unpacking Over Indexing  [2nd,3rd] · medium
- **Rule:** Bind sequence/tuple elements to named variables via unpacking instead of repeatedly indexing with numeric subscripts.
- **Why:** Numeric indices carry no meaning and drift out of sync when structure changes; unpacking names each piece and reads closer to intent. The deeper point most miss: unpacking also eliminates temp-variable swaps (`a, b = b, a`) and shines in loop bodies via `enumerate` and unpacking nested structures inline — index-heavy loops are a smell that idiomatic unpacking removes.
- **Smell:** `item[0]`, `item[1]` scattered through a function; `for i in range(len(seq)): x = seq[i]`; a manual `tmp` swap; indexing into a tuple returned by a function instead of naming its parts.
- **Signal:**
```python
# bad
for i in range(len(pairs)):
    name = pairs[i][0]; score = pairs[i][1]
tmp = a; a = b; b = tmp
# good
for rank, (name, score) in enumerate(pairs, 1):
    ...
a, b = b, a
```
- **Exceptions:** When you genuinely need only one element of a long sequence, a single index is clearer than unpacking with throwaway `_` placeholders; very deep nested unpacking can become harder to read than a couple of indexed accesses.

### 5. Prevent Repetition with Assignment Expressions  [2nd,3rd] · low
- **Rule:** Use the walrus operator (`:=`) to compute-and-test a value in one place when the same value would otherwise be assigned then immediately re-checked or recomputed.
- **Why:** The walrus removes a class of repetition where you'd assign before an `if`/`while` or recompute inside a comprehension, and it tightens variable scope to where it's used. The trap: it requires Python 3.8+, often needs surrounding parens in comparisons, and is easy to overuse — if it makes the line harder to parse it defeats the purpose. It's a deduplication tool, not a golf tool.
- **Smell:** A variable assigned on the line directly above an `if`/`while` that only tests that variable; `while True:` with a break that re-reads the same call; a comprehension that calls the same expensive function twice (once in the filter, once in the output).
- **Signal:**
```python
# bad
count = fresh_fruit.get('apple', 0)
if count >= 4:
    make_juice(count)
# good
if (count := fresh_fruit.get('apple', 0)) >= 4:
    make_juice(count)
# also good: [y for x in data if (y := f(x)) is not None]
```
- **Exceptions:** Skip it on pre-3.8 targets, and don't reach for it when a plain statement is clearer or when the assigned name is needed in a broader scope — readability beats saving a line. Don't nest walruses to be cute.

### 6. Never Expect Python to Detect Errors at Compile Time  [3rd] · high
- **Rule:** Do not rely on Python's bytecode compilation to surface bugs; gate correctness on tests, type checkers, and linters, and treat any code path not covered by these as unverified.
- **Why:** Python's only true compile step is producing bytecode, and it checks syntax — not name existence, attribute access, argument counts, or types. A misspelled name, a call to a deleted method, or a type mismatch raises only when that exact line executes at runtime, so untested branches (error handlers, rare conditionals) routinely ship broken. People assume "it imported, so it compiled, so the names resolve" — they don't; resolution is deferred to execution.
- **Smell:** A reviewer approving an except block, a fallback branch, or a logging call that was never exercised, assuming import success implies the symbols inside resolve. Also: no static type checker (mypy/pyright) in CI, plus tests that skip error/edge paths, leaving NameError/AttributeError to detonate in production.
- **Signal:**
```python
# bad: error path never runs in tests, NameError hides until prod
def handle(x):
    try:
        return parse(x)
    except ValueError:
        return logg.error("bad")  # typo 'logg' — compiles fine, blows up only here

# good: static analysis + branch coverage catch it pre-merge
# $ mypy app.py        -> error: Name "logg" is not defined
# $ pytest --cov --cov-fail-under=100  (exercise the except branch)
```
- **Exceptions:** None — this is a property of the language, not a stylistic preference. The directive is always to add the external safety nets (type checker, lint, branch coverage) rather than trust the interpreter's parse step.

### 7. Always Surround Single-Element Tuples with Parentheses  [3rd] · high
- **Rule:** Write one-element tuples as `(x,)` with explicit parentheses and the trailing comma; never let a lone trailing comma be the only signal of tuple-ness.
- **Why:** It is the comma — not the parentheses — that constructs a tuple, so `x,` and `(x,)` are equally valid tuples while `(x)` is just `x`. The danger is the inverse: a stray trailing comma silently turns a scalar into a 1-tuple. Lines like `value = foo(),` or `x = 1,` look like ordinary assignments but bind a tuple, and the bug surfaces far away as a type mismatch. Wrapping singletons in parentheses makes the intent visible and makes an accidental comma stand out.
- **Smell:** A trailing comma at the end of an assignment, return, or function argument that yields a tuple no one intended (`return result,`), or a deliberate singleton written bare (`pair = item,`) where a later edit could drop or duplicate the comma unnoticed.
- **Signal:**
```python
# bad: trailing comma silently makes a 1-tuple; reads like a scalar
total = compute(),      # total is (result,) not result
first = 1,              # first is (1,) not 1

# good: explicit parens for intentional singletons; no stray comma otherwise
total = compute()
pair = (item,)          # unmistakably a one-element tuple
```
- **Exceptions:** Multi-element tuples don't need parentheses for correctness (`x, y = 1, 2` is fine), and intentional trailing commas in multi-line literals/arg lists aid diffs. The rule targets the singleton case specifically, where the parens are about disambiguation, not grouping.

### 8. Consider Conditional Expressions for Simple Inline Logic  [3rd] · medium
- **Rule:** Use a conditional expression (`a if cond else b`) only for short, side-effect-free value selection that fits on one readable line; expand to a full if/else statement once branches do real work.
- **Why:** The ternary is a single expression that produces one of two values, so it shines where you'd otherwise write a throwaway variable plus a four-line if/else just to pick a value. But it reads condition-first-then-true-branch, which is unnatural, and it has no place for statements — so people abuse it by nesting ternaries, cramming in calls with side effects, or stretching it across wrapped lines, all of which are harder to scan than the plain statement form. The win is conciseness for trivial selection, not compression of logic.
- **Smell:** Nested or chained ternaries (`x if a else y if b else z`), a conditional expression wrapped across multiple lines, ternaries whose branches call functions for their side effects, or assigning the same target in both arms of an if/else where a one-line ternary would be clearer.
- **Signal:**
```python
# bad: verbose statement for trivial selection
if count > 0:
    label = "items"
else:
    label = "empty"
# bad: nested ternary, unreadable
t = "hi" if a else ("mid" if b else "lo")

# good: ternary for the simple pick; if/else for the branchy case
label = "items" if count > 0 else "empty"
```
- **Exceptions:** Prefer the full if/else when there are more than two outcomes, when either branch has side effects or statements, when the line would wrap, or when the condition is complex — readability beats brevity. Also: don't use a ternary purely to dodge a temporary variable if the statement form is plainly clearer.

### 9. Consider match for Destructuring in Flow Control; Avoid When if Statements Are Sufficient  [3rd] · medium
- **Rule:** Reach for `match` when you are simultaneously branching on the shape/structure of data and binding its parts; keep plain `if`/`elif` when you are only comparing values or testing simple conditions.
- **Why:** `match` (Python 3.10+) earns its keep through structural pattern matching: it can decompose sequences, mappings, and class instances and bind their components in one construct (`case Point(x, y):`, `case [first, *rest]:`), with capture, guards, and a `_` wildcard. Its footguns trip up newcomers: a bare lowercase name in a pattern is a capture binding, not a constant comparison, so `case OK:` rebinds `OK` rather than testing equality — you need a dotted name or guard for value matching. Using `match` for a flat ladder of equality checks adds ceremony and obscures intent where `if x == ...` is plainer; conversely, simulating destructuring with chained `isinstance` + index/attribute access is exactly what `match` replaces.
- **Smell:** A `match` whose every `case` is a literal/value equality check that a tidy `if`/`elif` chain would express more directly; OR the opposite — manual structural dispatch via stacked `isinstance(...)` checks followed by index/attribute extraction, reimplementing what one `match` would do. Also: a bare-name `case foo:` intended as a constant comparison that silently captures instead.
- **Signal:**
```python
# bad: match used for flat value checks (if/elif is clearer)
match status:
    case 200: return "ok"
    case 404: return "missing"
# bad: manual destructuring
if isinstance(p, tuple) and len(p) == 2:
    x, y = p[0], p[1]

# good: match for structure + binding
match point:
    case (x, y): handle(x, y)
    case [head, *tail]: handle_list(head, tail)
```
- **Exceptions:** Stick with `if`/`elif` for one or two simple conditions, boolean tests, or value comparisons — `match` there is over-engineering. `match` requires Python 3.10+, so it's unavailable on older runtimes. For constant comparisons inside a `match`, use dotted names (`case Color.RED:`) or guards (`case n if n == LIMIT:`) to avoid the bare-name capture trap.

## Strings and Slicing


### 10. Know the Differences Between bytes and str  [2nd,3rd] · high
- **Rule:** Never mix bytes and str in the same operation; decode/encode explicitly at I/O boundaries and pick one representation internally.
- **Why:** bytes holds raw 8-bit values, str holds Unicode code points; they never compare equal, cannot be concatenated, and won't interoperate even when the bytes 'look like' ASCII. Operations that silently fail or raise (==, +, %, sorting, in) are easy to write because both look string-like, and file mode ('r' vs 'rb') plus the platform default encoding decide which type you actually get.
- **Smell:** Calling .encode() on something already bytes (or .decode() on str), comparing b'foo' == 'foo' and expecting True, opening a binary file in text mode (or vice versa), or relying on the system default encoding instead of passing encoding= explicitly.
- **Signal:**
```python
# bad: type mix raises / compares False
data = b'hello'
if data == 'hello':  # always False
    ...
with open('img.png') as f:  # text mode mangles bytes
    raw = f.read()
# good: convert at the boundary, be explicit
text = data.decode('utf-8')
with open('img.png', 'rb') as f:
    raw = f.read()
```
- **Exceptions:** Genuinely binary data (images, compressed blobs, protocol frames) should stay bytes end-to-end — don't decode it to str just for uniformity. When reading/writing text always pass encoding= explicitly rather than trusting the locale default.

### 11. Prefer Interpolated F-Strings Over C-style Format Strings and str.format  [2nd,3rd] · medium
- **Rule:** Use f-strings for string interpolation instead of % formatting or str.format().
- **Why:** C-style % formatting is positional and brittle: argument-order/count mismatches raise at runtime, repeated values must be passed repeatedly, and a lone tuple or dict argument changes behavior. str.format() is verbose and forces you to restate or index every value. f-strings put the expression inline at the point of use, so the reader sees what's substituted without cross-referencing a separate argument list.
- **Smell:** '%s=%d' % (key, value) chains, 'value is %d' % x breaking when x is a tuple, or '{0} {1}'.format(a, b) / '{name}'.format(name=name) restating names that are already in scope.
- **Signal:**
```python
key, value = 'count', 42
# bad
print('%s = %d' % (key, value))
print('{} = {}'.format(key, value))
# good
print(f'{key} = {value}')
print(f'{value:.2f}')  # format specs still work inline
```
- **Exceptions:** Templates supplied at runtime (e.g. from config, i18n catalogs, or user input) can't be f-strings — use str.format() or string.Template with a mapping. Logging calls should pass %-style args lazily (logger.info('x=%s', x)) so formatting is skipped when the level is disabled.

### 12. Know How to Slice Sequences  [2nd,3rd] · medium
- **Rule:** Use clean slice syntax and let Python's defaults handle the endpoints instead of writing redundant or out-of-range indices.
- **Why:** Slicing tolerates start/stop indices past the sequence length without raising (unlike a single-element index), which is convenient but quietly hides off-by-one and bounds bugs; slicing also always returns a new list (shallow copy), so mutating the result never touches the original, and assigning into a slice splices in place and can change the list's length.
- **Smell:** Writing redundant zero or len() endpoints like a[0:5] or a[2:len(a)]; assuming a slice aliases the original list; using a slice index to bounds-check when the convenience masks the real out-of-range condition.
- **Signal:**
```python
# bad: redundant and noisy endpoints
first = a[0:5]
tail = a[3:len(a)]
# good: omit the defaults
first = a[:5]
tail = a[3:]
# note: slice is a copy; in-place splice can resize
b = a[:]            # shallow copy, b is not a
a[2:4] = [99]       # length of a now changes
```
- **Exceptions:** When you genuinely need the explicit numbers for clarity in arithmetic-heavy index math, spelling out a non-default start/stop is fine. Negative indices in slices are idiomatic and encouraged.

### 13. Avoid Striding and Slicing in a Single Expression  [2nd,3rd] · medium
- **Rule:** Never combine start, stop, and a (especially negative) stride in one slice; split striding and slicing into two statements.
- **Why:** The three-part slice with a stride is genuinely hard to read and the interaction of a negative stride with start/stop offsets is unintuitive (e.g. the endpoints flip meaning), which is exactly where silent off-by-one and reversed-range bugs come from; doing the stride first then slicing keeps each step's intent obvious and avoids materializing surprising results.
- **Smell:** A slice carrying all three components such as x[2:-1:2] or, worse, a negative stride mixed with bounds like x[-2:2:-2]; using [::-1] to reverse is fine, but bolting offsets onto a negative stride is the trap.
- **Signal:**
```python
# bad: stride + bounds + negative step, unreadable
odds_rev = x[8:1:-2]
# good: stride first, then slice in a second step
strided = x[::-2]
result = strided[1:4]
# reversing alone is still fine
rev = x[::-1]
```
- **Exceptions:** A bare stride with no offsets is acceptable: x[::2], x[::-1]. The rule targets the combination of stride with start/stop in one expression. For large byte/array data where the extra copy matters, prefer itertools.islice or a memoryview rather than chained slicing.

### 14. Prefer Catch-All Unpacking Over Slicing  [2nd,3rd] · high
- **Rule:** Use a starred target (a, *rest = seq) to split off head/tail/middle instead of indexing plus parallel slices.
- **Why:** Separate index-and-slice statements force you to keep boundary numbers in sync by hand, so changing one offset and forgetting the matching slice silently produces wrong results; starred unpacking expresses the same split in one line with no magic numbers. The catch (frequently gotten wrong): the starred target always collects into a new list in memory, so applying it to a large or infinite generator/iterator eagerly drains it and can blow up memory.
- **Smell:** first = row[0]; rest = row[1:] as two coupled lines; hardcoded mirrored offsets like seq[0], seq[1:-1], seq[-1]; using *rest on an unbounded generator.
- **Signal:**
```python
# bad: coupled index + slice, fragile offsets
first = row[0]
rest = row[1:]
# good: one catch-all unpack, no magic indices
first, *rest = row
first, *middle, last = row   # middle is a list
# footgun: *rest fully materializes the iterator
head, *everything = huge_generator()  # may exhaust memory
```
- **Exceptions:** Don't use it on iterators/generators you can't afford to fully realize; use itertools.islice for bounded consumption instead. You still cannot have two starred targets at the same level, and at least one non-starred name is required.

### 15. Understand the Difference Between repr and str when Printing Objects  [2nd,3rd] · medium
- **Rule:** Define __repr__ to return an unambiguous, ideally eval-able developer representation; only add __str__ when you need a distinct human-facing rendering.
- **Why:** print() and str()/format use __str__, but the interactive prompt, containers, %r, !r, and debuggers use __repr__; without __repr__ you get the useless default <Object at 0x...> exactly when debugging. str values can also hide their type (the str '5' and int 5 both print as 5), so use repr to disambiguate.
- **Smell:** A class with no __repr__ logging as <Foo object at 0x10a...>, debugging by printing dict/list of objects and seeing memory addresses, or a __str__ defined but __repr__ left to the default.
- **Signal:**
```python
# bad: only __str__, repr is the useless default
class Point:
    def __str__(self): return f"({self.x},{self.y})"
# good: repr is the canonical, reconstructable form
class Point:
    def __repr__(self): return f"Point(x={self.x!r}, y={self.y!r})"
# print(repr(p)) -> Point(x=1, y=2); use !r when ambiguity matters
```
- **Exceptions:** If the dev representation is already human-friendly, __repr__ alone suffices and __str__ is unnecessary. For dynamic/private attributes an eval-able repr may be impractical; a clear descriptive repr is still better than the default.

### 16. Prefer Explicit String Concatenation over Implicit, Especially in Lists  [3rd] · high
- **Rule:** Join adjacent string literals with explicit + (or join over multiple lines); never rely on Python silently concatenating side-by-side literals, above all inside list/tuple/call literals.
- **Why:** Two string literals separated only by whitespace are concatenated at compile time, so a single missing comma in a multiline list fuses two elements into one and silently shortens the collection with no error. The bug is invisible in review because the lines look like separate items.
- **Smell:** A multiline list/tuple/argument where one entry lacks a trailing comma and abuts the next quoted string, or deliberate wrapping of a long message across lines using bare adjacency instead of +.
- **Signal:**
```python
# bad: missing comma -> 2 items, not 3, no error raised
NAMES = [
    "alice"
    "bob",      # becomes "alicebob"
    "carol",
]
# good: explicit + makes intent loud and a missing comma a visible glob
MSG = ("line one " + "line two")
NAMES = ["alice", "bob", "carol"]
```
- **Exceptions:** Implicit adjacency is acceptable for a clearly intentional multiline literal where each fragment ends with explicit whitespace and a linter (pylint implicit-str-concat / flake8-no-implicit-concat) guards collections; the danger is specifically the missing-comma case in sequences.

## Dictionaries


### 17. Be Cautious When Relying on dict / Dictionary Insertion Ordering  [2nd,3rd] · high
- **Rule:** Don't assume an object behaves like an insertion-ordered dict just because it implements the mapping interface; if order matters, require a real dict or guard explicitly.
- **Why:** Standard dict guarantees insertion order since 3.7, but that guarantee covers the built-in type only — a function that accepts a 'dict-like' argument may receive a custom Mapping (or older/alternative implementation) that does NOT preserve order, so code iterating it 'in order' breaks silently. The footgun is duck typing: type checks and isinstance(x, dict) won't catch a subclass-of-Mapping that reorders, and equality ignores order so tests pass while iteration order is wrong.
- **Smell:** Functions that take an arbitrary mapping and then rely on iteration order (first key, last inserted, ordered output); assuming **kwargs-style ordering from a passed-in object; trusting order from a class that merely implements __getitem__/keys.
- **Signal:**
```python
# bad: trusts insertion order on any mapping passed in
def first_entry(scores):  # scores might be a custom Mapping
    return next(iter(scores))
# good: be explicit about the requirement
def first_entry(scores):
    if not isinstance(scores, dict):
        raise TypeError('requires a built-in dict')
    return next(iter(scores))
# or accept any mapping but don't depend on order at all
```
- **Exceptions:** When you fully control the value and it is always a built-in dict (or you target 3.7+ and pass literals/comprehensions), relying on order is fine and idiomatic. If you need order-sensitive equality or move_to_end/popitem(last=...), use collections.OrderedDict deliberately rather than a plain dict.

### 18. Prefer get Over in and KeyError to Handle Missing Dictionary Keys  [2nd,3rd] · medium
- **Rule:** Read possibly-absent dictionary keys with dict.get(key, default), not the in operator, a try/except KeyError, or a bare subscript followed by branching.
- **Why:** in and KeyError require two lookups (test then read) and several lines that obscure intent; get does it in one expression and one lookup. The subtle part: for the common 'fetch-or-insert-then-mutate' pattern (counters, accumulating into a list), get alone still reads awkwardly because you must reassign — that is where the walrus operator with get, or setdefault, becomes the clean form, and where the next item (defaultdict) takes over.
- **Smell:** if key in d: x = d[key] else: x = default; or a try: d[key] except KeyError: block just to supply a fallback; or `if key not in counts: counts[key] = 0` followed by `counts[key] += 1`.
- **Signal:**
```python
# bad
if name in votes:
    names = votes[name]
else:
    votes[name] = names = []
# good
if (names := votes.get(name)) is None:
    votes[name] = names = []
names.append(who)
```
- **Exceptions:** When a missing key is genuinely exceptional (a real programming error), let KeyError raise rather than masking it with a default. get with a default is also wrong when None/the default is itself a valid stored value, since you can't distinguish 'absent' from 'present-but-default' — use a sentinel or `in` then.

### 19. Prefer defaultdict Over setdefault to Handle Missing Items in Internal State  [2nd,3rd] · medium
- **Rule:** When you control a dictionary as internal state and repeatedly insert-then-mutate per key, use collections.defaultdict(factory) instead of calling setdefault at every access site.
- **Why:** setdefault is misleadingly named (it gets, with a side effect of setting) and constructs the default value on every call even when the key already exists — wasteful for non-trivial factories like list or set. defaultdict builds the default lazily only on a true miss and centralizes the default in one place. The key constraint: this only applies when you own the dict's construction; if a dictionary is passed in from elsewhere, you can't assume it's a defaultdict.
- **Smell:** d.setdefault(key, []).append(value) scattered across many call sites; or setdefault(key, ExpensiveObject()) where the default is allocated every call regardless of hit/miss.
- **Signal:**
```python
# bad
def add(self, key, v):
    self.data.setdefault(key, []).append(v)  # new [] built every call
# good
self.data = defaultdict(list)
def add(self, key, v):
    self.data[key].append(v)
```
- **Exceptions:** Don't use defaultdict when the factory needs the key itself (use __missing__). Avoid it for dicts handed to callers/serializers, since merely reading a missing key mutates the dict and the type surprises consumers. For a one-off default on a dict you don't own, plain get/setdefault is fine.

### 20. Know How to Construct Key-Dependent Default Values with __missing__  [2nd,3rd] · medium
- **Rule:** When the default for a missing key must be computed from the key itself, subclass dict and implement __missing__(self, key) rather than forcing setdefault or a parameterless defaultdict factory.
- **Why:** defaultdict's factory takes no arguments, so it cannot see the key — it can't open a file named after the key or build a key-derived object. setdefault would construct that key-dependent value on every access (and eagerly, even on hits), which is wasteful and, for side-effecting defaults like opening a file handle, outright buggy. __missing__ is invoked only on a genuine miss and receives the key, and the value it returns is stored so subsequent lookups hit normally.
- **Smell:** pictures.setdefault(path, open(path, 'a+b')) — opens (and leaks) a file handle on every call even when the key exists; or a defaultdict whose factory closes over a mutating variable to fake key awareness.
- **Signal:**
```python
# bad: opens a handle every call, even on hit
h = pictures.setdefault(path, open(path, 'a+b'))
# good
class Pictures(dict):
    def __missing__(self, path):
        self[path] = h = open(path, 'a+b')
        return h
```
- **Exceptions:** Unnecessary when the default is independent of the key — plain defaultdict or get is simpler. Note __missing__ fires only on d[key] subscript misses; it does not affect get() or `in`, so don't expect those to trigger it.

### 21. Compose Classes Instead of Deeply Nesting Dictionaries, Lists, and Tuples  [3rd] · medium
- **Rule:** Refactor internal state into small classes (namedtuple/dataclass and helper classes) once bookkeeping grows past a single layer of dicts/lists or a two-element tuple.
- **Why:** Nested containers and long tuples are positionally addressed and untyped, so call sites become brittle: adding one more field shifts every index, and `state[a][b][c]` carries no schema or validation. The threshold people miss is low — when a value is a dict-of-dicts, a list of 3+ tuples, or a tuple you keep extending, stop and introduce a class. namedtuple is the lightweight first step (immutable, positional+keyword), but it can't express default values cleanly and any subclass relationship still leaks tuple semantics; promote to dataclass when fields exceed a handful or need defaults/mutation.
- **Smell:** self.grades[name][subject].append((score, weight)); access via row[2][0]; or a 'simple' dict that has quietly grown to three nesting levels and value-tuples of length 3+.
- **Signal:**
```python
# bad
self.grades[name].setdefault(subject, []).append((score, weight))
# good
Grade = namedtuple('Grade', ('score', 'weight'))
class Subject:
    def __init__(self): self.grades = []
    def report(self, score, weight): self.grades.append(Grade(score, weight))
```
- **Exceptions:** Shallow, short-lived, or pure-serialization data (a parsed JSON blob passed straight through, a two-tuple return) doesn't need a class. Don't over-engineer trivial 1-level mappings; the rule triggers on nesting depth and tuple length, not on using dicts at all.

### 22. Be Cautious When Relying on dict Insertion Ordering  [2nd,3rd] · medium
- **Rule:** Only rely on insertion-order iteration of built-in dicts; never assume a dict-like parameter or third-party mapping preserves order, and use OrderedDict when order is semantically load-bearing or you need order-sensitive equality / move_to_end / reverse-popitem.
- **Why:** Since 3.7 plain dicts preserve insertion order as a language guarantee, which lulls people into treating any object that looks like a dict the same way. A function annotated or duck-typed as a mapping can receive a custom container (or a structurally-similar object built via __getitem__/keys) that iterates in a different order, so code that depends on ordering silently produces wrong results without raising. Also, dict equality ignores order while OrderedDict equality is order-sensitive — they are not interchangeable when comparison matters.
- **Smell:** Code iterates a function argument typed as a generic Mapping/dict and uses the first key or iteration order as if it were insertion order; or it compares two dicts expecting order to matter; or it builds ranking/priority logic on the assumption that an arbitrary passed-in mapping iterates the way it was constructed.
- **Signal:**
```python
# Bad: assumes any mapping arg iterates in insertion order
def first_ranked(votes):
    return next(iter(votes))          # custom Mapping may reorder

# Good: defend the contract or demand an ordered type
def first_ranked(votes: dict[str, int]) -> str:
    assert isinstance(votes, dict)    # or accept OrderedDict explicitly
    return next(iter(votes))
```
- **Exceptions:** Iterating a dict you constructed yourself in the same scope is safe and idiomatic — the guarantee holds for built-in dict. The caution applies to externally supplied or duck-typed mappings.

## Loops and Iterators


### 23. Prefer enumerate Over range  [2nd,3rd] · medium
- **Rule:** When you need both the index and the element, iterate with enumerate(seq) instead of range(len(seq)) plus subscripting.
- **Why:** range(len(...)) + seq[i] adds an indexing step that can go out of sync, only works on indexable sequences (not general iterators/generators), and reads as boilerplate. enumerate yields (index, item) pairs directly, accepts a start argument for non-zero numbering, and works on any iterable lazily.
- **Smell:** for i in range(len(items)): item = items[i], or a hand-maintained counter (i = 0 ... i += 1) walking alongside a for loop.
- **Signal:**
```python
items = ['a', 'b', 'c']
# bad
for i in range(len(items)):
    print(i, items[i])
# good
for i, item in enumerate(items):
    print(i, item)
for n, item in enumerate(items, 1):  # start at 1
    print(n, item)
```
- **Exceptions:** range is correct when there's no sequence to index into — pure numeric ranges, fixed repeat counts (for _ in range(n)), or striding/stepping (range(0, n, 2)). If you need only the element and never the index, plain for item in seq is better than either.

### 24. Use zip to Process Iterators in Parallel  [2nd,3rd] · high
- **Rule:** Iterate multiple related sequences together with zip rather than indexing each by a shared loop counter.
- **Why:** zip lazily yields tuples drawn one element from each iterable, which is clearer and avoids index drift. The footgun: zip stops silently at the shortest input, so unequal lengths truncate with no error and can drop data you assumed was processed.
- **Smell:** for i in range(len(names)): use names[i] and counts[i]; or assuming zip(a, b) covers all of the longer input when lengths can differ.
- **Signal:**
```python
names = ['ana', 'bo', 'cy']
lens = [3, 2]
# bad: silently drops 'cy' because lens is shorter
for name, n in zip(names, lens):
    ...
# good when lengths may differ: pad explicitly
from itertools import zip_longest
for name, n in zip_longest(names, lens, fillvalue=0):
    ...
```
- **Exceptions:** Plain zip is fine and intended when inputs are known to be equal length, or when truncating to the shortest is the desired behavior. Use itertools.zip_longest when you must consume the longest input; in 3.10+ pass strict=True to zip to raise on length mismatch instead of truncating silently.

### 25. Avoid else Blocks After for and while Loops  [2nd,3rd] · low
- **Rule:** Do not attach an else block to for or while loops; refactor the post-loop logic into a helper or a flag/sentinel instead.
- **Why:** Loop-else runs only when the loop completes without hitting break — the opposite of the conditional intuition the else keyword evokes. This counterintuitive semantics (else means 'no break happened', and runs even on an empty/zero-iteration loop) makes the code easy to misread and is rarely worth the cognitive cost.
- **Smell:** A for/while immediately followed by an else: clause, especially in search loops where else handles the 'not found' case — the reader has to recall that else fires when break did not.
- **Signal:**
```python
# bad: else runs only if no break — confusing
for x in items:
    if matches(x):
        found = x
        break
else:
    found = None
# good: a helper with explicit returns
def find(items):
    for x in items:
        if matches(x):
            return x
    return None
```
- **Exceptions:** The construct is legal and occasionally used for search/scan loops, but the book's guidance is to avoid it for readability. If a team genuinely standardizes on it, a clarifying comment is the minimum bar.

### 26. Never Use for Loop Variables After the Loop Ends  [3rd] · high
- **Rule:** Treat a for loop's target variable as undefined once the loop finishes; never read it after the loop body.
- **Why:** Python does not scope the loop variable to the loop — it leaks the LAST assigned value into the enclosing scope, so reading it afterward looks like it holds 'the final element' but breaks subtly: if the iterable was empty the name was never bound (NameError), and if you broke early it holds wherever break fired, not the end. Relying on this couples correctness to non-obvious iteration details.
- **Smell:** Referencing the loop variable (or a comprehension-era assumption about it) below the loop — e.g. computing something inside the loop and then using the loop var after it to represent 'the last one processed'.
- **Signal:**
```python
# bad
for row in rows:
    process(row)
print(row)  # NameError if rows empty; last value otherwise
# good
last = None
for row in rows:
    process(row)
    last = row
print(last)
```
- **Exceptions:** Genuinely none for reading the bare loop variable post-loop. Capture what you need into an explicitly named variable inside the loop (defaulted before it) so intent and the empty-iterable case are handled.

### 27. Be Defensive when Iterating over Arguments  [2nd,3rd] · high
- **Rule:** If a function iterates its input more than once, do not accept a bare iterator — copy it to a list, accept a fresh-iterator factory, or reject single-use iterators explicitly.
- **Why:** An iterator is exhausted after one pass and silently yields nothing on the second — no exception, because the loop machinery cannot distinguish 'empty' from 'already consumed.' Passing a generator to a function that loops twice (e.g. sum then normalize) produces wrong results, often zeros or empties, with no error. iter(x) returning x itself means x is a one-shot iterator; iter(x) returning a new object means x is a re-iterable container.
- **Smell:** A function that loops over the same parameter in two places (or calls sum()/min() then loops) while callers pass generators; or no guard distinguishing iterator from container.
- **Signal:**
```python
# bad: second pass sees nothing if numbers is a generator
def normalize(numbers):
    total = sum(numbers)
    return [100 * n / total for n in numbers]
# good: reject single-use iterators
def normalize(numbers):
    if iter(numbers) is numbers:
        raise TypeError('must be a container, not an iterator')
    total = sum(numbers)
    return [100 * n / total for n in numbers]
```
- **Exceptions:** If the function consumes the input exactly once, accepting a plain iterator is correct and even preferable for streaming large/infinite data. To support large reusable inputs without buffering, accept a callable that returns a fresh iterator (e.g. a lambda or a class implementing __iter__) rather than forcing a list copy.

### 28. Never Modify Containers While Iterating over Them; Use Copies or Caches Instead  [3rd] · high
- **Rule:** Don't add to or remove from a container inside a loop that iterates over that same container; iterate over a copy or stage the mutations in a separate structure and apply them after the loop.
- **Why:** The failure mode differs by container and is easy to misread: dicts and sets raise RuntimeError when their size changes mid-iteration, but lists silently skip or revisit elements because the loop tracks an integer index that no longer lines up after an insert/delete. The list case is the dangerous one — no exception, just wrong results that pass tests on small inputs.
- **Smell:** A for loop over a dict/set/list whose body calls del, .pop(), .append(), .add(), .remove(), or assigns a new key, on the very object being iterated. Also: deleting list elements by index inside enumerate(...).
- **Signal:**
```python
# Bad: deletes from the dict being iterated -> RuntimeError
for name, age in people.items():
    if age < 18:
        del people[name]

# Good: iterate over a snapshot copy
for name, age in list(people.items()):
    if age < 18:
        del people[name]
# Or build the survivors fresh: people = {n: a for n, a in people.items() if a >= 18}
```
- **Exceptions:** Reassigning the value of an existing dict key (without adding/removing keys) is fine since size is unchanged. For large containers where copying is too expensive, collect the keys to mutate in a separate list during the loop and apply the changes afterward instead of snapshotting the whole container.

### 29. Pass Iterators to any and all for Efficient Short-Circuiting Logic  [3rd] · medium
- **Rule:** Feed any()/all() a generator expression (or lazy iterator), not a fully materialized list comprehension, so the short-circuit actually saves work.
- **Why:** any() stops at the first truthy element and all() stops at the first falsy one, but only the iterable's remaining elements are skipped — if you pass a list comprehension, the entire list (and every side effect / expensive call inside it) is computed before any/all even runs, defeating the short-circuit. The fix is dropping the brackets to make it a generator, which is also lower memory. Build a named helper generator when the predicate is non-trivial rather than cramming it into one line.
- **Smell:** any([expensive(x) for x in items]) or all([check(x) for x in big_iter]) — square brackets inside the any/all call, especially when the inner expression does I/O, network calls, or heavy computation.
- **Signal:**
```python
# Bad: builds the whole list, runs validate() on every row up front
if any([validate(row) for row in rows]):
    handle()

# Good: generator — validate() stops at the first match
if any(validate(row) for row in rows):
    handle()
```
- **Exceptions:** If you also need the materialized results afterward (e.g. to count, reuse, or log them), building the list once and reusing it is reasonable. For tiny, cheap iterables the difference is negligible and clarity wins. Note an iterator is single-use, so don't feed the same one to all() then any().

### 30. Consider itertools for Working with Iterators and Generators  [2nd,3rd] · medium
- **Rule:** Reach for the named itertools building blocks (chain, islice, takewhile/dropwhile, groupby, zip_longest, accumulate, product/permutations/combinations, tee, etc.) before hand-rolling index math or nested loops to link, slice, filter, or combine iterables.
- **Why:** These functions are lazy, C-implemented, and battle-tested, so they're faster and clearer than manual equivalents — but each has a sharp edge people miss: zip() truncates to the shortest input (use zip_longest to keep the rest), groupby only groups *consecutive* equal keys (sort first), and tee buffers consumed items in memory so it's a trap for unbounded streams or when one branch races far ahead.
- **Smell:** Manual range(len(...)) index juggling to merge or window sequences; building a full intermediate list just to slice it ([:n] on a generator's list()); nested loops generating cartesian products or pairwise combinations by hand; calling groupby on unsorted data and expecting global grouping.
- **Signal:**
```python
# Bad: manual flatten + slice via full materialization
merged = []
for seq in (a, b, c):
    merged.extend(seq)
first5 = merged[:5]

# Good: lazy, no full intermediate list
from itertools import chain, islice
first5 = list(islice(chain(a, b, c), 5))
```
- **Exceptions:** A plain for loop or comprehension is clearer for simple one-off cases — don't pull in itertools just to look clever. Watch memory with tee() and avoid combinatoric functions (product/permutations) on large inputs since their output grows factorially/exponentially.

## Functions


### 31. Know That Function Arguments Can Be Mutated  [3rd] · high
- **Rule:** When a function receives a mutable argument it does not intend to modify, either avoid in-place mutation or defensively copy it first; if it does mutate, make that explicit in the name/signature/docstring.
- **Why:** Python passes object references, not values. A callee holds the same list/dict/set the caller does, so any in-place method (append, sort, .update, item assignment) silently rewrites the caller's data. Reassigning the parameter name (x = ...) does NOT affect the caller, but calling a mutating method on it does — people conflate the two.
- **Smell:** A helper named like a pure transform (normalize, compute, filter) that calls arg.sort()/arg.append()/del arg[k] on a passed-in collection, or stores the incoming reference on self and later mutates it, so the caller's object changes as a side effect they never asked for.
- **Signal:**
```python
# bad: caller's list gets reordered
def top_n(items, n):
    items.sort(reverse=True)   # mutates caller's list
    return items[:n]
# good: don't touch the input
def top_n(items, n):
    return sorted(items, reverse=True)[:n]
```
- **Exceptions:** In-place mutation is fine when it is the documented contract (list.sort itself, an accumulator deliberately passed in, methods named *_inplace, or hot paths where copying is prohibitively expensive and the mutation is clearly named). Copy cost matters: deep-copying huge structures defensively can be the wrong tradeoff — then document the mutation instead.

### 32. Return Dedicated Result Objects Instead of Requiring Function Callers to Unpack More Than Three Variables (3rd) / Never Unpack More Than Three Variables When Functions Return Multiple Values (2nd)  [2nd,3rd] · medium
- **Rule:** If a function returns more than three values, return a small named result object (dataclass / NamedTuple) instead of a bare tuple callers must positionally unpack.
- **Why:** Positional unpacking has no names at the call site, so reordering same-typed values (swapping average and median, both floats) is invisible to the reader and the type checker — it runs fine and produces wrong answers. Long unpack lines also wrap and obscure which value is which. Three is the practical ceiling before this gets dangerous.
- **Smell:** return (min_v, max_v, avg, median, count) consumed as `a, b, c, d, e = stats(...)`, especially when several returned values share a type and ordering is the only thing distinguishing them.
- **Signal:**
```python
# bad: 4-way unpack, easy to misorder
def stats(xs): return min(xs), max(xs), mean(xs), median(xs)
lo, hi, avg, med = stats(xs)
# good: named fields, checker-verifiable
@dataclass
class Stats: lo: float; hi: float; avg: float; med: float
def stats(xs) -> Stats: return Stats(min(xs), max(xs), mean(xs), median(xs))
```
- **Exceptions:** Two or three values of distinct, obvious meaning (e.g. (quotient, remainder), (x, y) coordinates, dict.items() pairs) are fine to return and unpack as a plain tuple. The threshold is about count plus same-type ambiguity, not a ban on multiple returns.

### 33. Prefer Raising Exceptions to Returning None  [2nd,3rd] · high
- **Rule:** Signal errors or 'no result' by raising a specific exception, not by returning None as a sentinel that callers test for truthiness.
- **Why:** None is falsy, and so are 0, 0.0, '', [], and {}. A caller writing `if not result:` to detect the error path will also misfire on a perfectly valid zero/empty result, swallowing real answers as failures. Raising forces the caller to handle the error path explicitly and removes the ambiguity; document the raised exception and annotate the return as non-Optional.
- **Smell:** `return None` on the error branch combined with call sites that do `if not func(...):` or `if func(...):`. Translating a low-level error into a None instead of re-raising a meaningful domain exception (e.g. catching ZeroDivisionError and returning None).
- **Signal:**
```python
# bad: 0 result is misread as failure
def divide(a, b):
    try: return a / b
    except ZeroDivisionError: return None
if not divide(0, 5):  # True for valid 0.0!
    print('error')
# good
def divide(a, b) -> float:
    try: return a / b
    except ZeroDivisionError: raise ValueError('invalid inputs')
```
- **Exceptions:** None is legitimate when absence is an ordinary, expected outcome rather than an error (dict.get, re.match, 'lookup miss'), provided callers test `is None` explicitly, not truthiness. Returning Optional with a clear annotation is fine there; the rule targets error signaling and truthiness-tested sentinels.

### 34. Know How Closures Interact with Variable Scope and nonlocal (3rd) / Know How Closures Interact with Variable Scope (2nd)  [2nd,3rd] · high
- **Rule:** A nested function can read enclosing-scope variables but assigning a name inside it creates a new local; use nonlocal only for trivial closures, otherwise hold the state in a class.
- **Why:** Variable resolution reads outward through scopes, but assignment always binds in the current (function) scope unless declared global/nonlocal. So `count += 1` inside a closure raises UnboundLocalError or silently shadows rather than updating the outer variable — people expect read-write but only get read. nonlocal fixes it but its action-at-a-distance is hard to follow when the declaration and the mutated assignments are far apart, and it cannot reach module scope.
- **Smell:** A closure that assigns to an outer name expecting to mutate it (a `found` flag or running counter set inside a sort key or callback) without a nonlocal declaration; or sprawling nonlocal usage threaded through a long function to simulate object state.
- **Signal:**
```python
# bad: assignment shadows; outer 'found' never changes
def sort_priority(values, group):
    found = False
    def helper(x):
        if x in group: found = True  # new local!
        return (0, x)
    values.sort(key=helper); return found
# good: declare intent
    def helper(x):
        nonlocal found
        if x in group: found = True
        return (0, x)
```
- **Exceptions:** nonlocal is acceptable and idiomatic for small, self-contained closures (a counter in a short factory). Once state grows or the function is long, prefer a small stateful class with __call__ or explicit methods over multiple nonlocal vars. Reading enclosing variables needs no declaration at all.

### 35. Reduce Visual Noise with Variable Positional Arguments  [2nd,3rd] · medium
- **Rule:** Use *args to make optional positional arguments cleaner, but don't unpack large/unbounded iterables into it, and never add a new positional parameter in front of an existing *args.
- **Why:** Two footguns. First, calling f(*gen) eagerly materializes the whole generator into a tuple in memory before the call — fine for a handful of known args, a memory blowup for large or infinite iterables. Second, *args swallows extra positionals, so inserting a new leading parameter silently realigns every existing call site to the wrong arguments with no exception — the program just runs with shifted, wrong values. Extend *args functions with keyword-only arguments instead.
- **Smell:** `func(*some_large_or_lazy_generator)`; or changing `def log(message, *values)` to `def log(sequence, message, *values)` and relying on old callers to still work — they now pass message as sequence.
- **Signal:**  ⚠ verifier-flagged
```python
# bad: new leading positional silently shifts old calls
def log(message, *values): ...
def log(seq, message, *values): ...  # log('hi', a) now seq='hi'
# good: extend with keyword-only arg
def log(message, *values, *, seq=None): ...
# also avoid: log(*huge_generator)  # full tuple built in memory
```
- **Exceptions:** *args is the right tool when the argument count is genuinely variable and small/bounded and all values are the same kind (print, logging-style APIs). The generator-materialization caveat only matters for large/unbounded iterables; a known short sequence is fine to splat.

### 36. Provide Optional Behavior with Keyword Arguments  [2nd,3rd] · medium
- **Rule:** Pass optional/configuration arguments by keyword, and design functions so callers can name them rather than relying on positional order.
- **Why:** Keyword arguments make call sites self-documenting and let you add new optional parameters with safe defaults without breaking existing callers; positional-only passing of optionals creates a brittle ordering contract where a later insertion silently shifts meaning. The nuance people miss: backward compatibility comes from giving new params defaults AND letting callers name them, not just from adding them at the end.
- **Smell:** calc(120, 1, 60) where 1 and 60 are flags/divisors with no visible meaning at the call site; or appending a 4th positional parameter and forcing all callers to re-count argument positions.
- **Signal:**
```python
# bad: opaque positional flags
result = flow_rate(weight_diff, time_diff, 3600, 2.2)
# good: named optional args with defaults
def flow_rate(weight_diff, time_diff, *, period=1, units_per_kg=1):
    return ((weight_diff / units_per_kg) / time_diff) * period
result = flow_rate(weight_diff, time_diff, period=3600, units_per_kg=2.2)
```
- **Exceptions:** The first one or two genuinely required, well-understood positional args (e.g. self, the primary operand) read fine positionally; forcing keywords there is noise.

### 37. Use None and Docstrings to Specify Dynamic Default Arguments  [2nd,3rd] · high
- **Rule:** Never use a mutable or dynamically-computed value as a default argument; default to None and construct the real value inside the body, documenting it in the docstring.
- **Why:** A default expression is evaluated exactly once, when the def executes at import time, not per call. So {}/[]/datetime.now()/uuid4() as a default is frozen forever: mutable defaults are shared and accumulate state across calls, and time/random defaults capture the import moment. The fix is None as a sentinel plus per-call construction; the docstring carries the human-readable default since the signature now just says None.
- **Smell:** def log(msg, ts=datetime.now()): ... (every call shows the same import-time timestamp) or def append(x, items=[]): items.append(x) (list grows across unrelated calls).
- **Signal:**
```python
# bad: evaluated once at def time; shared/frozen
def append(value, items=[]):
    items.append(value); return items
# good: None sentinel, fresh object per call
def append(value, items=None):
    """items defaults to a new empty list."""
    if items is None:
        items = []
    items.append(value); return items
```
- **Exceptions:** Immutable, constant defaults (numbers, strings, tuples, True/False/None) are fine inline because there is nothing to mutate and no time/identity dependency. If None is itself a valid caller-supplied value, use a private sentinel object instead.

### 38. Enforce Clarity with Keyword-Only and Positional-Only Arguments  [2nd,3rd] · medium
- **Rule:** Put confusable or behavior-altering parameters after * to force keyword-only calls, and put implementation-detail params before / to make them positional-only.
- **Why:** Two issues people conflate: (1) * prevents callers from passing easily-swapped booleans/flags positionally, so meaning can't be lost or reversed silently; (2) / lets you rename a parameter later without breaking callers, because nobody can depend on its name as a keyword. The deeper point is that the call/keyword boundary is part of your API contract, not just style: anything namable becomes frozen, anything positional-only stays free to rename.
- **Smell:** def divide(a, b, ignore_overflow, ignore_zero_div): then divide(1, 0, False, True) where the trailing booleans are indistinguishable at the call site; or a public function whose internal-detail param name leaks as a supported keyword.
- **Signal:**
```python
# bad: flags passable positionally and reversible by accident
def safe_div(a, b, ignore_overflow=False, ignore_zero=False): ...
safe_div(1, 0, False, True)
# good: numerator/denominator positional-only, flags keyword-only
def safe_div(numerator, denominator, /, *, ignore_overflow=False, ignore_zero=False): ...
safe_div(1, 0, ignore_zero=True)
```
- **Exceptions:** Positional-only (/) requires Python 3.8+. Don't over-restrict tiny helpers or hot-path internal functions where the ceremony outweighs the clarity gain; a single obvious operand rarely needs forcing.

### 39. Define Function Decorators with functools.wraps  [2nd,3rd] · medium
- **Rule:** Always apply @functools.wraps(func) to the inner wrapper in any decorator so the wrapped function keeps its identity and metadata.
- **Why:** A naive decorator returns a new function object whose __name__, __qualname__, __doc__, __module__, __wrapped__, annotations and __dict__ all belong to the wrapper, not the original. This silently breaks help(), introspection, debuggers, pickling of the function by reference, and anything that reads the docstring or signature. wraps copies that metadata over and sets __wrapped__ so the original is still reachable. People forget it because the decorated code still runs correctly — the breakage is invisible until something introspects it.
- **Smell:** def trace(func):\n    def wrapper(*a, **kw): ...\n    return wrapper  # no @wraps; help(decorated) now shows 'wrapper'
- **Signal:**
```python
import functools
def trace(func):
    @functools.wraps(func)          # <- required
    def wrapper(*args, **kwargs):
        return func(*args, **kwargs)
    return wrapper
# without wraps: traced.__name__ == 'wrapper', __doc__ is None
```
- **Exceptions:** None in practice. If you build a parameterized/class-based decorator, still use wraps (or functools.update_wrapper) on the actual wrapping callable; there's no good reason to omit it.

### 40. Prefer functools.partial over lambda Expressions for Glue Functions  [3rd] · low
- **Rule:** When adapting a callable by pinning some of its positional/keyword arguments, use functools.partial instead of a lambda.
- **Why:** partial produces an inspectable, picklable object: its .func, .args, and .keywords are readable for debugging and it serializes (unlike a lambda, which has an opaque <lambda> repr and cannot be pickled). Pinning keyword args via lambda forces verbose, error-prone *args/**kwargs forwarding. The one thing partial cannot do is reorder or transform the wrapped function's arguments — that's the legitimate lambda case people overlook when blanket-replacing.
- **Smell:** sort(items, key=lambda x: my_key(x, reverse=True)) or callback=lambda *a, **k: handler(*a, mode='fast', **k) — pinning args through a throwaway lambda that won't pickle and reads poorly.
- **Signal:**
```python
from functools import partial
# bad: opaque, unpicklable, verbose forwarding
cb = lambda *a, **k: log_event(*a, level='warn', **k)
# good: inspectable and picklable
cb = partial(log_event, level='warn')
# keep lambda only to REORDER args partial can't:
key = lambda item: (item.group, -item.score)
```
- **Exceptions:** Use a lambda when you must reorder, rename, or compute on the wrapped function's arguments (partial can only append/pin in original positions), or for a trivial inline transform like a sort key that isn't pure argument pinning.

## Comprehensions and Generators


### 41. Use Comprehensions Instead of map and filter  [2nd,3rd] · medium
- **Rule:** Prefer a list/dict/set comprehension over map() and filter() (and their nesting), especially when a lambda is involved.
- **Why:** map and filter force you to write a separate lambda for even trivial transforms, and combining a transform with a condition means wrapping a filter inside a map — two function-call layers reading inside-out. A comprehension states the transform and the condition in one left-to-right expression with no lambda overhead, and it extends naturally to dict and set forms that map/filter cannot produce directly.
- **Smell:** map(lambda x: x*2, lst), filter(lambda x: x%2==0, lst), or the nested list(map(lambda x: x**2, filter(lambda x: x%2==0, lst))) instead of a comprehension with an inline condition.
- **Signal:**
```python
# bad
evens_squared = list(map(lambda x: x**2,
                          filter(lambda x: x % 2 == 0, nums)))
# good
evens_squared = [x**2 for x in nums if x % 2 == 0]
# dicts/sets too:
lengths = {w: len(w) for w in words}
```
- **Exceptions:** map(str, nums) or map(int, fields) with an existing named function (no lambda) is fine and sometimes clearer; map/filter also return lazy iterators, so for huge inputs prefer a generator expression, not list(map(...)).

### 42. Avoid More Than Two Control Subexpressions in Comprehensions  [2nd,3rd] · medium
- **Rule:** Cap a comprehension at two control subexpressions total (any mix of for-clauses and if-clauses); beyond that, use explicit loops.
- **Why:** Each additional for or if adds a level of implied nesting that reads in a non-obvious order — multiple for-clauses run outer-to-inner left-to-right while the output expression sits first, so a reader must mentally unroll the loops. Two is the limit where the one-liner is still faster to parse than the equivalent loop; three or more becomes write-only code that hides bugs in the ordering and filtering.
- **Smell:** A comprehension with three+ for/if parts, e.g. flattening-and-filtering a matrix-of-matrices, or stacked conditions where the same logic in a nested for loop would be obviously clearer.
- **Signal:**
```python
# bad: 3 controls (two for, one if) — unreadable
flat = [x for row in matrix for sub in row for x in sub if x > 0]
# good: explicit loops
flat = []
for row in matrix:
    for sub in row:
        flat += [x for x in sub if x > 0]
```
- **Exceptions:** Two controls are fine (one for + one if, or two fors for a simple flatten). The count is about cognitive nesting, not raw character length.

### 43. Reduce Repetition in Comprehensions with Assignment Expressions  [2nd,3rd] · medium
- **Rule:** When a comprehension computes the same expensive/derived value in both its condition and its output, hoist it once with a walrus assignment (:=).
- **Why:** Without the walrus you either call the function twice (once in the if, once in the output expression) — doubling work and risking the two calls diverging — or you fall back to a loop. The walrus binds the result once in the condition and reuses it in the output. The subtle trap: the assigned name leaks into the enclosing scope (loop-variable-style leakage), so don't reuse a name you care about, and avoid putting the walrus in the output-half of the comprehension where it can read before it's assigned.
- **Smell:** Calling get_quota(x) or x.compute() twice in one comprehension — once to filter, once to emit — or a multi-line loop written only to avoid the double call.
- **Signal:**
```python
# bad: computes ratio twice
result = {k: get_ratio(k) for k in keys if get_ratio(k) > 1}
# good: compute once via walrus in the condition
result = {k: r for k in keys if (r := get_ratio(k)) > 1}
```
- **Exceptions:** If the value is cheap (attribute access, arithmetic) the walrus adds noise — skip it. Don't use it just to be clever; the payoff is eliminating a repeated expensive call or guaranteeing a single evaluation.

### 44. Consider Generators Instead of Returning Lists  [2nd,3rd] · medium
- **Rule:** For functions that build and return a sequence by appending in a loop, prefer a generator that yields items instead of accumulating into a list and returning it.
- **Why:** The append-and-return pattern buries the logic under list bookkeeping and forces the entire result into memory before the caller sees the first item — fatal for large or streaming inputs. A generator reads as a clear stream of yield statements and is lazy, so memory stays bounded and the caller can short-circuit. The catch reviewers miss: a generator is single-use and has no len()/indexing, so if a caller needs the full materialized sequence they must wrap it in list(), and the function must not assume it can be re-iterated.
- **Smell:** result = []; for ...: result.append(x); return result — particularly when the result feeds a for loop or could be huge.
- **Signal:**
```python
# bad
def index_words(text):
    result = []
    for i, c in enumerate(text):
        if c == ' ':
            result.append(i + 1)
    return result
# good
def index_words(text):
    for i, c in enumerate(text):
        if c == ' ':
            yield i + 1
```
- **Exceptions:** Return a list when callers need indexing, len(), multiple passes, or a concrete reusable collection, or when the sequence is small and the laziness buys nothing. Generators also make exceptions surface lazily (at iteration time, not call time), which can complicate error handling.

### 45. Consider Generator Expressions for Large List Comprehensions  [2nd,3rd] · medium
- **Rule:** Use a generator expression (parentheses) instead of a list comprehension when the input is large or unbounded and you only iterate the result once.
- **Why:** A list comprehension materializes every element into memory at once, which can exhaust RAM or crash on large/streaming inputs; a generator expression yields lazily and uses constant memory. Generator expressions are also composable — feeding one into another builds a streaming pipeline where each stage pulls one item at a time, never holding the full intermediate.
- **Smell:** A list comprehension whose result is immediately consumed by sum(), any(), a for loop, or a max()/min() call — the list is built only to be thrown away. Also chaining [...] comprehensions over file lines or DB cursors where the source could be huge.
- **Signal:**
```python
# bad: builds full list in memory just to sum
total = sum([len(line) for line in open('huge.log')])

# good: lazy, constant memory
total = sum(len(line) for line in open('huge.log'))

# good: composed streaming pipeline
lengths = (len(line) for line in open('huge.log'))
big = (l for l in lengths if l > 80)
```
- **Exceptions:** Use a list when you need to iterate the result more than once, index into it, take its len(), or pass it where a sequence is required — a generator is single-pass and exhausts after one traversal. For small, fixed-size inputs the memory difference is irrelevant and a list comprehension is clearer.

### 46. Compose Multiple Generators with yield from  [2nd,3rd] · medium
- **Rule:** Delegate to a sub-generator with `yield from subgen()` rather than manually looping `for x in subgen(): yield x`.
- **Why:** `yield from` is not just sugar — it transparently forwards values, and also forwards send()/throw() and propagates the sub-generator's return value, which a manual for-yield loop drops. It is also measurably faster because it avoids the Python-level loop overhead per item. Manual relay loops obscure intent and silently break coroutine semantics.
- **Smell:** A generator body containing one or more `for x in other(): yield x` loops whose sole purpose is to re-emit another iterable's items, especially when stacked sequentially to concatenate several generators.
- **Signal:**
```python
# bad: manual relay loops
def chain(a, b):
    for x in a:
        yield x
    for x in b:
        yield x

# good: clearer and faster
def chain(a, b):
    yield from a
    yield from b
```
- **Exceptions:** If you must transform each item as it passes through (e.g. `yield f(x)`), you cannot use `yield from` — the explicit loop is required. yield from only applies to pure pass-through delegation.

### 47. Pass Iterators into Generators as Arguments Instead of Calling the send Method  [2nd,3rd] · high
- **Rule:** Feed external input into a generator by passing an iterator as a function argument, not by driving it with the send() method.
- **Why:** send() repurposes the `yield` expression to receive values, but the protocol is awkward: the first send() must be None (the generator hasn't reached a yield yet), and interleaving yielded output with sent input produces None gaps and brittle priming code that readers misunderstand. Composing multiple send-driven generators is nearly impossible because each one's advancement is externally clocked. Passing an iterator keeps the generator a normal pull pipeline that composes naturally and needs no priming.
- **Smell:** A generator that reads with `value = yield` and a caller that primes with `gen.send(None)` then loops calling `gen.send(x)`; often paired with confusing interleaving of inputs and outputs, or a global/shared iterator hack to avoid send.
- **Signal:**  ⚠ verifier-flagged
```python
# bad: send-driven, needs priming, hard to compose
def amp(): 
    factor = yield
    while True:
        factor = yield (yield_val := factor * 2)

# good: pass the input iterator in
def amp(factors):
    for factor in factors:
        yield factor * 2
list(amp(iter([1, 2, 3])))
```
- **Exceptions:** Genuine two-way coroutines (cooperative scheduling, async frameworks built on PEP 342, asyncio internals) legitimately need send(). The rule targets ordinary data-processing generators where input is just another stream.

### 48. Manage Iterative State Transitions with a Class Instead of the Generator throw Method  [2nd,3rd] · high
- **Rule:** Model resettable or mode-switching iteration with an explicit stateful class (an __iter__ object) rather than injecting exceptions via the generator throw() method to flip behavior.
- **Why:** throw() re-raises an exception at the generator's suspended yield point so the caller can force a control-flow change, but the resulting code interleaves normal iteration with exception-handling-as-control-flow, which is deeply nested, hard to follow, and fragile under nesting. A class with named methods and explicit instance attributes makes each state transition a readable, testable method call instead of a hidden side effect of an injected exception.
- **Smell:** A try/except wrapped around `yield` inside a generator where the caller calls `gen.throw(SomeSignal)` to reset a counter, change modes, or restart — using exceptions as a state-mutation channel.
- **Signal:**  ⚠ verifier-flagged
```python
# bad: throw() drives state transitions
def timer(period):
    while True:
        try:
            yield period
        except Reset:
            period = ...  # injected control flow

# good: explicit stateful class
class Timer:
    def __init__(self, period): self.period = period
    def reset(self): self.period = self.original
    def __iter__(self):
        while self.period: yield self.period
```
- **Exceptions:** close()/GeneratorExit for cleanup on shutdown is fine and idiomatic — the rule is specifically about throw() used as a state-transition mechanism, not about all generator exception handling.

## Classes and Interfaces


### 49. Compose Classes Instead of Nesting Many Levels of Built-in Types  [2nd] · medium
- **Rule:** When a dict/list/tuple structure grows past one level of nesting (a dict of dicts, a dict whose values are tuples of lists), stop and refactor it into small composed classes.
- **Why:** The footgun is incremental: each nesting level is individually defensible (just one more dict key, one more tuple slot), but the cumulative structure becomes unreadable and the positional tuple indices (row[2]) silently break every callsite when you append a field. Bookkeeping logic written against deeply nested built-ins is also untestable in isolation.
- **Smell:** defaultdict(lambda: defaultdict(list)); accessing data via chained subscripts like grades[name][subject][0]; tuples longer than ~2-3 fields indexed positionally (student[2], student[3]) and being extended over time.
- **Signal:**
```python
# bad: positional tuple grows, every callsite breaks
grades.setdefault(name, []).append((score, weight))
total = sum(s * w for s, w in grades[name])
# good: namedtuple/dataclass + small classes
Grade = namedtuple('Grade', ('score', 'weight'))
class Subject:
    def __init__(self): self._grades = []
    def report(self, score, weight): self._grades.append(Grade(score, weight))
```
- **Exceptions:** Throwaway scripts, a single shallow level of nesting, or pure data passing straight to/from JSON/serialization where no behavior or bookkeeping is attached. Don't preemptively build a class hierarchy for a dict you read once.

### 50. Accept Functions Instead of Classes for Simple Interfaces  [2nd,3rd] · low
- **Rule:** For a single-method hook/callback (key function, default factory, visitor), accept a plain callable rather than requiring callers to define and instantiate a class implementing an interface.
- **Why:** Python functions are first-class, so a one-method 'strategy' interface is ceremony. The nuance people miss: when the callback needs to retain state across calls, reach for a closure or a class with __call__ (which stays callable and lets state be inspected) before introducing a stateful module-level variable or a multi-method abstract base class.
- **Smell:** An ABC or interface class with exactly one abstract method whose only purpose is to be passed in; callers writing class MyHook(Hook): def run(self,...) just to supply behavior; using a global counter to track callback invocations instead of a __call__ object.
- **Signal:**
```python
# bad: one-method class just to pass behavior
class Missing(DefaultFactory):
    def make(self): return 0
defaultdict(Missing().make)
# good: pass the function; use __call__ when state is needed
class CountMissing:
    def __init__(self): self.added = 0
    def __call__(self): self.added += 1; return 0
counter = CountMissing()
result = defaultdict(counter, current)  # counter.added is inspectable
```
- **Exceptions:** When the interface genuinely has multiple methods, or the behavior carries complex lifecycle/configuration, a class is clearer. Also keep a class when callers benefit from subclassing or from naming the concept.

### 51. Prefer Object-Oriented Polymorphism over Functions with isinstance Checks  [3rd] · high
- **Rule:** Replace a function that branches on type(x)/isinstance(x, ...) to choose behavior with a method on each type, dispatched polymorphically.
- **Why:** isinstance chains centralize type-specific behavior in one function that must be edited every time a new type is added — and forgetting one branch fails silently or hits a fallthrough rather than erroring. Polymorphism distributes behavior to where the type is defined, so adding a type means adding a class, not editing a switchboard. The subtle trap: isinstance ladders also break for subclasses depending on branch order.
- **Smell:** if isinstance(x, Circle): ... elif isinstance(x, Square): ...; a final else that returns None or raises a generic error; the same isinstance ladder duplicated across several functions (area(), perimeter(), draw()).
- **Signal:**
```python
# bad: type switchboard, edited on every new shape
def area(s):
    if isinstance(s, Circle): return pi * s.r**2
    elif isinstance(s, Square): return s.side**2
# good: each type owns its behavior
class Circle:
    def area(self): return pi * self.r**2
class Square:
    def area(self): return self.side**2
shape.area()  # adding Triangle = new class, no edits elsewhere
```
- **Exceptions:** Does not apply when you cannot add methods to the types (third-party/builtin types you don't own) — use singledispatch (item 50) instead. Narrowing isinstance for input validation or for typing-driven narrowing (not behavior selection) is fine.

### 52. Consider functools.singledispatch for Functional-Style Programming Instead of Object-Oriented Polymorphism  [3rd] · medium
- **Rule:** When you must add type-dispatched behavior to types you don't own (builtins, third-party, or types that shouldn't carry that concern), use @functools.singledispatch with registered implementations instead of either isinstance ladders or forcing methods onto the classes.
- **Why:** singledispatch gives you open extension (register handlers for new types from anywhere, including by string-annotation type) without polluting the data classes with serialization/rendering/visitor logic that doesn't belong to them. The gotcha: it dispatches only on the first positional argument's runtime type, follows MRO so subclasses inherit the nearest registered handler, and is a poor fit when you need dispatch on multiple arguments.
- **Smell:** A serialize()/to_json()/render() isinstance ladder over builtin or external types; or conversely, methods like to_json bolted onto domain dataclasses purely to satisfy an external serializer, coupling the model to a presentation concern.
- **Signal:**
```python
# bad: isinstance ladder over types you don't own
def to_json(x):
    if isinstance(x, int): return str(x)
    elif isinstance(x, datetime): return x.isoformat()
# good: open dispatch, no edits to the ladder
@singledispatch
def to_json(x): raise TypeError(f'no handler for {type(x)}')
@to_json.register
def _(x: int): return str(x)
@to_json.register
def _(x: datetime): return x.isoformat()
```
- **Exceptions:** If you own the types and the behavior naturally belongs to them, plain OO polymorphism (item 49) is simpler and discoverable via the class. Avoid singledispatch when dispatch depends on more than the first argument's type or on values, not types.

### 53. Prefer dataclasses for Defining Lightweight Classes  [3rd] · medium
- **Rule:** For a class that mostly holds named fields, default to @dataclass instead of hand-writing __init__/__repr__/__eq__ or reaching for namedtuple/plain tuples/dicts.
- **Why:** Hand-written boilerplate drifts: someone adds a field to __init__ but forgets __repr__ or __eq__, producing wrong equality or debugging output. dataclasses generate these consistently and add field-level features (defaults, default_factory, frozen=, field(compare=False), __post_init__ validation) that namedtuple can't express. The key footgun dataclasses fix vs namedtuple: namedtuples are tuples, so they compare equal to plain tuples and are unintentionally iterable/indexable, leaking the abstraction.
- **Smell:** A class whose body is only __init__ assigning self.x = x plus a manual __repr__/__eq__; using a bare dict or tuple as a record passed across functions; mutable default arguments like def __init__(self, items=[]) instead of field(default_factory=list).
- **Signal:**
```python
# bad: boilerplate that drifts, mutable default bug
class Point:
    def __init__(self, x, y, tags=[]): self.x, self.y, self.tags = x, y, tags
    def __repr__(self): return f'Point({self.x})'  # forgot y!
# good
@dataclass
class Point:
    x: float
    y: float
    tags: list = field(default_factory=list)
```
- **Exceptions:** Use NamedTuple when you specifically need an immutable tuple that interoperates with tuple-expecting APIs or unpacks positionally; use a plain class when behavior dominates over data; use frozen=True dataclasses (or attrs/pydantic) when you need hashability, immutability, or runtime validation beyond what stdlib dataclasses give.

### 54. Use @classmethod Polymorphism to Construct Objects Generically  [2nd,3rd] · medium
- **Rule:** When a base class or framework needs to build instances of unknown subclasses, expose a @classmethod factory instead of hardcoding the concrete type or relying on __init__ shape.
- **Why:** Python has no constructor overloading, so a single __init__ can't represent multiple alternative ways to build an object; @classmethod factories give each construction path a name and let cls resolve polymorphically to the actual subclass, so generic code (e.g. a generate-and-merge pipeline) can instantiate the right type without an if/else ladder over types.
- **Smell:** A generic function that switches on a type field or a config string to decide which concrete class to instantiate, or a base class that returns/instantiates a specific subclass by name rather than via cls.
- **Signal:**
```python
# bad: caller must know every concrete type
def build(kind, cfg):
    if kind == 'path': return PathInput(cfg)
    elif kind == 'net': return NetInput(cfg)
# good: each subclass owns its construction, cls is polymorphic
class InputData:
    @classmethod
    def generate_inputs(cls, config): raise NotImplementedError
class PathInputData(InputData):
    @classmethod
    def generate_inputs(cls, config):
        for path in glob(config['dir']): yield cls(path)
```
- **Exceptions:** Overkill for a single concrete class with one obvious construction path; a plain __init__ or one named alternative constructor is enough. The pattern earns its keep only when multiple subclasses must be built by code that shouldn't enumerate them.

### 55. Initialize Parent Classes with super  [2nd,3rd] · high
- **Rule:** Always initialize superclasses via super().__init__(), never by calling ParentClass.__init__(self, ...) directly.
- **Why:** Direct parent calls break under multiple/diamond inheritance: a shared ancestor's __init__ runs more than once (clobbering earlier state), and the order no longer follows the C3-linearized MRO. super() walks the MRO so each ancestor initializes exactly once in a consistent order, and it also decouples subclasses from the literal parent name.
- **Smell:** Explicit ParentName.__init__(self, ...) calls, especially several of them in one __init__ under multiple inheritance, or mixing super() with direct-name calls in the same hierarchy.
- **Signal:**
```python
# bad: common base runs twice, order is wrong under diamond inheritance
class C(A, B):
    def __init__(self, v):
        A.__init__(self, v)
        B.__init__(self, v)
# good: MRO runs each ancestor once, in order
class C(A, B):
    def __init__(self, v):
        super().__init__(v)
```
- **Exceptions:** If you genuinely need to call a specific bypassed ancestor for a deliberate reason it must be conscious and documented; cooperative multiple inheritance also requires every class in the chain to call super() and accept/forward **kwargs, or the chain breaks.

### 56. Consider Composing Functionality with Mix-in Classes  [2nd,3rd] · medium
- **Rule:** Reach for small stateless mix-in classes that add behavior via methods rather than deep multi-level inheritance trees or instance state.
- **Why:** Mix-ins work because they define behavior without their own __init__/attributes and rely on methods (often pluggable hooks) of the host class; this keeps composition flat and avoids the diamond-MRO and init-ordering hazards that come with stateful multiple inheritance. People misuse them by giving mix-ins their own state, which reintroduces every multiple-inheritance problem they were meant to avoid.
- **Smell:** A mix-in with __init__ or instance attributes; or a tall inheritance chain (4+ levels) used purely to share a couple of helper methods that could be a stateless mix-in or plain composition.
- **Signal:**
```python
# bad: deep, state-carrying inheritance to share one capability
class Node(StorageBase, JSONBase, LoggingBase): ...
# good: stateless mix-in adds behavior, leans on host methods
class ToDictMixin:
    def to_dict(self):
        return {k: self._traverse(v) for k, v in self.__dict__.items()}
class Node(ToDictMixin): ...
```
- **Exceptions:** When the shared functionality inherently needs state or a lifecycle, prefer plain composition (hold a collaborator object) over a mix-in. A single is-a relationship doesn't need a mix-in at all.

### 57. Prefer Public Attributes over Private Ones  [2nd,3rd] · low
- **Rule:** Default to public attributes (or a single leading underscore for "internal") and avoid dunder-prefixed __private fields except to deliberately avoid name clashes in subclasses.
- **Why:** Double-underscore __name only triggers name mangling (_Class__name); it isn't real access control and just makes legitimate subclass access and debugging harder. The leading-underscore convention already communicates "internal, touch at your own risk," and trusting it is more Pythonic and more extensible than fighting subclassers with mangling.
- **Smell:** __-prefixed attributes used to "protect" data from subclasses, leading to brittle subclasses that resort to _Class__attr hacks; or a getter/setter property wrapping a trivial __field with no validation logic.
- **Signal:**
```python
# bad: mangling blocks subclass access for no real protection
class Base:
    def __init__(self): self.__value = 5
class Child(Base):
    def get(self): return self.__value  # AttributeError
# good: single underscore signals internal, subclasses can extend
class Base:
    def __init__(self): self._value = 5
```
- **Exceptions:** Double underscore is legitimate when a class is widely subclassed and you must guard an attribute name from accidental collision with subclass attributes (e.g. in a base class meant for unknown future subclasses).

### 58. Prefer dataclasses for Creating Immutable Objects  [3rd] · medium
- **Rule:** For value/immutable objects, use @dataclass(frozen=True) instead of hand-writing __init__, __eq__, __hash__, or freezing via custom __setattr__.
- **Why:** frozen=True makes dataclasses synthesize __setattr__/__delattr__ that raise FrozenInstanceError, and with eq=True you get value equality plus a usable __hash__, making instances safe as dict keys/set members and effectively thread-safe. The subtlety people miss: frozen is shallow (a mutable list field is still mutable) and __post_init__ must use object.__setattr__ to set derived fields.
- **Smell:** Manual immutability via overridden __setattr__ that raises, or boilerplate classes reimplementing __init__/__eq__/__repr__/__hash__ by hand for what is conceptually a value object; also using a frozen dataclass while exposing a mutable default like a list field.
- **Signal:**
```python
# bad: hand-rolled immutability and equality boilerplate
class Point:
    def __init__(self, x, y): self._x, self._y = x, y
    def __setattr__(self, *a): raise AttributeError
# good: frozen dataclass gives immutability + eq + hash
from dataclasses import dataclass
@dataclass(frozen=True)
class Point:
    x: int
    y: int
```
- **Exceptions:** Frozen gives only shallow immutability — pair mutable fields with field(default_factory=...) and treat them as read-only, or use tuples/frozensets. For deep nesting or richer validation, attrs or a NamedTuple may fit better; the tiny per-write object.__setattr__ overhead rarely matters.

### 59. Inherit from collections.abc for Custom Container Types  [2nd,3rd] · medium
- **Rule:** When a class is meant to behave like a container (sequence, set, or mapping), inherit from the matching collections.abc abstract base class instead of hand-rolling the protocol.
- **Why:** Container protocols are far larger than they look: implementing __getitem__ alone does not give you len(), and consumers also expect index(), count(), __contains__, __iter__, __reversed__, and more. The ABCs supply every derived method for free once you implement the small set of abstract primitives, and they fail loudly with a TypeError at instantiation if you forget one — turning a class of silent behavioral gaps into a single startup error. People get this wrong by assuming 'I added __getitem__, so it's a sequence' when it only half-satisfies the contract.
- **Smell:** A class that defines __getitem__ (and maybe __len__) by hand and is treated as a sequence/set/mapping, but is missing count/index/__contains__/__iter__ or implements them inconsistently; or a homegrown mapping reimplementing keys/values/items/get/__eq__ instead of subclassing Mapping. Also: subclassing dict/list and being surprised that overridden __getitem__ isn't called by .get() or .update().
- **Signal:**
```python
# Bad: half a sequence — len(tree) and tree.index(x) break
class Tree:
    def __getitem__(self, i): ...

# Good: implement the primitives, get the rest for free
from collections.abc import Sequence
class Tree(Sequence):
    def __getitem__(self, i): ...   # required
    def __len__(self): ...          # required
# tree.index(7), tree.count(10), `x in tree`, iteration all work
```
- **Exceptions:** For trivial cases where you just want a built-in's behavior plus a method or two, subclass dict/list/set directly (or use UserDict/UserList so your overrides are actually invoked by inherited methods — plain dict/list call C-level internals that bypass your Python overrides). ABCs add value when you're defining a genuinely custom backing store, not lightly extending an existing one.

## Metaclasses and Attributes


### 60. Use Plain Attributes Instead of Setter and Getter Methods  [2nd,3rd] · medium
- **Rule:** Expose simple instance state as public attributes; do not write Java-style get_x()/set_x() pairs that wrap a plain field.
- **Why:** Python lets you start with a bare attribute and later swap in @property without changing any caller, so writing explicit accessors up front buys nothing and forces every call site into noisy method syntax. The mistake people make is importing the Java/C++ habit of pre-emptive encapsulation; in Python encapsulation is added lazily and transparently when a behavior is actually needed.
- **Smell:** A class whose __init__ stores self._voltage and which exposes get_voltage()/set_voltage() that only return or assign the field with no validation or side effect.
- **Signal:**
```python
# bad
class Resistor:
    def __init__(self, ohms): self._ohms = ohms
    def get_ohms(self): return self._ohms
    def set_ohms(self, v): self._ohms = v
# good
class Resistor:
    def __init__(self, ohms): self.ohms = ohms  # access r.ohms / r.ohms = 5 directly
```
- **Exceptions:** Keep explicit methods when access is genuinely an operation, not a field: it does I/O, is expensive/slow, can raise, or must be obviously side-effecting to the reader. Conforming to an externally mandated interface (ORM, RPC stub) is also fine.

### 61. Consider @property Instead of Refactoring Attributes  [2nd,3rd] · medium
- **Rule:** When a plain attribute needs new behavior (validation, derived value, lazy compute), convert it to @property in place rather than renaming the field and editing every caller.
- **Why:** @property lets you add logic behind an existing attribute name so all existing reads/writes keep working unchanged — the key migration tool that makes 'plain attributes first' safe. People misuse it by making getters do surprising work (mutating other state, slow I/O, side effects on read); a property should still feel like attribute access. It is also a signal to refactor toward a real method or descriptor once the logic grows beyond trivial.
- **Smell:** A @property getter that triggers network calls, mutates sibling attributes, or runs expensive computation on every read; or a setter that silently swallows invalid input instead of raising.
- **Signal:**
```python
# good: add validation without breaking callers who already use r.ohms
class Resistor:
    @property
    def ohms(self): return self._ohms
    @ohms.setter
    def ohms(self, v):
        if v <= 0: raise ValueError(f'ohms must be > 0; got {v}')
        self._ohms = v
```
- **Exceptions:** If you control all callers and the rename clarifies intent, a normal refactor to an explicit method may be cleaner. Don't reach for @property when the new behavior is clearly an action (use a method) or shared across many attributes (use a descriptor).

### 62. Use Descriptors for Reusable @property Methods  [2nd,3rd] · high
- **Rule:** When the same property logic (e.g. a 0–100 range validator) repeats across attributes or classes, extract it into a descriptor class instead of copy-pasting @property blocks.
- **Why:** @property is not reusable — each property is bound to one attribute on one class, so N similar fields means N near-identical getter/setter pairs. A descriptor centralizes the logic, but the classic footgun is storing per-instance state in a single dict on the descriptor instance: because one descriptor object is shared by every instance of the owning class, a plain {} leaks memory and lets instances clobber each other. Use WeakKeyDictionary keyed by instance (frees with the instance) and prefer __set_name__ (3.6+) so the descriptor learns its own attribute name automatically and can store into the instance __dict__ cleanly.
- **Smell:** Three @property pairs differing only by attribute name; or a descriptor that holds self.values = {} (strong refs, memory leak) or hardcodes a single shared value across all instances.
- **Signal:**
```python
# good
class Grade:
    def __set_name__(self, owner, name): self._name = f'_{name}'
    def __get__(self, obj, owner): return getattr(obj, self._name, 0) if obj else self
    def __set__(self, obj, value):
        if not 0 <= value <= 100: raise ValueError('0..100')
        setattr(obj, self._name, value)
class Exam: writing = Grade(); math = Grade()
```
- **Exceptions:** Don't introduce a descriptor for a single attribute used in one place — a plain @property is simpler. If you predate the per-instance __dict__ pattern and must use a dict, use WeakKeyDictionary, never a plain dict.

### 63. Use __getattr__, __getattribute__, and __setattr__ for Lazy Attributes  [2nd,3rd] · high
- **Rule:** Use __getattr__/__setattr__ for dynamic/lazy attributes, prefer __getattr__ over __getattribute__, and inside these hooks reach state via super().__getattribute__/super().__setattr__ (or self.__dict__) to avoid infinite recursion.
- **Why:** __getattr__ fires only when normal lookup fails (so accessing an already-set attribute is cheap and bypasses it), while __getattribute__ fires on every access — easy to make pathologically slow or recursive. The recursion trap: any self.x access inside __getattribute__, or self.x = v inside __setattr__, re-enters the same hook; you must go through super() or __dict__ directly. Also remember __getattr__ may be called repeatedly for the same name unless you cache the value into the instance dict.
- **Smell:** A __setattr__ that does self._loaded = True (re-triggers __setattr__ forever), or a __getattribute__ that references self.<anything> directly, or a __getattr__ that recomputes an expensive value on every miss without caching it back onto the instance.
- **Signal:**
```python
# bad: infinite recursion
def __setattr__(self, name, value): self.__dict__  # ok
    # self._x = value  # would recurse
# good
class Lazy:
    def __getattr__(self, name):
        value = load(name)
        setattr(self, name, value)  # cache so next access skips __getattr__
        return value
    def __setattr__(self, name, value):
        super().__setattr__(name, value)
```
- **Exceptions:** Reach for __getattribute__ only when you must intercept access to attributes that already exist (e.g. transparent lazy DB record hydration on every read); its per-access cost and recursion risk make it the wrong default. For most lazy/proxy needs, __getattr__ suffices.

### 64. Validate Subclasses with __init_subclass__  [2nd,3rd] · medium
- **Rule:** Enforce subclass constraints (required class attributes, valid field combinations, structural rules) in __init_subclass__ rather than via a custom metaclass.
- **Why:** __init_subclass__ (3.6+) runs at class-definition time and gives the same fail-fast validation a metaclass provided, without the metaclass's downsides: metaclasses don't compose (conflicting metaclasses across a hierarchy raise TypeError), are hard to read, and are overkill for validation. The subtlety people miss is that it must call super().__init_subclass__(**kwargs) to chain correctly when multiple base classes each define it — skipping the super() call silently breaks cooperative validation in diamond hierarchies.
- **Smell:** A metaclass whose __new__/__init__ exists only to check that subclasses define some attribute or satisfy an invariant; or an __init_subclass__ that omits the super().__init_subclass__(**kwargs) chain call.
- **Signal:**
```python
# good
class Shape:
    def __init_subclass__(cls, **kwargs):
        super().__init_subclass__(**kwargs)
        if not hasattr(cls, 'sides'):
            raise TypeError(f'{cls.__name__} must define sides')
class Triangle(Shape): sides = 3  # missing 'sides' fails at definition time
```
- **Exceptions:** A metaclass is still warranted when you must customize class creation itself (e.g. register classes, rewrite the namespace, alter the MRO, or build the class object dynamically) — things __init_subclass__ cannot do. Pure validation should not use a metaclass.

### 65. Register Class Existence with __init_subclass__  [2nd,3rd] · medium
- **Rule:** Use the __init_subclass__ hook to auto-register or validate subclasses at definition time instead of a metaclass or a manual registration call.
- **Why:** __init_subclass__ runs once per subclass during its creation and is implicitly a classmethod receiving the new subclass as cls; the common failure is forgetting it does NOT fire for the class that defines it (only descendants), and forgetting to call super().__init_subclass__(**kwargs) after popping the kwargs you consumed, which silently breaks cooperative multiple inheritance and any sibling base that also hooks creation.
- **Smell:** A base class with a custom metaclass whose __new__ does registration, OR a registry that relies on every author remembering to call register(MyClass) by hand after each class definition — both invite a forgotten registration that fails only at runtime when the missing class is looked up.
- **Signal:**
```python
# bad: relies on manual registration, easy to forget
class Shape: ...
class Circle(Shape): ...
register(Circle)  # forget this -> silent gap
# good: registration is automatic and unforgettable
class Shape:
    def __init_subclass__(cls, **kwargs):
        super().__init_subclass__(**kwargs)  # pop your own kwargs first
        registry[cls.__name__] = cls
class Circle(Shape): ...  # registered on definition
```
- **Exceptions:** If you must also customize the class object's own type behavior (e.g. control isinstance, add a custom __call__ on the class) a metaclass is still required. __init_subclass__ cannot register the base class itself, so a self-registering root needs an explicit registry insert for the root.

### 66. Annotate Class Attributes with __set_name__  [2nd,3rd] · medium
- **Rule:** Give descriptors a __set_name__(self, owner, name) method so they learn their assigned attribute name automatically, rather than passing the name redundantly to the descriptor constructor or using a metaclass to inject it.
- **Why:** Before __set_name__ (PEP 487), a descriptor had no way to know which attribute it was bound to, so people either duplicated the name as a constructor arg (Field('first_name') assigned to first_name — a copy-paste desync bug) or wrote a metaclass to walk the class dict. __set_name__ is called by type.__new__ once per descriptor in class-body order, after the class object exists but before __init_subclass__, eliminating the duplication.
- **Smell:** A descriptor class whose __init__ takes a name string that must match the attribute it is assigned to, e.g. weight = Field('weight'); any mismatch or rename produces a silently wrong storage key, not an error.
- **Signal:**
```python
# bad: name passed twice, can desync on rename
class Field:
    def __init__(self, name): self.name = name
class Row: first = Field('first')  # 'first' duplicated
# good: descriptor learns its own name
class Field:
    def __set_name__(self, owner, name): self.name = name
class Row: first = Field()  # name captured automatically
```
- **Exceptions:** __set_name__ only fires for descriptors assigned directly in a class body; objects stored in a list/dict, created after class definition, or assigned via setattr later won't receive it, so dynamic registration still needs an explicit name.

### 67. Consider Class Body Definition Order to Establish Relationships Between Attributes  [3rd] · medium
- **Rule:** When attributes need an inherent ordering (columns, form fields, serialization layout), rely on the guaranteed left-to-right class-body definition order surfaced by __set_name__/__init_subclass__ instead of inventing a manual order=N counter on each attribute.
- **Why:** Since PEP 520 the class namespace preserves insertion order, and __set_name__ is invoked in that same order, so the sequence attributes appear in the source IS a reliable, authoritative ordering — adding explicit per-attribute index numbers reintroduces exactly the desync/renumbering bugs that ordering guarantee removed.
- **Smell:** Descriptors carrying an explicit sequence number the author must keep monotonic by hand (Field(order=0), Field(order=1), ...); inserting a field in the middle forces renumbering every field below it, and a duplicate or skipped number corrupts the layout silently.
- **Signal:**
```python
# bad: manual order numbers, fragile on insert
class Form:
    name = Field(order=0)
    email = Field(order=1)  # insert above -> renumber all
# good: order derived from definition position
class Field:
    _counter = 0
    def __set_name__(self, owner, name):
        self.order = Field._counter; Field._counter += 1
```
- **Exceptions:** Definition order only reflects the order within a single class body; across an inheritance hierarchy or when fields are generated programmatically you still need an explicit, deterministic ordering scheme. Don't depend on dict ordering for sets or for attributes mutated after creation.

### 68. Prefer Class Decorators Over Metaclasses for Composable Class Extensions  [2nd,3rd] · high
- **Rule:** When a class-wide transformation (wrap every method, inject behavior, add attributes) needs to stack with other such transformations, implement it as a class decorator rather than a metaclass.
- **Why:** Metaclasses don't compose: a class can have exactly one metaclass and a subclass's metaclass must be a subtype of its bases' metaclasses, so combining two independent utility metaclasses raises a 'metaclass conflict' TypeError that you often cannot fix when one comes from a third party. Class decorators are plain functions applied after the class is fully built, so any number of them stack freely — at the cost of running post-creation, so they can't influence the class-creation machinery itself.
- **Smell:** Two orthogonal cross-cutting concerns (e.g. tracing + serialization) each shipped as its own metaclass, then a class trying to use both and failing with a metaclass conflict, or an awkward 'combined' metaclass written solely to merge them.
- **Signal:**
```python
# bad: utility as metaclass -> conflicts, can't stack
class TraceMeta(type): ...
class MyClass(Base, metaclass=TraceMeta): ...  # conflict if Base has a metaclass
# good: utility as decorator -> composes
def trace(cls): ...; return cls
@trace
@validate
class MyClass(Base): ...  # stack freely
```
- **Exceptions:** If the extension must alter how the class itself is constructed or called (custom isinstance, a class-level __call__/__prepare__, or controlling the type of the class object), a metaclass is genuinely required and a decorator cannot substitute. For single subclass-init hooks prefer __init_subclass__; reach for a decorator when you must transform the class object's existing members.

## Concurrency and Parallelism


### 69. Use subprocess to Manage Child Processes  [2nd,3rd] · high
- **Rule:** Run external commands through the subprocess module, never os.system/os.popen/os.spawn, and always feed input via stdin pipes, set a timeout, and check the return code.
- **Why:** subprocess is the only API that cleanly composes child-process I/O, polling, and timeouts. The footguns people hit are: child processes run independently so you must explicitly poll() or communicate() to detect completion; a hung child blocks forever unless you pass timeout=; and a nonzero exit silently passes unless you call check_returncode() (or use run(..., check=True)). os.system runs through a shell, inviting injection and losing structured access to streams.
- **Smell:** os.system(f'convert {user_path} out.png'); or Popen(...) followed by reading .stdout in a blocking loop with no timeout and no return-code check; or shell=True with an interpolated user string.
- **Signal:**
```python
# Bad: shell injection, no timeout, exit code ignored
os.system(f'gzip {path}')

# Good
proc = subprocess.run(['gzip', path], capture_output=True, timeout=30)
proc.check_returncode()  # raises CalledProcessError on nonzero exit
```
- **Exceptions:** For true CPU parallelism you typically reach for subprocess-backed worker pools (or multiprocessing). shell=True is acceptable only with a fully static, trusted command string. Long-running pipelines that must stream may legitimately manage Popen objects directly instead of run().

### 70. Use Threads for Blocking I/O, Avoid for Parallelism  [2nd,3rd] · high
- **Rule:** Use threads to overlap blocking I/O (network, disk, subprocess waits), not to speed up CPU-bound Python work.
- **Why:** The CPython GIL lets only one thread execute bytecode at a time, so CPU-bound code gets no speedup (often a slowdown) from threading—but during a blocking syscall the GIL is released, so I/O-bound threads do overlap and win. People misread "threads = parallel" and burn effort threading number-crunching that should go to multiprocessing, concurrent.futures.ProcessPoolExecutor, a C extension, or asyncio. (3rd edition adds the free-threaded/no-GIL build caveat, but assume the GIL holds unless you've confirmed the interpreter is free-threaded.)
- **Smell:** Splitting a numeric loop (factorization, image math, parsing) across threading.Thread workers and expecting near-linear speedup; benchmarking shows it's as slow as or slower than serial.
- **Signal:**
```python
# Bad: CPU-bound across threads — no speedup under the GIL
threads = [Thread(target=factorize, args=(n,)) for n in numbers]

# Good: threads for blocking I/O; processes for CPU
with ThreadPoolExecutor(8) as ex:        # I/O-bound
    results = list(ex.map(fetch_url, urls))
# CPU-bound -> ProcessPoolExecutor instead
```
- **Exceptions:** On a free-threaded (PEP 703 / no-GIL) interpreter, threads can run CPU work in parallel. CPU work inside C extensions that release the GIL (NumPy, hashlib) also parallelizes across threads. Threads are still preferable to processes for I/O because they avoid serialization/IPC overhead.

### 71. Use Lock to Prevent Data Races in Threads  [2nd,3rd] · high
- **Rule:** Guard every mutable state shared across threads with a threading.Lock (via a with block); do not rely on the GIL to make read-modify-write atomic.
- **Why:** The GIL prevents two bytecodes from running simultaneously, but a single Python statement like counter += 1 compiles to multiple bytecodes (load, add, store) and the interpreter can switch threads between them—so increments are lost and invariants corrupt. The GIL protects the interpreter, not your data. A Lock makes the critical section mutually exclusive; using it as a context manager guarantees release even on exception.
- **Smell:** self.count += 1 or shared_list.append(x) executed from multiple threads with no lock; or manual lock.acquire()/lock.release() without try/finally so an exception leaves the lock held (deadlock).
- **Signal:**
```python
# Bad: lost updates despite the GIL
def worker(): self.count += offset

# Good
def worker():
    with self.lock:        # threading.Lock()
        self.count += offset
```
- **Exceptions:** State confined to a single thread, or truly immutable shared data, needs no lock. A Queue already provides its own internal locking—don't wrap queue ops in your own lock. For multiple locks, impose a consistent acquisition order (or use RLock for re-entrant code) to avoid deadlock.

### 72. Use Queue to Coordinate Work Between Threads  [2nd,3rd] · medium
- **Rule:** Coordinate producer/consumer thread pipelines with queue.Queue, not hand-rolled lists plus sleeps and polling.
- **Why:** queue.Queue gives blocking get()/put() (consumers sleep until work arrives instead of busy-waiting), bounded capacity via maxsize to apply backpressure so a fast producer can't exhaust memory, and task_done()/join() to wait for all work to drain. Hand-built pipelines with a plain list, a Lock, and time.sleep() waste CPU polling, can busy-loop, leak memory under load, and are hard to shut down cleanly.
- **Smell:** A shared list guarded by a lock where the consumer loops with while not items: time.sleep(0.1); or no maxsize so the producer races ahead unbounded; or no sentinel/poison-pill mechanism to stop worker threads.
- **Signal:**
```python
# Bad: busy-wait, unbounded, no backpressure
while True:
    if items: process(items.pop(0))
    else: time.sleep(0.1)

# Good
q = Queue(maxsize=100)        # backpressure
item = q.get()                # blocks, no spin
process(item); q.task_done()
# producer: q.put(item); shutdown via sentinel + q.join()
```
- **Exceptions:** For purely functional fan-out/fan-in with no streaming pipeline, ThreadPoolExecutor.map is simpler than wiring Queues by hand. For CPU-bound stages use multiprocessing.Queue or a process pool. For async code use asyncio.Queue, not queue.Queue.

### 73. Know How to Recognize When Concurrency Is Necessary  [2nd,3rd] · medium
- **Rule:** Watch for unbounded fan-out—spawning one thread/process per work item as input scales—and switch to a pooled or async model before it becomes a bottleneck.
- **Why:** Programs grow in complexity ("the I/O explodes") as features are added, and the naive fix—one Thread per unit of work—has high per-thread memory and startup cost, crashes or thrashes at scale, and makes error handling fragile. The real skill is recognizing the fan-out/fan-in pattern early and picking the right tool (ThreadPoolExecutor for bounded I/O concurrency, asyncio for very high I/O fan-out, process pools for CPU) rather than scaling threads linearly with the workload.
- **Smell:** for item in items: Thread(target=work, args=(item,)).start() inside a loop whose size grows with input; thousands of live threads; per-item daemon threads with no pool, no limit, and no aggregated error handling.
- **Signal:**
```python
# Bad: one thread per item, unbounded fan-out
for task in tasks:
    Thread(target=run, args=(task,)).start()

# Good: bounded pool, collected results/errors
with ThreadPoolExecutor(max_workers=32) as ex:
    for r in ex.map(run, tasks):
        handle(r)
# very high I/O fan-out -> asyncio instead
```
- **Exceptions:** For a small, fixed, known-bounded number of concurrent units (a handful), spawning threads directly is fine and clearer than a pool. If the workload isn't actually concurrent (sequential dependencies, trivial runtime), adding concurrency at all is premature and just adds bugs.

### 74. Avoid Creating New Thread Instances for On-demand Fan-out  [2nd,3rd] · high
- **Rule:** Never spawn one `threading.Thread` per work item in a fan-out (e.g. per cell, per row, per request) loop.
- **Why:** Each OS thread carries ~8MB stack plus startup/teardown cost, so fanning out hundreds or thousands of Thread instances blows up memory and the scheduler before you ever get parallelism; worse, exceptions raised inside a worker thread vanish unless you build your own propagation channel, so failures are silently swallowed and debugging the fan-out becomes intractable.
- **Smell:** A loop body that does `t = Thread(target=work, args=(item,)); t.start()` collecting threads into a list, then a second loop calling `t.join()` — unbounded thread count scaled to input size.
- **Signal:**
```python
# Bad: one Thread per item, unbounded
threads = [Thread(target=step, args=(x,)) for x in grid]
for t in threads: t.start()
for t in threads: t.join()  # leaks exceptions, 1 thread/item

# Good: bound the work with a pool/executor instead
with ThreadPoolExecutor(max_workers=10) as ex:
    list(ex.map(step, grid))  # reuses workers, re-raises errors
```
- **Exceptions:** Fine for a small fixed number of long-lived threads (a few background daemons), where the count does not scale with input size and the overhead is amortized.

### 75. Understand How Using Queue for Concurrency Requires Refactoring  [2nd,3rd] · medium
- **Rule:** If you reach for `queue.Queue` pipelines to fix fan-out, recognize it forces a full rewrite into worker-thread stages — don't bolt it on incrementally.
- **Why:** A naive Queue pipeline still needs a fixed pool of worker threads per stage, sentinel/poison-pill shutdown logic, `task_done`/`join` bookkeeping, and rebalancing when stages have uneven throughput; people underestimate that making a Queue version robust (graceful shutdown, backpressure, exception handling across stages) is a substantial restructuring, not a drop-in, and the resulting code is hard to extend with new stages.
- **Smell:** Hand-rolled `Queue` + `while True: item = q.get()` worker loops with magic sentinel values, daemon worker threads, and brittle shutdown that hangs or drops items; adding a pipeline stage means rewriting the threading scaffolding again.
- **Signal:**
```python
# Smell: manual queue pipeline, sentinel shutdown, fixed workers
def worker(in_q, out_q):
    while True:
        item = in_q.get()
        if item is SENTINEL:  # fragile poison-pill protocol
            return
        out_q.put(do(item))
        in_q.task_done()
# Each stage needs its own thread pool + sentinel-per-worker fan-in.
# Prefer ThreadPoolExecutor / asyncio if the pipeline is the goal.
```
- **Exceptions:** A Queue pipeline is the right tool for genuine long-running producer/consumer streaming with backpressure between stages; the rule is against treating it as a cheap incremental patch.

### 76. Consider ThreadPoolExecutor When Threads Are Necessary for Concurrency  [2nd,3rd] · medium
- **Rule:** For bounded blocking-I/O fan-out, use `ThreadPoolExecutor` rather than raw threads or hand-built Queue pipelines.
- **Why:** ThreadPoolExecutor caps concurrency at `max_workers`, reuses threads, and — critically — propagates worker exceptions back to the caller through the `Future` (raised on `result()`/`map` iteration), eliminating the swallowed-exception footgun of raw threads with far less code; the catch people miss is that `max_workers` is a hard ceiling, so it doesn't scale to thousands of simultaneous connections the way coroutines do.
- **Smell:** Reinventing a worker pool with `Queue` + manual threads when a few lines of `ThreadPoolExecutor` would do; or setting `max_workers` arbitrarily high to force more concurrency, defeating the bound.
- **Signal:**
```python
# Bad: manual thread pool plumbing
# (Queue, worker loop, sentinels, join...) — dozens of lines

# Good: bounded pool, exceptions re-raised via futures
with ThreadPoolExecutor(max_workers=10) as ex:
    futures = [ex.submit(fetch, url) for url in urls]
    results = [f.result() for f in futures]  # errors surface here
```
- **Exceptions:** When concurrency must scale to thousands of simultaneous I/O operations, the per-thread memory and the `max_workers` ceiling make coroutines/asyncio the better choice; ThreadPoolExecutor is for the moderate, bounded case.

### 77. Achieve Highly Concurrent I/O with Coroutines  [2nd,3rd] · high
- **Rule:** For high-fan-out I/O (thousands of concurrent operations), use `async def` coroutines on the asyncio event loop instead of threads.
- **Why:** Coroutines run in a single thread with negligible per-coroutine memory (no OS stack) and no thread-context-switch cost, so they scale to tens of thousands of concurrent I/O operations where threads would exhaust memory; the trap is that any synchronous blocking call (`time.sleep`, blocking socket, CPU-bound work) inside a coroutine stalls the entire event loop — coroutines only help when every awaited operation is truly non-blocking.
- **Smell:** `async def` functions that call blocking APIs directly (`requests.get`, `time.sleep`, blocking DB drivers) without `await`, or forgetting to `await`/`gather` so coroutines run sequentially instead of concurrently.
- **Signal:**
```python
# Bad: blocking call inside a coroutine stalls the whole loop
async def fetch(u):
    time.sleep(1)          # blocks event loop; use asyncio.sleep
    return requests.get(u) # sync I/O blocks all coroutines

# Good: await non-blocking ops and run them concurrently
async def fetch(u):
    await asyncio.sleep(1)
    async with session.get(u) as r: return await r.text()
results = await asyncio.gather(*(fetch(u) for u in urls))
```
- **Exceptions:** Pointless for CPU-bound work (the GIL/single thread gives no speedup — use processes) and overkill for small, bounded I/O fan-out where ThreadPoolExecutor is simpler and avoids async-coloring the whole call stack.

### 78. Know How to Port Threaded I/O to asyncio  [2nd,3rd] · medium
- **Rule:** When migrating threaded I/O to asyncio, port incrementally using the event loop's executor/threadsafe bridges rather than rewriting everything at once.
- **Why:** asyncio is designed to interoperate with threads so you can convert a large codebase piecewise: wrap still-blocking/synchronous code with `loop.run_in_executor(...)` to call it from coroutines without stalling the loop, and use `asyncio.run_coroutine_threadsafe(...)` to drive coroutines from existing threads; people get burned by attempting a big-bang rewrite, or by calling blocking code directly from a coroutine (freezing the loop) instead of routing it through an executor during the transition.
- **Smell:** A migration that either rewrites the entire stack in one shot, or leaves synchronous blocking helpers being invoked directly inside `async def` without `run_in_executor`, freezing the loop and erasing the concurrency benefit.
- **Signal:**
```python
# Bridging during a port:
# call leftover blocking code from async without blocking the loop
async def handler(item):
    loop = asyncio.get_running_loop()
    data = await loop.run_in_executor(None, blocking_legacy_read, item)
    return data

# drive a coroutine from an existing (non-async) thread
fut = asyncio.run_coroutine_threadsafe(handler(x), loop)
result = fut.result()
```
- **Exceptions:** For small programs a clean full rewrite to native async libraries may be simpler than maintaining executor bridges; the incremental approach pays off mainly on large, mixed-paradigm codebases.

### 79. Mix Threads and Coroutines to Ease the Transition to asyncio  [2nd,3rd] · medium
- **Rule:** Migrate a threaded codebase to asyncio incrementally by bridging the two models rather than rewriting all at once: from a coroutine, offload blocking sync work via loop.run_in_executor / asyncio.to_thread; from a foreign (non-loop) thread, schedule a coroutine onto the loop via asyncio.run_coroutine_threadsafe (which returns a concurrent.futures.Future).
- **Why:** asyncio and threads are interoperable, so you can convert one layer at a time and keep a working program throughout; the failure mode is the all-at-once rewrite, which is unverifiable and stalls. The directional bridges differ: a coroutine must offload blocking sync work via run_in_executor/to_thread, while a synchronous thread must schedule a coroutine onto the loop via run_coroutine_threadsafe (which returns a concurrent.futures.Future, not an awaitable).
- **Smell:** A PR that rewrites an entire threaded module to async in one commit, or async code that calls a legacy blocking function directly (freezing the loop) because nobody wrapped it; conversely, sync code that calls loop.create_task() from a foreign thread instead of run_coroutine_threadsafe.
- **Signal:**
```python
# bad: async code calls a blocking sync API directly -> stalls loop
async def handle(line):
    legacy_blocking_write(line)  # blocks the event loop

# good: bridge sync<->async during migration
async def handle(line):
    loop = asyncio.get_running_loop()
    await loop.run_in_executor(None, legacy_blocking_write, line)
# from a worker thread, schedule a coroutine onto the loop:
fut = asyncio.run_coroutine_threadsafe(coro(), loop)  # returns concurrent.futures.Future
```
- **Exceptions:** For greenfield code that is async from the start, no bridging is needed. If the codebase is small enough to convert and test in one pass, the incremental machinery is unnecessary overhead.

### 80. Avoid Blocking the asyncio Event Loop to Maximize Responsiveness (2nd ed.) / Maximize Responsiveness of asyncio Event Loops with async-friendly Worker Threads (3rd ed.)  [2nd,3rd] · high
- **Rule:** Never call blocking operations (synchronous file/socket I/O, time.sleep, CPU-heavy work, blocking C calls) directly inside a coroutine; offload them to a worker thread or process via run_in_executor/asyncio.to_thread, and run with debug mode on to catch slow callbacks.
- **Why:** A single blocking call inside any coroutine stalls the entire event loop, freezing every other concurrent task on that loop, not just the current one. People assume `async def` makes a function non-blocking, but the keyword only enables suspension at await points; synchronous syscalls between awaits still hard-block. asyncio's debug mode (debug=True) logs callbacks that exceed a slow-callback threshold, surfacing the offenders.
- **Smell:** open()/file.write(), requests.get(), time.sleep(), or os.* syscalls inside a coroutine; a coroutine doing a tight CPU loop with no await; reliance on the fact that 'it's in an async function so it must be fine.'
- **Signal:**
```python
# bad: synchronous write blocks the whole loop
async def log(line):
    with open('out.log','a') as f:
        f.write(line)  # blocking syscall stalls all tasks

# good: offload to a worker thread; enable debug to detect stalls
async def log(line):
    await asyncio.to_thread(_write, line)
asyncio.run(main(), debug=True)  # logs slow callbacks
```
- **Exceptions:** Trivially fast in-memory operations between awaits are fine and not worth offloading. For CPU-bound work the GIL makes a thread pool ineffective; use a process pool (run_in_executor with ProcessPoolExecutor) instead. uvloop or specialized async drivers (aiofiles, asyncpg) remove the need to offload for their specific I/O.

### 81. Consider concurrent.futures for True Parallelism  [2nd,3rd] · medium
- **Rule:** For CPU-bound work that must run in parallel, use concurrent.futures.ProcessPoolExecutor (not threads), and only after confirming the per-task work is large enough to outweigh pickling/IPC overhead.
- **Why:** Threads cannot achieve CPU parallelism under the GIL, so a ThreadPoolExecutor gives zero speedup (often a slowdown) for compute. ProcessPoolExecutor sidesteps the GIL by running in separate interpreters, but it pays a real cost: arguments and results are pickled and copied between processes, so it only wins when each task does substantial isolated computation on small, picklable data. The common mistake is reaching for ProcessPoolExecutor on tiny tasks or on data that pickles poorly, making it slower than serial code.
- **Smell:** ThreadPoolExecutor wrapping a numeric/CPU-heavy function and expecting a speedup; ProcessPoolExecutor used for I/O-bound work (where threads/async would do); map() over millions of tiny tasks where IPC dominates; passing huge objects or unpicklable closures (lambdas, local functions) to a process pool.
- **Signal:**
```python
# bad: threads give no CPU parallelism under the GIL
with ThreadPoolExecutor() as ex:
    results = list(ex.map(crunch, inputs))  # no speedup, GIL-bound

# good: processes for true parallelism on coarse CPU tasks
from concurrent.futures import ProcessPoolExecutor
with ProcessPoolExecutor() as ex:
    results = list(ex.map(crunch, inputs))  # bypasses GIL
```
- **Exceptions:** For I/O-bound work, threads or asyncio are correct and processes are wasteful. If tasks are tiny or data is large/unpicklable, the IPC/serialization overhead can erase or reverse the gain — measure first. On free-threaded / no-GIL Python builds (PEP 703) the threads-vs-processes calculus shifts and threads may parallelize CPU work directly.

## Robustness


### 82. Take Advantage of Each Block in try/except/else/finally  [2nd,3rd] · medium
- **Rule:** Put only the operation that can raise inside try, recovery in except, the success-only continuation in else, and unconditional cleanup in finally — don't collapse them.
- **Why:** The else block runs only when try succeeds and keeps the protected region minimal, so you don't accidentally catch (and swallow) exceptions raised by follow-up code that was never meant to be guarded. finally runs whether or not an exception propagated, including during a return or re-raise, which is exactly the guarantee cleanup needs.
- **Smell:** A fat try body wrapping both the risky call and all the post-success processing, so an unrelated KeyError downstream gets caught by `except ValueError`-shaped logic, or cleanup duplicated in both the happy path and the except branch instead of living in finally.
- **Signal:**
```python
# bad: success-only work sits inside try and gets shadowed by the except
try:
    data = json.loads(raw)
    process(data)  # bug: a raise here is caught below
except ValueError:
    return None
# good
try:
    data = json.loads(raw)
except ValueError:
    return None
else:
    process(data)  # runs only on success, not guarded
```
- **Exceptions:** Trivial blocks where there's no success-only follow-up don't need an else; finally is unnecessary when there's nothing to release (no file/lock/handle).

### 83. Consider contextlib and with Statements for Reusable try/finally Behavior  [2nd,3rd] · medium
- **Rule:** When the same try/finally setup-teardown pattern repeats, encapsulate it as a context manager via @contextlib.contextmanager (or __enter__/__exit__) instead of copy-pasting the finally.
- **Why:** A context manager guarantees teardown even on exception or early return, the same as finally, but names the resource lifecycle in one place; @contextmanager's single yield separates setup from cleanup, and yielding a value lets `with ... as x` hand the caller a target. People forget the cleanup must sit after the yield in a try/finally inside the generator, or it won't run when the body raises.
- **Smell:** The identical `acquire(); try: ...; finally: release()` block duplicated across many call sites, or a contextmanager generator whose cleanup is after the yield but not wrapped in try/finally, so an exception in the with-body skips teardown.
- **Signal:**
```python
# bad: every caller repeats the finally
lock.acquire()
try:
    work()
finally:
    lock.release()
# good: define once, reuse everywhere
@contextlib.contextmanager
def held(lock):
    lock.acquire()
    try:
        yield lock
    finally:
        lock.release()
```
- **Exceptions:** For a single, one-off try/finally that isn't repeated, an inline try/finally is clearer than the ceremony of defining a manager. Objects that are already context managers (open files, locks) need no wrapper.

### 84. Make pickle Reliable with copyreg (3rd ed.: Make pickle Serialization Maintainable with copyreg)  [2nd,3rd] · high
- **Rule:** Register a copyreg pickle function for any class you persist, so unpickling supplies defaults for newly added attributes, can be versioned, and is decoupled from the class's import path.
- **Why:** Plain pickle stores a snapshot of __dict__; when you later add an attribute, old payloads deserialize missing it and crash on access, and renaming/moving the class breaks every existing pickle because the fully-qualified path is embedded in the data. A copyreg reducer that reconstructs via a stable unpickle function lets you inject default kwargs, embed an explicit version field to migrate old data, and rename the class freely since the function name (not the class path) is what's stored.
- **Smell:** Long-lived pickles of an evolving class with no copyreg registration; adding a field and seeing AttributeError on old data; renaming a pickled class and breaking deserialization of historical payloads; relying on bare __reduce__ without defaults/versioning.
- **Signal:**
```python
# bad: old pickles miss new fields, crash on access
pickle.dumps(GameState())  # later add a field -> AttributeError on load
# good: copyreg reducer supplies defaults + version
def unpickle_game(kwargs):
    kwargs.setdefault('version', 1)
    return GameState(**kwargs)
def pickle_game(g):
    return unpickle_game, (g.__dict__,)
copyreg.pickle(GameState, pickle_game)
```
- **Exceptions:** For throwaway, same-process, same-version serialization (caching, multiprocessing handoff) the overhead isn't justified. For untrusted data don't use pickle at all — it executes arbitrary code; use JSON.

### 85. assert Internal Assumptions and raise Missed Expectations  [3rd] · high
- **Rule:** Use assert only to verify conditions your own code guarantees internally; raise a real exception for anything caused by external input, callers, or runtime conditions.
- **Why:** assert is a developer-facing sanity check on invariants that should be impossible to violate if the code is correct, and crucially it is stripped out entirely when Python runs with -O, so any check that must hold at runtime cannot live in an assert. Validating untrusted or external data with assert means that validation silently vanishes in optimized deployments.
- **Smell:** assert statements that validate function arguments from callers, user input, API responses, or environment state — i.e. using assert as a substitute for input validation or error signaling.
- **Signal:**
```python
# bad: disappears under python -O, and it's external input
def withdraw(amount):
    assert amount > 0, "amount must be positive"
# good: assert internal invariants, raise on bad input
def withdraw(amount):
    if amount <= 0:
        raise ValueError("amount must be positive")
    balance = compute_balance()
    assert balance >= 0, "balance invariant violated"  # our bug if false
```
- **Exceptions:** Asserts are appropriate (and encouraged) for documenting and checking truly internal invariants — postconditions, unreachable branches, state your function itself established — where a failure means a programming bug, not a runtime condition. Tests are another legitimate home for assert.

### 86. Always Make try Blocks as Short as Possible  [3rd] · medium
- **Rule:** Put only the single statement that can raise the exception you intend to handle inside the try block; move setup, follow-up, and unrelated logic out.
- **Why:** A wide try block lets the except clause silently swallow exceptions from code you never meant to guard, masking unrelated bugs and producing handlers that fire for the wrong reason. Narrowing the try block makes the intended failure point explicit and ensures the handler only reacts to what it claims to.
- **Smell:** A try block wrapping many statements where only one realistically raises the caught exception, so the except clause could intercept errors from any of the surrounding lines.
- **Signal:**
```python
# bad: KeyError could come from either dict access
try:
    record = cache[key]
    result = process(record["field"])  # also raises KeyError
except KeyError:
    result = default
# good: guard only the lookup
try:
    record = cache[key]
except KeyError:
    record = None
result = process(record["field"]) if record else default
```
- **Exceptions:** When two adjacent operations genuinely share the same failure mode and handling, grouping them is acceptable; readability of an overly fragmented sequence of try blocks can outweigh the precision gain.

### 87. Beware of Exception Variables Disappearing  [3rd] · high
- **Rule:** Never use the except-as variable after the except block; if you need the exception later, bind it to a separate name inside the block.
- **Why:** In Python 3, the name bound by `except Exception as e` is automatically deleted when the block exits (to break a reference cycle between the exception, its traceback, and the frame), so referencing `e` afterward raises NameError. People assume the variable persists like any other assignment — it does not.
- **Smell:** Reading the exception variable outside the except suite, e.g. saving `e` for logging or re-raising after the try/except, or relying on it surviving the block.
- **Signal:**
```python
# bad: NameError after the block — e was deleted
try:
    do_work()
except ValueError as e:
    pass
print(e)  # NameError
# good: copy to a name that survives
error = None
try:
    do_work()
except ValueError as e:
    error = e
if error:
    print(error)
```
- **Exceptions:** No real exception — within the except block itself the variable is fully usable; the rule only concerns use after the block exits.

### 88. Beware of Catching the Exception Class  [3rd] · high
- **Rule:** Catch the most specific exception types you can handle; reserve a bare `except Exception` for top-level boundaries where you log and re-raise or convert, never to silently continue.
- **Why:** Catching Exception broadly intercepts errors you never anticipated — typos, attribute errors, programming bugs — and turns them into silent or generic failures, hiding defects and making debugging miserable. The danger is not catching Exception per se but doing so without re-raising or surfacing the unexpected ones.
- **Smell:** `except Exception:` (or bare `except:`) followed by `pass`, a swallowed log, or a generic fallback that hides the actual error type in normal control flow.
- **Signal:**
```python
# bad: swallows everything, hides real bugs
try:
    value = parse(data)
except Exception:
    value = None
# good: catch what you expect; let the rest propagate
try:
    value = parse(data)
except (ValueError, KeyError) as e:
    logging.warning("parse failed: %s", e)
    value = None
```
- **Exceptions:** A broad `except Exception` is legitimate at process/request boundaries (a server's request handler, a worker loop) where you must log every failure and keep running or translate it into a response — but log the full traceback and ideally re-raise or wrap rather than discard.

### 89. Understand the Difference Between Exception and BaseException  [3rd] · high
- **Rule:** Catch Exception, not BaseException, so that SystemExit, KeyboardInterrupt, and GeneratorExit propagate and let the program shut down.
- **Why:** BaseException is the root of the hierarchy and deliberately sits above the control-flow signals (SystemExit from sys.exit, KeyboardInterrupt from Ctrl-C, GeneratorExit on generator close) precisely so ordinary error handling does not trap them. Catching BaseException (or using a bare `except:`) blocks Ctrl-C and clean exits, making processes feel hung or unkillable.
- **Smell:** `except BaseException:` or bare `except:` in normal code, or a broad handler that retries/loops and thereby ignores KeyboardInterrupt and SystemExit.
- **Signal:**
```python
# bad: traps Ctrl-C and sys.exit
try:
    run_loop()
except BaseException:
    retry()
# good: only catch real errors; signals pass through
try:
    run_loop()
except Exception as e:
    logging.error("loop failed: %s", e)
    retry()
```
- **Exceptions:** Catching BaseException is justified only when you must run cleanup on any exit path and then re-raise — e.g. `except BaseException: cleanup(); raise` — never to suppress the signal. A `finally` block is usually the better tool for that.

### 90. Use traceback for Enhanced Exception Reporting  [3rd] · medium
- **Rule:** When logging or persisting a caught exception, capture the full traceback via the traceback module instead of stringifying the exception object alone.
- **Why:** Calling str() or repr() on an exception yields only the message and type, discarding the call stack that tells you where it happened; the traceback module (TracebackException, format_exc, the exception's __traceback__) preserves the frames and even lets you serialize and re-render them later, which is essential for async/queued work where the failure is reported far from where it occurred.
- **Smell:** except Exception as e: logger.error(str(e)) or storing exc as a bare string in a database/error queue, so the stack is gone by the time someone investigates.
- **Signal:**
```python
# Bad: stack lost
try:
    do_work()
except Exception as e:
    logger.error(f"failed: {e}")
# Good: full traceback preserved
import traceback
try:
    do_work()
except Exception:
    logger.error("failed:\n%s", traceback.format_exc())
```
- **Exceptions:** If you re-raise without handling, the interpreter already prints the full traceback for you; explicit capture is for cases where you swallow, cross a process/queue boundary, or need structured storage. logging.exception() / exc_info=True inside a handler also captures it idiomatically.

### 91. Consider Explicitly Chaining Exceptions to Clarify Tracebacks  [3rd] · medium
- **Rule:** When you catch one exception and raise a different one, use `raise New(...) from original` to set the cause explicitly, and use `from None` when you intend to hide the original.
- **Why:** Python implicitly chains exceptions raised inside an except block and prints 'During handling of the above exception, another occurred', but implicit chaining (__context__) reads like an accidental bug-during-cleanup; explicit `from` sets __cause__ and prints 'The above exception was the direct cause', signalling a deliberate translation. The nuance people miss: leaving it implicit leaks low-level internals (e.g. KeyError) into your API's traceback, and the fix for that leak is `from None`, not swallowing.
- **Smell:** Translating a library error to a domain error with a bare `raise DomainError(...)`, producing a confusing implicit chain, or hiding context that should have been preserved.
- **Signal:**
```python
# Bad: implicit, looks accidental
try:
    cfg[key]
except KeyError:
    raise ConfigError("missing key")
# Good: deliberate cause
except KeyError as e:
    raise ConfigError("missing key") from e
# Or deliberately suppress internals:
    raise ConfigError("missing key") from None
```
- **Exceptions:** For genuine re-raise (same exception) you don't chain at all. Use `from None` only when the underlying cause is noise to the caller (e.g. wrapping a private lookup); don't suppress causes that aid debugging.

### 92. Always Pass Resources into Generators and Have Callers Clean Them Up Outside  [3rd] · high
- **Rule:** A generator must receive already-open resources as arguments and never own their lifecycle; the caller opens and closes (via with) around the iteration.
- **Why:** A generator body is suspended between yields, so a `with` opened inside it stays open until the generator is exhausted, explicitly closed, or garbage-collected — and if the consumer stops iterating early (break, an exception, or just abandoning it), cleanup runs at an unpredictable time (GC's .close(), raising GeneratorExit) or not promptly at all. Putting the `with` in the caller guarantees the resource is released the moment the loop's scope exits, regardless of how iteration ends, and makes the generator pure/testable.
- **Smell:** `def read_rows(path): with open(path) as f: for line in f: yield parse(line)` — the file's close is hostage to whether and when the generator is fully consumed.
- **Signal:**
```python
# Bad: generator owns the file
def rows(path):
    with open(path) as f:
        for line in f:
            yield line
# Good: caller owns it
def rows(handle):
    for line in handle:
        yield line
with open(path) as f:
    for line in rows(f):
        ...
```
- **Exceptions:** Acceptable when the generator is always driven to completion in a tight scope and you accept GeneratorExit-based cleanup, but that fragility is exactly what the rule exists to avoid; prefer caller ownership by default.

### 93. Never Set __debug__ to False  [3rd] · high
- **Rule:** Don't run production code under -O/-OO/PYTHONOPTIMIZE (which sets __debug__ False), and never depend on assert statements for behavior that must execute.
- **Why:** Optimized mode strips every assert and every `if __debug__:` block from the bytecode entirely, so any validation, side effect, or control flow you placed in an assert silently vanishes — turning a checked invariant into an unchecked one. The deeper trap: the negligible speed win from -O almost never justifies the risk of disabling assertions your code (or its dependencies) may rely on, so treat assert strictly as a developer sanity check, never as input/permission/state validation.
- **Smell:** `assert user.is_admin, "forbidden"` or `assert resp.status == 200` guarding real behavior, plus a deploy script invoking `python -O app.py`.
- **Signal:**
```python
# Bad: vanishes under -O
assert token_is_valid(token)
process(request)
# Good: explicit runtime check
if not token_is_valid(token):
    raise PermissionError("invalid token")
process(request)
```
- **Exceptions:** assert is fine and idiomatic for internal invariants and tests where you accept it may be compiled out. The rule targets relying on assertions/__debug__ blocks for required runtime behavior and enabling -O in production.

### 94. Avoid exec and eval Unless You're Building a Developer Tool  [3rd] · high
- **Rule:** Don't reach for exec/eval to assemble logic at runtime; use a dict, getattr, closures, or proper data structures — reserve dynamic execution for genuine developer tooling (REPLs, debuggers, templating engines).
- **Why:** exec/eval defeat static analysis, linters, type checkers, and IDE navigation, are slow to compile each call, and are a code-injection vector the instant any of the evaluated string derives from external input. Most uses are reinventing dispatch that a dict-of-callables or getattr does more safely, faster, and legibly; the legitimate niche is tools whose entire purpose is running user-supplied code.
- **Smell:** `exec(f"{name} = {value}")` to create variables, or `eval(f"obj.{attr}")` / `eval(user_expr)` for dynamic dispatch or to parse data.
- **Signal:**
```python
# Bad: dynamic, unanalyzable, injectable
handler = eval(f"handle_{action}")
handler(payload)
# Good: explicit dispatch table
HANDLERS = {"add": handle_add, "remove": handle_remove}
HANDLERS[action](payload)
# data parsing: ast.literal_eval / json.loads, never eval
```
- **Exceptions:** Justified when the program's purpose is executing user/developer code (interactive shells, notebooks, plugin/macro systems, code generators). Even then, never eval untrusted input — prefer ast.literal_eval for data and sandboxed compilation for code.

### 95. Make pickle Reliable with copyreg  [2nd] · medium
- **Rule:** For any class whose instances are pickled and outlive a single run, register a copyreg reduction function with default arguments and an embedded version number rather than relying on default pickling.
- **Why:** Default pickle stores only __dict__, so when you later add an attribute, old pickles unpickle with that attribute missing and break code that assumes it; when you rename or remove a class, unpickling fails to import. copyreg lets you control the constructor call (so new fields get defaults) and stamp a version so __setstate__ can migrate old payloads. People assume pickle is a stable format — it is not across class evolution, and the breakage is silent until an old payload is loaded.
- **Smell:** pickle.dumps(obj) of an evolving domain class with no copyreg registration; adding a new __init__ field to a class that has existing pickled instances on disk/in a queue; renaming/moving a pickled class without a stability shim.
- **Signal:**
```python
# Bad: add a field later -> old pickles miss it
class GameState: ...
pickle.dumps(GameState())
# Good: copyreg controls construction + version
def pickle_game(s): return unpickle_game, (s.__dict__,)
def unpickle_game(kwargs):
    kwargs.setdefault('version', 1)
    return GameState(**kwargs)
copyreg.pickle(GameState, pickle_game)
```
- **Exceptions:** Don't bother for short-lived in-process pickling (e.g., multiprocessing args) where producer and consumer share the exact class definition. And never use pickle at all for untrusted input or cross-language/long-term interchange — prefer JSON/protobuf; copyreg only hardens the trusted-pickle case.

## Performance


### 96. Profile Before Optimizing  [2nd,3rd] · medium
- **Rule:** Identify hot paths with cProfile (wrapped in a Profile object) before changing any code for speed; never optimize on a hunch.
- **Why:** Python's runtime cost is unintuitive — interpreter overhead, hidden O(n) builtins, and dynamic dispatch mean the bottleneck is rarely where you guess. Use cProfile, not the pure-Python profile module (it adds large overhead that distorts results), and use Stats with sort_stats plus print_callers/print_callees to see whether a slow function is itself slow or merely called by something slow.
- **Smell:** A PR that rewrites a loop into a 'clever' comprehension, adds caching, or swaps data structures 'for performance' with no profiler output, benchmark, or timing in the description.
- **Signal:**
```python
# Bad: optimize by guessing
# Good: measure first
from cProfile import Profile
from pstats import Stats
profiler = Profile()
profiler.runcall(lambda: run_workload(data))
stats = Stats(profiler)
stats.sort_stats('cumulative').print_stats()
```
- **Exceptions:** Trivial, obviously-quadratic constructs (e.g. repeated string concatenation in a loop, list membership checks in a hot path) can be fixed on sight without a formal profile; profiling matters most when the cause is non-obvious.

### 97. Consider memoryview and bytearray for Zero-Copy Interactions with bytes  [2nd,3rd] · medium
- **Rule:** For slicing or receiving large binary buffers, wrap bytes/bytearray in a memoryview to slice without copying, and read I/O directly into a preallocated bytearray via recv_into/readinto.
- **Why:** Slicing a bytes object allocates and copies the sliced region — quadratic cost when splicing/streaming large payloads. Slicing a memoryview returns another memoryview over the same memory with zero copy, and a memoryview over a bytearray supports slice *assignment* to write into a region in place. Pairing a preallocated bytearray with socket.recv_into / file.readinto avoids allocating a fresh buffer per read. The footgun: memoryview holds a live reference to its buffer, so you cannot resize the underlying bytearray while a view is exported (raises BufferError), and views over freed/closed buffers are unsafe.
- **Smell:** Hot-path code doing `data = data[offset:offset+size]` on large bytes to carve chunks, or `chunk = sock.recv(n)` then concatenating chunks with `+`, instead of reading into a fixed buffer.
- **Signal:**
```python
# Bad: each slice copies; concatenation re-copies
chunk = data[1024:2048]
# Good: zero-copy view + in-place receive
buf = bytearray(4096)
view = memoryview(buf)
n = sock.recv_into(view[1024:])  # writes straight into buf, no alloc
slice_view = view[1024:1024 + n]  # no copy
```
- **Exceptions:** For small buffers the copy cost is negligible and plain bytes slicing is clearer. memoryview only helps for objects supporting the buffer protocol; and the added lifetime/resize constraints aren't worth it unless profiling shows copying or per-read allocation is the bottleneck.

### 98. Optimize Performance-Critical Code Using timeit Microbenchmarks  [3rd] · medium
- **Rule:** Justify every micro-optimization with a timeit measurement on representative inputs, not intuition.
- **Why:** Python's runtime cost is non-obvious (attribute lookups, bound-method binding, interpreter dispatch dominate in surprising places), so guessed hot spots are usually wrong; timeit also runs many iterations and reports the best to suppress OS/GC noise that a single time.time() delta would conflate. People misuse it by timing throwaway constant-folded expressions, by including setup work inside the timed block, or by extrapolating a microbenchmark to whole-program behavior where it is irrelevant.
- **Smell:** A PR claims 'this is faster' / rewrites readable code into a clever one-liner with no benchmark, or measures with a single wall-clock subtraction around one call.
- **Signal:**
```python
# bad: one-shot wall clock, includes setup, no repetition
start = time.time()
data = [x**2 for x in range(10000)]  # creation timed with the work
print(time.time() - start)
# good: isolate the operation, amortize over many runs
import timeit
t = timeit.timeit("[x*x for x in data]", setup="data=list(range(10000))", number=1000)
print(min(timeit.repeat("[x*x for x in data]", setup="data=list(range(10000))", repeat=5, number=1000)))
```
- **Exceptions:** Skip microbenchmarking entirely when the code is not on a hot path; whole-program profiling (cProfile) should drive where you bother to microbenchmark in the first place.

### 99. Know When and How to Replace Python with Another Programming Language  [3rd] · medium
- **Rule:** Reach for another language only after profiling proves a CPU-bound hot spot that algorithmic and Python-level fixes cannot resolve, and then rewrite the smallest possible kernel.
- **Why:** Most slowness is algorithmic, I/O-bound, or fixable with better data structures / stdlib (numpy, built-in C functions) — switching languages there adds build complexity, FFI marshalling cost, and a polyglot maintenance burden for no gain. The right move is surgical: isolate the proven bottleneck behind a clean interface and rewrite just that, keeping orchestration in Python.
- **Smell:** A proposal to 'port the service to Go/Rust for speed' with no profiler output, or a C extension introduced to speed up code that is actually waiting on network/disk.
- **Signal:**
```python
# bad: rewrite whole module in C because it 'feels slow'
# good: profile first, then replace only the kernel
import cProfile
cProfile.run("run_pipeline(data)")  # find the real hot function
# -> only hot_inner_loop() is 90% of time; rewrite THAT in C/Rust,
#    keep the rest in Python and call across the boundary
```
- **Exceptions:** Genuinely CPU-bound numerical/tight-loop work that resists vectorization, or hard real-time/latency floors the interpreter cannot meet, legitimately warrant a native rewrite of the kernel.

### 100. Consider ctypes to Rapidly Integrate with Native Libraries  [3rd] · high
- **Rule:** Use ctypes for quick pure-Python access to an existing shared library, but declare argtypes/restype explicitly and never let it cross a GIL-bound CPU hot loop.
- **Why:** ctypes needs no compilation or build step, which makes it ideal for prototyping or calling a stable C ABI; but if you omit argtypes/restype, arguments default to int-sized and pointers get truncated, silently corrupting memory or crashing. Per-call marshalling overhead is high, so calling a ctypes function inside a tight Python loop is often slower than the Python it replaced.
- **Smell:** A ctypes.CDLL function called without setting argtypes/restype, passing a Python str directly where char* is expected, or invoked millions of times in a loop.
- **Signal:**
```python
import ctypes
lib = ctypes.CDLL("./libmath.so")
# bad: no signatures -> 64-bit pointer/double truncated to int
result = lib.scale(buf, 3.14)
# good: declare the ABI, marshal once
lib.scale.argtypes = [ctypes.POINTER(ctypes.c_double), ctypes.c_double]
lib.scale.restype = ctypes.c_int
result = lib.scale(buf, ctypes.c_double(3.14))
```
- **Exceptions:** For a library you control or one needing complex type handling, exception propagation, or per-call speed, a proper extension module (Item 96) or cffi is the better long-term choice.

### 101. Consider Extension Modules to Maximize Performance and Ergonomics  [3rd] · medium
- **Rule:** When native integration must be fast, safe, and Pythonic, build a real extension module rather than gluing with ctypes — and prefer a tool (Cython/pybind11) over hand-written CPython C-API.
- **Why:** Extension modules let you release the GIL around heavy native work (enabling true parallelism), raise real Python exceptions, and expose idiomatic objects — things ctypes cannot do cleanly. The trap is hand-writing CPython C-API code: manual reference counting (Py_INCREF/Py_DECREF) is the classic source of leaks and crashes, so binding generators that manage refcounts for you are strongly preferred.
- **Smell:** Hand-rolled C-API code with manual INCREF/DECREF in review, or a build that never releases the GIL during a long native compute call so threads can't actually parallelize.
- **Signal:**
```python
// bad: hand-managed refcounts, GIL held during heavy work
PyObject *r = PyLong_FromLong(compute());  // leak risk on error paths
// good: let a binding tool manage refs + release the GIL
// (pybind11) py::gil_scoped_release nogil; heavy_compute(buf, n);
// or Cython: with nogil: heavy_compute(buf, n)
```
- **Exceptions:** Skip the build-system and ABI-versioning overhead of an extension module for one-off scripts or when ctypes/cffi already calls a stable external library adequately.

### 102. Lazy-Load Modules with Dynamic Imports to Reduce Startup Time  [3rd] · medium
- **Rule:** Defer expensive or rarely-used imports to the call site (function-local import or module-level __getattr__) instead of importing them eagerly at module top, but only when the import measurably hurts startup.
- **Why:** A top-level import runs the imported module's full initialization the moment the importing module is first loaded, so a CLI or short-lived process pays the cost of every heavy dependency (numpy, requests, big internal packages) even on code paths that never touch them. Deferring the import moves that cost to first use, but people misjudge the tradeoff: lazy imports push ImportError and module-init side effects from a deterministic startup failure to a runtime failure deep inside a request, and they confuse type checkers and IDEs. The win only materializes when the module is genuinely on a cold path; sprinkling function-local imports everywhere just adds per-call lookup overhead and hides the dependency graph.
- **Smell:** A heavyweight or optional dependency imported at the top of a module that is needed by only one rarely-called function; or, conversely, a hot-loop function that re-imports a module on every call when a top-level import would be fine; or scattered inline imports with no measurement justifying them.
- **Signal:**
```python
# Bad: pays pandas import cost at module load, even if export() is never called
import pandas as pd
def export(rows):
    return pd.DataFrame(rows).to_csv()

# Good: cost paid only on first export() call; import is cached by sys.modules
def export(rows):
    import pandas as pd  # heavy, cold path only
    return pd.DataFrame(rows).to_csv()

# Good (package API): defer submodule load via PEP 562 module __getattr__
def __getattr__(name):
    if name == "ml":
        import importlib
        return importlib.import_module("myapp.ml")
    raise AttributeError(name)
```
- **Exceptions:** Do not lazy-load modules that are used on the common path or in hot loops — the per-call import lookup and loss of fail-fast startup validation outweigh any savings. Keep imports eager when you want an unavailable/broken dependency to fail loudly at startup rather than mid-request. For static typing, still declare the import under `if TYPE_CHECKING:` so checkers and IDEs resolve the name. In threaded code, rely on the import system's own lock (re-importing in a function is safe) rather than rolling a custom cached loader without synchronization.

## Data Structures and Algorithms


### 103. Sort by Complex Criteria Using the key Parameter  [2nd,2nd (Item 14, Ch.2 Lists and Dictionaries),3rd,3rd (Item 100, Ch.12 Data Structures and Algorithms)] · medium
- **Rule:** Pass a key function to sort()/sorted() for derived or multi-field ordering rather than mutating the data or chaining manual comparisons.
- **Why:** sort is stable, so multi-criterion ordering can be expressed either as one key returning a tuple (with - to reverse a single numeric field) or as multiple sort passes from least-to-most significant key relying on that stability; people get this backwards (passes run in the wrong order) or try to negate non-numeric keys with -, which fails. The reverse= flag flips the entire sort, not one field.
- **Smell:** Decorating/undecorating by hand, building throwaway columns to sort on, calling sorted without key and post-processing, or attempting -key on a string to reverse just that field.
- **Signal:**
```python
# bad: multiple ad-hoc structures / wrong ordering intent
items.sort()
items.reverse()  # not what multi-field needs
# good: tuple key, numeric field reversed with negation
items.sort(key=lambda x: (x.group, -x.weight))
# good: stable multi-pass when you can't negate (e.g. str)
items.sort(key=lambda x: x.name)
items.sort(key=lambda x: x.weight, reverse=True)
```
- **Exceptions:** For a single simple field, key=attrgetter('x') or operator.itemgetter is cleaner than a lambda. Mixing ascending and descending across non-numeric fields can't be done in one tuple key — fall back to the stable multi-pass technique.

### 104. Use datetime Instead of time for Local Clocks  [2nd,2nd (Item 67, Ch.8 Robustness and Performance),3rd,3rd (Item 105, Ch.12 Data Structures and Algorithms)] · high
- **Rule:** Convert between time zones with timezone-aware datetime objects and a real tz database (zoneinfo / ZoneInfo), never with the platform-dependent time module functions.
- **Why:** The time module's behavior depends on the host OS C library and is unreliable for anything outside the machine's own locale, while datetime alone only knows UTC — correct conversions require a tz-database source. Keep internal values in UTC-aware datetimes and convert to local only at display; never build aware datetimes by passing a pytz/legacy zone straight into the constructor, which silently applies an 1800s LMT offset instead of `localize()`/ZoneInfo.
- **Smell:** Round-tripping through `time.mktime`/`time.localtime`/`strptime` to shift zones; naive datetimes (no tzinfo) treated as if they were UTC or local interchangeably; `datetime(..., tzinfo=pytz.timezone('US/Eastern'))` producing a bizarre offset like -04:56.
- **Signal:**
```python
# bad: platform-dependent, breaks for non-host zones
import time
t = time.mktime(time.strptime('2026-06-22 12:00', '%Y-%m-%d %H:%M'))
# good: aware datetime + tz database
from datetime import datetime, timezone
from zoneinfo import ZoneInfo
utc = datetime(2026, 6, 22, 12, 0, tzinfo=timezone.utc)
local = utc.astimezone(ZoneInfo('US/Eastern'))
```
- **Exceptions:** On Python <3.9 use backports.zoneinfo (or pytz with explicit `.localize()`). Pure monotonic interval timing legitimately uses `time.monotonic`, not datetime.

### 105. Use decimal When Precision Is Paramount  [2nd,2nd (Item 69, Ch.8 Robustness and Performance),3rd,3rd (Item 106, Ch.12 Data Structures and Algorithms)] · high
- **Rule:** Use decimal.Decimal for money and other exact base-10 quantities and for controlled rounding; keep float only for approximate/scientific math.
- **Why:** IEEE-754 binary float cannot represent values like 0.1 exactly, so sums drift and naive `round()` gives surprising results — unacceptable for currency where fractions of a cent accumulate. Decimal carries a chosen precision and an explicit rounding mode (e.g. ROUND_HALF_UP via `quantize`), and you must construct it from a string (or int), not a float, or you just inherit the float's error.
- **Smell:** Doing monetary arithmetic in float, comparing money with `==`, building Decimal from a float literal like `Decimal(1.1)`, or rounding currency with the builtin `round` and banker's-rounding surprises.
- **Signal:**
```python
# bad: float drift + Decimal seeded from a float keeps the error
rate = 1.45 * 222 / 60  # 5.364999999...
d = Decimal(1.1)  # Decimal('1.1000000000000000888...')
# good: construct from str, quantize with explicit rounding
from decimal import Decimal, ROUND_UP
cost = (Decimal('1.45') * 222 / 60).quantize(Decimal('0.01'), rounding=ROUND_UP)
```
- **Exceptions:** For irrational/transcendental math or large-scale numeric/scientific work, float (or the faster Fraction for exact ratios) is appropriate; Decimal is slower and still can't represent values like 1/3 exactly.

### 106. Prefer deque for Producer-Consumer Queues  [2nd,2nd (Item 71, Ch.8 Robustness and Performance),3rd,3rd (Item 103, Ch.12 Data Structures and Algorithms)] · high
- **Rule:** Use collections.deque with append/popleft for FIFO queues; never use list.pop(0) or list.insert(0, x) for queue semantics.
- **Why:** A list is contiguous, so removing or inserting at the front is O(n) — every other element shifts. This stays invisible until the queue grows, then total work degrades to O(n^2) and a 'working' pipeline silently falls off a cliff under load. deque gives O(1) at both ends. Note: deque solves the single-threaded efficiency problem, not blocking/backpressure — reach for queue.Queue when you need blocking get/put, maxsize, or join across threads.
- **Smell:** `queue.pop(0)` or `queue.insert(0, item)` inside a hot loop; a list named `queue`/`buffer` consumed from the front.
- **Signal:**
```python
# Bad: O(n) per dequeue -> O(n^2) overall
queue = []
queue.append(item)
x = queue.pop(0)
# Good: O(1) both ends
from collections import deque
queue = deque()
queue.append(item)
x = queue.popleft()
```
- **Exceptions:** Lists used as LIFO stacks (append/pop from the end) are already O(1) — no change needed. For cross-thread producer/consumer with backpressure or blocking semantics, use queue.Queue instead of a raw deque.

### 107. Consider Searching Sorted Sequences with bisect  [2nd,2nd (Item 72, Ch.8 Robustness and Performance),3rd,3rd (Item 102, Ch.12 Data Structures and Algorithms)] · medium
- **Rule:** For membership or position lookups in a large already-sorted list, use bisect_left instead of linear `in`/index scans.
- **Why:** `list.index()` and `x in list` are O(n) linear scans; on a sorted sequence bisect does a binary search in O(log n), which is dramatically faster for large data (microseconds vs. milliseconds). The footgun is exactness: bisect_left returns the *insertion point*, so you must verify `i < len(data) and data[i] == target` before concluding the element is actually present — the index alone does not mean a match.
- **Smell:** `if x in big_sorted_list:` or `big_sorted_list.index(x)` in a loop over a list that is known to be sorted.
- **Signal:**
```python
# Bad: O(n) scan on sorted data
i = data.index(target)  # raises if absent; linear
# Good: O(log n) binary search
from bisect import bisect_left
i = bisect_left(data, target)
found = i < len(data) and data[i] == target
```
- **Exceptions:** Only valid when the sequence is kept sorted — maintaining sort order on inserts is itself O(n), so if you mutate frequently and rarely search, a set/dict for membership or keeping it unsorted may win. For pure membership (no ordering/range needs) a set's O(1) lookup beats bisect.

### 108. Know How to Use heapq for Priority Queues  [2nd,2nd (Item 73, Ch.8 Robustness and Performance),3rd,3rd (Item 104, Ch.12 Data Structures and Algorithms)] · medium
- **Rule:** Implement priority queues with heapq (heappush/heappop) over a list; do not re-sort a list on every push/pop.
- **Why:** heapq gives O(log n) push and pop of the smallest item, vs. O(n log n) to re-sort or O(n) to scan for the min each time. Two gotchas: (1) it's a min-heap with no max variant — negate priorities or use a key wrapper for max/custom order; (2) tuples are compared element-by-element, so if two priorities tie Python compares the *next* field, which fails if that field is unorderable — include a unique monotonic tiebreaker (e.g. a counter) before the payload.
- **Smell:** `items.sort(); x = items.pop(0)` repeated in a loop, or scanning the whole list with `min()` each iteration to find the next-highest-priority item.
- **Signal:**
```python
# Bad: re-sort every pop -> O(n log n) each
items.sort(key=lambda i: i.priority)
next_item = items.pop(0)
# Good: O(log n), with counter tiebreaker to avoid comparing payloads
import heapq, itertools
counter = itertools.count()
heapq.heappush(heap, (priority, next(counter), item))
_, _, item = heapq.heappop(heap)
```
- **Exceptions:** For tiny or rarely-mutated collections the constant factors make a plain sorted list simpler and just as fast; if you need removal of arbitrary elements or decrease-key, raw heapq is awkward and a dedicated structure or lazy-deletion scheme is warranted.

### 109. Make pickle Serialization Maintainable with copyreg  [2nd (Item 68, Ch.8 Robustness and Performance, titled 'Make pickle Reliable with copyreg'),3rd (Item 107, Ch.12 Data Structures and Algorithms, titled 'Make pickle Serialization Maintainable with copyreg')] · medium
- **Rule:** When pickling your own classes, register a copyreg pickle function instead of relying on default pickling, so you control default values for new attributes, class versioning, and the stored import path.
- **Why:** Default pickle stores only the instance __dict__ that existed at dump time, so unpickling an old payload after you add a field yields an object missing that attribute (AttributeError later, not at load), and renaming/moving the class breaks every existing pickle because the qualified import path is baked into the data. A copyreg reconstructor lets you (a) supply defaults for attributes added after the data was written, (b) embed a version number so old states migrate forward, and (c) decouple the serialized form from the class's current module path.
- **Smell:** pickle.dumps/loads on evolving domain classes with no copyreg.pickle registration, no __getstate__/__setstate__, and no version field — then adding/removing fields or moving the class to a new module.
- **Signal:**
```python
import copyreg
class GameState:
    def __init__(self, level=0, lives=4, points=0):  # points added later
        self.level, self.lives, self.points = level, lives, points
def pickle_game(s):
    return unpickle_game, (s.__dict__,)
def unpickle_game(kwargs):
    kwargs.setdefault('points', 0)  # default for fields old pickles lack
    return GameState(**kwargs)
copyreg.pickle(GameState, pickle_game)
```
- **Exceptions:** Skip this for transient/same-process serialization or short-lived caches where the class never evolves. Never use pickle at all for untrusted input (arbitrary code execution) — copyreg makes it maintainable, not safe; use JSON/protobuf for data crossing trust or long-term storage boundaries.

## Testing and Debugging


### 110. Use repr Strings for Debugging Output  [2nd] · medium
- **Rule:** In debugging/log output, render values with repr (f-string !r, %r, or repr()) — never bare str — and give your own classes a useful __repr__.
- **Why:** str() of '5' and 5 print identically, hiding type bugs; repr disambiguates by showing quotes, types, and structure. The default object __repr__ (<Foo object at 0x...>) is useless, so for dynamic inspection prefer obj.__dict__ over a hand-written __repr__ that can drift out of sync.
- **Smell:** print(f'value={value}') or logging the bare object; print('got', x) where x could be a str or int and you can't tell which from the output; a class with no __repr__ being logged in a loop.
- **Signal:**
```python
# bad: type ambiguity
print(f'count={count}')        # count=5  (int? str '5'?)
# good
print(f'count={count!r}')      # count=5  vs count='5'
class Point:
    def __repr__(self):
        return f'Point(x={self.x!r}, y={self.y!r})'
```
- **Exceptions:** User-facing output (CLI messages, rendered UI) wants str/__str__, not repr. For one-off interactive inspection of an instance, print(obj.__dict__) beats maintaining a __repr__.

### 111. Verify Related Behaviors in TestCase Subclasses  [2nd,3rd] · medium
- **Rule:** Group related tests as methods on a unittest.TestCase subclass, assert with the specific assert helpers (assertEqual, assertRaises, etc.), and use subTest for data-driven cases instead of bare assert or a single mega-test.
- **Why:** The typed assert helpers print both operands and the diff on failure, where bare assert just says the boolean was False. One behavior per test method means a failure localizes the defect; folding many checks into one method hides which input broke and stops at the first failure. subTest keeps a parametrized loop reporting every failing case rather than aborting on the first.
- **Smell:** def test_all(self): assert f(1)==2; assert f(2)==4 — bare asserts, multiple unrelated behaviors in one method, or a for-loop of assertions with no subTest so only the first failure is reported.
- **Signal:**
```python
# bad
def test_math(self):
    assert add(1, 2) == 3
# good
def test_add(self):
    self.assertEqual(add(1, 2), 3)
    for a, b, want in CASES:
        with self.subTest(a=a, b=b):
            self.assertEqual(add(a, b), want)
```
- **Exceptions:** pytest's plain-assert rewriting gives rich failure output without the helpers, and @pytest.mark.parametrize replaces subTest — so on a pytest codebase bare assert is idiomatic, not a smell.

### 112. Prefer Integration Tests over Unit Tests  [3rd] · high
- **Rule:** Maintain integration tests that exercise real wired-together behavior in addition to unit tests; mocked unit tests can be green while the integrated system is broken, so both are needed — integration tests cover the inter-module seams, not replace fast unit tests.
- **Why:** A suite that is all unit tests with mocked collaborators can be fully green while the wired-together system is broken — mocks encode assumptions about dependencies that the real dependencies may violate (signature drift, contract changes). Integration tests catch the seams between modules, which is where most real defects live. The point is balance: keep fast units, but don't let mocks substitute for ever verifying the real interaction.
- **Smell:** Every test patches all collaborators so nothing real is invoked; no test starts the app/DB/HTTP layer together; refactoring internal call signatures breaks production but no test fails because mocks were configured to the old shape.
- **Signal:**
```python
# over-mocked unit test passes even if DB schema is wrong
with patch('app.db.query', return_value=ROWS):
    assert handler() == EXPECTED
# integration test: real (test) DB, real wiring
def test_handler_end_to_end(tmp_db):
    seed(tmp_db, ROWS)
    assert handler(db=tmp_db) == EXPECTED
```
- **Exceptions:** Pure functions and algorithmic/edge-case logic are best covered by fast units. Integration tests are slower and flakier; gate the slow/external ones (network, real services) behind markers so the fast suite stays fast.

### 113. Isolate Tests from Each Other with setUp, tearDown, setUpModule, and tearDownModule  [2nd,3rd] · high
- **Rule:** Build per-test fixtures in setUp and release them in tearDown so tests can't leak state into each other; reserve setUpModule/tearDownModule for expensive shared resources, knowing they run once per module, not per test.
- **Why:** setUp/tearDown run around every test method, guaranteeing a fresh, isolated environment so test order and one test's mutations never affect another. setUpModule runs exactly once for the whole module — anything mutable created there is shared across all tests and reintroduces the coupling you were avoiding; it's only for costly read-mostly setup (a test DB, a temp dir). Putting per-test state in module scope is the classic order-dependent-flakiness bug.
- **Smell:** Constructing fixtures inline at the top of each test method (duplication, no cleanup); module-level globals mutated by tests; per-test mutable state created in setUpModule so tests pass alone but fail when run together or reordered.
- **Signal:**
```python
# bad: shared mutable state, leaks across tests
def setUpModule():
    global CACHE; CACHE = {}
# good
class T(unittest.TestCase):
    def setUp(self):
        self.dir = TemporaryDirectory()
    def tearDown(self):
        self.dir.cleanup()
```
- **Exceptions:** If a resource is expensive and tests only read from it, module/class scope is the right tradeoff for speed. pytest fixtures with scope= are the idiomatic equivalent in a pytest codebase.

### 114. Use Mocks to Test Code with Complex Dependencies  [2nd,3rd] · high
- **Rule:** Mock hard-to-control dependencies with unittest.mock, but constrain them with spec/autospec, patch in the namespace where the name is looked up, and assert the calls — don't use bare unconstrained Mocks.
- **Why:** A bare Mock() accepts any attribute and any call, so a test keeps passing after the real API's signature or method name changes — the mock silently diverges from reality. spec=/create_autospec/autospec=True make the mock reject attributes and call signatures the real object wouldn't allow, restoring that safety. patch must target where the dependency is referenced (the consuming module), not where it's defined, or the patch is a no-op. Designing for mockability (dependency injection, keyword args for collaborators) is usually cleaner than reaching for patch.
- **Smell:** Mock() with no spec; patch('library.module.func') when the code did from library.module import func (wrong patch target); setting return_value but never calling assert_called_with, so the mock is never verified.
- **Signal:**
```python
# bad: unconstrained + wrong patch location
m = Mock(); m.fetchx()        # typo never caught
# good
with patch('app.service.db_client', autospec=True) as db:
    db.query.return_value = ROWS
    run()
    db.query.assert_called_once_with('SELECT 1')
```
- **Exceptions:** Cheap, deterministic dependencies (pure functions, in-memory structures) need no mock — use the real thing. Mocks encode assumptions, so back them with at least one integration test (Item 109) that runs the real collaborator.

### 115. Encapsulate Dependencies to Facilitate Mocking and Testing  [2nd,3rd] · high
- **Rule:** Inject collaborators (DB clients, clocks, network handles) through constructor/function parameters or a wrapper object so tests can substitute test doubles without patching module internals.
- **Why:** The mistake people make is patching at the import site with mock.patch on deep module paths, which couples every test to the implementation's import structure and breaks when code is refactored. Encapsulating the dependency behind a passed-in object (or a small wrapper class) means the seam is an explicit parameter, so tests pass a Mock directly and the production wiring stays in one place. unittest.mock's keyword_arg passing and Mock spec also become straightforward once the dependency is an argument rather than a hidden global.
- **Smell:** Functions that reach out to module-level globals or do `import db; db.query(...)` inline, forcing tests to use long `@patch('pkg.module.db')` decorators; constructors that instantiate their own clients internally with no override hook.
- **Signal:**
```python
# bad: hidden dependency, test must patch import path
def get_user(uid):
    return database.query(uid)  # global; tests do @patch('mod.database')

# good: dependency is an injected seam
def get_user(uid, db=None):
    db = db or default_database()
    return db.query(uid)  # test passes db=Mock(spec=Database)
```
- **Exceptions:** For trivial pure functions with no external collaborators there is nothing to inject. Over-parameterizing every leaf function just for testing adds noise; encapsulate at the boundary that actually crosses I/O, not every call.

### 116. Consider Interactive Debugging with pdb  [2nd,3rd] · medium
- **Rule:** Reach for breakpoint() / pdb to inspect live program state at a failure point instead of scattering print statements or guessing.
- **Why:** People conflate logging with debugging and litter code with prints they later forget to remove. The nuance: in modern Python use the builtin `breakpoint()` (not `import pdb; pdb.set_trace()`), because it honors PYTHONBREAKPOINT and can be globally disabled in production; and post-mortem debugging (`python -m pdb`, or `pdb.pm()` after an exception) lets you inspect the stack of an already-failed run rather than re-instrumenting and re-running. Breakpoints must never survive into committed code.
- **Smell:** Committed `import pdb; pdb.set_trace()` or stray `print(repr(x))` debugging lines left in the diff; re-running a script many times adding prints rather than dropping a single breakpoint.
- **Signal:**
```python
# bad: hard-coded, can't be disabled, often committed
import pdb; pdb.set_trace()

# good: builtin hook, honors PYTHONBREAKPOINT, removed before commit
breakpoint()
# post-mortem on a crash without editing code:
#   python -m pdb script.py   (then `c`, inspect after exception)
```
- **Exceptions:** In CI, headless, or production paths interactive pdb hangs the process — use logging/observability there. For reproducible regressions a failing test is better than a manual debugging session.

### 117. Use tracemalloc to Understand Memory Usage and Leaks  [2nd,3rd] · medium
- **Rule:** Diagnose memory growth and leaks with tracemalloc snapshots/diffs that attribute allocations to source lines, not with gc object counts or guesswork.
- **Why:** The common dead end is calling gc.get_objects() or counting types, which tells you *what* leaked but not *where* it was allocated. tracemalloc captures the allocation traceback, so comparing two snapshots (`snapshot2.compare_to(snapshot1, 'lineno')`) pinpoints the exact file:line responsible for retained growth. It must be enabled before the allocations happen (tracemalloc.start()), and it adds overhead, so it is a diagnostic tool, not an always-on production setting.
- **Smell:** Leak investigations relying on `len(gc.get_objects())` deltas or `sys.getsizeof` spot-checks; trying to find a leak by reading code instead of capturing allocation tracebacks.
- **Signal:**
```python
# bad: tells you a count grew, not where
before = len(gc.get_objects()); run(); after = len(gc.get_objects())

# good: attribute growth to source lines
import tracemalloc
tracemalloc.start()
s1 = tracemalloc.take_snapshot(); run(); s2 = tracemalloc.take_snapshot()
for stat in s2.compare_to(s1, 'lineno')[:10]:
    print(stat)  # shows file:line and size delta
```
- **Exceptions:** For C-extension or native allocations tracemalloc only sees the Python side; pair with OS-level tools (valgrind, RSS monitoring). Don't leave tracing enabled in hot production paths due to overhead.

## Collaboration


### 118. Know Where to Find Community-Built Modules  [2nd,3rd] · medium
- **Rule:** Prefer a vetted package from PyPI (installed via pip) over hand-rolling a solution to a solved, general problem.
- **Why:** The standard library plus PyPI cover an enormous surface; reinventing parsing, retries, date math, or HTTP wastes effort and ships bugs the community already fixed. The nuance people miss is that adopting a dependency is a tradeoff, not a free win — vet maintenance health, license, transitive deps, and supply-chain risk before adding it.
- **Smell:** A homegrown CSV/JSON/datetime/HTTP/retry helper reimplemented inline when a mature, maintained library exists; or pulling a heavyweight dependency for a three-line task.
- **Signal:**
```python
# bad: hand-rolled HTTP with sockets / manual retry loop
import urllib.request
# fragile retry, no timeout, no backoff

# good: use a vetted package
import requests
resp = requests.get(url, timeout=5)
resp.raise_for_status()
```
- **Exceptions:** Avoid dependencies for trivial one-liners, in constrained/security-audited environments where every transitive dep is a liability, or when the candidate package is unmaintained. The stdlib is the first place to look before PyPI.

### 119. Use Virtual Environments for Isolated and Reproducible Dependencies  [2nd,3rd] · high
- **Rule:** Install project dependencies into a per-project virtual environment and pin them with a transitively-complete, version-locked manifest.
- **Why:** Installing into the system/global interpreter causes dependency conflicts between projects and makes builds irreproducible. The detail people get wrong: a top-level `requirements.txt` listing only direct deps is not reproducible — transitive versions drift, so you must freeze the full closure (pip freeze, a lock file, or a tool like uv/poetry) and commit it.
- **Smell:** `sudo pip install` into the global interpreter, a requirements file listing only direct dependencies without pinned versions, or no manifest at all so the env can't be rebuilt on another machine.
- **Signal:**
```python
# bad: global install, unpinned, partial
# sudo pip install flask requests

# good: isolated env + full pinned closure
python -m venv .venv && source .venv/bin/activate
pip install flask requests
pip freeze > requirements.txt   # captures ALL transitive versions
# rebuild elsewhere: pip install -r requirements.txt
```
- **Exceptions:** Throwaway one-off scripts or ephemeral CI containers that are themselves the isolation boundary may skip an explicit venv; pip freeze can over-pin platform-specific wheels, so a lock tool is preferable for cross-platform projects.

### 120. Write Docstrings for Every Function, Class, and Module  [2nd,3rd] · medium
- **Rule:** Give every module, public class, and public function a docstring documenting behavior, arguments, return values, and raised exceptions.
- **Why:** Docstrings are accessible at runtime via `help()`/`__doc__` and power tooling (Sphinx, IDEs, doctests) in a way comments never are. The nuance: the docstring should describe the contract — args, return, side effects, exceptions — not restate the signature; type hints complement docstrings (document what types *mean*, not just what they are) rather than replacing prose.
- **Smell:** A `#` comment used where a docstring belongs, an empty/placeholder docstring, or a docstring that merely echoes the function name and adds no contract information.
- **Signal:**
```python
# bad
def find(rows, key):  # look up a row by key
    ...

# good
def find(rows, key):
    """Return the first row whose 'id' equals key.

    Raises KeyError if no row matches.
    """
    ...
```
- **Exceptions:** Truly private helpers (leading underscore) and trivial dunder/property accessors can skip docstrings; don't write ritual docstrings that add no information just to satisfy a linter.

### 121. Use Packages to Organize Modules and Provide Stable APIs  [2nd,3rd] · medium
- **Rule:** Group related modules into packages and expose a curated public API through the package's __init__.py and an explicit __all__.
- **Why:** Packages give namespacing and let you refactor internal module layout without breaking callers — as long as the public surface is defined in one place. The subtlety: `__all__` controls what `from pkg import *` exports and signals intent, but it does not actually make other names private; pair it with re-exports in __init__.py so consumers import from the package root, not deep internal paths.
- **Smell:** Callers reaching into `mypkg.internal.submodule._helper`, no __init__.py curation, or a flat module dumping ground with no __all__ so every name is implicitly public and unsafe to rename.
- **Signal:**
```python
# mypkg/__init__.py
# bad: nothing exported; users dig into internals

# good: stable surface
from mypkg.engine import Runner
from mypkg.models import Job
__all__ = ["Runner", "Job"]   # internal modules free to move
```
- **Exceptions:** Tiny single-purpose libraries may not need package structure; __all__ is unnecessary if you never use star-imports and rely on naming conventions, though it still documents the intended API.

### 122. Consider Module-Scoped Code to Configure Deployment Environments  [2nd,3rd] · medium
- **Rule:** Branch on environment (host introspection or an env var) at module scope to bind the right implementation/config once at import time, rather than checking the environment on every call.
- **Why:** Module bodies run once at import, so deciding dev vs. prod there — via os.environ, sys.platform, or platform introspection — lets the rest of the code stay environment-agnostic. What people get wrong: keep this to selecting config/implementations, not arbitrary side effects; over-clever import-time logic makes imports slow, order-dependent, and hard to test, and a missing/typo'd env var should fail loud, not silently pick a default.
- **Smell:** `if os.environ['ENV'] == 'prod'` repeated inside many functions, or import-time code doing network/IO side effects instead of just selecting configuration.
- **Signal:**
```python
# bad: env checked on every call
def get_db():
    if os.environ['ENV'] == 'prod': return ProdDB()
    return TestDB()

# good: bound once at module scope
if os.environ.get('ENV') == 'prod':
    Database = ProdDB
else:
    Database = TestDB
```
- **Exceptions:** Doesn't apply when config must change at runtime (feature flags, hot reload) — that needs runtime lookup, not import-time binding. Prefer a dedicated settings/config object over scattered module-scope branches once configuration grows beyond a few switches.

### 123. Define a Root Exception to Insulate Callers from APIs  [2nd,3rd] · medium
- **Rule:** Every module/package that raises exceptions should define a single root exception base class, and all module-specific exceptions must subclass it.
- **Why:** The point is not tidy taxonomy — it lets callers choose their blast radius: catch the root to defend against the whole API, catch a specific subclass for known cases, and a leaked non-root exception (e.g. bare ValueError from your internals) signals a bug in your API rather than caller misuse. It also lets you add new exception subtypes later without breaking callers who catch the root.
- **Smell:** A module raising bare built-ins (ValueError, KeyError, RuntimeError) or a flat set of unrelated Exception subclasses with no common base, so callers either over-catch Exception or under-catch and miss new error types.
- **Signal:**
```python
# bad: caller can't distinguish your errors from anyone's
def get_density(weight, volume):
    return weight / volume  # raises bare ZeroDivisionError
# good
class Error(Exception): pass
class InvalidVolumeError(Error): pass
def get_density(weight, volume):
    if volume <= 0: raise InvalidVolumeError('volume must be > 0')
    return weight / volume
```
- **Exceptions:** Tiny internal/private modules with a single caller you control gain little; the discipline pays off at API/library boundaries consumed by code you don't own. You may also layer intermediate roots (one per major feature area) under the top root for larger APIs.

### 124. Know How to Break Circular Dependencies  [2nd,3rd] · high
- **Rule:** When two modules import each other, break the cycle by reordering/deferring rather than papering over it; prefer refactoring shared code into a third module.
- **Why:** The crash (AttributeError / ImportError: cannot import name) happens because at module-load time Python runs top-level code top-to-bottom and a half-initialized module is visible to its importer; the symbol simply isn't defined yet when the second module reaches in. Of the four fixes — reorder imports, import-then-use (dynamic import inside the function), import-and-call-after-definition, and dynamic import — the cleanest long-term fix is extracting the mutually needed pieces into a separate dependency-free module; deferring the import inside the function works but hides coupling and pays a per-call import cost.
- **Smell:** `from a import b` at the top of two files that import each other, or a 'fix' that just moves an `import` statement to the bottom of the file or buries it inside every function without addressing the underlying coupling.
- **Signal:**
```python
# bad: app.py and dialog.py import each other at top level -> AttributeError
# from dialog import show  (dialog.py also does: from app import prefs)
# good: defer the import to call time to break the load-order cycle
def show():
    import app  # imported lazily, after both modules finish loading
    app.prefs.get('font')
```
- **Exceptions:** A one-off lazy import inside a function is acceptable for a genuinely unavoidable cycle (e.g. plugin systems, optional backends). The refactor-into-third-module fix is preferred but not always worth it for a single isolated cycle.

### 125. Consider warnings to Refactor and Migrate Usage  [2nd,3rd] · medium
- **Rule:** When changing an API's behavior or signature in a way callers must adapt to, emit warnings.warn(..., DeprecationWarning, stacklevel=2) during the migration window instead of silently changing or hard-breaking.
- **Why:** Warnings are the bridge between 'logging is for operators at runtime' and 'errors stop execution': they let downstream developers find and fix call sites at their own pace. The detail people botch is stacklevel — it must point the warning at the caller's line, not your library's internal frame, or the warning is useless for locating the offending code. Tests should escalate warnings to errors (warnings.simplefilter('error') / -W error) so new violations fail CI, and production should route them via logging.captureWarnings.
- **Smell:** Silently changing a default, or adding a print()/log line to nudge callers, or removing a parameter outright with no deprecation period; also warnings.warn with no category or default stacklevel=1 (points at the library, not the caller).
- **Signal:**
```python
# bad: silently breaks or just prints
def render(value, unit):  # 'unit' newly required
    ...
# good: warn at the caller's frame during migration
import warnings
def render(value, unit=None):
    if unit is None:
        warnings.warn('unit will be required', DeprecationWarning, stacklevel=2)
        unit = 'px'
```
- **Exceptions:** Skip warnings for purely internal APIs you can migrate in the same change, or for additive/backward-compatible changes that need no caller action. Warnings are a transition tool, not a permanent state — they should be paired with a removal deadline.

### 126. Consider Static Analysis via typing to Obviate Bugs  [2nd,3rd] · medium
- **Rule:** Add type annotations and run a static type checker (mypy/pyright) in CI for code at API boundaries and bug-prone logic, treating reported errors as build failures.
- **Why:** Annotations are inert documentation until a checker enforces them — the value is the tool catching None-handling, wrong argument types, and incompatible returns before runtime, not the syntax itself. The subtlety: don't over-annotate early or annotate everything (it slows iteration and adds noise); apply types strategically to public interfaces and the parts where a type bug would be costly, and adopt incrementally on existing code via gradual/strict-per-module settings. Annotations have no runtime effect, so a wrong annotation that's never checked is worse than none.
- **Smell:** Type hints present in the codebase but no checker wired into CI (so they drift and lie), Any sprinkled to silence errors, or a function whose annotation says -> str while a branch returns None.
- **Signal:**
```python
# bad: annotated but unchecked, and actually wrong
def first(items: list) -> int:
    return items[0] if items else None  # returns None, not int
# good: precise type the checker can verify
from typing import Optional
def first(items: list[int]) -> Optional[int]:
    return items[0] if items else None  # mypy now enforces callers handle None
```
- **Exceptions:** Throwaway scripts, notebooks, and rapid prototypes don't need it. Highly dynamic code (decorators, metaprogramming, **kwargs passthrough) can be hard to type precisely — annotate the stable boundary and don't fight the checker on genuinely dynamic internals.

### 127. Prefer Open Source Projects for Bundling Python Programs over zipimport and zipapp  [3rd] · low
- **Rule:** To ship a self-contained Python application, reach for a maintained packaging tool (shiv, PEX, PyInstaller, Briefcase) rather than hand-rolling distribution with stdlib zipimport/zipapp.
- **Why:** zipapp produces a .pyz that still requires a compatible Python interpreter on the target and, critically, does not handle C-extension dependencies (compiled .so/.pyd can't be imported directly from inside a zip) or bytecode-cache/startup-extraction concerns. The mature OSS tools solve exactly these gaps — extracting native extensions to a cache dir, pinning the interpreter, vendoring dependencies — so rolling your own zipapp pipeline re-implements their hard-won edge cases badly. Match the tool to the target: shiv/PEX assume Python is present; PyInstaller/Briefcase bundle the interpreter for users who have none.
- **Smell:** A build script that manually assembles a zip and sets __main__.py via python -m zipapp, or pip install --target then zip, to distribute an app with third-party (especially compiled) dependencies.
- **Signal:**
```python
# bad: hand-rolled, breaks on any C-extension dep
# python -m zipapp myapp -m 'myapp.cli:main' -o app.pyz
# good: a tool that vendors deps and handles native extensions
# pip install shiv
# shiv -c mycli -o app.pyz -p '/usr/bin/env python3' .
# (or PyInstaller / Briefcase when the target has no Python at all)
```
- **Exceptions:** For a trivial pure-Python, dependency-free script targeting machines that already have the right Python, stdlib zipapp is perfectly adequate and avoids a build-tool dependency. The rule bites once you have third-party or compiled dependencies, or need to guarantee the runtime.
