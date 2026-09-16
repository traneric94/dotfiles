# Effective Python - dense index (124 items)

Tier-1 scan layer for `effective-python-review`, mirroring `go-review/reference/checklist.md`. One line per item: `N · title · rule`. Scan the diff against these; open the full item in `effective-python-rules.md` **only** for a candidate match. Severity/prioritization comes from the cross-language spine (`memory/engineering-principles.md`). The `why`/`smell`/`signal` detail lives in the full reference - not here.

Provenance tags: `•2`/`•3` = book edition (2nd/3rd). 3rd-ed-only items (walrus, `match`, typing, dataclasses) apply only to code targeting modern Python.

## Pythonic Thinking

1. **Know Which Version of Python You're Using** •2·3 - Pin and verify the interpreter version at runtime and in tooling config; never assume the environment runs the Python you developed against.
2. **Follow the PEP 8 Style Guide** •2·3 - Enforce PEP 8 mechanically via a formatter/linter in CI rather than debating style in review comments.
3. **Write Helper Functions Instead of Complex Expressions** •2·3 - Extract any multi-step or repeated expression into a named helper function instead of cramming logic into one dense line.
4. **Prefer Multiple-Assignment Unpacking Over Indexing** •2·3 - Bind sequence/tuple elements to named variables via unpacking instead of repeatedly indexing with numeric subscripts.
5. **Prevent Repetition with Assignment Expressions** •2·3 - Use the walrus operator (`:=`) to compute-and-test a value in one place when the same value would otherwise be assigned then immediately re-checked or recomputed.
6. **Never Expect Python to Detect Errors at Compile Time** •3 - Do not rely on Python's bytecode compilation to surface bugs; gate correctness on tests, type checkers, and linters, and treat any code path not covered by these as unverified.
7. **Always Surround Single-Element Tuples with Parentheses** •3 - Write one-element tuples as `(x,)` with explicit parentheses and the trailing comma; never let a lone trailing comma be the only signal of tuple-ness.
8. **Consider Conditional Expressions for Simple Inline Logic** •3 - Use a conditional expression (`a if cond else b`) only for short, side-effect-free value selection that fits on one readable line; expand to a full if/else statement once branches do real work.
9. **Consider match for Destructuring in Flow Control; Avoid When if Statements Are Sufficient** •3 - Reach for `match` when you are simultaneously branching on the shape/structure of data and binding its parts; keep plain `if`/`elif` when you are only comparing values or testing simple conditions.

## Strings and Slicing

10. **Know the Differences Between bytes and str** •2·3 - Never mix bytes and str in the same operation; decode/encode explicitly at I/O boundaries and pick one representation internally.
11. **Prefer Interpolated F-Strings Over C-style Format Strings and str.format** •2·3 - Use f-strings for string interpolation instead of % formatting or str.format().
12. **Know How to Slice Sequences** •2·3 - Use clean slice syntax and let Python's defaults handle the endpoints instead of writing redundant or out-of-range indices.
13. **Avoid Striding and Slicing in a Single Expression** •2·3 - Never combine start, stop, and a (especially negative) stride in one slice; split striding and slicing into two statements.
14. **Prefer Catch-All Unpacking Over Slicing** •2·3 - Use a starred target (a, *rest = seq) to split off head/tail/middle instead of indexing plus parallel slices.
15. **Understand the Difference Between repr and str when Printing Objects** •2·3 - Define __repr__ to return an unambiguous, ideally eval-able developer representation; only add __str__ when you need a distinct human-facing rendering.
16. **Prefer Explicit String Concatenation over Implicit, Especially in Lists** •3 - Join adjacent string literals with explicit + (or join over multiple lines); never rely on Python silently concatenating side-by-side literals, above all inside list/tuple/call literals.

## Dictionaries

