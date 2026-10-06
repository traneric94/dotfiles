# Go review checklist

Deeper detail lives in any team `memory/*_checklist.md` and the
`100-go-mistakes` reference; this is the fast pre-merge pass.

- Interface defined at consumer, not producer
- Overuse of `any` / empty interface
- Utility packages (`util`, `common`, `helper`) - flag these
- Naked returns, `init()` side effects
- Error wrapping with `%w` vs `%v`
- Context propagation - is it threaded through?
- Goroutine leaks - are all goroutines guaranteed to exit?
