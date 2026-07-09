# Deep Go review checklist

Distilled from the team's 12 code-review principles + 100 Go Mistakes. This is
the self-contained source for `go-review`; it deliberately goes deeper than
`pr-review/reference/go.md`.

## Observability (correctness, not decoration)
- Every outcome - error, degraded, partial failure, not-found - is in metrics AND logs.
- Request counters fire before validation (rejected requests still count).
- Error tags carry dimensional context (client, model, strategy).
- Graceful degradation emits a warn log AND a dedicated metric (e.g. `*_not_found`), never the generic error metric.
- Metric/tag names are `const`, not inline literals.

## Layering
- Adapters translate; services own business rules; domain owns the model.
- Timestamps set in the repo layer, not the handler.
- Use `request.GetLogger(ctx)`, not a struct-field logger (keeps request context).

## Fail loud
- Required config validated at startup (empty URL -> server does not boot).
- Unknown enum/switch default returning `(nil, nil)` is a bug - return an error.
- Unrecognized input at any boundary is an error, never a silent pass.

## Interfaces and naming
- Interface defined at the consumer, not the producer (`ports.ModelClient` in `ports`, not `merlin`).
- No `util`/`common`/`helper` packages.
- Names encode intent: `Ranker` vs `Strategy`, `Provider` vs `Registry`.
- Overuse of `any`/empty interface is a smell.

## Zero values and platform idioms
- Work with zero values; do not penalize with `-1` when `0` works, no extra `found` bool when the zero value is the sentinel.
- `sort.Stable` for tie-sensitive ordering; `sync.RWMutex` for read-heavy access.
- Map iteration order is nondeterministic - collect keys, `sort`, iterate for any ordering/priority logic.

## Correctness traps (100 Go Mistakes)
- Integer overflow before widening: `uint64(a) + uint64(b)`, not `uint64(a + b)`.
- `float32` loses precision on large ints (timestamps) - use `float64`.
- Global `rand` is a data race - use per-call `rand.New(rand.NewPCG(...))` from `math/rand/v2`.
- Error wrapping: `%w` when callers unwrap, `%v` otherwise - be deliberate.
- Context threaded through all call paths; no `context.TODO()` left in.
- Goroutine leaks: every goroutine has a guaranteed exit; check `defer`/cancel paths.
- No `init()` side effects; no naked returns in non-trivial functions.
- Inject a clock (`benbjohnson/clock`) instead of calling `time.Now()` in testable code.

## Type vs domain correctness
- A passing type assertion / nil check proves shape, not validity.
- After the structural check, validate bounds: multipliers `> 0`, durations `>= 0`, collections non-empty, `GetStringValue() != ""`.

## Mutations and config
- Partial-update APIs use field masks; full-document replacement is wrong for multi-writer paths. Unknown mask paths are validation errors.
- Optional config with wrong type -> error; defaults apply only when the key is absent entirely.
- Every new domain field wired through both directions of the convert layer.

## Operational tunability
- Retry counts, timeouts, backoff live in an `Options` struct with `env:` tags, never hardcoded.

## Platform clients
- HTTP via `atlasHTTPClient.NewDefaultHTTPClient()` + S2S middleware + `StandardTwirpClientOptions`. No bare `&http.Client{}`, no hardcoded auth headers.

## Tests
- New behavior has tests; tests assert behavior, not implementation.
- Cover empty input, max bounds, error paths.