17. **Be Cautious When Relying on dict / Dictionary Insertion Ordering** •2·3 - Don't assume an object behaves like an insertion-ordered dict just because it implements the mapping interface; if order matters, require a real dict or guard explicitly.
18. **Prefer get Over in and KeyError to Handle Missing Dictionary Keys** •2·3 - Read possibly-absent dictionary keys with dict.get(key, default), not the in operator, a try/except KeyError, or a bare subscript followed by branching.
19. **Prefer defaultdict Over setdefault to Handle Missing Items in Internal State** •2·3 - When you control a dictionary as internal state and repeatedly insert-then-mutate per key, use collections.defaultdict(factory) instead of calling setdefault at every access site.
20. **Know How to Construct Key-Dependent Default Values with __missing__** •2·3 - When the default for a missing key must be computed from the key itself, subclass dict and implement __missing__(self, key) rather than forcing setdefault or a parameterless defaultdict factory.
21. **Compose Classes Instead of Deeply Nesting Dictionaries, Lists, and Tuples** •3 - Refactor internal state into small classes (namedtuple/dataclass and helper classes) once bookkeeping grows past a single layer of dicts/lists or a two-element tuple.

## Loops and Iterators

22. **Prefer enumerate Over range** •2·3 - When you need both the index and the element, iterate with enumerate(seq) instead of range(len(seq)) plus subscripting.
23. **Use zip to Process Iterators in Parallel** •2·3 - Iterate multiple related sequences together with zip rather than indexing each by a shared loop counter.
24. **Avoid else Blocks After for and while Loops** •2·3 - Do not attach an else block to for or while loops; refactor the post-loop logic into a helper or a flag/sentinel instead.
25. **Never Use for Loop Variables After the Loop Ends** •3 - Treat a for loop's target variable as undefined once the loop finishes; never read it after the loop body.
26. **Be Defensive when Iterating over Arguments** •2·3 - If a function iterates its input more than once, do not accept a bare iterator - copy it to a list, accept a fresh-iterator factory, or reject single-use iterators explicitly.
27. **Never Modify Containers While Iterating over Them; Use Copies or Caches Instead** •3 - Don't add to or remove from a container inside a loop that iterates over that same container; iterate over a copy or stage the mutations in a separate structure and apply them after the loop.
28. **Pass Iterators to any and all for Efficient Short-Circuiting Logic** •3 - Feed any()/all() a generator expression (or lazy iterator), not a fully materialized list comprehension, so the short-circuit actually saves work.
29. **Consider itertools for Working with Iterators and Generators** •2·3 - Reach for the named itertools building blocks (chain, islice, takewhile/dropwhile, groupby, zip_longest, accumulate, product/permutations/combinations, tee, etc.) before hand-rolling index math or nested loops to link, slice, filter, or combine iterables.

## Functions

30. **Know That Function Arguments Can Be Mutated** •3 - When a function receives a mutable argument it does not intend to modify, either avoid in-place mutation or defensively copy it first; if it does mutate, make that explicit in the name/signature/docstring.
31. **Return Dedicated Result Objects Instead of Requiring Function Callers to Unpack More Than Three Variables (3rd) / Never Unpack More Than Three Variables When Functions Return Multiple Values (2nd)** •2·3 - If a function returns more than three values, return a small named result object (dataclass / NamedTuple) instead of a bare tuple callers must positionally unpack.
32. **Prefer Raising Exceptions to Returning None** •2·3 - Signal errors or 'no result' by raising a specific exception, not by returning None as a sentinel that callers test for truthiness.
33. **Know How Closures Interact with Variable Scope and nonlocal (3rd) / Know How Closures Interact with Variable Scope (2nd)** •2·3 - A nested function can read enclosing-scope variables but assigning a name inside it creates a new local; use nonlocal only for trivial closures, otherwise hold the state in a class.
34. **Reduce Visual Noise with Variable Positional Arguments** •2·3 - Use *args to make optional positional arguments cleaner, but don't unpack large/unbounded iterables into it, and never add a new positional parameter in front of an existing *args.
35. **Provide Optional Behavior with Keyword Arguments** •2·3 - Pass optional/configuration arguments by keyword, and design functions so callers can name them rather than relying on positional order.
36. **Use None and Docstrings to Specify Dynamic Default Arguments** •2·3 - Never use a mutable or dynamically-computed value as a default argument; default to None and construct the real value inside the body, documenting it in the docstring.
37. **Enforce Clarity with Keyword-Only and Positional-Only Arguments** •2·3 - Put confusable or behavior-altering parameters after * to force keyword-only calls, and put implementation-detail params before / to make them positional-only.
38. **Define Function Decorators with functools.wraps** •2·3 - Always apply @functools.wraps(func) to the inner wrapper in any decorator so the wrapped function keeps its identity and metadata.
39. **Prefer functools.partial over lambda Expressions for Glue Functions** •3 - When adapting a callable by pinning some of its positional/keyword arguments, use functools.partial instead of a lambda.

## Comprehensions and Generators

40. **Use Comprehensions Instead of map and filter** •2·3 - Prefer a list/dict/set comprehension over map() and filter() (and their nesting), especially when a lambda is involved.
41. **Avoid More Than Two Control Subexpressions in Comprehensions** •2·3 - Cap a comprehension at two control subexpressions total (any mix of for-clauses and if-clauses); beyond that, use explicit loops.
42. **Reduce Repetition in Comprehensions with Assignment Expressions** •2·3 - When a comprehension computes the same expensive/derived value in both its condition and its output, hoist it once with a walrus assignment (:=).
43. **Consider Generators Instead of Returning Lists** •2·3 - For functions that build and return a sequence by appending in a loop, prefer a generator that yields items instead of accumulating into a list and returning it.
44. **Consider Generator Expressions for Large List Comprehensions** •2·3 - Use a generator expression (parentheses) instead of a list comprehension when the input is large or unbounded and you only iterate the result once.
45. **Compose Multiple Generators with yield from** •2·3 - Delegate to a sub-generator with `yield from subgen()` rather than manually looping `for x in subgen(): yield x`.
46. **Pass Iterators into Generators as Arguments Instead of Calling the send Method** •2·3 - Feed external input into a generator by passing an iterator as a function argument, not by driving it with the send() method.
47. **Manage Iterative State Transitions with a Class Instead of the Generator throw Method** •2·3 - Model resettable or mode-switching iteration with an explicit stateful class (an __iter__ object) rather than injecting exceptions via the generator throw() method to flip behavior.

## Classes and Interfaces

48. **Compose Classes Instead of Nesting Many Levels of Built-in Types** •2 - When a dict/list/tuple structure grows past one level of nesting (a dict of dicts, a dict whose values are tuples of lists), stop and refactor it into small composed classes.
49. **Accept Functions Instead of Classes for Simple Interfaces** •2·3 - For a single-method hook/callback (key function, default factory, visitor), accept a plain callable rather than requiring callers to define and instantiate a class implementing an interface.
50. **Prefer Object-Oriented Polymorphism over Functions with isinstance Checks** •3 - Replace a function that branches on type(x)/isinstance(x, ...) to choose behavior with a method on each type, dispatched polymorphically.
51. **Consider functools.singledispatch for Functional-Style Programming Instead of Object-Oriented Polymorphism** •3 - When you must add type-dispatched behavior to types you don't own (builtins, third-party, or types that shouldn't carry that concern), use @functools.singledispatch with registered implementations instead of either isinstance ladders or forcing methods onto the classes.
52. **Prefer dataclasses for Defining Lightweight Classes** •3 - For a class that mostly holds named fields, default to @dataclass instead of hand-writing __init__/__repr__/__eq__ or reaching for namedtuple/plain tuples/dicts.
53. **Use @classmethod Polymorphism to Construct Objects Generically** •2·3 - When a base class or framework needs to build instances of unknown subclasses, expose a @classmethod factory instead of hardcoding the concrete type or relying on __init__ shape.
54. **Initialize Parent Classes with super** •2·3 - Always initialize superclasses via super().__init__(), never by calling ParentClass.__init__(self, ...) directly.
55. **Consider Composing Functionality with Mix-in Classes** •2·3 - Reach for small stateless mix-in classes that add behavior via methods rather than deep multi-level inheritance trees or instance state.
56. **Prefer Public Attributes over Private Ones** •2·3 - Default to public attributes (or a single leading underscore for "internal") and avoid dunder-prefixed __private fields except to deliberately avoid name clashes in subclasses.
57. **Prefer dataclasses for Creating Immutable Objects** •3 - For value/immutable objects, use @dataclass(frozen=True) instead of hand-writing __init__, __eq__, __hash__, or freezing via custom __setattr__.
58. **Inherit from collections.abc for Custom Container Types** •2·3 - When a class is meant to behave like a container (sequence, set, or mapping), inherit from the matching collections.abc abstract base class instead of hand-rolling the protocol.

## Metaclasses and Attributes

59. **Use Plain Attributes Instead of Setter and Getter Methods** •2·3 - Expose simple instance state as public attributes; do not write Java-style get_x()/set_x() pairs that wrap a plain field.
60. **Consider @property Instead of Refactoring Attributes** •2·3 - When a plain attribute needs new behavior (validation, derived value, lazy compute), convert it to @property in place rather than renaming the field and editing every caller.
61. **Use Descriptors for Reusable @property Methods** •2·3 - When the same property logic (e.g. a 0–100 range validator) repeats across attributes or classes, extract it into a descriptor class instead of copy-pasting @property blocks.
62. **Use __getattr__, __getattribute__, and __setattr__ for Lazy Attributes** •2·3 - Use __getattr__/__setattr__ for dynamic/lazy attributes, prefer __getattr__ over __getattribute__, and inside these hooks reach state via super().__getattribute__/super().__setattr__ (or self.__dict__) to avoid infinite recursion.
63. **Validate Subclasses with __init_subclass__** •2·3 - Enforce subclass constraints (required class attributes, valid field combinations, structural rules) in __init_subclass__ rather than via a custom metaclass.
64. **Register Class Existence with __init_subclass__** •2·3 - Use the __init_subclass__ hook to auto-register or validate subclasses at definition time instead of a metaclass or a manual registration call.
65. **Annotate Class Attributes with __set_name__** •2·3 - Give descriptors a __set_name__(self, owner, name) method so they learn their assigned attribute name automatically, rather than passing the name redundantly to the descriptor constructor or using a metaclass to inject it.
66. **Consider Class Body Definition Order to Establish Relationships Between Attributes** •3 - When attributes need an inherent ordering (columns, form fields, serialization layout), rely on the guaranteed left-to-right class-body definition order surfaced by __set_name__/__init_subclass__ instead of inventing a manual order=N counter on each attribute.
67. **Prefer Class Decorators Over Metaclasses for Composable Class Extensions** •2·3 - When a class-wide transformation (wrap every method, inject behavior, add attributes) needs to stack with other such transformations, implement it as a class decorator rather than a metaclass.

## Concurrency and Parallelism

68. **Use subprocess to Manage Child Processes** •2·3 - Run external commands through the subprocess module, never os.system/os.popen/os.spawn, and always feed input via stdin pipes, set a timeout, and check the return code.
69. **Use Threads for Blocking I/O, Avoid for Parallelism** •2·3 - Use threads to overlap blocking I/O (network, disk, subprocess waits), not to speed up CPU-bound Python work.
70. **Use Lock to Prevent Data Races in Threads** •2·3 - Guard every mutable state shared across threads with a threading.Lock (via a with block); do not rely on the GIL to make read-modify-write atomic.
71. **Use Queue to Coordinate Work Between Threads** •2·3 - Coordinate producer/consumer thread pipelines with queue.Queue, not hand-rolled lists plus sleeps and polling.
72. **Know How to Recognize When Concurrency Is Necessary** •2·3 - Watch for unbounded fan-out-spawning one thread/process per work item as input scales-and switch to a pooled or async model before it becomes a bottleneck.
73. **Avoid Creating New Thread Instances for On-demand Fan-out** •2·3 - Never spawn one `threading.Thread` per work item in a fan-out (e.g. per cell, per row, per request) loop.
74. **Understand How Using Queue for Concurrency Requires Refactoring** •2·3 - If you reach for `queue.Queue` pipelines to fix fan-out, recognize it forces a full rewrite into worker-thread stages - don't bolt it on incrementally.
75. **Consider ThreadPoolExecutor When Threads Are Necessary for Concurrency** •2·3 - For bounded blocking-I/O fan-out, use `ThreadPoolExecutor` rather than raw threads or hand-built Queue pipelines.
76. **Achieve Highly Concurrent I/O with Coroutines** •2·3 - For high-fan-out I/O (thousands of concurrent operations), use `async def` coroutines on the asyncio event loop instead of threads.
77. **Know How to Port Threaded I/O to asyncio** •2·3 - When migrating threaded I/O to asyncio, port incrementally using the event loop's executor/threadsafe bridges rather than rewriting everything at once.
78. **Mix Threads and Coroutines to Ease the Transition to asyncio** •2·3 - Migrate a threaded codebase to asyncio incrementally by bridging the two models rather than rewriting all at once: from a coroutine, offload blocking sync work via loop.run_in_executor / asyncio.to_thread; from a foreign (non-loop) thread, schedule a coroutine onto the loop via asyncio.run_coroutine_threadsafe (which returns a concurrent.futures.Future).
79. **Avoid Blocking the asyncio Event Loop to Maximize Responsiveness (2nd ed.) / Maximize Responsiveness of asyncio Event Loops with async-friendly Worker Threads (3rd ed.)** •2·3 - Never call blocking operations (synchronous file/socket I/O, time.sleep, CPU-heavy work, blocking C calls) directly inside a coroutine; offload them to a worker thread or process via run_in_executor/asyncio.to_thread, and run with debug mode on to catch slow callbacks.
80. **Consider concurrent.futures for True Parallelism** •2·3 - For CPU-bound work that must run in parallel, use concurrent.futures.ProcessPoolExecutor (not threads), and only after confirming the per-task work is large enough to outweigh pickling/IPC overhead.

## Robustness

81. **Take Advantage of Each Block in try/except/else/finally** •2·3 - Put only the operation that can raise inside try, recovery in except, the success-only continuation in else, and unconditional cleanup in finally - don't collapse them.
82. **Consider contextlib and with Statements for Reusable try/finally Behavior** •2·3 - When the same try/finally setup-teardown pattern repeats, encapsulate it as a context manager via @contextlib.contextmanager (or __enter__/__exit__) instead of copy-pasting the finally.
83. **Make pickle Reliable with copyreg (3rd ed.: Make pickle Serialization Maintainable with copyreg)** •2·3 - Register a copyreg pickle function for any class you persist, so unpickling supplies defaults for newly added attributes, can be versioned, and is decoupled from the class's import path.
84. **assert Internal Assumptions and raise Missed Expectations** •3 - Use assert only to verify conditions your own code guarantees internally; raise a real exception for anything caused by external input, callers, or runtime conditions.
85. **Always Make try Blocks as Short as Possible** •3 - Put only the single statement that can raise the exception you intend to handle inside the try block; move setup, follow-up, and unrelated logic out.
86. **Beware of Exception Variables Disappearing** •3 - Never use the except-as variable after the except block; if you need the exception later, bind it to a separate name inside the block.
87. **Beware of Catching the Exception Class** •3 - Catch the most specific exception types you can handle; reserve a bare `except Exception` for top-level boundaries where you log and re-raise or convert, never to silently continue.
88. **Understand the Difference Between Exception and BaseException** •3 - Catch Exception, not BaseException, so that SystemExit, KeyboardInterrupt, and GeneratorExit propagate and let the program shut down.
89. **Use traceback for Enhanced Exception Reporting** •3 - When logging or persisting a caught exception, capture the full traceback via the traceback module instead of stringifying the exception object alone.
90. **Consider Explicitly Chaining Exceptions to Clarify Tracebacks** •3 - When you catch one exception and raise a different one, use `raise New(...) from original` to set the cause explicitly, and use `from None` when you intend to hide the original.
91. **Always Pass Resources into Generators and Have Callers Clean Them Up Outside** •3 - A generator must receive already-open resources as arguments and never own their lifecycle; the caller opens and closes (via with) around the iteration.
92. **Never Set __debug__ to False** •3 - Don't run production code under -O/-OO/PYTHONOPTIMIZE (which sets __debug__ False), and never depend on assert statements for behavior that must execute.
93. **Avoid exec and eval Unless You're Building a Developer Tool** •3 - Don't reach for exec/eval to assemble logic at runtime; use a dict, getattr, closures, or proper data structures - reserve dynamic execution for genuine developer tooling (REPLs, debuggers, templating engines).

## Performance

94. **Profile Before Optimizing** •2·3 - Identify hot paths with cProfile (wrapped in a Profile object) before changing any code for speed; never optimize on a hunch.
95. **Consider memoryview and bytearray for Zero-Copy Interactions with bytes** •2·3 - For slicing or receiving large binary buffers, wrap bytes/bytearray in a memoryview to slice without copying, and read I/O directly into a preallocated bytearray via recv_into/readinto.
96. **Optimize Performance-Critical Code Using timeit Microbenchmarks** •3 - Justify every micro-optimization with a timeit measurement on representative inputs, not intuition.
97. **Know When and How to Replace Python with Another Programming Language** •3 - Reach for another language only after profiling proves a CPU-bound hot spot that algorithmic and Python-level fixes cannot resolve, and then rewrite the smallest possible kernel.
98. **Consider ctypes to Rapidly Integrate with Native Libraries** •3 - Use ctypes for quick pure-Python access to an existing shared library, but declare argtypes/restype explicitly and never let it cross a GIL-bound CPU hot loop.
99. **Consider Extension Modules to Maximize Performance and Ergonomics** •3 - When native integration must be fast, safe, and Pythonic, build a real extension module rather than gluing with ctypes - and prefer a tool (Cython/pybind11) over hand-written CPython C-API.
100. **Lazy-Load Modules with Dynamic Imports to Reduce Startup Time** •3 - Defer expensive or rarely-used imports to the call site (function-local import or module-level __getattr__) instead of importing them eagerly at module top, but only when the import measurably hurts startup.

## Data Structures and Algorithms

101. **Sort by Complex Criteria Using the key Parameter** •2·3 - Pass a key function to sort()/sorted() for derived or multi-field ordering rather than mutating the data or chaining manual comparisons.
102. **Use datetime Instead of time for Local Clocks** •2·3 - Convert between time zones with timezone-aware datetime objects and a real tz database (zoneinfo / ZoneInfo), never with the platform-dependent time module functions.
103. **Use decimal When Precision Is Paramount** •2·3 - Use decimal.Decimal for money and other exact base-10 quantities and for controlled rounding; keep float only for approximate/scientific math.
104. **Prefer deque for Producer-Consumer Queues** •2·3 - Use collections.deque with append/popleft for FIFO queues; never use list.pop(0) or list.insert(0, x) for queue semantics.
105. **Consider Searching Sorted Sequences with bisect** •2·3 - For membership or position lookups in a large already-sorted list, use bisect_left instead of linear `in`/index scans.
106. **Know How to Use heapq for Priority Queues** •2·3 - Implement priority queues with heapq (heappush/heappop) over a list; do not re-sort a list on every push/pop.

## Testing and Debugging

107. **Use repr Strings for Debugging Output** •2 - In debugging/log output, render values with repr (f-string !r, %r, or repr()) - never bare str - and give your own classes a useful __repr__.
108. **Verify Related Behaviors in TestCase Subclasses** •2·3 - Group related tests as methods on a unittest.TestCase subclass, assert with the specific assert helpers (assertEqual, assertRaises, etc.), and use subTest for data-driven cases instead of bare assert or a single mega-test.
109. **Prefer Integration Tests over Unit Tests** •3 - Maintain integration tests that exercise real wired-together behavior in addition to unit tests; mocked unit tests can be green while the integrated system is broken, so both are needed - integration tests cover the inter-module seams, not replace fast unit tests.
110. **Isolate Tests from Each Other with setUp, tearDown, setUpModule, and tearDownModule** •2·3 - Build per-test fixtures in setUp and release them in tearDown so tests can't leak state into each other; reserve setUpModule/tearDownModule for expensive shared resources, knowing they run once per module, not per test.
111. **Use Mocks to Test Code with Complex Dependencies** •2·3 - Mock hard-to-control dependencies with unittest.mock, but constrain them with spec/autospec, patch in the namespace where the name is looked up, and assert the calls - don't use bare unconstrained Mocks.
112. **Encapsulate Dependencies to Facilitate Mocking and Testing** •2·3 - Inject collaborators (DB clients, clocks, network handles) through constructor/function parameters or a wrapper object so tests can substitute test doubles without patching module internals.
113. **Consider Interactive Debugging with pdb** •2·3 - Reach for breakpoint() / pdb to inspect live program state at a failure point instead of scattering print statements or guessing.
114. **Use tracemalloc to Understand Memory Usage and Leaks** •2·3 - Diagnose memory growth and leaks with tracemalloc snapshots/diffs that attribute allocations to source lines, not with gc object counts or guesswork.

## Collaboration

115. **Know Where to Find Community-Built Modules** •2·3 - Prefer a vetted package from PyPI (installed via pip) over hand-rolling a solution to a solved, general problem.
116. **Use Virtual Environments for Isolated and Reproducible Dependencies** •2·3 - Install project dependencies into a per-project virtual environment and pin them with a transitively-complete, version-locked manifest.
117. **Write Docstrings for Every Function, Class, and Module** •2·3 - Give every module, public class, and public function a docstring documenting behavior, arguments, return values, and raised exceptions.
118. **Use Packages to Organize Modules and Provide Stable APIs** •2·3 - Group related modules into packages and expose a curated public API through the package's __init__.py and an explicit __all__.
119. **Consider Module-Scoped Code to Configure Deployment Environments** •2·3 - Branch on environment (host introspection or an env var) at module scope to bind the right implementation/config once at import time, rather than checking the environment on every call.
120. **Define a Root Exception to Insulate Callers from APIs** •2·3 - Every module/package that raises exceptions should define a single root exception base class, and all module-specific exceptions must subclass it.
121. **Know How to Break Circular Dependencies** •2·3 - When two modules import each other, break the cycle by reordering/deferring rather than papering over it; prefer refactoring shared code into a third module.
122. **Consider warnings to Refactor and Migrate Usage** •2·3 - When changing an API's behavior or signature in a way callers must adapt to, emit warnings.warn(..., DeprecationWarning, stacklevel=2) during the migration window instead of silently changing or hard-breaking.
123. **Consider Static Analysis via typing to Obviate Bugs** •2·3 - Add type annotations and run a static type checker (mypy/pyright) in CI for code at API boundaries and bug-prone logic, treating reported errors as build failures.
124. **Prefer Open Source Projects for Bundling Python Programs over zipimport and zipapp** •3 - To ship a self-contained Python application, reach for a maintained packaging tool (shiv, PEX, PyInstaller, Briefcase) rather than hand-rolling distribution with stdlib zipimport/zipapp.
